// Three-quarter "3D" illustrations of each device type, drawn in SVG: every
// solid is a front face plus a lit top face and a shaded side face, with
// gradients for material (steel, glass, copper, brass) and a soft ground
// shadow. Status LEDs glow green when the device is online.

import { useId } from 'react';
import { isGasCylinderType } from '../lib/gas/gasCore';

const D = 14; // depth of every solid
const DY = D * 0.55;

// A box seen three-quarter: front rect + top + right side.
function Box({ x, y, w, h, front, top, side, rx = 2, stroke = 'rgba(15,35,48,.18)' }) {
  return (
    <g>
      <path d={`M${x + w} ${y} l${D} ${-DY} v${h} l${-D} ${DY} z`} fill={side} stroke={stroke} strokeWidth=".6" />
      <path d={`M${x} ${y} l${D} ${-DY} h${w} l${-D} ${DY} z`} fill={top} stroke={stroke} strokeWidth=".6" />
      <rect x={x} y={y} width={w} height={h} rx={rx} fill={front} stroke={stroke} strokeWidth=".6" />
    </g>
  );
}

function Led({ x, y, on, id, r = 2.6 }) {
  return (
    <g>
      {on && <circle cx={x} cy={y} r={r * 2.4} fill={`url(#${id}-glow)`} />}
      <circle cx={x} cy={y} r={r} fill={on ? '#22c55e' : '#94a3b8'} stroke="rgba(0,0,0,.25)" strokeWidth=".5" />
      <circle cx={x - r * 0.35} cy={y - r * 0.35} r={r * 0.35} fill="#fff" opacity=".7" />
    </g>
  );
}

