#!/usr/bin/env python3
"""Generate dictionary-checked, unique WordNest crossword levels.

Examples:
  python tools/generate_levels.py --count 60 --common --min-zipf 4.5 --replace
  python tools/generate_levels.py --append --count 20 --common --min-zipf 4.5
  python tools/generate_levels.py --validate assets/levels/levels.json

The bundled ENABLE subset is the default dictionary. A custom --wordlist only
narrows that dictionary; it cannot introduce words not in it.
"""
import argparse
import json
from pathlib import Path
import random
import sys
from collections import Counter, defaultdict
from itertools import combinations

MIN_LEN = 3
MAX_GRID = 8            # default max rows/cols so the board fits a phone (--max-grid)
BONUS_CAP = 30          # max bonus words stored per level
MIN_SUBS = {4: 5, 5: 8, 6: 10, 7: 12}   # a wheel needs at least this many playable words

CHAPTERS = ["Whispering Forest", "Ocean Serenity", "Celestial Cosmos"]
THEME_KEYS = ["forest", "ocean", "cosmos"]
LEVELS_PER_CHAPTER = 20

# Words that get a preference in a chapter (only used to choose which wheel to play).
THEME_WORDS = {
    "forest": "TREE TREES LEAF LEAVES PINE OAK MOSS FERN BARK WOOD WOODS ROOT ROOTS DEER OWL BIRD NEST BEAR FOX GLADE PATH TRAIL BRANCH SEED LOG DEW BERRY ACORN FOREST GREEN WILD STREAM BROOK HARE ELM ASH BIRCH CEDAR PETAL BLOOM GROVE HIVE BEE WREN LARK".split(),
    "ocean": "SEA WAVE WAVES TIDE TIDES SALT SHELL SAND REEF FISH WHALE SHARK CORAL DEEP BLUE SURF FOAM BAY GULL SEAL SAIL BOAT ANCHOR PEARL KELP CRAB EEL ISLE SHORE COAST DIVE SWIM DRIFT BREEZE STORM CURRENT HARBOR".split(),
    "cosmos": "STAR STARS MOON SUN ORBIT COMET COSMOS PLANET SPACE GALAXY NOVA LUNAR SOLAR DUST VOID RING MARS SKY NIGHT ASTRO RAY BEAM GLOW DAWN DUSK ECLIPSE METEOR SATURN COSMIC LIGHT".split(),
}

# Minimal safety list. EXTEND THIS for production (or use a curated dictionary).
BLOCKLIST = set("""ASS ARSE DAMN HELL SEX SEXY PORN NUDE NAZI RAPE RAPED RAPES KILL KILLS KILLER DEAD DIE DIES GOD
SHIT SHITS SHITTED FUCK FUCKS FUCKED FUCKER FUCKERS FUCKING BITCH BITCHES BASTARD BASTARDS
DICK DICKS COCK COCKS CUNT CUNTS PISS PISSED PISSES CRAP CRAPS SLUT SLUTS WHORE WHORES
RACISM RACIST RACISTS SLAVE SLAVES SLAVERY GUN GUNS MURDER MURDERS SUICIDE SUICIDES
DEATH DEATHS WAR WARS THREAT THREATS
""".split())


# --------------------------------------------------------------------------- words
def read_word_list(path):
    """Read one ASCII English word per line, normalized to uppercase."""
    out = set()
    try:
        with open(path, encoding="utf8") as fh:
            for line in fh:
                word = line.strip().upper()
                if word.isalpha() and word.isascii():
                    out.add(word)
    except OSError as exc:
        sys.exit(f"Cannot read word list {path}: {exc}")
    if not out:
        sys.exit(f"Word list is empty: {path}")
    return out


