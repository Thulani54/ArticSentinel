import 'package:artic_sentinel/models/unit.dart';

class AddedDevice {
  int id;
  String deviceId;
  String type;
  String allocatedTo;
  String status;

  AddedDevice(this.id, this.deviceId, this.type, this.allocatedTo, this.status);
}

class Device {
  final int? id;
  final String? companyName;
  final String name;
  final String deviceId;
  final String? productId;
  final String? location;
  final String? building;
  final String? floor;
  final String? room;
  final String? deviceType;
  final String? phaseType;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? capacity;
  final double? targetTempMin;
  final double? targetTempMax;
  final String? installationDate;
  final String? warrantyExpiry;
  final String? lastServiceDate;
  final String? nextServiceDate;
  final bool isActive;
  final bool isOnline;
  final String? lastPing;
  final String? createdAt;
  final String? updatedAt;
  final ConnectedUnit? connectedUnit;
  final bool isInRepairMode;
  final String? repairModeStartedAt;
  final String? repairModeReason;

  Device({
    this.id,
    this.companyName,
    required this.name,
    required this.deviceId,
    this.productId,
    this.location,
    this.building,
    this.floor,
    this.room,
    this.deviceType,
    this.phaseType,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.capacity,
    this.targetTempMin,
    this.targetTempMax,
    this.installationDate,
    this.warrantyExpiry,
    this.lastServiceDate,
    this.nextServiceDate,
    this.isActive = true,
    this.isOnline = false,
    this.lastPing,
    this.createdAt,
    this.updatedAt,
    this.connectedUnit,
    this.isInRepairMode = false,
    this.repairModeStartedAt,
    this.repairModeReason,
  });

  // Factory constructor to create an empty Device
  factory Device.empty() {
    return Device(
      name: '',
      deviceId: '',
    );
  }

