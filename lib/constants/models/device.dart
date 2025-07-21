import 'package:artic_sentinel/models/user.dart';

import '../../models/client.dart';

class DeviceModel {
  int id;
  String deviceStatus;
  String deviceId;
  Client client;
  User created_by;
  String currentStatus;
  String firmwareVersion;
  String hardwareVersion;
  String imei;
  String iccid;
  double batteryCapacity;
  double pvPower;
  String longitude;
  String latitude;
  double speed;
  String accuracy;
  String gpsTime;
  double temperature;
  double humidity;
  DateTime dateCreated;
  DateTime lastAvailable;
  DateTime lastModified;
  String notes;
  String lastCheckedBy;
  String deviceAttachedBy;

  DeviceModel({
    required this.id,
    required this.deviceId,
    required this.deviceStatus,
    required this.client,
    required this.created_by,
    required this.currentStatus,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.imei,
    required this.iccid,
    required this.batteryCapacity,
    required this.pvPower,
    required this.longitude,
    required this.latitude,
    required this.speed,
    required this.accuracy,
    required this.gpsTime,
    required this.temperature,
    required this.humidity,
    required this.dateCreated,
    required this.lastAvailable,
    required this.lastModified,
    required this.notes,
    required this.lastCheckedBy,
    required this.deviceAttachedBy,
  });

  // Factory method to parse data from JSON
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? '',
      deviceStatus: json['deviceStatus'] ?? '',
      client: Client.fromJson(json['client'] ?? {}),
      created_by: User.fromJson(json['created_by'] ?? {}),
      currentStatus: json['current_status'] ?? '',
      firmwareVersion: json['firmware_version'] ?? '',
      hardwareVersion: json['hardware_version'] ?? '',
      imei: json['imei'] ?? '',
      iccid: json['iccid'] ?? '',
      batteryCapacity: json['battery_capacity'] != null
          ? double.tryParse(json['battery_capacity'].toString()) ?? 0.0
          : 0.0,
      pvPower: json['pv_power'] != null
          ? double.tryParse(json['pv_power'].toString()) ?? 0.0
          : 0.0,
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      speed: json['speed'] != null
          ? double.tryParse(json['speed'].toString()) ?? 0.0
          : 0.0,
      accuracy: json['accuracy'] ?? '',
      gpsTime: json['gps_time'] ?? "",
      temperature: json['temperature'] != null
          ? double.tryParse(json['temperature'].toString()) ?? 0.0
          : 0.0,
      humidity: json['humidity'] != null
          ? double.tryParse(json['humidity'].toString()) ?? 0.0
          : 0.0,
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : DateTime.now(),
      lastAvailable: json['last_available'] != null
          ? DateTime.parse(json['last_available'])
          : DateTime.now(),
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'])
          : DateTime.now(),
      notes: json['notes'] ?? '',
      lastCheckedBy: json['lastCheckedBy'] ?? '',
      deviceAttachedBy: json['deviceAttachedBy'] ?? '',
    );
  }

  // Convert the object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'deviceStatus': deviceStatus,
      'client': client,
      'created_by': created_by,
      'current_status': currentStatus,
      'firmware_version': firmwareVersion,
      'hardware_version': hardwareVersion,
      'imei': imei,
      'iccid': iccid,
      'battery_capacity': batteryCapacity,
      'pv_power': pvPower,
      'longitude': longitude,
      'latitude': latitude,
      'speed': speed,
      'accuracy': accuracy,
      'gps_time': gpsTime,
      'temperature': temperature,
      'humidity': humidity,
      'date_created': dateCreated.toIso8601String(),
      'last_available': lastAvailable.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'notes': notes,
      'last_checked_by': lastCheckedBy,
      'device_attached_by': deviceAttachedBy,
    };
  }
}

class LatestDeviceData3 {
  final String? time;
  final double? temperature;
  final double? temperatureAir;
  final double? temperatureCoil;
  final double? temperatureDrain;
  final bool? door;
  final bool? iceBuiltUp;
  final bool? comp;
  final double? compressorLow;
  final double? compressorHigh;
  final double? compAmpPh1;
  final double? compAmpPh2;
  final double? compAmpPh3;

  LatestDeviceData3({
    this.time,
    this.temperature,
    this.temperatureAir,
    this.temperatureCoil,
    this.temperatureDrain,
    this.door,
    this.iceBuiltUp,
    this.comp,
    this.compressorLow,
    this.compressorHigh,
    this.compAmpPh1,
    this.compAmpPh2,
    this.compAmpPh3,
  });

  factory LatestDeviceData3.fromJson(Map<String, dynamic> json) {
    return LatestDeviceData3(
      time: json['time'],
      temperature: json['temperature']?.toDouble(),
      temperatureAir:
          json['temperature_air']?.toDouble(), // Note: snake_case in API
      temperatureCoil: json['temperature_coil']?.toDouble(),
      temperatureDrain: json['temperature_drain']?.toDouble(),
      door: json['door'],
      iceBuiltUp: json['ice_built_up'], // Note: snake_case in API
      comp: json['comp'],
      compressorLow:
          json['compressor_low']?.toDouble(), // Note: snake_case in API
      compressorHigh: json['compressor_high']?.toDouble(),
      compAmpPh1: json['comp_amp_ph1']?.toDouble(),
      compAmpPh2: json['comp_amp_ph2']?.toDouble(),
      compAmpPh3: json['comp_amp_ph3']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature': temperature,
      'temperature_air': temperatureAir,
      'temperature_coil': temperatureCoil,
      'temperature_drain': temperatureDrain,
      'door': door,
      'ice_built_up': iceBuiltUp,
      'comp': comp,
      'compressor_low': compressorLow,
      'compressor_high': compressorHigh,
      'comp_amp_ph1': compAmpPh1,
      'comp_amp_ph2': compAmpPh2,
      'comp_amp_ph3': compAmpPh3,
    };
  }
}

