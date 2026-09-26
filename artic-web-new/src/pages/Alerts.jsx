import { useState } from "react";
import { api } from "../api";
import { useAuth } from "../auth";
import { useDevices } from "../useDevices";
import { Panel, Spinner } from "../components/bits";
import Modal from "../components/Modal";
import {
  Tabs,
  Field,
  FormDialog,
  Facts,
  DataTable,
  Pager,
  Tiles,
  words,
  dateTime,
  choice,
  field,
} from "../components/Operations";
import { useOperation } from "../components/useOperation";

const statuses = ["active", "acknowledged", "resolved", "false_positive"];
const severities = ["critical", "high", "medium", "low"];
function AISettings({ token, bid }) {
  const state = useOperation(
    () => api.post("/ai/settings/get/", { business_id: bid }, token),
    [token, bid],
  );
  const [edit, setEdit] = useState(false);
  const settings = state.data?.settings ?? state.data;
  return (
    <Panel
      title="AI alert settings"
      actions={
        <button
          className="btn"
          onClick={() => setEdit(true)}
          disabled={!settings}
        >
          Edit settings
        </button>
      }
    >
      {state.loading && <Spinner />}
      {state.error && (
        <p className="form-err">
          {state.error}{" "}
          <button className="btn" onClick={state.refresh}>
            Retry
          </button>
        </p>
      )}
      {settings && <Facts data={settings} />}
      {edit && (
        <FormDialog
          title="AI alert settings"
          initial={settings}
          fields={[
            field("enabled", "checkbox", { label: "Enable AI alerts" }),
            field("enable_compressor_health", "checkbox"),
            field("enable_leak_detection", "checkbox"),
            field("enable_smart_defrost", "checkbox"),
            { key: "min_severity_to_alert", options: severities },
          ]}
          onClose={() => setEdit(false)}
          onSave={async (values) => {
            await api.post(
              "/ai/settings/update/",
              { ...values, business_id: bid },
              token,
            );
            state.refresh();
          }}
        />
      )}
    </Panel>
  );
}
export default function Alerts() {
  const { token, business } = useAuth();
  const bid = business.business_uid;
  const { devices = [] } = useDevices();
  const [tab, setTab] = useState("alerts");
  const [filters, setFilters] = useState({
    status: "",
    severity: "",
    device_id: "",
  });
  const [page, setPage] = useState(1);
  const [detailId, setDetailId] = useState(null);
  const [action, setAction] = useState(null);
  const [notice, setNotice] = useState("");
  const list = useOperation(
    () =>
      api.post(
        "/alerts/list/",
        {
          business_id: bid,
          ...filters,
          device_id: filters.device_id ? Number(filters.device_id) : undefined,
          page,
          page_size: 25,
        },
        token,
      ),
    [token, bid, filters, page],
  );
  const stats = useOperation(
    () => api.post("/alerts/statistics/", { business_id: bid }, token),
    [token, bid],
  );
  const detail = useOperation(
    () =>
      detailId
        ? api.post(
            "/alerts/detail/",
            { business_id: bid, alert_id: detailId },
            token,
          )
        : null,
    [token, bid, detailId],
  );
  const refresh = () => {
    list.refresh();
    stats.refresh();
    detail.refresh();
  };
  const actions = (a) => (
    <div className="ops-actions">
      {a.status === "active" && (
        <button
          className="btn sm"
          onClick={() => setAction({ name: "acknowledge", alert: a })}
        >
          Acknowledge
        </button>
      )}
      {["active", "acknowledged"].includes(a.status) && (
        <>
          <button
            className="btn sm primary"
            onClick={() => setAction({ name: "resolve", alert: a })}
          >
            Resolve
          </button>
          <button
            className="btn sm"
            onClick={() => setAction({ name: "false-positive", alert: a })}
          >
            False positive
          </button>
        </>
      )}
    </div>
  );
  const alert = detail.data?.alert;
  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Monitoring</div>
          <h1 className="page-title">Alerts</h1>
          <p className="page-sub">
            Investigate events, respond to issues, and tune automatic
            monitoring.
          </p>
        </div>
        <button className="btn" onClick={refresh}>
          Refresh
        </button>
      </div>
      {notice && (
        <p className="ops-success" role="status">
          {notice}
        </p>
      )}
      {stats.data && (
        <Tiles
          data={Object.fromEntries(
            [
              "total",
              "active",
              "acknowledged",
              "resolved",
              "false_positive",
              "recent_24h",
            ].map((k) => [k, stats.data[k]]),
          )}
        />
      )}
      {stats.error && <p className="form-err">Statistics: {stats.error}</p>}
      <Tabs
        items={["alerts", "analytics", "AI settings"]}
        value={tab}
        onChange={setTab}
      />
      {tab === "alerts" && (
        <Panel
          title="Fleet alerts"
          actions={
            <button
              className="btn"
              onClick={() => setAction({ name: "mark-all-read" })}
            >
              Mark all as read
            </button>
          }
        >
          <div className="ops-toolbar">
            {[
              choice("status", statuses),
              choice("severity", severities),
              choice(
                "device_id",
                (devices ?? []).map((d) => ({
                  value: d.id,
                  label: `${d.name} (${d.device_id})`,
                })),
                "Device",
              ),
            ].map((f) => (
              <Field
                key={f.key}
                field={f}
                value={filters[f.key]}
                onChange={(v) => {
                  setFilters((old) => ({ ...old, [f.key]: v }));
                  setPage(1);
                }}
              />
            ))}
          </div>
          {list.loading ? (
            <Spinner />
          ) : list.error ? (
            <p className="form-err">
              {list.error}{" "}
              <button className="btn" onClick={list.refresh}>
                Retry
              </button>
            </p>
          ) : (
            <>
              <DataTable
                rows={list.data?.alerts}
                columns={[
                  {
                    key: "title",
                    render: (a) => (
                      <button
                        className="btn sm"
                        onClick={() => setDetailId(a.id)}
                      >
                        {a.title || "View alert"}
                      </button>
                    ),
                  },
                  { key: "device_name" },
                  {
                    key: "severity",
                    render: (a) => (
                      <span
                        className={`chip ${["critical", "high"].includes(a.severity) ? "crit" : "neutral"}`}
                      >
                        {words(a.severity)}
                      </span>
                    ),
                  },
                  { key: "status", render: (a) => words(a.status) },
                  {
                    key: "triggered_at",
                    render: (a) => dateTime(a.triggered_at),
                  },
                  { key: "actions", render: actions },
                ]}
              />
              <Pager
                page={page}
                pages={list.data?.total_pages}
                total={list.data?.count}
                onChange={setPage}
              />
            </>
          )}
        </Panel>
      )}
      {tab === "analytics" && (
        <Panel title="Alert activity">
          {stats.loading ? (
            <Spinner />
          ) : (
            <>
              <Tiles
                data={Object.fromEntries(
                  severities.map((k) => [k, stats.data?.[k]]),
                )}
              />
              <DataTable
                rows={stats.data?.top_devices}
                columns={[
                  { key: "device__name", label: "Device" },
                  { key: "count", label: "Alerts" },
                ]}
              />
            </>
          )}
        </Panel>
      )}
      {tab === "AI settings" && <AISettings token={token} bid={bid} />}
      {detailId && (
        <Modal label="Alert details" onClose={() => setDetailId(null)}>
          <div className="modal ops-modal">
            <div className="page-head">
              <h2>{alert?.title || "Alert details"}</h2>
              <button className="btn" onClick={() => setDetailId(null)}>
                Close
              </button>
            </div>
            {detail.loading && <Spinner />}
            {detail.error && (
              <p className="form-err">
                {detail.error}{" "}
                <button onClick={detail.refresh} className="btn">
                  Retry
                </button>
              </p>
            )}
            {alert && (
              <>
                <div className="ops-detail">
                  <Facts data={alert} />
                </div>
                {actions(alert)}
              </>
            )}
          </div>
        </Modal>
      )}
      {action && (
        <FormDialog
          title={words(action.name.replaceAll("-", " "))}
          submit="Confirm"
          onClose={() => setAction(null)}
          onSave={async () => {
            const result = await api.post(
              `/alerts/${action.name}/`,
              {
                business_id: bid,
                ...(action.alert
                  ? { alert_id: action.alert.id }
                  : filters.status
                    ? { status: filters.status }
                    : {}),
              },
              token,
            );
            setNotice(result.message || "Alert updated.");
            refresh();
          }}
        >
          <p>
            {action.alert
              ? `Apply this action to “${action.alert.title}”?`
              : `Mark all ${filters.status ? words(filters.status) : ""} alerts in this business as read. Device and severity filters do not limit this action.`}
          </p>
        </FormDialog>
      )}
    </>
  );
}
