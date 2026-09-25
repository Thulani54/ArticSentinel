// Settings — account and business details plus sign-out
// (mirrors the identity portion of lib/screens/settings.dart; the web app
// keeps no local notification/theme preferences).

import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';
import { Panel } from '../components/bits';

function kv(rows) {
  return (
    <dl className="kv">
      {rows.filter(([, v]) => v != null && v !== '').map(([k, v]) => (
        <div key={k} style={{ display: 'contents' }}>
          <dt>{k}</dt>
          <dd>{v}</dd>
        </div>
      ))}
    </dl>
  );
}

const cap = (s) => (typeof s === 'string' ? s.replace(/_/g, ' ') : s);

export default function Settings() {
  const { user, business, logout } = useAuth();
  const navigate = useNavigate();

  function onLogout() {
    if (!window.confirm('Sign out of ArticSentinel?')) return;
    logout();
    navigate('/login');
  }

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Account</div>
          <h1 className="page-title">Settings</h1>
          <p className="page-sub">Your account, the business workspace, and sign-out.</p>
        </div>
      </div>

      <div className="gas-grid">
        <Panel eyebrow="You" title="Account">
          {kv([
            ['Name', [user?.firstname, user?.lastname].filter(Boolean).join(' ')],
            ['Email', user?.email],
            ['Username', user?.username],
            ['Title', cap(user?.job_title)],
            ['User type', cap(user?.user_type)],
            ['Phone', user?.cellphone_number ?? user?.work_phone],
            ['Timezone', user?.timezone],
            ['Joined', user?.date_joined ? new Date(user.date_joined).toLocaleDateString() : null],
          ])}
        </Panel>

        <Panel eyebrow="Workspace" title="Business">
          {kv([
            ['Business', business?.business_name],
            ['ID', business?.business_uid],
            ['Contact person', business?.contact_person],
            ['Address', [business?.address, business?.city, business?.province].filter(Boolean).join(', ')],
            ['Phone', business?.phone],
            ['Email', business?.email],
            ['Active devices', business?.active_devices_count],
          ])}
        </Panel>
      </div>

      <div className="mt16" style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        <button className="btn danger" onClick={onLogout}>Sign out</button>
        <span className="ink2" style={{ fontSize: 12 }}>
          Signed in as {user?.email || user?.username || '—'} · {business?.business_name || ''}
        </span>
      </div>
    </>
  );
}