class DeviceModel3 {
  final int id;
  final String deviceId;
  final String name;
  final String? productId;
  final String? location;
  final String? building;
  final String? floor;
  final String? room;
  final String deviceType;
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
  final DateTime? lastPing;
  final bool isInRepairMode;
  final DateTime? repairModeStartedAt;
  final String? repairModeReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String currentStatus;
  final String latitude;
  final String longitude;
  final LatestDeviceData3? latestData;

  DeviceModel3({
    required this.id,
    required this.deviceId,
    required this.name,
    this.productId,
    this.location,
    this.building,
    this.floor,
    this.room,
    required this.deviceType,
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
    required this.isActive,
    required this.isOnline,
    this.lastPing,
    required this.isInRepairMode,
    this.repairModeStartedAt,
    this.repairModeReason,
    required this.createdAt,
    required this.updatedAt,
    required this.currentStatus,
    required this.latitude,
    required this.longitude,
    this.latestData,
  });

  factory DeviceModel3.fromJson(Map<String, dynamic> json) {
    return DeviceModel3(
      id: json['id'],
      deviceId: json['device_id'],
      name: json['name'],
      productId: json['product_id'],
      location: json['location'],
      building: json['building'],
      floor: json['floor'],
      room: json['room'],
      deviceType: json['device_type'],
      phaseType: json['phase_type'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      serialNumber: json['serial_number'],
      capacity: json['capacity'],
      targetTempMin: json['target_temp_min']?.toDouble(),
      targetTempMax: json['target_temp_max']?.toDouble(),
      installationDate: json['installation_date'],
      warrantyExpiry: json['warranty_expiry'],
      lastServiceDate: json['last_service_date'],
      nextServiceDate: json['next_service_date'],
      isActive: json['is_active'] ?? false,
      isOnline: json['is_online'] ?? false,
      lastPing:
          json['last_ping'] != null ? DateTime.parse(json['last_ping']) : null,
      isInRepairMode: json['is_in_repair_mode'] ?? false,
      repairModeStartedAt: json['repair_mode_started_at'] != null
          ? DateTime.parse(json['repair_mode_started_at'])
          : null,
      repairModeReason: json['repair_mode_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      currentStatus: json['current_status'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      latestData: json['latest_data'] != null
          ? LatestDeviceData3.fromJson(json['latest_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'name': name,
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
      'last_ping': lastPing?.toIso8601String(),
      'is_in_repair_mode': isInRepairMode,
      'repair_mode_started_at': repairModeStartedAt?.toIso8601String(),
      'repair_mode_reason': repairModeReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'current_status': currentStatus,
      'latitude': latitude,
      'longitude': longitude,
      'latest_data': latestData?.toJson(),
    };
  }

  // Helper methods for device status
  String get statusColor {
    if (isOnline) return 'green';
    if (isActive) return 'orange';
    return 'red';
  }

  String get statusText {
    if (isOnline) return 'Online';
    if (isActive) return 'Offline';
    return 'Inactive';
  }

  String get deviceTypeDisplayName {
    switch (deviceType.toLowerCase()) {
      case 'chiller':
        return 'Chiller';
      case 'freezer':
        return 'Freezer';
      case 'refrigerator':
        return 'Refrigerator';
      default:
        return deviceType;
    }
  }

  String get phaseTypeDisplayName {
    switch (phaseType?.toLowerCase()) {
      case 'single':
        return 'Single Phase';
      case 'three':
        return 'Three Phase';
      default:
        return phaseType ?? 'Unknown';
    }
  }

  // Check if device needs service
  bool get needsService {
    if (nextServiceDate == null) return false;

    try {
      final serviceDate = DateTime.parse(nextServiceDate!);
      final now = DateTime.now();
      final daysUntilService = serviceDate.difference(now).inDays;

      return daysUntilService <= 30; // Service needed within 30 days
    } catch (e) {
      return false;
    }
  }

  // Check if warranty is expiring soon
  bool get warrantyExpiringSoon {
    if (warrantyExpiry == null) return false;

    try {
      final warrantyDate = DateTime.parse(warrantyExpiry!);
      final now = DateTime.now();
      final daysUntilExpiry = warrantyDate.difference(now).inDays;

      return daysUntilExpiry <= 90 &&
          daysUntilExpiry > 0; // Expiring within 90 days
    } catch (e) {
      return false;
    }
  }

  // Get temperature status based on target range
  String get temperatureStatus {
    if (latestData?.temperatureAir == null) return 'No Data';
    if (targetTempMin == null || targetTempMax == null) return 'No Target Set';

    final temp = latestData!.temperatureAir!;

    if (temp < targetTempMin!) return 'Too Cold';
    if (temp > targetTempMax!) return 'Too Warm';
    return 'Normal';
  }

  // Check if device has critical alerts
  bool get hasCriticalIssues {
    if (!isOnline) return true;
    if (isInRepairMode) return true;
    if (temperatureStatus == 'Too Cold' || temperatureStatus == 'Too Warm')
      return true;
    if (latestData?.iceBuiltUp == true) return true;

    return false;
  }

  // Get compressor status
  String get compressorStatus {
    if (latestData?.comp == null) return 'Unknown';
    return latestData!.comp! ? 'Running' : 'Stopped';
  }

  // Calculate average compressor amperage
  double? get averageCompressorAmp {
    if (latestData?.compAmpPh1 == null ||
        latestData?.compAmpPh2 == null ||
        latestData?.compAmpPh3 == null) return null;

    return (latestData!.compAmpPh1! +
            latestData!.compAmpPh2! +
            latestData!.compAmpPh3!) /
        3;
  }
}
