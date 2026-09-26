"""Pure threshold policy: downward alerts with five percentage points of hysteresis."""
import math
THRESHOLDS = (50, 30, 10)

def evaluate_level(level, notified):
    if not math.isfinite(level) or not 0 <= level <= 100:
        return None, list(notified)
    armed = set(notified)
    for threshold in THRESHOLDS:
        if level >= threshold + 5:
            armed.discard(threshold)
    crossed = [t for t in THRESHOLDS if level <= t and t not in armed]
    # One useful message if a report skips several levels; no burst of alerts.
    alert = min(crossed) if crossed else None
    armed.update(crossed)
    return alert, sorted(armed, reverse=True)
