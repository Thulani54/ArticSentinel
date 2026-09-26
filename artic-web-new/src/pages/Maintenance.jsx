import { useState } from "react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";
import { api } from "../api";
import { useAuth } from "../auth";
import { useDevices } from "../useDevices";
import { Panel, Spinner } from "../components/bits";
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
import MaintenanceDetail from "../components/MaintenanceDetail";
import {
  priorities,
  statuses,
  frequencies,
  maintenancePayload,
  localDateTime,
} from "../lib/operations/maintenance";

function LoadState({ state, children }) {
  return state.loading ? (
    <Spinner />
  ) : state.error ? (
    <p className="form-err" role="alert">
      {state.error}{" "}
      <button className="btn" onClick={state.refresh}>
        Retry
      </button>
    </p>
  ) : (
    children
  );
}
function Chart({ rows = [], x, title }) {
  return (
    <Panel title={title}>
      <div className="ops-chart">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={rows}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} />
            <XAxis dataKey={x} />
            <YAxis allowDecimals={false} />
            <Tooltip />
            <Bar dataKey="count" fill="#e56a3b" radius={[5, 5, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
      {!rows.length && <p className="ops-note">No readings for this period.</p>}
    </Panel>
  );
}
function MaintenanceReports({ token, bid, onOpen }) {
  const [year, setYear] = useState(new Date().getFullYear());
  const [month, setMonth] = useState(null);
  const [error, setError] = useState("");
  const reports = useOperation(
    () =>
      api.post(
        "/maintenance/reports/monthly/",
        { business_id: bid, year: Number(year) },
        token,
      ),
    [token, bid, year],
  );
  const records = useOperation(
    () =>
      month
        ? api.get(
            `/maintenance/reports/${year}/${month}/records/?business_id=${bid}`,
            token,
          )
        : null,
    [token, bid, year, month],
  );
  return (
    <Panel title="Maintenance reports">
      <div className="ops-toolbar">
        <Field
          field={field("year", "number", { min: 2000, max: 2100 })}
          value={year}
          onChange={(v) => {
            setYear(v);
            setMonth(null);
          }}
        />
      </div>
      {error && <p className="form-err">{error}</p>}
      <LoadState state={reports}>
        <DataTable
          rows={reports.data?.reports}
          columns={[
            { key: "month_name", label: "Month" },
            { key: "total_maintenance", label: "Records" },
            { key: "completed" },
            { key: "overdue" },
            { key: "completion_rate", label: "Completion %" },
            { key: "total_cost", label: "Actual cost (R)" },
            { key: "estimated_cost", label: "Estimated cost (R)" },
            { key: "avg_duration_hours", label: "Average hours" },
            {
              key: "actions",
              render: (r) => (
                <div className="ops-actions">
                  <button className="btn sm" onClick={() => setMonth(r.month)}>
                    View records
                  </button>
                  <button
                    className="btn sm"
                    onClick={async () => {
                      setError("");
                      try {
                        await api.download(
                          `/maintenance/reports/${year}/${r.month}/summary-pdf/`,
                          "POST",
                          { business_id: bid },
                          token,
                          `maintenance-${year}-${r.month}.pdf`,
                        );
                      } catch (e) {
                        setError(e.message);
                      }
                    }}
                  >
                    Summary PDF
                  </button>
                </div>
              ),
            },
          ]}
        />
      </LoadState>
      {month && (
        <>
          <h3>
            {new Date(Number(year), month - 1).toLocaleString(undefined, {
              month: "long",
              year: "numeric",
            })}
          </h3>
          <LoadState state={records}>
            <RecordTable
              rows={
                records.data?.maintenance_records ?? records.data?.records ?? []
              }
              onOpen={onOpen}
            />
          </LoadState>
        </>
      )}
    </Panel>
  );
}
function RecordTable({ rows = [], onOpen }) {
  return (
    <DataTable
      rows={rows}
      columns={[
        {
          key: "device",
          render: (r) => (
            <button className="btn sm" onClick={() => onOpen(r.id)}>
              {r.device?.name ?? r.device_name ?? "View record"}
            </button>
          ),
        },
        {
          key: "maintenance_type",
          label: "Type",
          render: (r) => r.maintenance_type?.name ?? r.maintenance_type,
        },
        { key: "scheduled_date", render: (r) => dateTime(r.scheduled_date) },
        { key: "priority", render: (r) => words(r.priority) },
        {
          key: "assigned_to",
          render: (r) =>
            typeof r.assigned_to === "object"
              ? r.assigned_to?.full_name ||
                r.assigned_to?.username ||
                "Unassigned"
              : r.assigned_to || "Unassigned",
        },
        {
          key: "status",
          render: (r) => (
            <span
              className={`chip ${r.status === "completed" ? "good" : r.status === "overdue" ? "crit" : "neutral"}`}
            >
              {words(r.status)}
            </span>
          ),
        },
      ]}
    />
  );
}
export default function Maintenance() {
  const { token, business } = useAuth();
  const bid = business.business_uid;
  const { devices } = useDevices();
  const [tab, setTab] = useState("overview");
  const [filters, setFilters] = useState({});
  const [page, setPage] = useState(1);
  const [dates, setDates] = useState({
    date_from: new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10),
    date_to: new Date().toISOString().slice(0, 10),
  });
  const [modal, setModal] = useState(null);
  const [detail, setDetail] = useState(null);
  const [notice, setNotice] = useState("");
  const dashboard = useOperation(
    () =>
      api
        .post("/maintenance/dashboard/", { business_id: bid, ...dates }, token)
        .then((d) => d.dashboard),
    [token, bid, dates],
  );
  const records = useOperation(
    () =>
      api.post(
        "/maintenance/list/",
        { business_id: bid, filters, page, per_page: 25 },
        token,
      ),
    [token, bid, filters, page],
  );
  const types = useOperation(
    () =>
      api
        .get(`/maintenance/types/?business_id=${bid}`, token)
        .then((d) => d.maintenance_types),
    [token, bid],
  );
  const users = useOperation(
    () =>
      api
        .get(`/maintenance/assignable-users/?business_id=${bid}`, token)
        .then((d) => d.users),
    [token, bid],
  );
  const schedules = useOperation(
    () =>
      api
        .post("/maintenance/schedules/", { business_id: bid }, token)
        .then((d) => d.schedules),
    [token, bid],
  );
  const reminders = useOperation(
    () =>
      api
        .post("/maintenance/reminders/", { business_id: bid }, token)
        .then((d) => d.reminders),
    [token, bid],
  );
  const refresh = () => {
    dashboard.refresh();
    records.refresh();
    schedules.refresh();
    reminders.refresh();
  };
  const deviceOptions = (devices ?? []).map((d) => ({
    value: d.id,
    label: `${d.name} (${d.device_id})`,
  }));
  const typeOptions = (types.data ?? []).map((t) => ({
    value: t.id,
    label: t.name,
  }));
  const userOptions = (users.data ?? []).map((u) => ({
    value: u.id,
    label: u.full_name || u.username,
  }));
  const baseFields = [
    {
      key: "device_id",
      label: "Device",
      options: [{ value: "", label: "Select device" }, ...deviceOptions],
      required: true,
    },
    {
      key: "maintenance_type_id",
      label: "Maintenance type",
      options: [{ value: "", label: "Select type" }, ...typeOptions],
      required: true,
    },
  ];
  const scheduleFields = [
    { key: "frequency", options: frequencies },
    field("custom_frequency_days", "number", {
      min: 1,
      label: "Custom interval (days, required for custom frequency)",
    }),
    field("start_date", "date", { required: true }),
    field("end_date", "date"),
    {
      key: "auto_assign_to_id",
      label: "Auto assign to",
      options: [{ value: "", label: "Unassigned" }, ...userOptions],
    },
    field("is_active", "checkbox"),
  ];
  const recordFields = [
    ...baseFields,
    field("scheduled_date", "datetime-local", { required: true }),
    { key: "priority", options: priorities },
    { key: "status", options: statuses },
    {
      key: "assigned_to_id",
      label: "Assigned to",
      options: [{ value: "", label: "Unassigned" }, ...userOptions],
    },
    field("estimated_cost", "number", {
      min: 0,
      step: "any",
      label: "Estimated cost (R)",
    }),
    field("estimated_duration_hours", "number", { min: 0, step: "any" }),
    field("work_description", "textarea", { required: true }),
    field("parts_used", "textarea", { label: "Parts (one per line)" }),
    field("materials_used", "textarea", { label: "Materials (one per line)" }),
    field("external_contractor"),
    field("safety_precautions", "textarea"),
    field("checklist", "textarea", {
      label: "Initial checklist (one item per line)",
    }),
  ];
  const ready =
    !!deviceOptions.length &&
    !!typeOptions.length &&
    !users.loading &&
    !users.error;
  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Servicing</div>
          <h1 className="page-title">Maintenance</h1>
          <p className="page-sub">
            Plan work, document repairs, and keep every service accountable.
          </p>
        </div>
        <div className="ops-actions">
          <button className="btn" onClick={refresh}>
            Refresh
          </button>
          <button
            className="btn flame"
            disabled={!ready}
            onClick={() => setModal({ type: "record" })}
          >
            + Schedule maintenance
          </button>
        </div>
      </div>
      {notice && (
        <p className="ops-success" role="status">
          {notice}
        </p>
      )}
      {(types.error || users.error) && (
        <p className="form-err">
          Scheduling options: {types.error || users.error}{" "}
          <button
            className="btn"
            onClick={() => {
              types.refresh();
              users.refresh();
            }}
          >
            Retry
          </button>
        </p>
      )}
      {dashboard.data && <Tiles data={dashboard.data.summary} />}
      <Tabs
        items={[
          "overview",
          "records",
          "scheduling",
          "reminders",
          "analytics",
          "reports",
          "settings",
        ]}
        value={tab}
        onChange={setTab}
      />
      {tab === "overview" && (
        <div className="ops-stack">
          <Panel title="Quick actions">
            <div className="ops-actions">
              <button
                className="btn primary"
                disabled={!ready}
                onClick={() => setModal({ type: "record" })}
              >
                Schedule
              </button>
              <button className="btn" onClick={() => setTab("reports")}>
                Reports
              </button>
              <button
                className="btn"
                onClick={() => {
                  setFilters({ status: "overdue" });
                  setPage(1);
                  setTab("records");
                }}
              >
                Overdue
              </button>
              <button className="btn" onClick={() => setTab("settings")}>
                Maintenance types
              </button>
            </div>
          </Panel>
          <Panel title="Upcoming maintenance · next 7 days">
            <LoadState state={dashboard}>
              <RecordTable
                rows={dashboard.data?.upcoming_maintenance}
                onOpen={setDetail}
              />
            </LoadState>
          </Panel>
          <Panel title="Recent records">
            <LoadState state={records}>
              <RecordTable
                rows={records.data?.maintenance_records?.slice(0, 5)}
                onOpen={setDetail}
              />
            </LoadState>
          </Panel>
        </div>
      )}
      {tab === "records" && (
        <Panel title="Maintenance records">
          <div className="ops-toolbar">
            {[
              choice("device_id", deviceOptions, "Device"),
              choice("status", statuses),
              choice("priority", priorities),
              choice("maintenance_type", typeOptions, "Type"),
              choice("assigned_to", userOptions, "Assigned to"),
              field("date_from", "date"),
              field("date_to", "date"),
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
            <button
              className="btn"
              onClick={() => {
                setFilters({});
                setPage(1);
              }}
            >
              Clear filters
            </button>
          </div>
          <LoadState state={records}>
            <RecordTable
              rows={records.data?.maintenance_records}
              onOpen={setDetail}
            />
            <Pager
              page={page}
              pages={records.data?.pagination?.total_pages}
              total={records.data?.pagination?.total_items}
              onChange={setPage}
            />
          </LoadState>
        </Panel>
      )}
      {tab === "scheduling" && (
        <Panel
          title="Recurring schedules"
          actions={
            <div className="ops-actions">
              <button
                className="btn"
                disabled={!ready}
                onClick={() => setModal({ type: "schedule" })}
              >
                + Create schedule
              </button>
              <button
                className="btn primary"
                onClick={() => setModal({ type: "generate" })}
              >
                Generate due maintenance
              </button>
            </div>
          }
        >
          <LoadState state={schedules}>
            <DataTable
              rows={schedules.data}
              columns={[
                { key: "device", render: (r) => r.device.name },
                {
                  key: "maintenance_type",
                  render: (r) => r.maintenance_type.name,
                },
                { key: "frequency_display", label: "Frequency" },
                { key: "start_date" },
                { key: "end_date" },
                { key: "next_due" },
                {
                  key: "auto_assign_to",
                  render: (r) => r.auto_assign_to?.name ?? "Unassigned",
                },
                { key: "is_active", label: "Active" },
                {
                  key: "actions",
                  render: (r) => (
                    <div className="ops-actions">
                      <button
                        className="btn sm"
                        onClick={() =>
                          setModal({ type: "schedule", schedule: r })
                        }
                      >
                        Edit
                      </button>
                      <button
                        className="btn sm"
                        onClick={() =>
                          setModal({ type: "toggle", schedule: r })
                        }
                      >
                        {r.is_active ? "Pause" : "Activate"}
                      </button>
                      <button
                        className="btn sm"
                        onClick={() =>
                          setModal({ type: "delete", schedule: r })
                        }
                      >
                        Delete
                      </button>
                    </div>
                  ),
                },
              ]}
            />
          </LoadState>
          <p className="ops-note">
            Generate due maintenance creates records from active schedules.
            Review existing records before generating.
          </p>
        </Panel>
      )}
      {tab === "reminders" && (
        <LoadState state={reminders}>
          <Tiles data={reminders.data?.summary} />
          <div className="ops-stack">
            {[
              "upcoming",
              "overdue",
              "sent_reminders",
              "sent_overdue_reminders",
            ].map((group) => (
              <Panel key={group} title={words(group)}>
                <DataTable
                  rows={reminders.data?.[group]}
                  columns={[
                    {
                      key: "device_name",
                      label: "Device",
                      render: (r) => (
                        <button
                          className="btn sm"
                          onClick={() => setDetail(r.id)}
                        >
                          {r.device_name}
                        </button>
                      ),
                    },
                    { key: "maintenance_type" },
                    {
                      key: "scheduled_date",
                      render: (r) => dateTime(r.scheduled_date),
                    },
                    { key: "assigned_to" },
                    { key: "time_display", label: "Due" },
                    {
                      key: "reminder_sent_at",
                      render: (r) =>
                        dateTime(
                          r.overdue_reminder_sent_at || r.reminder_sent_at,
                        ),
                    },
                    {
                      key: "actions",
                      render: (r) =>
                        ["upcoming", "overdue"].includes(group) ? (
                          <button
                            className="btn sm"
                            onClick={() =>
                              setModal({
                                type: "reminder",
                                record: r,
                                reminderType: group,
                              })
                            }
                          >
                            Send reminder
                          </button>
                        ) : null,
                    },
                  ]}
                />
              </Panel>
            ))}
          </div>
        </LoadState>
      )}
      {tab === "analytics" && (
        <>
          <div className="ops-toolbar">
            {["date_from", "date_to"].map((k) => (
              <Field
                key={k}
                field={field(k, "date")}
                value={dates[k]}
                onChange={(v) => setDates((old) => ({ ...old, [k]: v }))}
              />
            ))}
          </div>
          <LoadState state={dashboard}>
            <div className="ops-two">
              <Panel title="Cost analysis (R)">
                <Facts data={dashboard.data?.cost_analysis} />
              </Panel>
              <Panel title="Duration & performance">
                <Facts
                  data={{
                    ...dashboard.data?.duration_analysis,
                    completion_rate: dashboard.data?.summary?.completion_rate,
                  }}
                />
              </Panel>
              <Chart
                title="Monthly activity"
                rows={[...(dashboard.data?.trends?.monthly ?? [])].reverse()}
                x="month"
              />
              <Chart
                title="Status breakdown"
                rows={dashboard.data?.breakdowns?.by_status}
                x="status"
              />
            </div>
            <Panel title="Maintenance by type">
              <DataTable
                rows={dashboard.data?.breakdowns?.by_type}
                columns={[
                  { key: "maintenance_type__name", label: "Type" },
                  { key: "count" },
                  { key: "avg_cost", label: "Average cost (R)" },
                  { key: "avg_duration", label: "Average hours" },
                ]}
              />
            </Panel>
            <Panel title="Maintenance by device">
              <DataTable
                rows={dashboard.data?.breakdowns?.by_device}
                columns={[
                  { key: "device__name", label: "Device" },
                  { key: "device__device_id", label: "Device ID" },
                  { key: "count" },
                  { key: "last_maintenance" },
                ]}
              />
            </Panel>
            <Chart
              title="Priority breakdown"
              rows={dashboard.data?.breakdowns?.by_priority}
              x="priority"
            />
          </LoadState>
        </>
      )}
      {tab === "reports" && (
        <MaintenanceReports token={token} bid={bid} onOpen={setDetail} />
      )}
      {tab === "settings" && (
        <Panel title="Maintenance types">
          <LoadState state={types}>
            <DataTable
              rows={types.data}
              columns={[
                { key: "name" },
                { key: "category_display", label: "Category" },
                { key: "description" },
                { key: "estimated_duration_hours", label: "Estimated hours" },
                {
                  key: "recommended_frequency_days",
                  label: "Frequency (days)",
                },
                { key: "requires_specialist" },
              ]}
            />
          </LoadState>
          <h3>Service configuration</h3>
          <p className="ops-note">
            Recurring generation and notification delivery are managed by the
            server. Use Scheduling to manage active schedules, Reminders to send
            a notification, and record details to track estimated and actual
            costs.
          </p>
        </Panel>
      )}
      {modal?.type === "record" && (
        <FormDialog
          title="Schedule maintenance"
          fields={recordFields}
          initial={{
            device_id: "",
            maintenance_type_id: "",
            priority: "normal",
            status: "scheduled",
            scheduled_date: localDateTime(Date.now() + 86400000),
            checklist: "",
          }}
          onClose={() => setModal(null)}
          onSave={async (v) => {
            await api.post(
              "/maintenance/create/",
              maintenancePayload(v),
              token,
            );
            refresh();
            setNotice("Maintenance scheduled.");
          }}
        />
      )}
      {modal?.type === "schedule" && (
        <FormDialog
          title={
            modal.schedule
              ? "Edit recurring schedule"
              : "Create recurring schedule"
          }
          fields={
            modal.schedule
              ? scheduleFields.filter((f) => f.key !== "start_date")
              : [...baseFields, ...scheduleFields]
          }
          initial={
            modal.schedule
              ? {
                  ...modal.schedule,
                  auto_assign_to_id: modal.schedule.auto_assign_to?.id ?? "",
                }
              : {
                  frequency: "monthly",
                  start_date: new Date().toISOString().slice(0, 10),
                  is_active: true,
                }
          }
          onClose={() => setModal(null)}
          onSave={async (v) => {
            const keys = (
              modal.schedule
                ? scheduleFields.filter((f) => f.key !== "start_date")
                : [...baseFields, ...scheduleFields]
            ).map((f) => f.key);
            await api.post(
              modal.schedule
                ? `/maintenance/schedule/${modal.schedule.id}/update/`
                : "/maintenance/schedule/create/",
              maintenancePayload(
                Object.fromEntries(keys.map((k) => [k, v[k] ?? ""])),
              ),
              token,
            );
            refresh();
            setNotice("Recurring schedule saved.");
          }}
        />
      )}
      {["generate", "delete", "toggle", "reminder"].includes(modal?.type) && (
        <FormDialog
          title={
            modal.type === "generate"
              ? "Generate due maintenance"
              : modal.type === "reminder"
                ? "Send reminder"
                : modal.type === "delete"
                  ? "Delete recurring schedule"
                  : `${modal.schedule.is_active ? "Pause" : "Activate"} schedule`
          }
          submit="Confirm"
          onClose={() => setModal(null)}
          onSave={async () => {
            let result;
            if (modal.type === "delete")
              result = await api.request(
                `/maintenance/schedule/${modal.schedule.id}/delete/`,
                "DELETE",
                null,
                token,
              );
            if (modal.type === "toggle")
              result = await api.post(
                `/maintenance/schedule/${modal.schedule.id}/update/`,
                { is_active: !modal.schedule.is_active },
                token,
              );
            if (modal.type === "generate")
              result = await api.post(
                "/maintenance/schedule/generate/",
                { business_id: bid },
                token,
              );
            if (modal.type === "reminder")
              result = await api.post(
                `/maintenance/${modal.record.id}/send-reminder/`,
                { reminder_type: modal.reminderType },
                token,
              );
            refresh();
            setNotice(result.message || "Action completed.");
          }}
        >
          <p>
            {modal.type === "generate"
              ? "Create maintenance records for due active schedules in this business."
              : modal.type === "reminder"
                ? `Send a ${modal.reminderType} notification for ${modal.record.device_name} to the assigned recipient.`
                : modal.type === "delete"
                  ? "Permanently delete this recurring schedule? Existing maintenance records remain."
                  : `Change the active state of the schedule for ${modal.schedule.device.name}?`}
          </p>
        </FormDialog>
      )}
      {detail && (
        <MaintenanceDetail
          id={detail}
          users={users.data ?? []}
          onClose={() => setDetail(null)}
          onChange={refresh}
        />
      )}
    </>
  );
}
