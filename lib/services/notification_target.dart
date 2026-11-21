/// Only known server payload fields can become an in-app destination.
class NotificationTarget {
  const NotificationTarget({this.deviceId});
  final int? deviceId;
  factory NotificationTarget.fromData(Map<String, dynamic> data) {
    if (data['kind'] == 'notification_test') return const NotificationTarget();
    final id = int.tryParse('${data['device_id']}');
    return NotificationTarget(deviceId: id != null && id > 0 ? id : null);
  }
  String get route => deviceId == null
      ? '/notification-settings'
      : '/notification-device/$deviceId';
}
