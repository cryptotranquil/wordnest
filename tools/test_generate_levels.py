"""Offline tests for the level generator and checked-in data."""
import copy
import json
import random
import subprocess
import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

from generate_levels import (
    BLOCKLIST,
    DEFAULT_DICTIONARY,
    load_words,
    make_level,
    read_word_list,
    sig,
    validate_collection,
)

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / 'tools/generate_levels.py'


class GeneratedLevelsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dictionary = read_word_list(DEFAULT_DICTIONARY)
        cls.payload = json.loads((ROOT / 'assets/levels/levels.json').read_text(encoding='utf8'))

    def test_checked_in_data_is_dictionary_valid_unique_and_matches_app(self):
        levels = self.payload['levels']
        self.assertEqual([level['number'] for level in levels], list(range(1, 61)))
        self.assertEqual(validate_collection(levels, self.dictionary), [])
        for level in levels:
            with self.subTest(level=level['number']):
                self.assertGreaterEqual(len(level['words']), 2)
                self.assertTrue(all(w['word'] not in BLOCKLIST for w in level['words']))
                self.assertTrue(all(w not in BLOCKLIST for w in level['bonusWords']))
                chapter = (level['number'] - 1) // 20
                self.assertEqual(level['chapter'], ['Whispering Forest', 'Ocean Serenity', 'Celestial Cosmos'][chapter])
        dart = (ROOT / 'lib/src/data/generated_levels.dart').read_text(encoding='utf8')
        self.assertEqual(json.loads(dart.split("r'''", 1)[1].rsplit("'''", 1)[0]), self.payload)

    def test_dictionary_validation_checks_grid_and_bonus_words(self):
        levels = copy.deepcopy(self.payload['levels'])
        levels[0]['words'][0]['word'] = 'ZZZZ'
        levels[1]['bonusWords'].append('ZZQ')
        problems = validate_collection(levels, self.dictionary)
        self.assertTrue(any('ZZZZ not in dictionary' in p for p in problems))
        self.assertTrue(any('ZZQ not in dictionary' in p for p in problems))

    def test_collection_detects_duplicate_wheels_and_grids(self):
        levels = copy.deepcopy(self.payload['levels'])
        levels[1]['letters'] = list(reversed(levels[0]['letters']))
        levels[2]['words'] = copy.deepcopy(levels[0]['words'])
        problems = validate_collection(levels, self.dictionary)
        self.assertTrue(any('duplicate letter set from level 1' in p for p in problems))
        self.assertTrue(any('duplicate grid words from level 1' in p for p in problems))

    def test_curated_word_list_cannot_add_non_dictionary_words(self):
        with tempfile.TemporaryDirectory() as temp:
            dictionary = Path(temp) / 'dictionary.txt'
            allowed = Path(temp) / 'allowed.txt'
            dictionary.write_text('note\nten\nnot\n', encoding='utf8')
            allowed.write_text('note\nzzzz\n', encoding='utf8')
            args = Namespace(dictionary=dictionary, wordlist=allowed, max_wheel=6, common=False)
            words, _, entries = load_words(args)
            self.assertEqual(words, {'NOTE'})
            self.assertNotIn('ZZZZ', entries)

    def test_validate_command_rejects_non_dictionary_bonus(self):
        with tempfile.TemporaryDirectory() as temp:
            payload = copy.deepcopy(self.payload)
            payload['levels'][0]['bonusWords'].append('ZZQ')
            path = Path(temp) / 'invalid.json'
            path.write_text(json.dumps(payload), encoding='utf8')
            result = subprocess.run([sys.executable, str(SCRIPT), '--validate', str(path)],
                                    cwd=ROOT, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('ZZQ not in dictionary', result.stdout)

    def test_exhausted_wheels_do_not_fall_back_to_duplicates(self):
        args = Namespace(max_wheel=6)
        self.assertIsNone(make_level(1, args, {}, {4: ['NOTE']}, {sig('NOTE')}, set(), random.Random(1)))

    def test_append_preserves_existing_levels_and_outputs(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / 'levels.json'
            dart = Path(temp) / 'levels.dart'
            base = [sys.executable, str(SCRIPT), '--out', str(output), '--dart-out', str(dart)]
            subprocess.run(base + ['--count', '4'], cwd=ROOT, check=True, capture_output=True, text=True)
            original = json.loads(output.read_text(encoding='utf8'))
            subprocess.run(base + ['--append', '--count', '2'], cwd=ROOT, check=True, capture_output=True, text=True)
            extended = json.loads(output.read_text(encoding='utf8'))
            self.assertEqual(extended['levels'][:4], original['levels'])
            self.assertEqual([v['number'] for v in extended['levels']], list(range(1, 7)))
            self.assertEqual(validate_collection(extended['levels'], self.dictionary), [])
            self.assertEqual(json.loads(dart.read_text(encoding='utf8').split("r'''", 1)[1].rsplit("'''", 1)[0]), extended)
            single = Path(temp) / 'single.json'
            single_dart = Path(temp) / 'single.dart'
            subprocess.run([sys.executable, str(SCRIPT), '--out', str(single), '--dart-out', str(single_dart), '--count', '6'], cwd=ROOT, check=True, capture_output=True)
            self.assertEqual(json.loads(single.read_text(encoding='utf8')), extended)

            # Neither a mistaken replacement nor a failed generation may clobber data.
            before_json, before_dart = output.read_bytes(), dart.read_bytes()
            rejected = subprocess.run(base + ['--count', '1'], cwd=ROOT, capture_output=True)
            self.assertNotEqual(rejected.returncode, 0)
            tiny = Path(temp) / 'tiny.txt'
            tiny.write_text('note\n', encoding='utf8')
            rejected = subprocess.run(base + ['--append', '--count', '1', '--wordlist', str(tiny)], cwd=ROOT, capture_output=True)
            self.assertNotEqual(rejected.returncode, 0)
            self.assertEqual((output.read_bytes(), dart.read_bytes()), (before_json, before_dart))

            # Guard against accidentally overwriting a different Dart data set.
            dart.write_text("unrelated data", encoding='utf8')
            rejected = subprocess.run(base + ['--append', '--count', '1'], cwd=ROOT, capture_output=True)
            self.assertNotEqual(rejected.returncode, 0)
            self.assertEqual(output.read_bytes(), before_json)
            self.assertEqual(dart.read_text(encoding='utf8'), 'unrelated data')


if __name__ == '__main__':
    unittest.main()