def load_words(args):
    """Return eligible generation words, frequencies, and the dictionary.

    A curated word list and frequency filtering can only narrow the dictionary;
    neither can add words that are absent from it.
    """
    dictionary = read_word_list(args.dictionary)
    words = set(dictionary)
    if args.wordlist:
        words &= read_word_list(args.wordlist)
    words = {w for w in words if MIN_LEN <= len(w) <= args.max_wheel
             and w not in BLOCKLIST and len(set(w)) > 1}
    freq = {}
    if args.common:
        try:
            import wordfreq  # type: ignore
        except ImportError:
            sys.exit("--common needs the wordfreq package: pip install wordfreq==3.1.1")
        freq = {w: wordfreq.zipf_frequency(w.lower(), "en") for w in words}
        words = {w for w in words if freq[w] >= args.min_zipf}
    if not words:
        sys.exit("No eligible dictionary words remain after filtering")
    return words, freq, dictionary


def sig(word):
    return "".join(sorted(word))


def build_index(words):
    by_sig = defaultdict(list)
    for w in words:
        by_sig[sig(w)].append(w)
    return by_sig


def subwords_of(root, by_sig):
    """All words (len>=3) buildable from the letters of root."""
    letters = sorted(root)
    n = len(letters)
    found = set()
    for k in range(MIN_LEN, n + 1):
        for idx in combinations(range(n), k):
            key = "".join(letters[i] for i in idx)
            for w in by_sig.get(key, ()):
                found.add(w)
    return found


def can_build(word, letters):
    return not (Counter(word) - Counter(letters))


# --------------------------------------------------------------------------- crossword
class Grid:
    def __init__(self):
        self.cells = {}    # (r,c) -> letter
        self.owner = {}    # (r,c) -> set of 'across'/'down'
        self.words = []    # (word, r, c, dir)

    def occ(self, r, c):
        return (r, c) in self.cells

    def can_place(self, w, r, c, d):
        dr, dc = (1, 0) if d == "down" else (0, 1)
        if self.occ(r - dr, c - dc) or self.occ(r + dr * len(w), c + dc * len(w)):
            return False
        crosses = 0
        for i, ch in enumerate(w):
            rr, cc = r + dr * i, c + dc * i
            if (rr, cc) in self.cells:
                if self.cells[(rr, cc)] != ch or d in self.owner[(rr, cc)]:
                    return False
                crosses += 1
            else:
                if self.occ(rr + dc, cc + dr) or self.occ(rr - dc, cc - dr):
                    return False
        return crosses < len(w)

    def place(self, w, r, c, d):
        dr, dc = (1, 0) if d == "down" else (0, 1)
        for i, ch in enumerate(w):
            p = (r + dr * i, c + dc * i)
            self.cells[p] = ch
            self.owner.setdefault(p, set()).add(d)
        self.words.append((w, r, c, d))

    def bbox(self):
        rs = [p[0] for p in self.cells]
        cs = [p[1] for p in self.cells]
        return min(rs), min(cs), max(rs), max(cs)


def build_crossword(rng, root, candidates, target, attempts=80, max_grid=MAX_GRID):
    """Randomised greedy placement. Returns the best Grid or None."""
    best = None
    best_key = None
    for _ in range(attempts):
        g = Grid()
        first = root if rng.random() < 0.75 else rng.choice([w for w in candidates if len(w) >= len(root) - 1] or [root])
        g.place(first, 0, 0, "across" if rng.random() < 0.5 else "down")
        pool = [w for w in candidates if w != first]
        rng.shuffle(pool)
        pool.sort(key=lambda w: -len(w) + rng.random() * 2.2)
        for w in pool:
            if len(g.words) >= target:
                break
            opts = []
            for (pr, pc), ch in g.cells.items():
                for i, wc in enumerate(w):
                    if wc != ch:
                        continue
                    for d in ("across", "down"):
                        r, c = (pr, pc - i) if d == "across" else (pr - i, pc)
                        if g.can_place(w, r, c, d):
                            opts.append((r, c, d))
            if opts:
                g.place(w, *rng.choice(opts))
        r0, c0, r1, c1 = g.bbox()
        rows, cols = r1 - r0 + 1, c1 - c0 + 1
        if rows > max_grid or cols > max_grid:
            continue
        key = (len(g.words), -rows * cols)
        if best is None or key > best_key:
            best, best_key = g, key
            if len(g.words) >= target and rows * cols <= target * 8:
                break
    return best


