class MaintenanceRecord {
  final String id;
  final Device device;
  final MaintenanceType maintenanceType;
  final DateTime scheduledDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final String status;
  final String statusDisplay;
  final String priority;
  final String priorityDisplay;
  final User? assignedTo;
  final User? performedBy;
  final String workDescription;
  final String workPerformed;
  final String issuesFound;
  final String resolutionNotes;
  final String recommendations;
  final String? outcome;
  final String? outcomeDisplay;
  final double? estimatedCost;
  final double? actualCost;
  final double? estimatedDurationHours;
  final double? actualDurationHours;
  final DateTime? nextMaintenanceDate;
  final List<dynamic> partsUsed;
  final List<dynamic> materialsUsed;
  final String externalContractor;
  final bool isOverdue;
  final double? durationVariance;
  final double? costVariance;
  final List<ChecklistItem> checklistItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRecord({
    required this.id,
    required this.device,
    required this.maintenanceType,
    required this.scheduledDate,
    this.actualStartDate,
    this.actualEndDate,
    required this.status,
    required this.statusDisplay,
    required this.priority,
    required this.priorityDisplay,
    this.assignedTo,
    this.performedBy,
    required this.workDescription,
    required this.workPerformed,
    required this.issuesFound,
    required this.resolutionNotes,
    required this.recommendations,
    this.outcome,
    this.outcomeDisplay,
    this.estimatedCost,
    this.actualCost,
    this.estimatedDurationHours,
    this.actualDurationHours,
    this.nextMaintenanceDate,
    required this.partsUsed,
    required this.materialsUsed,
    required this.externalContractor,
    required this.isOverdue,
    this.durationVariance,
    this.costVariance,
    required this.checklistItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'],
      device: Device.fromJson(json['device']),
      maintenanceType: MaintenanceType.fromJson(json['maintenance_type']),
      scheduledDate: DateTime.parse(json['scheduled_date']),
      actualStartDate: json['actual_start_date'] != null
          ? DateTime.parse(json['actual_start_date'])
          : null,
      actualEndDate: json['actual_end_date'] != null
          ? DateTime.parse(json['actual_end_date'])
          : null,
      status: json['status'],
      statusDisplay: json['status_display'],
      priority: json['priority'],
      priorityDisplay: json['priority_display'],
      assignedTo: json['assigned_to'] != null
          ? User.fromJson(json['assigned_to'])
          : null,
      performedBy: json['performed_by'] != null
          ? User.fromJson(json['performed_by'])
          : null,
      workDescription: json['work_description'] ?? '',
      workPerformed: json['work_performed'] ?? '',
      issuesFound: json['issues_found'] ?? '',
      resolutionNotes: json['resolution_notes'] ?? '',
      recommendations: json['recommendations'] ?? '',
      outcome: json['outcome'],
      outcomeDisplay: json['outcome_display'],
      estimatedCost: json['estimated_cost']?.toDouble(),
      actualCost: json['actual_cost']?.toDouble(),
      estimatedDurationHours: json['estimated_duration_hours']?.toDouble(),
      actualDurationHours: json['actual_duration_hours']?.toDouble(),
      nextMaintenanceDate: json['next_maintenance_date'] != null
          ? DateTime.parse(json['next_maintenance_date'])
          : null,
      partsUsed: json['parts_used'] ?? [],
      materialsUsed: json['materials_used'] ?? [],
      externalContractor: json['external_contractor'] ?? '',
      isOverdue: json['is_overdue'] ?? false,
      durationVariance: json['duration_variance']?.toDouble(),
      costVariance: json['cost_variance']?.toDouble(),
      checklistItems: (json['checklist_items'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Device {
  final int id;
  final String name;
  final String deviceId;

  Device({required this.id, required this.name, required this.deviceId});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      deviceId: json['device_id']?.toString() ?? '',
    );
  }
}

class MaintenanceType {
  final String id;
  final String name;
  final String category;
  final String categoryDisplay;

  MaintenanceType({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryDisplay,
  });

  factory MaintenanceType.fromJson(Map<String, dynamic> json) {
    return MaintenanceType(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      categoryDisplay: json['category_display'],
    );
  }
}

class User {
  final int id;
  final String username;
  final String fullName;

  User({required this.id, required this.username, required this.fullName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
    );
  }
}

class ChecklistItem {
  final int id;
  final String description;
  final bool isCompleted;
  final bool isCritical;
  final String? completedBy;
  final DateTime? completedAt;
  final String notes;
  final int order;

  ChecklistItem({
    required this.id,
    required this.description,
    required this.isCompleted,
    required this.isCritical,
    this.completedBy,
    this.completedAt,
    required this.notes,
    required this.order,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      description: json['description'],
      isCompleted: json['is_completed'],
      isCritical: json['is_critical'],
      completedBy: json['completed_by'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      notes: json['notes'] ?? '',
      order: json['order'],
    );
  }
}
