# Historical performance for inactive equipment

`inactive-performance-history.patch` removes only the active-status restriction from the existing `DeviceMetricsView` read. The device/company lookup remains intact and device settings are not changed. This allows the web UI to use the same rich metrics response as Flutter for inactive equipment.

Applied to `/home/vmrvsnyo/exvr/services/mqtt_data_service.py` on 2026-09-25. Original source backup: `/home/vmrvsnyo/backups/uat-website/mqtt-before-inactive-history.py`. Gunicorn workers were gracefully reloaded with HUP. The backend repository is separate from this frontend repository; this patch records the deployed change without including unrelated server changes.

Validation: the metrics view returned HTTP 200 for all 11 non-gas devices in company 1, querying 2026-07-19 through 2026-08-06. D7-001 returned 90 readings with daily and hourly activity. Device1 without data returns synthetic zero buckets, so the frontend checks actual reading counts before displaying analytics.

Existing limitation: device1 maintenance insight generation logs a missing `device_maintenance_urgency_log` table, although the metrics request succeeds. This patch does not alter database schema or maintenance logic.