function Defs({ id }) {
  return (
    <defs>
      <linearGradient id={`${id}-steel`} x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#dfe6eb" /><stop offset=".45" stopColor="#f7f9fa" /><stop offset="1" stopColor="#c9d3da" />
      </linearGradient>
      <linearGradient id={`${id}-steelTop`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#ffffff" /><stop offset="1" stopColor="#e3e9ed" />
      </linearGradient>
      <linearGradient id={`${id}-steelSide`} x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#aebbc4" /><stop offset="1" stopColor="#8e9ca6" />
      </linearGradient>
      <linearGradient id={`${id}-navy`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#24536b" /><stop offset="1" stopColor="#133648" />
      </linearGradient>
      <linearGradient id={`${id}-glass`} x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#e3f4fc" /><stop offset=".6" stopColor="#b5dcef" /><stop offset="1" stopColor="#8fc3dd" />
      </linearGradient>
      <linearGradient id={`${id}-cyl`} x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#7b8a94" /><stop offset=".35" stopColor="#e9eef1" /><stop offset=".6" stopColor="#c3ccd2" /><stop offset="1" stopColor="#6f7e88" />
      </linearGradient>
      <linearGradient id={`${id}-copper`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#e39a62" /><stop offset="1" stopColor="#a8592b" />
      </linearGradient>
      <linearGradient id={`${id}-brass`} x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#a47e2c" /><stop offset=".45" stopColor="#f1d27a" /><stop offset="1" stopColor="#9a7424" />
      </linearGradient>
      <linearGradient id={`${id}-gas`} x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#9a3412" /><stop offset=".32" stopColor="#f97316" /><stop offset=".55" stopColor="#fdba74" /><stop offset=".78" stopColor="#ea580c" /><stop offset="1" stopColor="#7c2d12" />
      </linearGradient>
      <linearGradient id={`${id}-pcb`} x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#1f8a5a" /><stop offset="1" stopColor="#0f5a3a" />
      </linearGradient>
      <radialGradient id={`${id}-glow`}>
        <stop offset="0" stopColor="#4ade80" stopOpacity=".75" /><stop offset="1" stopColor="#4ade80" stopOpacity="0" />
      </radialGradient>
      <radialGradient id={`${id}-shadow`}>
        <stop offset="0" stopColor="#0f2330" stopOpacity=".32" /><stop offset="1" stopColor="#0f2330" stopOpacity="0" />
      </radialGradient>
      <linearGradient id={`${id}-glare`} x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#fff" stopOpacity=".75" /><stop offset="1" stopColor="#fff" stopOpacity="0" />
      </linearGradient>
    </defs>
  );
}

const Shadow = ({ id, cx = 100, cy = 150, rx = 70 }) => <ellipse cx={cx} cy={cy} rx={rx} ry={9} fill={`url(#${id}-shadow)`} />;

// -------------------------------------------------------------- drawings
function Fridge({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  const items = ['#e34948', '#2a78d6', '#eda100', '#1baf7a', '#e87ba4'];
  return (
    <g>
      <Shadow id={id} rx={62} />
      <Box x={60} y={22} w={72} h={124} front={g('steel')} top={g('steelTop')} side={g('steelSide')} rx={4} />
      <rect x={60} y={22} width={72} height={16} rx={4} fill={g('navy')} />
      <rect x={66} y={27} width={24} height={7} rx={1.5} fill="#0b2230" />
      <text x={78} y={33} textAnchor="middle" fontSize="6" fontWeight="700" fill="#5eead4" fontFamily="monospace">4.0°</text>
      <Led id={id} x={124} y={30} on={on} />
      <rect x={65} y={42} width={62} height={98} rx={3} fill={g('glass')} stroke="#7a95a6" strokeWidth="1.2" />
      {[64, 88, 112].map((y) => <rect key={y} x={67} y={y} width={58} height={2} rx={1} fill="#8fb3c7" />)}
      {[46, 70, 94, 118].map((y, r) =>
        [0, 1, 2, 3, 4].map((i) => (
          <g key={`${r}-${i}`}>
            <rect x={70 + i * 11} y={y + 6} width={7} height={12} rx={2} fill={items[(i + r) % 5]} opacity=".9" />
            <rect x={71} y={y + 7} width={1.6} height={9} rx={.8} fill="#fff" opacity=".45" transform={`translate(${i * 11} 0)`} />
          </g>
        )))}
      <path d="M68 44 L90 44 L68 92 Z" fill={g('glare')} opacity=".6" />
      <rect x={121} y={70} width={3.5} height={40} rx={1.7} fill="#dfe6eb" stroke="#8e9ca6" strokeWidth=".8" />
      <rect x={64} y={146} width={8} height={4} rx={1} fill="#56636c" /><rect x={120} y={146} width={8} height={4} rx={1} fill="#56636c" />
    </g>
  );
}

function ColdRoom({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  const zone = ['#2a78d6', '#1baf7a', '#e34948', '#eda100'];
  return (
    <g>
      <Shadow id={id} rx={82} cy={148} />
      <Box x={26} y={52} w={132} h={92} front={g('steel')} top={g('steelTop')} side={g('steelSide')} rx={3} />
      {[0, 1, 2, 3].map((i) => (
        <g key={i}>
          <rect x={33 + i * 31} y={70} width={25} height={70} rx={2} fill="#d5dde3" stroke="#9aa9b3" strokeWidth=".8" />
          {Array.from({ length: 9 }, (_, k) => <line key={k} x1={34 + i * 31} x2={57 + i * 31} y1={75 + k * 7} y2={75 + k * 7} stroke="#aebbc4" strokeWidth=".8" />)}
          <rect x={37 + i * 31} y={58} width={17} height={7} rx={1.5} fill="#0b2230" />
          <rect x={39 + i * 31} y={60} width={6} height={3} rx={1} fill={zone[i]} />
        </g>
      ))}
      <Box x={44} y={36} w={34} h={14} front={g('cyl')} top={g('steelTop')} side={g('steelSide')} />
      <Box x={100} y={36} w={34} h={14} front={g('cyl')} top={g('steelTop')} side={g('steelSide')} />
      {[61, 117].map((cx) => <g key={cx}><ellipse cx={cx + 7} cy={36 - DY / 2} rx={11} ry={3.4} fill="#5b6a74" /><ellipse cx={cx + 7} cy={36 - DY / 2} rx={3} ry={1} fill="#c9d3da" /></g>)}
      <Led id={id} x={150} y={60} on={on} />
    </g>
  );
}

function IceMachine({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  return (
    <g>
      <Shadow id={id} rx={66} />
      <Box x={52} y={82} w={92} h={64} front={g('navy')} top="#2c5a72" side="#0e2a39" rx={3} />
      <Box x={52} y={26} w={92} h={52} front={g('steel')} top={g('steelTop')} side={g('steelSide')} rx={3} />
      {Array.from({ length: 7 }, (_, k) => <rect key={k} x={60} y={34 + k * 5.5} width={60} height={2.4} rx={1.2} fill="#b3c0c8" />)}
      <rect x={124} y={34} width={14} height={20} rx={2} fill="#0b2230" />
      <Led id={id} x={131} y={40} on={on} r={2.2} />
      <rect x={127} y={46} width={8} height={4} rx={1} fill="#5eead4" opacity=".7" />
      <rect x={62} y={92} width={72} height={44} rx={4} fill={g('glass')} opacity=".95" stroke="#0b2230" strokeWidth="1.5" />
      {[[68, 118], [80, 116], [92, 119], [104, 117], [116, 118], [74, 106], [86, 104], [98, 107], [110, 105], [83, 94], [96, 95]].map(([x, y], i) => (
        <g key={i}>
          <rect x={x} y={y} width={11} height={11} rx={2.5} fill="#f0fbff" stroke="#9fcde3" strokeWidth=".8" />
          <rect x={x + 2} y={y + 2} width={4} height={3} rx={1} fill="#fff" />
        </g>
      ))}
      <path d="M64 94 L82 94 L64 124 Z" fill={g('glare')} opacity=".55" />
      <rect x={90} y={138} width={16} height={3} rx={1.5} fill="#8fb3c7" />
    </g>
  );
}

function CompressorRack({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  return (
    <g>
      <Shadow id={id} rx={80} cy={150} />
      <Box x={22} y={128} w={140} h={12} front="#56636c" top="#7d8b95" side="#3f4a52" rx={2} />
      <rect x={24} y={30} width={136} height={7} rx={3.5} fill={g('copper')} />
      {[0, 1, 2].map((i) => {
        const cx = 50 + i * 44;
        return (
          <g key={i}>
            <path d={`M${cx} 37 V58`} stroke={g('copper')} strokeWidth="5" strokeLinecap="round" />
            <rect x={cx - 17} y={62} width={34} height={64} rx={5} fill={g('cyl')} stroke="#56636c" strokeWidth=".8" />
            <ellipse cx={cx} cy={62} rx={17} ry={9} fill="#e4eaee" stroke="#56636c" strokeWidth=".8" />
            <ellipse cx={cx} cy={60} rx={9} ry={4.5} fill="#c3ccd2" />
            <rect x={cx - 10} y={84} width={20} height={12} rx={2} fill="#133648" />
            <Led id={id} x={cx} y={90} on={on && i < 2} r={2.2} />
            <ellipse cx={cx} cy={126} rx={17} ry={5} fill="#56636c" />
          </g>
        );
      })}
      <path d="M160 33 q10 0 10 12 v24" stroke={g('copper')} strokeWidth="5" fill="none" strokeLinecap="round" />
    </g>
  );
}

function RelayBoard({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  return (
    <g>
      <Shadow id={id} rx={80} cy={146} />
      <g transform="translate(100 96) skewX(-18) translate(-100 -96)">
        <rect x={34} y={48} width={138} height={90} rx={5} fill="#0b3d27" />
        <rect x={30} y={44} width={138} height={90} rx={5} fill={g('pcb')} stroke="#0b3d27" strokeWidth="1" />
        {Array.from({ length: 6 }, (_, k) => <path key={k} d={`M44 ${58 + k * 12} h${40 + (k % 3) * 18}`} stroke="#3fb57f" strokeWidth=".8" opacity=".6" />)}
        {[0, 1, 2, 3].map((i) => (
          <g key={i}>
            <rect x={46 + i * 28} y={56} width={22} height={28} rx={2} fill="#2a78d6" stroke="#184f95" strokeWidth=".8" />
            <rect x={48 + i * 28} y={58} width={18} height={6} rx={1} fill="#86b6ef" opacity=".7" />
            <text x={57 + i * 28} y={76} textAnchor="middle" fontSize="5" fill="#dbeafe" fontFamily="monospace">RLY{i + 1}</text>
            <Led id={id} x={57 + i * 28} y={92} on={on && i % 2 === 0} r={2.2} />
          </g>
        ))}
        <rect x={100} y={100} width={24} height={16} rx={1.5} fill="#1e293b" />
        {Array.from({ length: 5 }, (_, k) => <rect key={k} x={102 + k * 4.6} y={116} width={1.6} height={3} fill="#c9d3da" />)}
        <rect x={44} y={120} width={48} height={10} rx={1.5} fill="#16a34a" />
        {Array.from({ length: 6 }, (_, k) => <circle key={k} cx={49 + k * 7.6} cy={125} r={2} fill="#c9d3da" stroke="#56636c" strokeWidth=".6" />)}
        <circle cx={40} cy={52} r={3} fill="#c9d3da" /><circle cx={160} cy={52} r={3} fill="#c9d3da" />
      </g>
    </g>
  );
}

function PressureGauges({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  const Gauge = ({ cx, rim, angle }) => (
    <g>
      <circle cx={cx} cy={70} r={30} fill={rim} />
      <circle cx={cx} cy={70} r={26} fill="#fbfdfe" stroke="#c9d3da" strokeWidth="1" />
      {Array.from({ length: 11 }, (_, k) => {
        const a = (-220 + k * 26) * (Math.PI / 180);
        return <line key={k} x1={cx + Math.cos(a) * 21} y1={70 + Math.sin(a) * 21} x2={cx + Math.cos(a) * 25} y2={70 + Math.sin(a) * 25} stroke="#56636c" strokeWidth={k % 5 === 0 ? 1.4 : .7} />;
      })}
      <line x1={cx} y1={70} x2={cx + Math.cos(angle) * 20} y2={70 + Math.sin(angle) * 20} stroke="#d03b3b" strokeWidth="1.8" strokeLinecap="round" />
      <circle cx={cx} cy={70} r={3} fill="#1e293b" />
      <path d={`M${cx - 20} 55 a26 26 0 0 1 22 -10`} stroke="#fff" strokeWidth="4" fill="none" opacity=".7" strokeLinecap="round" />
      <rect x={cx - 5} y={100} width={10} height={14} fill={g('brass')} />
    </g>
  );
  return (
    <g>
      <Shadow id={id} rx={80} cy={148} />
      <Box x={30} y={114} w={132} h={18} front={g('steel')} top={g('steelTop')} side={g('steelSide')} rx={3} />
      <Gauge cx={66} rim="#2a78d6" angle={-2.4} />
      <Gauge cx={130} rim="#e34948" angle={-0.7} />
      <path d="M40 132 q-14 8 -12 18" stroke="#1e293b" strokeWidth="5" fill="none" strokeLinecap="round" />
      <path d="M154 132 q14 8 12 18" stroke="#1e293b" strokeWidth="5" fill="none" strokeLinecap="round" />
      <Led id={id} x={98} y={123} on={on} />
    </g>
  );
}

function BottleCabinet({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  return (
    <g>
      <Shadow id={id} rx={66} />
      <Box x={54} y={30} w={86} h={116} front={g('steel')} top={g('steelTop')} side={g('steelSide')} rx={4} />
      <rect x={60} y={40} width={74} height={100} rx={3} fill={g('glass')} stroke="#7a95a6" strokeWidth="1.2" />
      {[64, 88, 112, 136].map((y) => (
        <g key={y}>
          <rect x={62} y={y} width={70} height={3} rx={1.5} fill="#8fb3c7" />
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <g key={i}>
              <rect x={66 + i * 11} y={y - 18} width={7} height={18} rx={2.5} fill="#8a4b12" />
              <rect x={68 + i * 11} y={y - 23} width={3} height={6} rx={1} fill="#6b3a0e" />
              <rect x={67 + i * 11} y={y - 15} width={1.6} height={11} rx={.8} fill="#fff" opacity=".4" />
            </g>
          ))}
        </g>
      ))}
      <path d="M63 42 L84 42 L63 88 Z" fill={g('glare')} opacity=".55" />
      <rect x={84} y={16} width={30} height={10} rx={2} fill={g('navy')} />
      <path d="M99 26 L86 44 L112 44 Z" fill="#ef4444" opacity=".22" />
      <rect x={88} y={19} width={8} height={4} rx={1} fill="#ef4444" />
      <Led id={id} x={108} y={21} on={on} r={2} />
    </g>
  );
}

function GasCylinder({ id, on }) {
  const g = (n) => `url(#${id}-${n})`;
  return (
    <g>
      <Shadow id={id} rx={46} />
      <rect x={70} y={44} width={60} height={100} rx={22} fill={g('gas')} />
      <ellipse cx={100} cy={48} rx={30} ry={10} fill="#fb923c" />
      <rect x={80} y={80} width={40} height={26} rx={3} fill="#fff7ed" opacity=".92" />
      <text x={100} y={91} textAnchor="middle" fontSize="7" fontWeight="800" fill="#9a3412">LPG</text>
      <text x={100} y={100} textAnchor="middle" fontSize="5" fill="#9a3412">9 kg</text>
      <path d="M78 36 a22 10 0 0 1 44 0 v8 a22 8 0 0 1 -44 0 z" fill="#78818a" />
      <ellipse cx={100} cy={36} rx={22} ry={8} fill="#aab4bc" />
      <rect x={93} y={20} width={14} height={16} rx={2} fill={g('brass')} />
      <rect x={87} y={16} width={26} height={6} rx={3} fill={g('brass')} />
      <rect x={72} y={140} width={56} height={8} rx={3} fill="#57534e" />
      <path d="M76 58 q4 40 0 78" stroke="#fff" strokeWidth="5" fill="none" opacity=".25" strokeLinecap="round" />
      <Led id={id} x={120} y={30} on={on} r={2.2} />
    </g>
  );
}

const DRAW = {
  device1: Fridge,
  device2: ColdRoom,
  device3: IceMachine,
  device4: CompressorRack,
  device5: RelayBoard,
  device6: PressureGauges,
  device7: BottleCabinet,
};

export default function DeviceIllustration({ type, online = false, size = 160, title }) {
  const raw = useId();
  const id = `di${raw.replace(/[^a-zA-Z0-9]/g, '')}`;
  const Drawing = isGasCylinderType(type) ? GasCylinder : DRAW[type] || Fridge;
  return (
    <svg viewBox="0 0 200 160" width={size} height={(size * 160) / 200} role="img" aria-label={title || 'Device illustration'} className="device-illustration">
      <Defs id={id} />
      <Drawing id={id} on={online} />
    </svg>
  );
}
