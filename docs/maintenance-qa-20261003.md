# Maintenance workflow verification — 3 October 2026

The Flutter maintenance module was audited against the deployed Django route and view source and checked in the iOS simulator. Backend verification then exercised temporary records inside a PostgreSQL transaction that was rolled back. No existing customer maintenance records changed, no test rows persisted, and no reminder emails were sent.

## Repaired behaviour

- Every maintenance JSON call sends the signed-in token. Actor IDs come from the actual signed-in profile instead of the previous hardcoded user 1. Team lookups include the current business.
- Failed inventory requests no longer invent three sample devices. Empty accounts and unavailable setup have distinct states.
- Creating maintenance refreshes the dashboard. Record detail changes refresh on return. Scheduled dates are sent in UTC and displayed locally.
- Recurring schedule creation now has a working form. Edit, duplicate, delete and record export actions now work instead of being empty menu handlers.
- Create and duplicate forms include a stable `client_request_id` across unchanged retries. Changing a payload creates a new ID. Recurring schedule creation sends the same field. Matching backend replay handling was deployed and verified.
- Record pagination is reachable after the first 50 entries. Changing filters starts from page one; stale requests cannot replace newer results. Clearing filters also clears the date range.
- Status and checklist failures stay visible; a failed request does not report success. Critical checklist items must be completed before closing maintenance in the detail view.
- Create-form dropdowns and text inputs explicitly use a readable dark foreground; the real iOS theme exposed white-on-white values that widget layout tests had missed. Dashboard summary counts show their reporting period so recent totals are not mistaken for all-time record counts.
- Narrow-screen header and checklist overflows were fixed. Full-screen mobile edit/schedule forms retain constrained dialogs on larger screens.
- Maintenance settings no longer show switches that did nothing. They link to the real recurring schedule, reminder and cost analysis tools.
- Sample CSV and PDF exports were removed from both reports entry points. HTTP failures cannot become empty successful maintenance reports.
- Detailed PDFs unwrap the actual record from the API response. A file-save failure cannot dismiss the reports page. Mobile exports use the native save/share chooser without requesting broad storage permission or assuming a filesystem path.

## Automated coverage

`test/maintenance_workflow_test.dart` has 16 tests:

1. Create a record using actual-shaped equipment data and refresh the dashboard.
2. Load more record pages, filter by status and clear filters.
3. Inventory request failure does not fabricate devices.
4. Empty equipment produces an explicit setup state.
5. Validate and create a recurring schedule with the chosen frequency.
6. Edit a record, assign a technician and send a UTC date.
7. Retain form entries after a failed edit.
8. Start maintenance, block completion for an unchecked critical item, check it and complete.
9. Render all five detail tabs at 320 pixels.
10. Render all six dashboard tabs at 320 pixels.
11. Keep the original status after a failed status update.
12. Duplicate into a new scheduled record without overwriting the original.
13. Reuse request identity on retry and replace it after changed entries.
14. Show real empty report state without sample actions.
15. Generate a PDF containing the actual record ID; retain the report page after a simulated file-save failure.
16. Propagate report HTTP failure instead of returning empty data.

Combined with the 12 existing operation empty-state tests and four report mobile-control tests, 32 checks pass. These use mocked HTTP responses and secure-storage mocks and exercise real Flutter widgets and PDF generation; they are not a physical-device or live-service end-to-end run. Analyzer reports no errors in the maintenance/report files and new tests; legacy style and unused-code warnings remain in the two existing large screen files.

## Read-only iOS simulator verification

On iPhone 17 Pro (iOS 26.5), signed into the existing authorized account, the live service supplied the maintenance overview and records. Opened the create and recurring schedule forms, existing record details, all five detail tabs, and populated Edit form. Canceled forms without submitting changes. All checked views loaded; empty checklist/findings/documentation states appeared correctly. The check discovered and fixed the create-form contrast issue and missing summary-period context noted above.

Evidence: `mobile-reliability-20261003/maintenance-detail-ios.png`, `maintenance-edit-ios.png`, and `maintenance-recurring-ios.png`. The final build was reinstalled and reopened successfully. Device/type dropdowns and selected values were verified readable; the full-screen form was canceled without saving. The final capture is `mobile-reliability-20261003/maintenance-create-ios.png`.

## Rolled-back deployed-handler verification

`backend/maintenance_updates/verify_rollback_workflow.py` was executed successfully on the deployed host against the actual Django route handlers and PostgreSQL. All 15 route calls returned their expected status. The script verified:

- Create and unchanged retry return the same record without duplication; edits persist within the transaction.
- Start records the authenticated actor. Completion returns the expected 409 while a critical item remains unchecked, then succeeds after checking it.
- Detail, PostgreSQL report aggregates, monthly records and the generated PDF include the temporary completed record.
- Recurring schedule creation and retry retain one schedule; updating the frequency recalculates the next due date.
- After rollback, the temporary maintenance, checklist and schedule rows are absent. No messages were sent.

The script used an existing authorized token in process, checked for unexpected model receivers/database triggers, and blocked mail, Celery, new network connections and storage writes. It did not generate globally due maintenance or modify existing records. PostgreSQL checklist sequences can advance despite rollback. This is deployed-handler/database integration verification, separate from the read-only simulator checks; it is not a single physical-device-to-network end-to-end run.

Sanitized route/status evidence: [maintenance-postgres-verification.json](mobile-reliability-20261003/maintenance-postgres-verification.json).

## Read-only background-task review

Inspected the deployed `maintenance/tasks.py` and only maintenance-related beat names/schedules. The file contains reminder tasks, with upcoming checks every 30 minutes and advance/overdue checks every four hours. No recurring generation task or maintenance generation beat entry was found in the inspected configuration; generation remains the explicit guarded action.

Two existing worker concurrency gaps were identified for release review: the overdue checker can save an outdated status without a lock or conditional transition, and the email sender does not recheck status or the reminder's sent flag before delivery. A queued reminder can therefore become stale or duplicated. The unconfigured one-time missed-reminder repair task also includes in-progress records when marking overdue and should not be used for verification. No background task was run and no email was sent during this inspection. Worker-load/concurrent-delivery behaviour is not covered by the successful in-process route verification.

## Physical-device checks still outstanding

- Select a real document/photo through the native picker and verify upload/download permissions.
- Save/share a PDF through the Android and iOS system chooser.
- Trigger real reminder delivery to an agreed test recipient.
