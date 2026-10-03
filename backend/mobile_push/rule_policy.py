import math

def normalize_rules(groups,metrics):
    if not isinstance(groups,list) or len(groups)>20:raise ValueError('Use up to 20 alert conditions.')
    result=[];seen=set()
    for group in groups:
        if not isinstance(group,dict):raise ValueError('Invalid alert condition.')
        name=group.get('metric');comparison=group.get('comparison');values=group.get('thresholds')
        if not isinstance(name,str) or name not in metrics or comparison not in ('lte','gte'):raise ValueError('Choose a supported reading and comparison.')
        if not isinstance(values,list) or not 1<=len(values)<=20:raise ValueError('Enter between 1 and 20 thresholds for each condition.')
        spec=metrics[name]
        for value in values:
            if isinstance(value,bool) or not isinstance(value,(int,float)) or not math.isfinite(value):raise ValueError('Thresholds must be finite numbers.')
            if (spec['minimum'] is not None and value<spec['minimum']) or (spec['maximum'] is not None and value>spec['maximum']):raise ValueError(f"{spec['label']} thresholds must be between {spec['minimum']} and {spec['maximum']} {spec['unit']}.")
            if spec['boolean'] and (value not in (0,1) or (comparison=='lte' and value!=0) or (comparison=='gte' and value!=1)):raise ValueError('Choose On or Off for switch readings.')
            key=(name,comparison,float(value))
            if key not in seen:seen.add(key);result.append(key)
    if len(result)>50:raise ValueError('Use up to 50 thresholds per device.')
    return result

def evaluate_rule(value,threshold,comparison,triggered,spec):
    if value is None or not math.isfinite(value):return False,triggered
    reached=value<=threshold if comparison=='lte' else value>=threshold
    if not triggered:return reached,reached
    recovered=not reached and (abs(value-threshold)>=spec['reset_margin'] or value==spec['minimum'] or value==spec['maximum'])
    return False,not recovered


def most_urgent_rules(rules):
    groups={}
    for rule in rules:
        key=(rule.metric,rule.comparison)
        prior=groups.get(key)
        if prior is None or (rule.threshold<prior.threshold if rule.comparison=='lte' else rule.threshold>prior.threshold):groups[key]=rule
    return list(groups.values())
