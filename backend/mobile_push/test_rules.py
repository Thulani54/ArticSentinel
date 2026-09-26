import unittest
from .rule_policy import normalize_rules,evaluate_rule
PERCENT=dict(label='Gas remaining',unit='%',reset_margin=5,minimum=0,maximum=100,boolean=False)
TEMP=dict(label='Temperature',unit='°C',reset_margin=.5,minimum=-100,maximum=500,boolean=False)
STATE=dict(label='Relay',unit='',reset_margin=.5,minimum=0,maximum=1,boolean=True)
class RulePolicyTests(unittest.TestCase):
    def test_custom_percentages_and_deduplication(self):
        self.assertEqual(normalize_rules([{'metric':'gas','comparison':'lte','thresholds':[75,40,15,40]}],{'gas':PERCENT}),[('gas','lte',75.),('gas','lte',40.),('gas','lte',15.)])
    def test_invalid_percentages_and_nonfinite(self):
        for value in [-1,101,float('nan'),float('inf'),True,'30']:
            with self.subTest(value=value), self.assertRaises(ValueError):normalize_rules([{'metric':'gas','comparison':'lte','thresholds':[value]}],{'gas':PERCENT})
    def test_unknown_metric_rejected(self):
        with self.assertRaises(ValueError):normalize_rules([{'metric':'auth_key','comparison':'gte','thresholds':[1]}],{'gas':PERCENT})
    def test_empty_list_disables_thresholds(self):self.assertEqual(normalize_rules([],{'gas':PERCENT}),[])
    def test_low_threshold_only_fires_once_until_recovery(self):
        fired,latched=evaluate_rule(30,30,'lte',False,PERCENT);self.assertTrue(fired)
        self.assertEqual(evaluate_rule(29,30,'lte',latched,PERCENT),(False,True))
        self.assertEqual(evaluate_rule(32,30,'lte',latched,PERCENT),(False,True))
        self.assertEqual(evaluate_rule(35,30,'lte',latched,PERCENT),(False,False))
        self.assertEqual(evaluate_rule(30,30,'lte',False,PERCENT),(True,True))
    def test_high_and_negative_temperature(self):
        self.assertEqual(evaluate_rule(-17,-18,'gte',False,TEMP),(True,True))
        self.assertEqual(evaluate_rule(-18.2,-18,'gte',True,TEMP),(False,True))
        self.assertEqual(evaluate_rule(-19,-18,'gte',True,TEMP),(False,False))
    def test_binary_rule_and_recovery(self):
        self.assertEqual(normalize_rules([{'metric':'relay','comparison':'gte','thresholds':[1]}],{'relay':STATE}),[('relay','gte',1.)])
        self.assertEqual(evaluate_rule(0,1,'gte',True,STATE),(False,False))
        with self.assertRaises(ValueError):normalize_rules([{'metric':'relay','comparison':'gte','thresholds':[0]}],{'relay':STATE})
    def test_missing_data_does_not_rearm_or_trigger(self):
        self.assertEqual(evaluate_rule(None,30,'lte',True,PERCENT),(False,True))
        self.assertEqual(evaluate_rule(float('nan'),30,'lte',False,PERCENT),(False,False))
    def test_near_limit_can_rearm_at_full(self):
        self.assertEqual(evaluate_rule(100,99,'lte',True,PERCENT),(False,False))

    def test_skipped_thresholds_send_only_most_urgent_per_reading(self):
        from types import SimpleNamespace
        from .rule_policy import most_urgent_rules
        rules=[SimpleNamespace(metric='gas',comparison='lte',threshold=v) for v in [50,30,10]]
        rules += [SimpleNamespace(metric='temp',comparison='gte',threshold=v) for v in [5,10]]
        self.assertEqual([r.threshold for r in most_urgent_rules(rules)],[10,10])
