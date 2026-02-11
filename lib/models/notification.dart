class NotificationModel {
  final int id;
  final String deviceId;
  final String alertType;
  final String alertCategory;
  final String message;
  final String timestamp;
  final bool isResolved;
  final bool isSystemAlert;
  final String paramCode;

  NotificationModel({
    required this.id,
    required this.deviceId,
    required this.alertType,
    required this.alertCategory,
    required this.message,
    required this.timestamp,
    required this.isResolved,
    required this.isSystemAlert,
    required this.paramCode,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      deviceId: json['device_id']?.toString() ?? '',
      alertType: json['alert_type'],
      alertCategory: json['alert_category'],
      message: json['message'],
      timestamp: json['timestamp'],
      isResolved: json['is_resolved'],
      isSystemAlert: json['is_system_alert'],
      paramCode: json['param_code'],
    );
  }
}
