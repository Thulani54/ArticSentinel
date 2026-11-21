// Same illustrative profiles as Flutter's _mobileBodyBounds, not physical dimensions.
const profiles = [
  { kg: 5, width: .50, top: .435 },
  { kg: 9, width: .66, top: .32 },
  { kg: 14, width: .63, top: .265 },
  { kg: 19, width: .61, top: .22 },
  { kg: 48, width: .49, top: .17 },
];

export function cylinderGeometry(capacityKg) {
  const kg = Number.isFinite(capacityKg) && capacityKg > 0
    ? Math.min(48, Math.max(5, capacityKg)) : 19;
  let profile = profiles.at(-1);
  for (let i = 1; i < profiles.length; i++) {
    const a = profiles[i - 1], b = profiles[i];
    if (kg <= b.kg) {
      const t = (kg - a.kg) / (b.kg - a.kg);
      profile = { width: a.width + (b.width - a.width) * t, top: a.top + (b.top - a.top) * t };
      break;
    }
  }
  const width = 250 * profile.width, cx = 250 * .45;
  const left = cx - width / 2, right = cx + width / 2;
  const top = 300 * profile.top, bottom = 270;
  const dome = width * .29, heel = width * .18;
  const bodyPath = [
    `M ${cx - width * .14} ${top} L ${cx + width * .14} ${top}`,
    `C ${right - width * .13} ${top + 3} ${right} ${top + dome * .5} ${right} ${top + dome}`,
    `L ${right} ${bottom - heel}`,
    `C ${right} ${bottom - 5} ${cx + width * .26} ${bottom} ${cx + width * .13} ${bottom}`,
    `L ${cx - width * .13} ${bottom}`,
    `C ${cx - width * .26} ${bottom} ${left} ${bottom - 5} ${left} ${bottom - heel}`,
    `L ${left} ${top + dome}`,
    `C ${left} ${top + dome * .5} ${left + width * .13} ${top + 3} ${cx - width * .14} ${top} Z`,
  ].join(' ');
  const guardWidth = width * .48;
  const guardPath = [
    `M ${cx - guardWidth / 2} ${top + 5} L ${cx - guardWidth / 2} ${top - 32}`,
    `Q ${cx - guardWidth / 2} ${top - 42} ${cx - guardWidth / 2 + 10} ${top - 42}`,
    `L ${cx + guardWidth / 2 - 10} ${top - 42}`,
    `Q ${cx + guardWidth / 2} ${top - 42} ${cx + guardWidth / 2} ${top - 32}`,
    `L ${cx + guardWidth / 2} ${top + 5}`,
  ].join(' ');
  return { left, right, top, bottom, width, height: bottom - top, cx, bodyPath, guardPath };
}

export function gasFraction(levelPct) {
  return Number.isFinite(levelPct) ? Math.min(1, Math.max(0, levelPct / 100)) : 0;
}

export function cylinderFill(geometry, fraction) {
  const height = geometry.height * Math.min(1, Math.max(0, Number.isFinite(fraction) ? fraction : 0));
  const y = Math.max(geometry.top, geometry.bottom - height);
  return { y, height: geometry.bottom - y };
}
