// Accept a new measurement, not an online flag or an old cached reading.
export function isFreshSetupReading(reading,startedAt,now=Date.now()) {
  if(!reading||typeof reading.gross_kg!=='number'||!Number.isFinite(reading.gross_kg))return false;
  const at=Date.parse(reading.time);
  return Number.isFinite(at)&&at>startedAt&&at<=now+30000;
}
