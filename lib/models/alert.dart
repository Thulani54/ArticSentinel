import 'dart:ui';

import 'package:flutter/material.dart';

class Alert {
  final int? id;
  final int deviceId;
  final String? deviceName;
  final int? triggerRuleId;
  final int companyId;
  final String title;
  final String message;
  final String severity;
  final String status;
  final String triggeredAt;
  final String? resolvedAt;
  final String? acknowledgedAt;
  final int? acknowledgedBy;
  final String? acknowledgedByName;
  final bool emailSent;
  final bool smsSent;
  final String? emailSentAt;
  final String? smsSentAt;
  final Map<String, dynamic>? triggerData;

  Alert({
    this.id,
    required this.deviceId,
    this.deviceName,
    this.triggerRuleId,
    required this.companyId,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.triggeredAt,
    this.resolvedAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.acknowledgedByName,
    this.emailSent = false,
    this.smsSent = false,
    this.emailSentAt,
    this.smsSentAt,
    this.triggerData,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int?,
      deviceId: json['device_id'] ?? json['device'] ?? 0,
      deviceName: json['device_name'] as String?,
      triggerRuleId: json['trigger_rule_id'] ?? json['trigger_rule'] as int?,
      companyId: json['company_id'] ?? json['company'] ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      status: json['status'] as String? ?? 'active',
      triggeredAt: json['triggered_at'] as String? ?? '',
      resolvedAt: json['resolved_at'] as String?,
      acknowledgedAt: json['acknowledged_at'] as String?,
      acknowledgedBy: json['acknowledged_by'] as int?,
      acknowledgedByName: json['acknowledged_by_name'] as String?,
      emailSent: json['email_sent'] as bool? ?? false,
      smsSent: json['sms_sent'] as bool? ?? false,
      emailSentAt: json['email_sent_at'] as String?,
      smsSentAt: json['sms_sent_at'] as String?,
      triggerData: json['trigger_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (triggerRuleId != null) 'trigger_rule_id': triggerRuleId,
      'company_id': companyId,
      'title': title,
      'message': message,
      'severity': severity,
      'status': status,
      'triggered_at': triggeredAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
      if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
      if (acknowledgedByName != null)
        'acknowledged_by_name': acknowledgedByName,
      'email_sent': emailSent,
      'sms_sent': smsSent,
      if (emailSentAt != null) 'email_sent_at': emailSentAt,
      if (smsSentAt != null) 'sms_sent_at': smsSentAt,
      if (triggerData != null) 'trigger_data': triggerData,
    };
  }

  // Helper getters
  String get formattedTriggeredAt {
    try {
      final dateTime = DateTime.parse(triggeredAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return triggeredAt;
    }
  }

  DateTime get triggeredDateTime {
    try {
      return DateTime.parse(triggeredAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get severityDisplay {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return severity;
    }
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'acknowledged':
        return 'Acknowledged';
      case 'resolved':
        return 'Resolved';
      case 'false_positive':
        return 'False Positive';
      default:
        return status;
    }
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'false_positive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get severityIcon {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.notification_important;
      default:
        return Icons.notifications;
    }
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isAcknowledged => status.toLowerCase() == 'acknowledged';
  bool get isResolved => status.toLowerCase() == 'resolved';

  String get duration {
    DateTime endTime =
        resolvedAt != null ? DateTime.parse(resolvedAt!) : DateTime.now();

    Duration diff = endTime.difference(triggeredDateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inMinutes}m';
    }
  }

  Alert copyWith({
    int? id,
    int? deviceId,
    String? deviceName,
    int? triggerRuleId,
    int? companyId,
    String? title,
    String? message,
    String? severity,
    String? status,
    String? triggeredAt,
    String? resolvedAt,
    String? acknowledgedAt,
    int? acknowledgedBy,
    String? acknowledgedByName,
    bool? emailSent,
    bool? smsSent,
    String? emailSentAt,
    String? smsSentAt,
    Map<String, dynamic>? triggerData,
  }) {
    return Alert(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      triggerRuleId: triggerRuleId ?? this.triggerRuleId,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedByName: acknowledgedByName ?? this.acknowledgedByName,
      emailSent: emailSent ?? this.emailSent,
      smsSent: smsSent ?? this.smsSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      smsSentAt: smsSentAt ?? this.smsSentAt,
      triggerData: triggerData ?? this.triggerData,
    );
  }

  @override
  String toString() {
    return 'Alert{id: $id, title: $title, severity: $severity, status: $status}';
  }
}

// Alert response wrapper
class AlertResponse {
  final List<Alert> alerts;
  final int count;
  final String? nextPage;
  final String? previousPage;

  AlertResponse({
    required this.alerts,
    required this.count,
    this.nextPage,
    this.previousPage,
  });

  factory AlertResponse.fromJson(Map<String, dynamic> json) {
    return AlertResponse(
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((item) => Alert.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] as int? ?? 0,
      nextPage: json['next'] as String?,
      previousPage: json['previous'] as String?,
    );
  }
}