# --------------------------------------------------------------------------- validation
def validate_level(level, wordset=None):
    """Returns list of problems (empty = OK). Mirrors the Dart test."""
    errs = []
    rows, cols = level["rows"], level["cols"]
    letters = level["letters"]
    cells = {}
    grid_words = [w["word"] for w in level["words"]]
    for w in level["words"]:
        dr, dc = (1, 0) if w["dir"] == "down" else (0, 1)
        for i, ch in enumerate(w["word"]):
            r, c = w["row"] + dr * i, w["col"] + dc * i
            if not (0 <= r < rows and 0 <= c < cols):
                errs.append(f'{w["word"]} outside grid')
            if cells.get((r, c), ch) != ch:
                errs.append(f'{w["word"]} crossing mismatch at {r},{c}')
            cells[(r, c)] = ch
    for w in grid_words + level["bonusWords"]:
        if not can_build(w, letters):
            errs.append(f"{w} cannot be built from {''.join(letters)}")
        if wordset is not None and w not in wordset:
            errs.append(f"{w} not in dictionary")
    if len(set(grid_words)) != len(grid_words):
        errs.append("duplicate grid word")
    if len(set(level["bonusWords"])) != len(level["bonusWords"]):
        errs.append("duplicate bonus word")
    for b in level["bonusWords"]:
        if b in grid_words:
            errs.append(f"{b} is both grid and bonus")
    gset = set(grid_words)
    for r in range(rows):
        run = ""
        for c in range(cols + 1):
            if (r, c) in cells:
                run += cells[(r, c)]
            else:
                if len(run) > 1 and run not in gset:
                    errs.append(f"accidental across run {run}")
                run = ""
    for c in range(cols):
        run = ""
        for r in range(rows + 1):
            if (r, c) in cells:
                run += cells[(r, c)]
            else:
                if len(run) > 1 and run not in gset:
                    errs.append(f"accidental down run {run}")
                run = ""
    return errs


