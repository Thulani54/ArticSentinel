def mqtt_client_id(device_pk):
    """Stable, automatically assigned identity for one registered device."""
    value = int(device_pk)
    if value <= 0 or value >= 2**80:
        raise ValueError('Invalid device identifier')
    return f'AS_{value:020X}'


def csv_cell(value):
    """Avoid spreadsheet formula execution in exported user-entered values."""
    if value is None:
        return ''
    value = str(value)
    if value.lstrip().startswith(('=', '+', '-', '@', '\t', '\r', '\n')):
        return "'" + value
    return value
