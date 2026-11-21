import test from "node:test";
import assert from "node:assert/strict";
import {
  maintenancePayload,
  localDateTime,
  mediaUrl,
} from "../src/lib/operations/maintenance.js";
test("maintenance payload preserves zero costs and converts IDs and lists", () => {
  const p = maintenancePayload({
    device_id: "28",
    assigned_to_id: "",
    estimated_cost: "0",
    parts_used: "Valve\n\nSeal",
    materials_used: "",
    checklist: "Check seal\nTest pressure",
  });
  assert.equal(p.device_id, 28);
  assert.equal(p.assigned_to_id, null);
  assert.equal(p.estimated_cost, 0);
  assert.deepEqual(p.parts_used, ["Valve", "Seal"]);
  assert.deepEqual(p.materials_used, []);
  assert.deepEqual(p.checklist_items, [
    { description: "Check seal" },
    { description: "Test pressure" },
  ]);
  assert.equal(p.checklist, undefined);
});
test("custom scheduling validates intervals and end date", () => {
  assert.throws(
    () =>
      maintenancePayload({ frequency: "custom", custom_frequency_days: "0" }),
    /at least one day/,
  );
  assert.throws(
    () =>
      maintenancePayload({ start_date: "2026-09-26", end_date: "2026-09-25" }),
    /End date/,
  );
  assert.equal(
    maintenancePayload({ frequency: "custom", custom_frequency_days: "14" })
      .custom_frequency_days,
    14,
  );
});
test("local datetime conversion leaves absent dates blank", () => {
  assert.equal(localDateTime(null), "");
  assert.equal(localDateTime(undefined), "");
  assert.equal(localDateTime("invalid"), "");
});
test("attachment URLs resolve server-relative paths and reject executable URLs", () => {
  assert.equal(
    mediaUrl("/media/maintenance/a.pdf"),
    "https://api.articsentinel.com/media/maintenance/a.pdf",
  );
  assert.equal(mediaUrl("javascript:alert(1)"), null);
  assert.equal(
    mediaUrl({ url: "https://api.articsentinel.com/media/a.png" }),
    "https://api.articsentinel.com/media/a.png",
  );
});