# --------------------------------------------------------------------------- level plan
def chapter_name(index):
    base = CHAPTERS[index % len(CHAPTERS)]
    cycle = index // len(CHAPTERS)
    if cycle == 0:
        return base
    roman = ["", "", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    return f"{base} {roman[cycle + 1] if cycle + 1 < len(roman) else cycle + 1}"


def plan(n, max_wheel):
    """Difficulty for level n (1-based)."""
    ch = (n - 1) // LEVELS_PER_CHAPTER
    pos = (n - 1) % LEVELS_PER_CHAPTER
    size = 4 if pos < 4 else 5 if pos < 10 else 6
    if ch >= 1:
        size = max(size, 5)
    if ch >= 2:
        size = max(size, 6)
    if ch >= 3 and pos >= 10:
        size = 7
    size = min(size, max_wheel)
    target = min(9, 3 + pos // 4 + min(ch, 2))
    return ch, size, target


def theme_score(subs, theme_key):
    tw = THEME_WORDS.get(theme_key, ())
    return sum(1 for w in tw if w in subs)


def make_level(n, args, by_sig, roots_by_size, used_wheels, used_grids, rng):
    ch, size, target = plan(n, args.max_wheel)
    theme = THEME_KEYS[ch % len(THEME_KEYS)]
    pool = roots_by_size.get(size, [])
    if not pool:
        return None
    candidates = [r for r in pool if sig(r) not in used_wheels]
    rng.shuffle(candidates)
    # try a sample, preferring themed roots
    sample = candidates[:60]
    sample.sort(key=lambda r: -theme_score(subwords_of(r, by_sig), theme))
    for root in sample + candidates[60:]:
        subs = subwords_of(root, by_sig)
        cand = sorted(subs)
        if len(cand) < target:
            continue
        g = build_crossword(rng, root, cand, target, max_grid=args.max_grid)
        if g is None or len(g.words) < max(2, target - 1):
            continue
        r0, c0, _, _ = g.bbox()
        r1, c1 = g.bbox()[2], g.bbox()[3]
        grid_words = [w for w, *_ in g.words]
        grid_signature = tuple(sorted(grid_words))
        if grid_signature in used_grids:
            continue
        letters = list(root)
        rng.shuffle(letters)
        bonus = [w for w in subs if w not in grid_words]
        bonus.sort(key=lambda w: (-args._freq.get(w, 0), -len(w), w))
        bonus = sorted(bonus[:BONUS_CAP])
        level = {
            "number": n,
            "chapter": chapter_name(ch),
            "letters": letters,
            "rows": r1 - r0 + 1,
            "cols": c1 - c0 + 1,
            "words": [{"word": w, "row": r - r0, "col": c - c0, "dir": d}
                      for (w, r, c, d) in sorted(g.words, key=lambda x: (x[1], x[2], x[3]))],
            "bonusWords": bonus,
        }
        if validate_level(level, args._wordset):
            continue
        used_wheels.add(sig(root))
        used_grids.add(grid_signature)
        return level
    return None


DEFAULT_DICTIONARY = Path(__file__).resolve().parent / "dictionaries" / "enable1_3to7.txt"


def validate_collection(levels, dictionary):
    """Validate dictionary membership, structure, order, and uniqueness."""
    problems = []
    numbers = [level["number"] for level in levels]
    if not numbers or numbers != list(range(1, len(numbers) + 1)):
        problems.append("level numbers must be contiguous starting at 1")
    seen_wheels = {}
    seen_grids = {}
    for level in levels:
        number = level["number"]
        for error in validate_level(level, dictionary):
            problems.append(f"level {number}: {error}")
        wheel = sig(level["letters"])
        grid = tuple(sorted(w["word"] for w in level["words"]))
        if wheel in seen_wheels:
            problems.append(f"level {number}: duplicate letter set from level {seen_wheels[wheel]}")
        else:
            seen_wheels[wheel] = number
        if grid in seen_grids:
            problems.append(f"level {number}: duplicate grid words from level {seen_grids[grid]}")
        else:
            seen_grids[grid] = number
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--count", type=int, default=100, help="number of new levels to generate")
    ap.add_argument("--start", type=int, help="first level (1 for a new set; next number when appending)")
    ap.add_argument("--seed", type=int, default=2024)
    ap.add_argument("--out", default="assets/levels/levels.json")
    ap.add_argument("--dart-out", default="lib/src/data/generated_levels.dart", help="generated Dart data used by the app")
    ap.add_argument("--dictionary", default=str(DEFAULT_DICTIONARY), help="dictionary file (default: bundled ENABLE 3–7 letter subset)")
    ap.add_argument("--wordlist", help="optional curated word list; intersected with the dictionary")
    ap.add_argument("--common", action="store_true", help="keep only common words (needs wordfreq)")
    ap.add_argument("--min-zipf", type=float, default=3.0, help="commonness cutoff for --common (higher = more common)")
    ap.add_argument("--max-wheel", type=int, default=6, help="largest wheel size (4-7)")
    ap.add_argument("--max-grid", type=int, default=MAX_GRID, help="largest board rows/cols")
    ap.add_argument("--validate", metavar="JSON", help="validate an existing levels file and exit")
    ap.add_argument("--append", action="store_true", help="preserve and extend the existing --out file")
    ap.add_argument("--replace", action="store_true", help="explicitly allow replacing existing output files")
    args = ap.parse_args()

    if args.count < 1 or (args.start is not None and args.start < 1) or not 4 <= args.max_wheel <= 7 or args.max_grid < 4:
        ap.error("count and start must be positive; max-wheel must be 4–7 and max-grid at least 4")
    if args.append and args.replace:
        ap.error("--append and --replace cannot be combined")
    if args.validate and (args.append or args.replace):
        ap.error("--validate cannot be combined with --append or --replace")

    # Validation checks dictionary membership, not the optional frequency or
    # curated generation filters, which may change over time.
    dictionary = read_word_list(args.dictionary)
    if args.validate:
        with open(args.validate, encoding="utf8") as fh:
            data = json.load(fh)
        problems = validate_collection(data["levels"], dictionary)
        for problem in problems:
            print(problem)
        print(f"{len(data['levels'])} levels checked, {len(problems)} problems")
        sys.exit(1 if problems else 0)

    output = Path(args.out)
    dart_output = Path(args.dart_out)
    if output.resolve() == dart_output.resolve():
        ap.error("JSON and Dart outputs must be different files")
    levels = []
    if args.append:
        if not output.is_file():
            ap.error("--append requires an existing --out JSON file")
        with output.open(encoding="utf8") as fh:
            data = json.load(fh)
        levels = data["levels"]
        problems = validate_collection(levels, dictionary)
        if problems:
            for problem in problems:
                print(problem, file=sys.stderr)
            sys.exit("Existing levels failed validation; no output was changed")
        if dart_output.exists():
            # Do not accidentally overwrite an unrelated Dart level set when a
            # custom JSON path is supplied without a matching --dart-out.
            dart_text = dart_output.read_text(encoding="utf8")
            marker = "const String generatedLevelsJson = r\'\'\'"
            try:
                encoded = dart_text.split(marker, 1)[1].rsplit("\'\'\';", 1)[0]
                dart_data = json.loads(encoded)
            except (IndexError, json.JSONDecodeError):
                sys.exit("Dart output is not recognized; no output was changed")
            if dart_data != data:
                sys.exit("JSON and Dart outputs do not match; no output was changed")
        start = len(levels) + 1
        if args.start is not None and args.start != start:
            ap.error(f"--start must be {start} when appending")
    else:
        if args.start not in (None, 1):
            ap.error("new sets must start at 1; use --append to extend an existing set")
        if not args.replace and (output.exists() or dart_output.exists()):
            ap.error("output exists; use --append to extend it or --replace to overwrite it")
        start = 1

    words, freq, dictionary = load_words(args)
    args._freq = freq
    args._wordset = dictionary
    by_sig = build_index(words)
    roots_by_size = defaultdict(list)
    seen = set()
    for w in sorted(words):
        if 4 <= len(w) <= args.max_wheel and sig(w) not in seen:
            subs = subwords_of(w, by_sig)
            if len(subs) >= MIN_SUBS.get(len(w), 12):
                roots_by_size[len(w)].append(w)
                seen.add(sig(w))
    for size in sorted(roots_by_size):
        print(f"wheel size {size}: {len(roots_by_size[size])} usable roots")

    used_wheels = {sig(level["letters"]) for level in levels}
    used_grids = {tuple(sorted(w["word"] for w in level["words"])) for level in levels}
    for n in range(start, start + args.count):
        rng = random.Random(args.seed * 100003 + n)
        lv = make_level(n, args, by_sig, roots_by_size, used_wheels, used_grids, rng)
        if lv is None:
            sys.exit(f"Could not build unique level {n}; existing output was not overwritten. Try a larger dictionary or different seed.")
        levels.append(lv)

    problems = validate_collection(levels, dictionary)
    if problems:
        sys.exit("Generated data failed validation; existing output was not overwritten:\n" + "\n".join(problems))
    out = {"version": 1, "levels": levels}
    output.parent.mkdir(parents=True, exist_ok=True)
    dart_output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
    # The app consumes the same generated data synchronously, without an asset race.
    encoded = json.dumps(out, ensure_ascii=True, separators=(",", ":"))
    dart_output.write_text(
        "// Generated by tools/generate_levels.py; do not edit.\n"
        "const String generatedLevelsJson = r\'\'\'" + encoded + "\'\'\';\n",
        encoding="utf8",
    )
    print(f"wrote {len(levels)} levels to {output} and {dart_output}")


if __name__ == "__main__":
    main()
