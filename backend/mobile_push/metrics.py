"""Allowlisted telemetry columns and units; client input never becomes SQL."""
import math
from django.db import connections

def metric(label, unit, margin, minimum=None, maximum=None, boolean=False):
    return dict(label=label,unit=unit,reset_margin=margin,minimum=minimum,maximum=maximum,boolean=boolean)
TEMP=lambda label: metric(label,'°C',0.5,-100,500)
CURRENT=lambda label: metric(label,'A',0.5,0,10000)
PRESSURE=lambda label: metric(label,'bar',0.2,-1,1000)
STATE=lambda label: metric(label,'',0.5,0,1,True)
CATALOG={
 'gas_cylinder': {'gas_level':metric('Gas remaining','%',5,0,100),'battery_pct':metric('Battery','%',5,0,100),'temp':TEMP('Scale temperature')},
 'device1': {'temperature_air':TEMP('Air temperature'),'temperature_coil':TEMP('Coil temperature'),'temperature_drain':TEMP('Drain temperature'),
  **{f'comp_amp_ph{i}':CURRENT(f'Compressor phase {i} current') for i in range(1,4)},
  'compressor_low':metric('Low-side pressure','psi',2,-15,10000),'compressor_high':metric('High-side pressure','psi',2,-15,10000),'door':STATE('Door open'),'comp':STATE('Compressor running'),'ice_built_up':STATE('Ice buildup')},
 'device2': {f'temp{i}':TEMP(f'Temperature {i}') for i in range(1,9)},
 'device3': {'hs_temp':TEMP('High-side temperature'),'ls_temp':TEMP('Low-side temperature'),'ice_temp':TEMP('Ice temperature'),'air_temp':TEMP('Air temperature'),'wtrlvl':metric('Water level','%',5,0,100),'amps':CURRENT('Current'),'harvsw':STATE('Harvest switch')},
 'device4': {f'{i}comph{p}':CURRENT(f'Compressor {i} phase {p} current') for i in range(1,9) for p in range(1,4)},
 'device5': {f'relay{i}':STATE(f'Relay {i}') for i in range(1,17)},
 'device6': {f'prs{i}':PRESSURE(f'Pressure {i}') for i in range(1,9)},
 'device7': {**{f'tray{i}wt':metric(f'Tray {i} weight','kg',0.5,-1000,10000) for i in range(1,5)},'temp':TEMP('Temperature'),'scan_verified':STATE('Scan verified')},
}
TABLES={'gas_cylinder':'gas_cylinder_data','device1':'mqtt_data_timescale','device2':'device2_data','device3':'mqtt_data_device3',**{f'device{i}':f'device{i}_data' for i in range(4,8)}}

def device_kind(device):
    return {'chiller':'device1','freezer':'device1'}.get(device.device_type,device.device_type)

def catalog(device):
    return CATALOG.get(device_kind(device),{})

def read_latest(device):
    kind=device_kind(device)
    fields=list(catalog(device))
    if not fields:return None,{}
    columns=[f for f in fields if f!='gas_level']
    if kind=='gas_cylinder':columns.append('gross_kg')
    # Table and columns originate solely in the static catalog above.
    quoted=', '.join('"'+field+'"' for field in columns)
    with connections['timeseries'].cursor() as cursor:
        cursor.execute(f'SELECT time, {quoted} FROM "{TABLES[kind]}" WHERE device_id=%s AND time >= NOW() - INTERVAL \'15 minutes\' AND time <= NOW() ORDER BY time DESC LIMIT 1',[device.device_id])
        row=cursor.fetchone()
    if row is None:return None,{}
    values={key:float(value) for key,value in zip(columns,row[1:]) if value is not None and math.isfinite(float(value))}
    if kind=='gas_cylinder':
        from device.models import GasCylinderConfig
        config=GasCylinderConfig.objects.filter(device=device).first()
        gross=values.get('gross_kg')
        if config and config.gas_capacity_kg>0 and gross is not None and gross>=config.tare_kg-0.2:
            values['gas_level']=min(100,max(0,(gross-config.tare_kg)/config.gas_capacity_kg*100))
    return row[0],values
