import { useId, useState } from "react";
import Modal from "./Modal";
import { Empty } from "./bits";
import "./operations.css";

export const words = (value) =>
  String(value ?? "")
    .replaceAll("_", " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
export const dateTime = (value) =>
  value ? new Date(value).toLocaleString() : "—";
export function Tabs({ items, value, onChange, label = "Sections" }) {
  return (
    <nav className="ops-tabs" aria-label={label}>
      {items.map((item) => (
        <button
          type="button"
          className={value === item ? "on" : ""}
          aria-current={value === item ? "page" : undefined}
          key={item}
          onClick={() => onChange(item)}
        >
          {words(item)}
        </button>
      ))}
    </nav>
  );
}
export function Field({ field, value, onChange }) {
  const id = useId();
  const {
    key,
    label = words(key),
    type = "text",
    options,
    required,
    ...rest
  } = field;
  return (
    <div className={type === "textarea" ? "full" : ""}>
      <label htmlFor={id}>
        {label}
        {required ? " *" : ""}
      </label>
      {type === "checkbox" ? (
        <input
          id={id}
          type="checkbox"
          checked={!!value}
          onChange={(e) => onChange(e.target.checked)}
        />
      ) : options ? (
        <select
          id={id}
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value)}
          required={required}
        >
          {options.map((o) => (
            <option key={o.value ?? o} value={o.value ?? o}>
              {o.label ?? words(o)}
            </option>
          ))}
        </select>
      ) : type === "textarea" ? (
        <textarea
          id={id}
          rows={3}
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value)}
          required={required}
        />
      ) : (
        <input
          id={id}
          type={type}
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value)}
          required={required}
          {...rest}
        />
      )}
    </div>
  );
}
export function FormDialog({
  title,
  fields = [],
  initial = {},
  onSave,
  onClose,
  children,
  submit = "Save",
}) {
  const [form, setForm] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  return (
    <Modal label={title} onClose={() => !busy && onClose()}>
      <div className="modal ops-modal">
        <h2>{title}</h2>
        {children}
        {error && (
          <p className="form-err" role="alert">
            {error}
          </p>
        )}
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            setBusy(true);
            setError("");
            try {
              await onSave(form);
              onClose();
            } catch (err) {
              setError(err.message);
            } finally {
              setBusy(false);
            }
          }}
        >
          <div className="form-grid">
            {fields.map((f) => (
              <Field
                key={f.key}
                field={f}
                value={form[f.key]}
                onChange={(value) =>
                  setForm((old) => ({ ...old, [f.key]: value }))
                }
              />
            ))}
          </div>
          <div className="foot">
            <button
              type="button"
              className="btn"
              disabled={busy}
              onClick={onClose}
            >
              Cancel
            </button>
            <button className="btn primary" disabled={busy}>
              {busy ? "Saving…" : submit}
            </button>
          </div>
        </form>
      </div>
    </Modal>
  );
}
export function Facts({ data, omit = [] }) {
  if (!data || typeof data !== "object")
    return (
      <span>
        {data == null || data === ""
          ? "—"
          : typeof data === "boolean"
            ? data
              ? "Yes"
              : "No"
            : String(data)}
      </span>
    );
  if (Array.isArray(data))
    return data.length ? (
      <div className="ops-stack">
        {data.map((v, i) => (
          <div className="ops-card" key={i}>
            <Facts data={v} />
          </div>
        ))}
      </div>
    ) : (
      <span>None</span>
    );
  return (
    <dl className="ops-facts">
      {Object.entries(data)
        .filter(([k]) => !omit.includes(k))
        .map(([k, v]) => (
          <div key={k}>
            <dt>{words(k)}</dt>
            <dd>
              <Facts data={v} />
            </dd>
          </div>
        ))}
    </dl>
  );
}
export function DataTable({ rows = [], columns, empty = "No records found." }) {
  return rows.length ? (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c.key}>{c.label ?? words(c.key)}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr
              key={
                row.id ??
                row.role_id ??
                row.permission_id ??
                row.request_id ??
                i
              }
            >
              {columns.map((c) => (
                <td key={c.key}>
                  {c.render ? c.render(row) : <Facts data={row[c.key]} />}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  ) : (
    <Empty>{empty}</Empty>
  );
}
export function Pager({ page, pages = 1, total, onChange, busy }) {
  return (
    <div className="ops-toolbar">
      <span className="ink2">
        {total ?? "—"} results · Page {page} of {Math.max(1, pages)}
      </span>
      <button
        className="btn sm"
        disabled={busy || page <= 1}
        onClick={() => onChange(page - 1)}
      >
        Previous
      </button>
      <button
        className="btn sm"
        disabled={busy || page >= pages}
        onClick={() => onChange(page + 1)}
      >
        Next
      </button>
    </div>
  );
}
export function Tiles({ data = {} }) {
  return (
    <div className="tiles">
      {Object.entries(data).map(([k, v]) => (
        <div className="tile" key={k}>
          <div className="eyebrow">{words(k)}</div>
          <div className="v">{v ?? "—"}</div>
        </div>
      ))}
    </div>
  );
}
export const choice = (key, options, label) => ({
  key,
  options: [{ value: "", label: "All" }, ...options],
  label,
});
export const field = (key, type = "text", extra = {}) => ({
  key,
  type,
  ...extra,
});
