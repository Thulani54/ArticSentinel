"""Read-only Timescale queries. Never returns MQTT credentials or auth keys."""
from django.db import connections

def scan_rows(device, since, until, search, result, offset):
    clauses = ['device_id = %s', 'time >= %s', 'time < %s', "code_scan IS NOT NULL AND BTRIM(code_scan) <> ''"]
    params = [device.device_id, since, until]
    if search:
        clauses.append('POSITION(LOWER(%s) IN LOWER(code_scan)) > 0')
        params.append(search)
    if result != 'all':
        clauses.append('scan_verified = %s')
        params.append(result == 'verified')
    query = '''SELECT time, code_scan, scan_verified, scan_direction, manufacturer,
        temp, tray1wt, tray2wt, tray3wt, tray4wt FROM device7_data WHERE ''' + ' AND '.join(clauses)
    with connections['timeseries'].cursor() as cursor:
        cursor.execute(query + ' ORDER BY time DESC, code_scan ASC LIMIT 51 OFFSET %s', [*params, offset])
        rows = cursor.fetchall()
    return [{'time': row[0].isoformat(), 'code': row[1], 'verified': row[2], 'direction': row[3],
        'manufacturer': row[4], 'temperature': row[5], 'tray_kg': list(row[6:10])} for row in rows]