  // Factory constructor to create Device from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int?,
      companyName: json['company_name'] as String?,
      name: json['name'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      location: json['location'] as String?,
      building: json['building'] as String?,
      floor: json['floor'] as String?,
      room: json['room'] as String?,
      deviceType: json['device_type'] as String?,
      phaseType: json['phase_type'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      capacity: json['capacity'] as String?,
      targetTempMin: _parseDouble(json['target_temp_min']),
      targetTempMax: _parseDouble(json['target_temp_max']),
      installationDate: json['installation_date'] as String?,
      warrantyExpiry: json['warranty_expiry'] as String?,
      lastServiceDate: json['last_service_date'] as String?,
      nextServiceDate: json['next_service_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isOnline: json['is_online'] as bool? ?? false,
      lastPing: json['last_ping'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isInRepairMode: json['is_in_repair_mode'] ?? false,
      repairModeStartedAt: json['repair_mode_started_at'],
      repairModeReason: json['repair_mode_reason'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'device_id': deviceId,
      'product_id': productId,
      'location': location,
      'building': building,
      'floor': floor,
      'room': room,
      'device_type': deviceType,
      'phase_type': phaseType,
      'manufacturer': manufacturer,
      'model': model,
      'serial_number': serialNumber,
      'capacity': capacity,
      'target_temp_min': targetTempMin,
      'target_temp_max': targetTempMax,
      'installation_date': installationDate,
      'warranty_expiry': warrantyExpiry,
      'last_service_date': lastServiceDate,
      'next_service_date': nextServiceDate,
      'is_active': isActive,
      'is_online': isOnline,
      'last_ping': lastPing,
      'is_in_repair_mode': isInRepairMode,
      'repair_mode_started_at': repairModeStartedAt,
      'repair_mode_reason': repairModeReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'connected_unit_id': connectedUnit?.id,
    };
  }

  // Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Convert Device to JSON
  Map<String, dynamic> toJsonOld() {
    return {
      if (id != null) 'id': id,
      if (companyName != null) 'company_name': companyName,
      'name': name,
      'device_id': deviceId,
      if (productId != null) 'product_id': productId,
      if (location != null) 'location': location,
      if (building != null) 'building': building,
      if (floor != null) 'floor': floor,
      if (room != null) 'room': room,
      if (deviceType != null) 'device_type': deviceType,
      if (phaseType != null) 'phase_type': phaseType,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (capacity != null) 'capacity': capacity,
      if (targetTempMin != null) 'target_temp_min': targetTempMin,
      if (targetTempMax != null) 'target_temp_max': targetTempMax,
      if (installationDate != null) 'installation_date': installationDate,
      if (warrantyExpiry != null) 'warranty_expiry': warrantyExpiry,
      if (lastServiceDate != null) 'last_service_date': lastServiceDate,
      if (nextServiceDate != null) 'next_service_date': nextServiceDate,
      'is_active': isActive,
      'is_online': isOnline,
      if (lastPing != null) 'last_ping': lastPing,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  // Convert Device to JSON for API requests (excludes read-only fields)
  Map<String, dynamic> toJsonForApi() {
    return {
      'name': name,
      'device_id': deviceId,
      if (productId != null && productId!.isNotEmpty) 'product_id': productId,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (building != null && building!.isNotEmpty) 'building': building,
      if (floor != null && floor!.isNotEmpty) 'floor': floor,
      if (room != null && room!.isNotEmpty) 'room': room,
      if (deviceType != null && deviceType!.isNotEmpty)
        'device_type': deviceType,
      if (phaseType != null && phaseType!.isNotEmpty) 'phase_type': phaseType,
      if (manufacturer != null && manufacturer!.isNotEmpty)
        'manufacturer': manufacturer,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (serialNumber != null && serialNumber!.isNotEmpty)
        'serial_number': serialNumber,
      if (capacity != null && capacity!.isNotEmpty) 'capacity': capacity,
      if (targetTempMin != null) 'target_temp_min': targetTempMin,
      if (targetTempMax != null) 'target_temp_max': targetTempMax,
      if (installationDate != null && installationDate!.isNotEmpty)
        'installation_date': installationDate,
      if (warrantyExpiry != null && warrantyExpiry!.isNotEmpty)
        'warranty_expiry': warrantyExpiry,
      if (lastServiceDate != null && lastServiceDate!.isNotEmpty)
        'last_service_date': lastServiceDate,
      if (nextServiceDate != null && nextServiceDate!.isNotEmpty)
        'next_service_date': nextServiceDate,
      'is_active': isActive,
    };
  }

  // Create a copy of Device with modified fields
  Device copyWith({
    int? id,
    String? companyName,
    String? name,
    String? deviceId,
    String? productId,
    String? location,
    String? building,
    String? floor,
    String? room,
    String? deviceType,
    String? phaseType,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? capacity,
    double? targetTempMin,
    double? targetTempMax,
    String? installationDate,
    String? warrantyExpiry,
    String? lastServiceDate,
    String? nextServiceDate,
    bool? isActive,
    bool? isOnline,
    String? lastPing,
    String? createdAt,
    String? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      productId: productId ?? this.productId,
      location: location ?? this.location,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      room: room ?? this.room,
      deviceType: deviceType ?? this.deviceType,
      phaseType: phaseType ?? this.phaseType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      capacity: capacity ?? this.capacity,
      targetTempMin: targetTempMin ?? this.targetTempMin,
      targetTempMax: targetTempMax ?? this.targetTempMax,
      installationDate: installationDate ?? this.installationDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      lastPing: lastPing ?? this.lastPing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if device is empty (useful for form validation)
  bool get isEmpty {
    return name.isEmpty && deviceId.isEmpty;
  }

  // Check if device has basic required information
  bool get isValid {
    return name.isNotEmpty && deviceId.isNotEmpty;
  }

  // Get device status display text
  String get statusDisplay {
    if (!isActive) return 'Inactive';
    if (isOnline) return 'Online';
    return 'Offline';
  }

  // Get device type display text (capitalize first letter)
  String get deviceTypeDisplay {
    if (deviceType == null || deviceType!.isEmpty) return 'Unknown';
    return deviceType![0].toUpperCase() + deviceType!.substring(1);
  }

  // Get formatted temperature range
  String get temperatureRange {
    if (targetTempMin != null && targetTempMax != null) {
      return '${targetTempMin!.toStringAsFixed(1)}°C to ${targetTempMax!.toStringAsFixed(1)}°C';
    } else if (targetTempMin != null) {
      return 'Min: ${targetTempMin!.toStringAsFixed(1)}°C';
    } else if (targetTempMax != null) {
      return 'Max: ${targetTempMax!.toStringAsFixed(1)}°C';
    }
    return 'Not set';
  }

  // Get formatted installation date
  String get formattedInstallationDate {
    if (installationDate == null || installationDate!.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(installationDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return installationDate!;
    }
  }

  // Check if warranty is still valid
  bool get isWarrantyValid {
    if (warrantyExpiry == null || warrantyExpiry!.isEmpty) return false;
    try {
      final expiryDate = DateTime.parse(warrantyExpiry!);
      return expiryDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  // Check if service is due
  bool get isServiceDue {
    if (nextServiceDate == null || nextServiceDate!.isEmpty) return false;
    try {
      final serviceDate = DateTime.parse(nextServiceDate!);
      return serviceDate.isBefore(
          DateTime.now().add(Duration(days: 30))); // Due within 30 days
    } catch (e) {
      return false;
    }
  }

  // Get full location string
  String get fullLocation {
    List<String> locationParts = [];
    if (location != null && location!.isNotEmpty) locationParts.add(location!);
    if (building != null && building!.isNotEmpty) locationParts.add(building!);
    if (floor != null && floor!.isNotEmpty)
      locationParts.add('Floor: ${floor!}');
    if (room != null && room!.isNotEmpty) locationParts.add('Room: ${room!}');

    return locationParts.isEmpty
        ? 'Location not set'
        : locationParts.join(', ');
  }

  @override
  String toString() {
    return 'Device{id: $id, name: $name, deviceId: $deviceId, deviceType: $deviceType, isActive: $isActive, isOnline: $isOnline}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device &&
        other.id == id &&
        other.name == name &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ deviceId.hashCode;
  }
}

// Helper class for parsing API responses
class DeviceResponse {
  final List<Device> devices;
  final int count;

  DeviceResponse({
    required this.devices,
    required this.count,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      devices: (json['devices'] as List<dynamic>?)
              ?.map((item) => Device.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devices': devices.map((device) => device.toJson()).toList(),
      'count': count,
    };
  }
}

// Enum for device types (you can extend this based on your needs)
enum DeviceType {
  chiller,
  freezer,
  refrigerator,
  airConditioner,
  heater,
  ventilation,
  unknown;

  String get displayName {
    switch (this) {
      case DeviceType.chiller:
        return 'Chiller';
      case DeviceType.freezer:
        return 'Freezer';
      case DeviceType.refrigerator:
        return 'Refrigerator';
      case DeviceType.airConditioner:
        return 'Air Conditioner';
      case DeviceType.heater:
        return 'Heater';
      case DeviceType.ventilation:
        return 'Ventilation';
      case DeviceType.unknown:
        return 'Unknown';
    }
  }

  static DeviceType fromString(String? value) {
    if (value == null || value.isEmpty) return DeviceType.unknown;

    switch (value.toLowerCase()) {
      case 'chiller':
        return DeviceType.chiller;
      case 'freezer':
        return DeviceType.freezer;
      case 'refrigerator':
        return DeviceType.refrigerator;
      case 'air_conditioner':
      case 'airconditioner':
        return DeviceType.airConditioner;
      case 'heater':
        return DeviceType.heater;
      case 'ventilation':
        return DeviceType.ventilation;
      default:
        return DeviceType.unknown;
    }
  }
}

// Enum for phase types
enum PhaseType {
  single,
  three,
  unknown;

  String get displayName {
    switch (this) {
      case PhaseType.single:
        return 'Single Phase';
      case PhaseType.three:
        return 'Three Phase';
      case PhaseType.unknown:
        return 'Unknown';
    }
  }

  static PhaseType fromString(String? value) {
    if (value == null || value.isEmpty) return PhaseType.unknown;

    switch (value.toLowerCase()) {
      case 'single':
        return PhaseType.single;
      case 'three':
        return PhaseType.three;
      default:
        return PhaseType.unknown;
    }
  }
}
