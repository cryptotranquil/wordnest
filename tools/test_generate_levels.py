"""Structural checks for the checked-in level set (standard library only)."""
import json
import unittest
from pathlib import Path

from generate_levels import validate_level

ROOT = Path(__file__).resolve().parent.parent


class GeneratedLevelsTest(unittest.TestCase):
    def test_checked_in_data_is_valid_and_matches_app_data(self):
        payload = json.loads((ROOT / 'assets/levels/levels.json').read_text())
        levels = payload['levels']
        self.assertEqual([level['number'] for level in levels], list(range(1, 61)))
        for level in levels:
            with self.subTest(level=level['number']):
                self.assertGreaterEqual(len(level['words']), 2)
                self.assertEqual(validate_level(level), [])
                chapter = (level['number'] - 1) // 20
                self.assertEqual(level['chapter'], ['Whispering Forest', 'Ocean Serenity', 'Celestial Cosmos'][chapter])
        dart = (ROOT / 'lib/src/data/generated_levels.dart').read_text()
        self.assertEqual(json.loads(dart.split("r'''", 1)[1].rsplit("'''", 1)[0]), payload)


if __name__ == '__main__':
    unittest.main()
