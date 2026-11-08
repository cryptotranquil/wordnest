#!/usr/bin/env python3
"""WordNest level generator.

Generates crossword levels (letter wheel + crossword + bonus words) as JSON.
Every level is checked with the same rules as test/level_validation_test.dart.

Examples
--------
  # real dictionary (one word per line, e.g. the ENABLE list) + only common words
  pip install wordfreq
  python tools/generate_levels.py --count 500 --dictionary enable1.txt --common \
      --out assets/levels/levels.json

  # a plain word list you trust
  python tools/generate_levels.py --count 200 --wordlist my_words.txt

  # re-check an existing file
  python tools/generate_levels.py --validate assets/levels/levels.json --wordlist my_words.txt
"""
import argparse
import json
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
""".split())


# --------------------------------------------------------------------------- words
def load_words(args):
    """Returns (words:set[str], freq:dict[str,float])."""
    words = set()
    freq = {}

    def read_file(path):
        out = set()
        with open(path, encoding="utf8") as fh:
            for line in fh:
                w = line.strip().split()[0].upper() if line.strip() else ""
                if w.isalpha() and w.isascii():
                    out.add(w)
        return out

    dictionary = read_file(args.dictionary) if args.dictionary else None
    plain = read_file(args.wordlist) if args.wordlist else None
    wf = None
    if args.common:
        try:
            import wordfreq  # type: ignore
            wf = wordfreq
        except ImportError:
            sys.exit("--common needs the wordfreq package: pip install wordfreq")

    if plain is not None:
        words = plain
    elif dictionary is not None:
        words = dictionary
    elif wf is not None:
        words = {w.upper() for w in wf.top_n_list("en", 80000) if w.isalpha() and w.isascii()}
    else:
        sys.exit("Give me words: --wordlist FILE, or --dictionary FILE [--common].")

    if wf is not None:
        for w in list(words):
            z = wf.zipf_frequency(w.lower(), "en")
            freq[w] = z
        if args.common:
            words = {w for w in words if freq.get(w, 0) >= args.min_zipf}
        if dictionary is not None and plain is None:
            words &= dictionary
    words = {w for w in words if MIN_LEN <= len(w) <= args.max_wheel and w not in BLOCKLIST
             and len(set(w)) > 1}
    return words, freq


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


def make_level(n, args, by_sig, roots_by_size, used_roots, rng):
    ch, size, target = plan(n, args.max_wheel)
    theme = THEME_KEYS[ch % len(THEME_KEYS)]
    pool = roots_by_size.get(size, [])
    if not pool:
        return None
    candidates = [r for r in pool if r not in used_roots] or pool
    rng.shuffle(candidates)
    # try a sample, preferring themed roots
    sample = candidates[:60]
    sample.sort(key=lambda r: -theme_score(subwords_of(r, by_sig), theme))
    for root in sample:
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
        used_roots.add(root)
        return level
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--count", type=int, default=100, help="how many levels to generate")
    ap.add_argument("--start", type=int, default=1, help="first level number")
    ap.add_argument("--seed", type=int, default=2024)
    ap.add_argument("--out", default="assets/levels/levels.json")
    ap.add_argument("--wordlist", help="plain word list, one word per line (used as-is)")
    ap.add_argument("--dictionary", help="valid-words list (e.g. ENABLE); combine with --common")
    ap.add_argument("--common", action="store_true", help="keep only common words (needs wordfreq)")
    ap.add_argument("--min-zipf", type=float, default=3.0, help="commonness cutoff for --common (higher = more common)")
    ap.add_argument("--max-wheel", type=int, default=6, help="largest wheel size (4-7)")
    ap.add_argument("--max-grid", type=int, default=MAX_GRID, help="largest board rows/cols")
    ap.add_argument("--validate", metavar="JSON", help="validate an existing levels file and exit")
    args = ap.parse_args()

    words, freq = load_words(args)
    args._freq = freq
    args._wordset = words
    by_sig = build_index(words)

    if args.validate:
        data = json.load(open(args.validate, encoding="utf8"))
        bad = 0
        nums = [lv["number"] for lv in data["levels"]]
        if nums != list(range(nums[0], nums[0] + len(nums))):
            print("WARNING: level numbers are not contiguous")
        for lv in data["levels"]:
            errs = validate_level(lv, words)
            if errs:
                bad += 1
                print(f'level {lv["number"]}: ' + "; ".join(errs))
        print(f"{len(data['levels'])} levels checked, {bad} with problems")
        sys.exit(1 if bad else 0)

    # candidate wheels per size: one word per letter-set
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

    levels = []
    used = set()
    for n in range(args.start, args.start + args.count):
        rng = random.Random(args.seed * 100003 + n)
        lv = make_level(n, args, by_sig, roots_by_size, used, rng)
        if lv is None:
            print(f"could not build level {n}; stopping (more words or a bigger list needed)")
            break
        levels.append(lv)

    out = {"version": 1, "levels": levels}
    with open(args.out, "w", encoding="utf8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
    print(f"wrote {len(levels)} levels to {args.out}")
    if len(levels) < args.count:
        sys.exit(2)


if __name__ == "__main__":
    main()
