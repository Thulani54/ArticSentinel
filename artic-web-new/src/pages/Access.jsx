import { useState } from "react";
import { api } from "../api";
import { useAuth } from "../auth";
import { Panel, Spinner } from "../components/bits";
import Modal from "../components/Modal";
import {
  Tabs,
  Field,
  FormDialog,
  Facts,
  DataTable,
  Tiles,
  words,
  dateTime,
  field,
  choice,
} from "../components/Operations";
import { useOperation } from "../components/useOperation";
const array = (d) => (Array.isArray(d) ? d : (d?.results ?? []));
const categories = [
  "executive",
  "operations_management",
  "technical_management",
  "field_technician",
  "monitoring_specialist",
  "customer_user",
  "customer_admin",
  "system_admin",
  "support_staff",
  "service_provider",
  "custom",
];
const roleTypes = [
  "operational",
  "technical",
  "management",
  "customer",
  "administrator",
  "support",
  "service_provider",
];
export default function Access() {
  const { token } = useAuth();
  const [tab, setTab] = useState("roles");
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("");
  const [modal, setModal] = useState(null);
  const [selectedRole, setSelectedRole] = useState(null);
  const [notice, setNotice] = useState("");
  const [exportError, setExportError] = useState("");
  const [dates, setDates] = useState({ date_from: "", date_to: "" });
  const roles = useOperation(
    () => api.get("/roles/", token).then(array),
    [token],
  );
  const permissions = useOperation(
    () => api.get("/permissions/", token).then(array),
    [token],
  );
  const requests = useOperation(
    () => api.get("/permission-requests/", token).then(array),
    [token],
  );
  const stats = useOperation(
    () => api.get("/dashboard/stats/", token),
    [token],
  );
  const assigned = useOperation(
    () =>
      selectedRole
        ? api
            .get(`/roles/${selectedRole.role_id}/permissions/`, token)
            .then(array)
        : [],
    [token, selectedRole],
  );
  const refresh = () => {
    roles.refresh();
    permissions.refresh();
    requests.refresh();
    stats.refresh();
    assigned.refresh();
  };
  const source =
    tab === "roles" ? roles : tab === "permissions" ? permissions : requests;
  const rows = (source.data ?? []).filter(
    (r) =>
      JSON.stringify(r).toLowerCase().includes(search.toLowerCase()) &&
      (!filter ||
        (tab === "roles"
          ? r.category
          : tab === "permissions"
            ? r.module
            : r.request_status) === filter),
  );
  const options =
    tab === "roles"
      ? categories
      : tab === "permissions"
        ? [...new Set((permissions.data ?? []).map((p) => p.module))]
        : ["pending", "approved", "rejected", "implemented"];
  const roleFields = [
    field("name", "text", { required: true }),
    field("description", "textarea", { required: true }),
    { key: "category", options: categories },
    {
      key: "parent_role",
      options: [
        { value: "", label: "None" },
        ...(roles.data ?? [])
          .filter((r) => r.role_id !== modal?.role?.role_id)
          .map((r) => ({ value: r.role_id, label: r.name })),
      ],
    },
    field("company_specific", "checkbox"),
    field("system_role", "checkbox"),
    field("is_active", "checkbox"),
  ];
  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Team</div>
          <h1 className="page-title">Roles & permissions</h1>
          <p className="page-sub">
            Manage access, review requests, and inspect activity.
          </p>
        </div>
        <div className="ops-actions">
          <button className="btn" onClick={refresh}>
            Refresh
          </button>
          <button
            className="btn flame"
            onClick={() => setModal({ type: "role" })}
          >
            + Create role
          </button>
        </div>
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
              "total_users",
              "total_roles",
              "total_permissions",
              "pending_requests",
              "emergency_requests",
            ].map((k) => [k, stats.data[k]]),
          )}
        />
      )}
      {stats.error && <p className="form-err">{stats.error}</p>}
      <Tabs
        items={["roles", "permissions", "requests", "audit logs"]}
        value={tab}
        onChange={(v) => {
          setTab(v);
          setFilter("");
          setSearch("");
        }}
      />
      {tab !== "audit logs" ? (
        <Panel title={words(tab)}>
          <div className="ops-toolbar">
            <Field
              field={field("search", "search", {
                label: "Search roles, permissions, or users",
              })}
              value={search}
              onChange={setSearch}
            />
            <Field
              field={choice(
                "filter",
                options,
                tab === "roles"
                  ? "Category"
                  : tab === "permissions"
                    ? "Module"
                    : "Status",
              )}
              value={filter}
              onChange={setFilter}
            />
          </div>
          {source.loading ? (
            <Spinner />
          ) : source.error ? (
            <p className="form-err">
              {source.error}{" "}
              <button className="btn" onClick={source.refresh}>
                Retry
              </button>
            </p>
          ) : (
            <DataTable
              rows={rows}
              columns={
                tab === "roles"
                  ? [
                      {
                        key: "name",
                        render: (r) => (
                          <button
                            className="btn sm"
                            onClick={() => setSelectedRole(r)}
                          >
                            {r.name}
                          </button>
                        ),
                      },
                      { key: "category_display", label: "Category" },
                      { key: "user_count", label: "Users" },
                      { key: "permission_count", label: "Permissions" },
                      { key: "description" },
                      {
                        key: "actions",
                        render: (r) => (
                          <button
                            className="btn sm"
                            onClick={() => setModal({ type: "role", role: r })}
                          >
                            Edit
                          </button>
                        ),
                      },
                    ]
                  : tab === "permissions"
                    ? [
                        {
                          key: "name",
                          render: (p) => (
                            <button
                              className="btn sm"
                              onClick={() =>
                                setModal({ type: "detail", data: p })
                              }
                            >
                              {p.name}
                            </button>
                          ),
                        },
                        { key: "module_display", label: "Module" },
                        { key: "type_display", label: "Type" },
                        { key: "description" },
                        { key: "requires_approval" },
                        { key: "emergency_override" },
                      ]
                    : [
                        { key: "user_full_name", label: "User" },
                        { key: "role_name", label: "Role" },
                        { key: "permission_name", label: "Permission" },
                        { key: "status_display", label: "Status" },
                        {
                          key: "request_timestamp",
                          render: (r) => dateTime(r.request_timestamp),
                        },
                        {
                          key: "actions",
                          render: (r) => (
                            <div className="ops-actions">
                              <button
                                className="btn sm"
                                onClick={() =>
                                  setModal({ type: "detail", data: r })
                                }
                              >
                                Details
                              </button>
                              {r.request_status === "pending" && (
                                <>
                                  <button
                                    className="btn sm primary"
                                    onClick={() =>
                                      setModal({ type: "approve", request: r })
                                    }
                                  >
                                    Approve
                                  </button>
                                  <button
                                    className="btn sm"
                                    onClick={() =>
                                      setModal({ type: "reject", request: r })
                                    }
                                  >
                                    Reject
                                  </button>
                                </>
                              )}
                            </div>
                          ),
                        },
                      ]
              }
            />
          )}
        </Panel>
      ) : (
        <Panel title="Audit activity">
          <p className="ops-note">
            Activity totals for the last seven days. Download the detailed audit
            log for a selected date range (up to 10,000 entries).
          </p>
          <DataTable
            rows={stats.data?.recent_activity}
            columns={[{ key: "action_type" }, { key: "count" }]}
          />
          <div className="ops-toolbar">
            {["date_from", "date_to"].map((key) => (
              <Field
                key={key}
                field={field(key, "date")}
                value={dates[key]}
                onChange={(v) => setDates((old) => ({ ...old, [key]: v }))}
              />
            ))}
            <button
              className="btn"
              onClick={async () => {
                setExportError("");
                try {
                  await api.download(
                    `/export/audit-logs/?${new URLSearchParams(dates)}`,
                    "GET",
                    null,
                    token,
                    "audit-logs.csv",
                  );
                } catch (e) {
                  setExportError(e.message);
                }
              }}
            >
              Download CSV
            </button>
          </div>
          {exportError && <p className="form-err">{exportError}</p>}
        </Panel>
      )}
      {selectedRole && (
        <Modal label="Role details" onClose={() => setSelectedRole(null)}>
          <div className="modal ops-modal">
            <div className="page-head">
              <h2>{selectedRole.name}</h2>
              <button className="btn" onClick={() => setSelectedRole(null)}>
                Close
              </button>
            </div>
            <div className="ops-detail">
              <Facts data={selectedRole} />
              <h3>Assigned permissions</h3>
              {assigned.loading ? (
                <Spinner />
              ) : assigned.error ? (
                <p className="form-err">{assigned.error}</p>
              ) : (
                <DataTable
                  rows={assigned.data}
                  columns={[
                    { key: "name" },
                    { key: "module_display", label: "Module" },
                    { key: "type_display", label: "Type" },
                  ]}
                />
              )}
            </div>
            <button
              className="btn primary"
              disabled={!permissions.data || !assigned.data}
              onClick={() => setModal({ type: "assign" })}
            >
              Add permissions
            </button>
          </div>
        </Modal>
      )}
      {modal?.type === "role" && (
        <FormDialog
          title={modal.role ? "Edit role" : "Create role"}
          initial={
            modal.role ?? {
              name: "",
              description: "",
              category: "custom",
              is_active: true,
              company_specific: false,
              system_role: false,
            }
          }
          fields={[
            ...roleFields,
            ...(!modal.role
              ? roleTypes.map((t) =>
                  field(`type_${t}`, "checkbox", {
                    label: `${words(t)} role type`,
                  }),
                )
              : []),
          ]}
          onClose={() => setModal(null)}
          onSave={async (values) => {
            const payload = Object.fromEntries(
              roleFields.map((f) => [f.key, values[f.key] ?? null]),
            );
            payload.parent_role = payload.parent_role
              ? Number(payload.parent_role)
              : null;
            if (modal.role) {
              await api.request(
                `/roles/${modal.role.role_id}/`,
                "PATCH",
                payload,
                token,
              );
            } else {
              payload.role_types = roleTypes.filter((t) => values[`type_${t}`]);
              const result = await api.post("/create_role/", payload, token);
              if (result.warnings?.length) setNotice(result.warnings.join(" "));
            }
            refresh();
          }}
        />
      )}
      {modal?.type === "assign" && (
        <FormDialog
          title={`Add permissions to ${selectedRole.name}`}
          fields={(permissions.data ?? [])
            .filter(
              (p) =>
                !(assigned.data ?? []).some(
                  (a) => a.permission_id === p.permission_id,
                ),
            )
            .map((p) =>
              field(String(p.permission_id), "checkbox", {
                label: `${p.name} · ${p.module_display}`,
              }),
            )}
          onClose={() => setModal(null)}
          onSave={async (values) => {
            await api.post(
              `/roles/${selectedRole.role_id}/assign-permissions/`,
              {
                permission_ids: Object.keys(values)
                  .filter((k) => values[k])
                  .map(Number),
              },
              token,
            );
            refresh();
            setNotice("Permissions assigned.");
          }}
        >
          <p>
            Existing permissions are retained. Select additional permissions to
            grant.
          </p>
        </FormDialog>
      )}
      {["approve", "reject"].includes(modal?.type) && (
        <FormDialog
          title={`${words(modal.type)} access request`}
          submit={words(modal.type)}
          fields={
            modal.type === "reject"
              ? [field("rejection_reason", "textarea", { required: true })]
              : []
          }
          onClose={() => setModal(null)}
          onSave={async (values) => {
            await api.post(
              `/permission-requests/${modal.request.request_id}/${modal.type}/`,
              values,
              token,
            );
            refresh();
            setNotice(
              `Request ${modal.type === "approve" ? "approved" : "rejected"}.`,
            );
          }}
        >
          <Facts data={modal.request} />
        </FormDialog>
      )}
      {modal?.type === "detail" && (
        <Modal label="Details" onClose={() => setModal(null)}>
          <div className="modal ops-modal">
            <h2>Details</h2>
            <div className="ops-detail">
              <Facts data={modal.data} />
            </div>
            <button className="btn" onClick={() => setModal(null)}>
              Close
            </button>
          </div>
        </Modal>
      )}
    </>
  );
}
