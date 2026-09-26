import unittest
from .thresholds import evaluate_level
class ThresholdTests(unittest.TestCase):
    def test_each_level_once(self):
        flags=[]; emitted=[]
        for level in [90,50,49,51,49,30,29,10,9]:
            alert,flags=evaluate_level(level,flags)
            if alert is not None: emitted.append(alert)
        self.assertEqual(emitted,[50,30,10])
    def test_skipped_levels_emit_only_most_urgent(self):
        self.assertEqual(evaluate_level(8,[]),(10,[50,30,10]))
    def test_refill_rearms(self):
        alert,flags=evaluate_level(80,[50,30,10]);self.assertIsNone(alert)
        self.assertEqual(evaluate_level(49,flags),(50,[50]))
    def test_bad_data_ignored(self):
        for value in [float('nan'),float('inf'),-1,101]:
            self.assertEqual(evaluate_level(value,[50]),(None,[50]))
if __name__=='__main__': unittest.main()
