// SVG counterpart of the mobile app's LPG tank and measured fill animation.
import { useEffect, useId, useRef, useState } from 'react';
import { cylinderGeometry, cylinderFill, gasFraction } from '../lib/gas/cylinderGeometry.js';

function useReducedMotion() {
  const [reduced, setReduced] = useState(() =>
    typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  useEffect(() => {
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    const update = () => setReduced(media.matches);
    update();
    media.addEventListener('change', update);
    return () => media.removeEventListener('change', update);
  }, []);
  return reduced;
}

function useAnimatedFill(target, reduced) {
  const [shown, setShown] = useState(() => reduced ? target : 0);
  const current = useRef(shown);
  const entered = useRef(false);
  useEffect(() => {
    const from = current.current;
    const duration = entered.current ? 650 : 1100;
    entered.current = true;
    if (reduced || from === target) {
      current.current = target;
      setShown(target);
      return;
    }
    let frame;
    const start = performance.now();
    const animate = (now) => {
      const progress = Math.min(1, Math.max(0, (now - start) / duration));
      const eased = 1 - (1 - progress) ** 3;
      current.current = from + (target - from) * eased;
      setShown(current.current);
      if (progress < 1) frame = requestAnimationFrame(animate);
    };
    frame = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(frame);
  }, [target, reduced]);
  return reduced ? target : shown;
}

export default function CylinderGauge({ levelPct, netKg, capacityKg, band }) {
  const geometry = cylinderGeometry(capacityKg);
  const { left, right, top, bottom, width, height, cx, bodyPath, guardPath } = geometry;
  const target = gasFraction(levelPct);
  const reduced = useReducedMotion();
  const shown = useAnimatedFill(target, reduced);
  const fill = cylinderFill(geometry, shown);
  const id = useId().replaceAll(':', '');
  const clipId = `gas-body-${id}`;
  const readoutY = top + height * .43;
  const net = Number.isFinite(netKg) ? netKg.toFixed(1) : '—';
  const capacity = Number.isFinite(capacityKg) ? capacityKg.toFixed(1) : '—';
  return (
    <svg className="gas-cylinder-gauge" viewBox="0 0 250 300" width="250" height="300"
      style={{ maxWidth: '100%', height: 'auto', display: 'block', margin: '0 auto' }}
      role="img" aria-label={`Gas cylinder: ${Math.round(target * 100)}% full, ${net} of ${capacity} kg`}>
      <defs><clipPath id={clipId}><path d={bodyPath} /></clipPath></defs>
      {/* Foot ring and ventilation slots, behind the curved tank base. */}
      <rect x={cx - width * .31} y={bottom - 12} width={width * .62} height="26" rx="5" fill="#6D7F8D" />
      {[-1, 1].map((side) => <rect key={side} x={cx + side * width * .2 - width * .05}
        y={bottom + 6.5} width={width * .10} height="3" rx="1.5" fill="#DCE6EC" />)}
      {/* Recessed brass valve and protective carrying guard. */}
      <rect x={cx - 5} y={top - 23} width="10" height="25" rx="2" fill="#B78B46" />
      <rect x={cx + 2} y={top - 17} width="14" height="8" rx="2" fill="#B78B46" />
      <rect x={cx - 11} y={top - 26} width="22" height="5" rx="2" fill="#6D7F8D" />
      <path d={guardPath} fill="none" stroke="#6D7F8D" strokeWidth="6" strokeLinecap="round" />
      <path className="gas-cylinder-body" d={bodyPath} fill="var(--panel-alt, #F2F6F9)" />
      <g clipPath={`url(#${clipId})`}>
        <rect className="gas-cylinder-fill" x={left} y={fill.y} width={width} height={fill.height} fill="#ED6A24" />
        {shown > 0 && <line x1={left} y1={fill.y} x2={right} y2={fill.y} stroke="#C54D12" strokeWidth="2" />}
      </g>
      <path d={bodyPath} fill="none" stroke="#8496A5" strokeWidth="2" />
      {/* The rail and fill share the same zero/full bounds. */}
      {[0, 25, 50, 75, 100].map((percent) => {
        const y = bottom - height * percent / 100;
        return <g key={percent}>
          <line x1={right + 7} y1={y} x2={right + 14} y2={y} stroke="var(--border, #DCE6EC)" strokeWidth="1.2" />
          <text x={right + 19} y={y} dominantBaseline="middle" fontSize="9.5" fill="var(--ink2, #607686)">{percent}</text>
        </g>;
      })}
      {/* A flat plaque keeps the measured value readable at every level. */}
      <rect x={cx - width * .385} y={readoutY + 12 - 33.5} width={width * .77} height="67" rx="12" fill="var(--panel, white)" />
      <text x={cx} y={readoutY} textAnchor="middle" dominantBaseline="middle"
        fontSize={width < 140 ? 28 : 32} fontWeight="700" letterSpacing="-.5"
        fill={band === 'low' ? '#EF4444' : 'var(--ink, #173648)'}>
        {Math.round(target * 100)}%
      </text>
      <text x={cx} y={readoutY + 30} textAnchor="middle" fontSize="10.5" fill="var(--ink2, #607686)">
        {net} of {capacity} kg
      </text>
    </svg>
  );
}
