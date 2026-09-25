// SVG LPG cylinder gauge — web port of gas_cylinder_gauge.dart (CustomPaint):
// brass valve + collar, steel body, orange liquid with a lit surface line,
// tick rail and a centred % readout. The fill animates on mount.

import { useEffect, useState } from 'react';

const W = 220;
const H = 300;

// Body geometry (the liquid clips to this).
const BODY = { x: 46, y: 74, w: 128, h: 200, r: 18 };

export default function CylinderGauge({ levelPct, netKg, capacityKg, band }) {
  const [shown, setShown] = useState(0);

  useEffect(() => {
    // Next frame so the CSS transition runs from 0 → level.
    const id = requestAnimationFrame(() => setShown(levelPct));
    return () => cancelAnimationFrame(id);
  }, [levelPct]);

  const inset = 7;
  const inner = {
    x: BODY.x + inset,
    y: BODY.y + inset,
    w: BODY.w - inset * 2,
    h: BODY.h - inset * 2,
    r: BODY.r - inset / 2,
  };
  const fillH = (inner.h * Math.min(100, Math.max(0, shown))) / 100;
  const fillY = inner.y + inner.h - fillH;

  const stroke = band === 'low' ? '#EF4444' : band === 'warning' ? '#F59E0B' : '#64748B';

  const ticks = [0, 25, 50, 75, 100].map((p) => {
    const y = inner.y + inner.h - (inner.h * p) / 100;
    return { p, y };
  });

  return (
    <svg
      viewBox={`0 0 ${W} ${H}`}
      width="100%"
      style={{ maxWidth: 240, display: 'block', margin: '0 auto' }}
      role="img"
      aria-label={`Cylinder ${Math.round(levelPct)}% full`}
    >
      <defs>
        <linearGradient id="gasLiquid" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#F97316" />
          <stop offset="100%" stopColor="#C2410C" />
        </linearGradient>
        <clipPath id="gasBodyClip">
          <rect x={inner.x} y={inner.y} width={inner.w} height={inner.h} rx={inner.r} />
        </clipPath>
      </defs>

      {/* valve + handle */}
      <rect x={W / 2 - 7} y={26} width={14} height={22} rx={3} fill="#B8A269" />
      <rect x={W / 2 - 22} y={18} width={44} height={10} rx={5} fill="#8C7A4B" />

      {/* collar */}
      <rect x={W / 2 - 30} y={52} width={60} height={18} rx={6} fill="#D9C58A" stroke="#B8A269" strokeWidth="1" />

      {/* body + liquid */}
      <rect
        x={BODY.x} y={BODY.y} width={BODY.w} height={BODY.h} rx={BODY.r}
        fill="#F8FAFC" stroke={stroke} strokeWidth="3"
      />
      <g clipPath="url(#gasBodyClip)">
        <rect
          x={inner.x} y={fillY} width={inner.w} height={fillH}
          fill="url(#gasLiquid)"
          style={{ transition: 'y 1.1s cubic-bezier(0.22, 1, 0.36, 1), height 1.1s cubic-bezier(0.22, 1, 0.36, 1)' }}
        />
        {/* lit surface line */}
        <rect
          x={inner.x} y={fillY} width={inner.w} height={3} fill="#FDBA74"
          style={{ transition: 'y 1.1s cubic-bezier(0.22, 1, 0.36, 1)' }}
        />
        {/* white highlight stripe */}
        <rect x={inner.x + 12} y={inner.y + 14} width={12} height={inner.h - 28} rx={6} fill="rgba(255,255,255,0.28)" />
      </g>

      {/* tick rail */}
      {ticks.map((t) => (
        <g key={t.p}>
          <line x1={BODY.x - 10} y1={t.y} x2={BODY.x - 3} y2={t.y} stroke="#94A3B8" strokeWidth="1.5" />
          <text x={BODY.x - 14} y={t.y + 3.5} textAnchor="end" fontSize="9" fill="#94A3B8" fontWeight="600">
            {t.p}
          </text>
        </g>
      ))}

      {/* centred readout */}
      <text x={W / 2} y={158} textAnchor="middle" fontSize="34" fontWeight="800" fill={band === 'low' ? '#EF4444' : '#1E293B'} style={{ pointerEvents: 'none' }}>
        {Math.round(levelPct)}%
      </text>
      <text x={W / 2} y={180} textAnchor="middle" fontSize="12" fontWeight="600" fill="#64748B" style={{ pointerEvents: 'none' }}>
        {netKg.toFixed(1)} of {capacityKg.toFixed(0)} kg
      </text>
    </svg>
  );
}
