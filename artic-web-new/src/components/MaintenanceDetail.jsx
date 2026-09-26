import { useState } from "react";
import { api } from "../api";
import { useAuth } from "../auth";
import Modal from "./Modal";
import { Panel, Spinner } from "./bits";
import {
  Tabs,
  Facts,
  FormDialog,
  Field,
  DataTable,
  field,
  words,
  dateTime,
} from "./Operations";
import { useOperation } from "./useOperation";
import {
  priorities,
  statuses,
  outcomes,
  observationCategories,
  maintenancePayload,
  localDateTime,
  mediaUrl,
} from "../lib/operations/maintenance";

function AttachmentUpload({
  title,
  path,
  token,
  fields = [],
  onClose,
  onDone,
}) {
  const [file, setFile] = useState(null);
  const [values, setValues] = useState({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  return (
    <Modal label={title} onClose={() => !busy && onClose()}>
      <div className="modal ops-modal">
        <h2>{title}</h2>
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            setBusy(true);
            try {
              const body = new FormData();
              body.append("file", file);
              Object.entries(values).forEach(([k, v]) => body.append(k, v));
              await api.request(path, "POST", body, token);
              onDone();
              onClose();
            } catch (err) {
              setError(err.message);
            } finally {
              setBusy(false);
            }
          }}
        >
          <label htmlFor="maintenance-upload">File</label>
          <input
            id="maintenance-upload"
            type="file"
            required
            onChange={(e) => setFile(e.target.files[0])}
          />
          {fields.map((f) => (
            <Field
              key={f.key}
              field={f}
              value={values[f.key]}
              onChange={(v) => setValues((old) => ({ ...old, [f.key]: v }))}
            />
          ))}
          {error && <p className="form-err">{error}</p>}
          <div className="foot">
            <button
              type="button"
              className="btn"
              disabled={busy}
              onClick={onClose}
            >
              Cancel
            </button>
            <button className="btn primary" disabled={busy || !file}>
              {busy ? "Uploading…" : "Upload"}
            </button>
          </div>
        </form>
      </div>
    </Modal>
  );
}
export default function MaintenanceDetail({ id, users, onClose, onChange }) {
  const { token, business, user } = useAuth();
  const bid = business.business_uid;
  const [tab, setTab] = useState("overview");
  const [modal, setModal] = useState(null);
  const [error, setError] = useState("");
  const state = useOperation(
    () => api.get(`/maintenance/${id}/`, token).then((d) => d.maintenance),
    [id, token],
  );
  const record = state.data;
  const refresh = () => {
    state.refresh();
    onChange();
  };
  const post = async (path, data) => {
    await api.post(`/maintenance/${path}`, data, token);
    refresh();
  };
  const assignedOptions = [
    { value: "", label: "Unassigned" },
    ...users.map((u) => ({ value: u.id, label: u.full_name || u.username })),
  ];
  const detailsFields = [
    field("work_description", "textarea", { required: true }),
    { key: "priority", options: priorities },
    { key: "assigned_to_id", options: assignedOptions },
    { key: "performed_by_id", options: assignedOptions },
    field("scheduled_date", "datetime-local", { required: true }),
    field("estimated_cost", "number", { min: 0, step: "any" }),
    field("actual_cost", "number", { min: 0, step: "any" }),
    field("estimated_duration_hours", "number", { min: 0, step: "any" }),
    field("actual_start_date", "datetime-local"),
    field("actual_end_date", "datetime-local"),
    field("next_maintenance_date", "date"),
  ];
  const findingsFields = [
    "work_performed",
    "issues_found",
    "resolution_notes",
    "recommendations",
  ]
    .map((k) => field(k, "textarea"))
    .concat({
      key: "outcome",
      options: [{ value: "", label: "Not recorded" }, ...outcomes],
    });
  const documentationFields = [
    "parts_used",
    "materials_used",
    "external_contractor",
    "contractor_contact",
    "safety_precautions",
    "compliance_notes",
  ].map((k) =>
    field(k, "textarea", {
      label: words(k) + (k.endsWith("_used") ? " (one per line)" : ""),
    }),
  );
  const edit = (title, fields) => setModal({ type: "edit", title, fields });
  const confirmDelete = (path, title) =>
    setModal({ type: "delete", path, title });
  const files = (items, section, observation) => (
    <div>
      {(items ?? []).length === 0 ? (
        <p className="ops-note">No attachments.</p>
      ) : (
        (items ?? []).map((f, i) => (
          <div className="ops-file" key={f.id ?? i}>
            {mediaUrl(f) ? (
              <a href={mediaUrl(f)} target="_blank" rel="noreferrer">
                {f.filename || f.caption || `Attachment ${i + 1}`}
              </a>
            ) : (
              <span>Attachment unavailable</span>
            )}
            <span>
              {f.description || f.caption || f.part_name || f.material_name}
            </span>
            {f.id && (
              <button
                className="btn sm"
                onClick={() =>
                  confirmDelete(
                    observation
                      ? `observation/${observation}/image/${f.id}/delete/`
                      : `${id}/${section}/${f.id}/delete/`,
                    "Delete attachment",
                  )
                }
              >
                Delete
              </button>
            )}
          </div>
        ))
      )}
    </div>
  );
  const upload = (title, path, fields) =>
    setModal({ type: "upload", title, path: `/maintenance/${path}`, fields });
  const initial = record
    ? {
        ...record,
        assigned_to_id: record.assigned_to?.id ?? "",
        performed_by_id: record.performed_by?.id ?? "",
        scheduled_date: localDateTime(record.scheduled_date),
        actual_start_date: localDateTime(record.actual_start_date),
        actual_end_date: localDateTime(record.actual_end_date),
        parts_used: Array.isArray(record.parts_used)
          ? record.parts_used.join("\n")
          : record.parts_used,
        materials_used: Array.isArray(record.materials_used)
          ? record.materials_used.join("\n")
          : record.materials_used,
      }
    : {};
  return (
    <Modal label="Maintenance details" onClose={onClose}>
      <div className="modal ops-modal">
        <div className="page-head">
          <div>
            <div className="eyebrow">Service record</div>
            <h2>{record?.device?.name || "Maintenance details"}</h2>
          </div>
          <button className="btn" onClick={onClose}>
            Close
          </button>
        </div>
        {state.loading && <Spinner />}
        {state.error && (
          <p className="form-err">
            {state.error}
            <button className="btn" onClick={state.refresh}>
              Retry
            </button>
          </p>
        )}
        {error && <p className="form-err">{error}</p>}
        {record && (
          <>
            <div className="ops-actions">
              <span
                className={`chip ${record.status === "completed" ? "good" : "warn"}`}
              >
                {words(record.status)}
              </span>
              {["scheduled", "overdue"].includes(record.status) && (
                <button
                  className="btn primary"
                  onClick={() => setModal({ type: "status", action: "start" })}
                >
                  Start work
                </button>
              )}
              {record.status === "in_progress" && (
                <button
                  className="btn primary"
                  onClick={() =>
                    setModal({ type: "status", action: "complete" })
                  }
                >
                  Complete
                </button>
              )}
              {!["completed", "cancelled"].includes(record.status) && (
                <>
                  <button
                    className="btn"
                    onClick={() =>
                      setModal({ type: "status", action: "reschedule" })
                    }
                  >
                    Reschedule
                  </button>
                  <button
                    className="btn"
                    onClick={() =>
                      setModal({ type: "status", action: "cancel" })
                    }
                  >
                    Cancel maintenance
                  </button>
                </>
              )}
              <button
                className="btn"
                onClick={async () => {
                  setError("");
                  try {
                    await api.download(
                      `/maintenance/reports/${id}/pdf/?business_id=${bid}`,
                      "GET",
                      null,
                      token,
                      `maintenance-${id}.pdf`,
                    );
                  } catch (e) {
                    setError(e.message);
                  }
                }}
              >
                Download PDF
              </button>
              <button
                className="btn"
                onClick={() =>
                  confirmDelete(`${id}/delete/`, "Delete maintenance record")
                }
              >
                Delete
              </button>
            </div>
            <Tabs
              items={[
                "overview",
                "checklist",
                "findings",
                "timeline",
                "documentation",
              ]}
              value={tab}
              onChange={setTab}
            />
            <div className="ops-detail">
              {tab === "overview" && (
                <>
                  <button
                    className="btn"
                    onClick={() => edit("Edit maintenance", detailsFields)}
                  >
                    Edit record
                  </button>
                  <Facts
                    data={record}
                    omit={[
                      "checklist_items",
                      "observations",
                      "before_photos",
                      "after_photos",
                      "documents",
                      "parts_images",
                      "materials_images",
                      "work_performed",
                      "issues_found",
                      "resolution_notes",
                      "recommendations",
                    ]}
                  />
                </>
              )}
              {tab === "checklist" && (
                <>
                  <p className="ops-note">
                    Checklist changes are available while maintenance is in
                    progress.
                  </p>
                  <button
                    className="btn"
                    disabled={record.status !== "in_progress"}
                    onClick={() => setModal({ type: "checklist" })}
                  >
                    Add checklist item
                  </button>
                  <DataTable
                    rows={record.checklist_items}
                    columns={[
                      { key: "description" },
                      { key: "is_critical" },
                      { key: "is_completed" },
                      { key: "notes" },
                      { key: "completed_by" },
                      {
                        key: "completed_at",
                        render: (r) => dateTime(r.completed_at),
                      },
                      {
                        key: "actions",
                        render: (r) => (
                          <div className="ops-actions">
                            <button
                              className="btn sm"
                              disabled={record.status !== "in_progress"}
                              onClick={() =>
                                setModal({ type: "checklist", item: r })
                              }
                            >
                              Edit / complete
                            </button>
                            <button
                              className="btn sm"
                              disabled={record.status !== "in_progress"}
                              onClick={() =>
                                confirmDelete(
                                  `checklist/${r.id}/delete/`,
                                  "Delete checklist item",
                                )
                              }
                            >
                              Delete
                            </button>
                          </div>
                        ),
                      },
                    ]}
                  />
                </>
              )}
              {tab === "findings" && (
                <>
                  <button
                    className="btn"
                    onClick={() => edit("Findings and outcome", findingsFields)}
                  >
                    Edit findings
                  </button>
                  <Facts
                    data={Object.fromEntries(
                      findingsFields.map((f) => [f.key, record[f.key]]),
                    )}
                  />
                </>
              )}
              {tab === "timeline" && (
                <Facts
                  data={Object.fromEntries(
                    [
                      "created_at",
                      "scheduled_date",
                      "actual_start_date",
                      "actual_end_date",
                      "next_maintenance_date",
                      "updated_at",
                    ].map((k) => [k, dateTime(record[k])]),
                  )}
                />
              )}
              {tab === "documentation" && (
                <div className="ops-stack">
                  <button
                    className="btn"
                    onClick={() =>
                      edit("Parts, materials and safety", documentationFields)
                    }
                  >
                    Edit documentation
                  </button>
                  <Facts
                    data={Object.fromEntries(
                      documentationFields.map((f) => [f.key, record[f.key]]),
                    )}
                  />
                  {[
                    {
                      title: "Before photos",
                      key: "before_photos",
                      section: "media",
                    },
                    {
                      title: "After photos",
                      key: "after_photos",
                      section: "media",
                    },
                    {
                      title: "Documents",
                      key: "documents",
                      section: "document",
                    },
                    {
                      title: "Parts images",
                      key: "parts_images",
                      section: "parts",
                    },
                    {
                      title: "Materials images",
                      key: "materials_images",
                      section: "materials",
                    },
                  ].map((group) => (
                    <section className="ops-card" key={group.key}>
                      <h3>{group.title}</h3>
                      {files(record[group.key], group.section)}
                      <button
                        className="btn sm"
                        onClick={() =>
                          upload(
                            `Upload ${group.title.toLowerCase()}`,
                            `${id}/upload-${group.section === "media" ? "media" : group.section === "document" ? "document" : `${group.section}-image`}/`,
                            group.section === "media"
                              ? [
                                  {
                                    key: "photo_type",
                                    options: ["before", "after"],
                                  },
                                ]
                              : group.section === "document"
                                ? [field("description")]
                                : [
                                    field(
                                      group.section === "parts"
                                        ? "part_name"
                                        : "material_name",
                                    ),
                                    field("caption"),
                                  ],
                          )
                        }
                      >
                        Upload
                      </button>
                    </section>
                  ))}
                  <section className="ops-card">
                    <h3>Observations</h3>
                    <button
                      className="btn"
                      onClick={() => setModal({ type: "observation" })}
                    >
                      Add observation
                    </button>
                    {(record.observations ?? []).map((o) => (
                      <article key={o.id} className="ops-card">
                        <Facts data={o} omit={["images"]} />
                        {files(o.images, null, o.id)}
                        <div className="ops-actions">
                          <button
                            className="btn sm"
                            onClick={() =>
                              setModal({ type: "observation", item: o })
                            }
                          >
                            Edit
                          </button>
                          <button
                            className="btn sm"
                            onClick={() =>
                              upload(
                                "Observation attachment",
                                `observation/${o.id}/upload-image/`,
                                [field("caption")],
                              )
                            }
                          >
                            Upload image
                          </button>
                          <button
                            className="btn sm"
                            onClick={() =>
                              confirmDelete(
                                `observations/${o.id}/delete/`,
                                "Delete observation",
                              )
                            }
                          >
                            Delete
                          </button>
                        </div>
                      </article>
                    ))}
                  </section>
                </div>
              )}
            </div>
          </>
        )}
        {modal?.type === "edit" && (
          <FormDialog
            title={modal.title}
            fields={modal.fields}
            initial={Object.fromEntries(
              modal.fields.map((f) => [f.key, initial[f.key] ?? ""]),
            )}
            onClose={() => setModal(null)}
            onSave={(v) => post(`${id}/update/`, maintenancePayload(v))}
          />
        )}
        {modal?.type === "status" && (
          <FormDialog
            title={`${words(modal.action)} maintenance`}
            submit="Confirm"
            initial={{ outcome: "successful" }}
            fields={
              modal.action === "complete"
                ? [{ key: "outcome", options: outcomes }]
                : modal.action === "reschedule"
                  ? [field("new_date", "datetime-local", { required: true })]
                  : modal.action === "cancel"
                    ? [field("reason", "textarea", { required: true })]
                    : []
            }
            onClose={() => setModal(null)}
            onSave={(v) =>
              post(`${id}/status/`, {
                ...v,
                ...(v.new_date
                  ? { new_date: new Date(v.new_date).toISOString() }
                  : {}),
                action: modal.action,
                user_id: user?.user_uid,
              })
            }
          >
            <p>
              {record?.device?.name} · {record?.maintenance_type?.name}
            </p>
          </FormDialog>
        )}
        {modal?.type === "delete" && (
          <FormDialog
            title={modal.title}
            submit="Delete permanently"
            onClose={() => setModal(null)}
            onSave={async () => {
              await api.request(
                `/maintenance/${modal.path}`,
                "DELETE",
                null,
                token,
              );
              if (modal.path === `${id}/delete/`) {
                onChange();
                onClose();
              } else refresh();
            }}
          >
            <p>
              This permanently removes the selected item. This cannot be undone.
            </p>
          </FormDialog>
        )}
        {modal?.type === "checklist" && (
          <FormDialog
            title={modal.item ? "Edit checklist item" : "Add checklist item"}
            initial={modal.item ?? { is_critical: false, is_completed: false }}
            fields={[
              field("description", "textarea", { required: true }),
              field("notes", "textarea"),
              field("is_critical", "checkbox"),
              ...(modal.item ? [field("is_completed", "checkbox")] : []),
            ]}
            onClose={() => setModal(null)}
            onSave={(v) =>
              post(
                modal.item
                  ? `checklist/${modal.item.id}/update/`
                  : `${id}/checklist/add/`,
                { ...v, user_id: user?.user_uid },
              )
            }
          />
        )}
        {modal?.type === "observation" && (
          <FormDialog
            title={modal.item ? "Edit observation" : "Add observation"}
            initial={modal.item ?? { category: "general", is_critical: false }}
            fields={[
              { key: "category", options: observationCategories },
              field("text", "textarea", { required: true }),
              field("is_critical", "checkbox"),
            ]}
            onClose={() => setModal(null)}
            onSave={(v) =>
              post(
                modal.item
                  ? `observations/${modal.item.id}/update/`
                  : `${id}/observations/`,
                { ...v, user_id: user?.user_uid },
              )
            }
          />
        )}
        {modal?.type === "upload" && (
          <AttachmentUpload
            {...modal}
            token={token}
            onClose={() => setModal(null)}
            onDone={refresh}
          />
        )}
      </div>
    </Modal>
  );
}
