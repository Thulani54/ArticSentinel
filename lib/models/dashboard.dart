import 'dart:ui';

import 'package:flutter/cupertino.dart';

class DashboardData {
  final List<LatestDeviceData> currentData;
  final List<DailyAggregate> dailyAggregates;
  final List<HourlyAggregate> hourlyAggregates;
  final List<DeviceAlert> alerts;
  final DateTime timestamp;

  DashboardData({
    required this.currentData,
    required this.dailyAggregates,
    required this.hourlyAggregates,
    required this.alerts,
    required this.timestamp,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      currentData: (json['current_data'] as List? ?? [])
          .map((item) => LatestDeviceData.fromJson(item))
          .toList(),
      dailyAggregates: (json['daily_aggregates'] as List? ?? [])
          .map((item) => DailyAggregate.fromJson(item))
          .toList(),
      hourlyAggregates: (json['hourly_aggregates'] as List? ?? [])
          .map((item) => HourlyAggregate.fromJson(item))
          .toList(),
      alerts: (json['alerts'] as List? ?? [])
          .map((item) => DeviceAlert.fromJson(item))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class DeviceAlert {
  final String deviceId;
  final String alertType;
  final String severity;
  final String message;
  final DateTime timestamp;
  final dynamic value;
  final dynamic threshold;

  DeviceAlert({
    required this.deviceId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.value,
    this.threshold,
  });

  factory DeviceAlert.fromJson(Map<String, dynamic> json) {
    return DeviceAlert(
      deviceId: json['device_id']
          .toString(), // Convert to String to handle both int and String
      alertType: json['alert_type'],
      severity: json['severity'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'],
      threshold: json['threshold'],
    );
  }
}

class DailyAggregate2 {
  String? dayBucket;
  String? deviceId;
  double? avgTempAir;
  double? minTempAir;
  double? maxTempAir;
  double? avgTempCoil;
  double? minTempCoil;
  double? maxTempCoil;
  double? avgTempDrain;
  double? minTempDrain;
  double? maxTempDrain;
  int? doorOpenCount;
  int? iceEvents;
  double? avgCompAmp;
  double? maxCompAmp;
  double? avgLowSidePressure;
  double? avgHighSidePressure;
  // New fields for door analysis
  double? totalDoorOpenMinutes;
  String? doorStabilityStatus;

  DailyAggregate2({
    this.dayBucket,
    this.deviceId,
    this.avgTempAir,
    this.minTempAir,
    this.maxTempAir,
    this.avgTempCoil,
    this.minTempCoil,
    this.maxTempCoil,
    this.avgTempDrain,
    this.minTempDrain,
    this.maxTempDrain,
    this.doorOpenCount,
    this.iceEvents,
    this.avgCompAmp,
    this.maxCompAmp,
    this.avgLowSidePressure,
    this.avgHighSidePressure,
    // Add to constructor
    this.totalDoorOpenMinutes,
    this.doorStabilityStatus,
  });

  factory DailyAggregate2.fromJson(Map<String, dynamic> json) {
    return DailyAggregate2(
      dayBucket: json['day_bucket'],
      deviceId: json['device_id'],
      avgTempAir: json['avg_temp_air']?.toDouble(),
      minTempAir: json['min_temp_air']?.toDouble(),
      maxTempAir: json['max_temp_air']?.toDouble(),
      avgTempCoil: json['avg_temp_coil']?.toDouble(),
      minTempCoil: json['min_temp_coil']?.toDouble(),
      maxTempCoil: json['max_temp_coil']?.toDouble(),
      avgTempDrain: json['avg_temp_drain']?.toDouble(),
      minTempDrain: json['min_temp_drain']?.toDouble(),
      maxTempDrain: json['max_temp_drain']?.toDouble(),
      doorOpenCount: json['door_open_count'],
      iceEvents: json['ice_events'],
      avgCompAmp: json['avg_comp_amp']?.toDouble(),
      maxCompAmp: json['max_comp_amp']?.toDouble(),
      avgLowSidePressure: json['avg_low_side_pressure']?.toDouble(),
      avgHighSidePressure: json['avg_high_side_pressure']?.toDouble(),
      // Add fromJson mapping for new fields
      totalDoorOpenMinutes: json['total_door_open_minutes']?.toDouble(),
      doorStabilityStatus: json['door_stability_status'],
    );
  }
}

class HourlyData {
  String? hourBucket;
  String? deviceId;
  double? avgTempAir;
  double? avgTempCoil;
  double? avgTempDrain;
  int? doorOpenCount;
  int? iceEvents;
  double? avgCompAmp;
  double? avgLowSidePressure;
  double? avgHighSidePressure;

  HourlyData({
    this.hourBucket,
    this.deviceId,
    this.avgTempAir,
    this.avgTempCoil,
    this.avgTempDrain,
    this.doorOpenCount,
    this.iceEvents,
    this.avgCompAmp,
    this.avgLowSidePressure,
    this.avgHighSidePressure,
  });

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hourBucket: json['hour_bucket'],
      deviceId: json['device_id'],
      avgTempAir: json['avg_temp_air'],
      avgTempCoil: json['avg_temp_coil'],
      avgTempDrain: json['avg_temp_drain'],
      doorOpenCount: json['door_open_count'],
      iceEvents: json['ice_events'],
      avgCompAmp: json['avg_comp_amp'],
      avgLowSidePressure: json['avg_low_side_pressure'],
      avgHighSidePressure: json['avg_high_side_pressure'],
    );
  }
}

class DailyAggregate {
  final String? dayBucket;
  final String? deviceId;

  // Temperature Air metrics with timestamps
  final double? avgTempAir;
  final double? minTempAir;
  final double? maxTempAir;
  final DateTime? minTempAirTimestamp;
  final DateTime? maxTempAirTimestamp;

  // Temperature Coil metrics with timestamps
  final double? avgTempCoil;
  final double? minTempCoil;
  final double? maxTempCoil;
  final DateTime? minTempCoilTimestamp;
  final DateTime? maxTempCoilTimestamp;

  // Temperature Drain metrics with timestamps
  final double? avgTempDrain;
  final double? minTempDrain;
  final double? maxTempDrain;
  final DateTime? minTempDrainTimestamp;
  final DateTime? maxTempDrainTimestamp;

  // General Temperature metrics
  final double? avgTemp;
  final double? minTemp;
  final double? maxTemp;

  // Event tracking
  final int? iceEvents;

  // Door analysis
  final int? doorOpenCount;
  final int? doorClosedCount;
  final double? totalDoorOpenMinutes;
  final String? doorStabilityStatus;

  // Compressor Amp metrics
  final double? avgCompAmp;
  final double? maxCompAmp;
  final double? avgCompAmpPh1;
  final double? avgCompAmpPh2;
  final double? avgCompAmpPh3;

  // Pressure metrics with timestamps
  final double? avgLowSidePressure;
  final double? minLowSidePressure;
  final double? maxLowSidePressure;
  final DateTime? minLowSidePressureTimestamp;
  final DateTime? maxLowSidePressureTimestamp;

  final double? avgHighSidePressure;
  final double? minHighSidePressure;
  final double? maxHighSidePressure;
  final DateTime? minHighSidePressureTimestamp;
  final DateTime? maxHighSidePressureTimestamp;

  // Compressor runtime
  final int? compressorOnCount;
  final int? compressorOffCount;
  final double? compressorRuntimePercentage;

  // Data quality metrics
  final int? totalReadings;
  final int? validTempAirReadings;
  final int? validPressureReadings;

  // Time-based metrics
  final String? firstReadingTime;
  final String? lastReadingTime;

  // NEW: Uptime Analysis Fields
  final double? deviceUptimePercentage;
  final double? unitOperationalPercentage;
  final int? deviceOnReadings;
  final int? unitOperationalReadings;
  final int? expectedTotalReadings;
  final double? dataTransmissionPercentage;
  final double? dataQualityPercentage;
  final String? deviceStatus;
  final String? unitStatus;

  DailyAggregate({
    this.dayBucket,
    this.deviceId,
    this.avgTempAir,
    this.minTempAir,
    this.maxTempAir,
    this.minTempAirTimestamp,
    this.maxTempAirTimestamp,
    this.avgTempCoil,
    this.minTempCoil,
    this.maxTempCoil,
    this.minTempCoilTimestamp,
    this.maxTempCoilTimestamp,
    this.avgTempDrain,
    this.minTempDrain,
    this.maxTempDrain,
    this.minTempDrainTimestamp,
    this.maxTempDrainTimestamp,
    this.avgTemp,
    this.minTemp,
    this.maxTemp,
    this.iceEvents,
    this.doorOpenCount,
    this.doorClosedCount,
    this.totalDoorOpenMinutes,
    this.doorStabilityStatus,
    this.avgCompAmp,
    this.maxCompAmp,
    this.avgCompAmpPh1,
    this.avgCompAmpPh2,
    this.avgCompAmpPh3,
    this.avgLowSidePressure,
    this.minLowSidePressure,
    this.maxLowSidePressure,
    this.minLowSidePressureTimestamp,
    this.maxLowSidePressureTimestamp,
    this.avgHighSidePressure,
    this.minHighSidePressure,
    this.maxHighSidePressure,
    this.minHighSidePressureTimestamp,
    this.maxHighSidePressureTimestamp,
    this.compressorOnCount,
    this.compressorOffCount,
    this.compressorRuntimePercentage,
    this.totalReadings,
    this.validTempAirReadings,
    this.validPressureReadings,
    this.firstReadingTime,
    this.lastReadingTime,
    // New uptime parameters
    this.deviceUptimePercentage,
    this.unitOperationalPercentage,
    this.deviceOnReadings,
    this.unitOperationalReadings,
    this.expectedTotalReadings,
    this.dataTransmissionPercentage,
    this.dataQualityPercentage,
    this.deviceStatus,
    this.unitStatus,
  });

  factory DailyAggregate.fromJson(Map<String, dynamic> json) {
    return DailyAggregate(
      dayBucket: json['day_bucket'],
      deviceId: json['device_id'],

      // Temperature Air with timestamps
      avgTempAir: json['avg_temp_air']?.toDouble(),
      minTempAir: json['min_temp_air']?.toDouble(),
      maxTempAir: json['max_temp_air']?.toDouble(),
      minTempAirTimestamp: json['min_temp_air_timestamp'] != null
          ? DateTime.parse(json['min_temp_air_timestamp'])
          : null,
      maxTempAirTimestamp: json['max_temp_air_timestamp'] != null
          ? DateTime.parse(json['max_temp_air_timestamp'])
          : null,

      // Temperature Coil with timestamps
      avgTempCoil: json['avg_temp_coil']?.toDouble(),
      minTempCoil: json['min_temp_coil']?.toDouble(),
      maxTempCoil: json['max_temp_coil']?.toDouble(),
      minTempCoilTimestamp: json['min_temp_coil_timestamp'] != null
          ? DateTime.parse(json['min_temp_coil_timestamp'])
          : null,
      maxTempCoilTimestamp: json['max_temp_coil_timestamp'] != null
          ? DateTime.parse(json['max_temp_coil_timestamp'])
          : null,

      // Temperature Drain with timestamps
      avgTempDrain: json['avg_temp_drain']?.toDouble(),
      minTempDrain: json['min_temp_drain']?.toDouble(),
      maxTempDrain: json['max_temp_drain']?.toDouble(),
      minTempDrainTimestamp: json['min_temp_drain_timestamp'] != null
          ? DateTime.parse(json['min_temp_drain_timestamp'])
          : null,
      maxTempDrainTimestamp: json['max_temp_drain_timestamp'] != null
          ? DateTime.parse(json['max_temp_drain_timestamp'])
          : null,

      // General temperature
      avgTemp: json['avg_temp']?.toDouble(),
      minTemp: json['min_temp']?.toDouble(),
      maxTemp: json['max_temp']?.toDouble(),

      // Events
      iceEvents: json['ice_events'],

      // Door analysis
      doorOpenCount: json['door_open_count'],
      doorClosedCount: json['door_closed_count'],
      totalDoorOpenMinutes: json['total_door_open_minutes']?.toDouble(),
      doorStabilityStatus: json['door_stability_status'],

      // Compressor - Note: these fields are missing from the JSON response
      avgCompAmp: json['avg_comp_amp']?.toDouble(),
      maxCompAmp: json['max_comp_amp']?.toDouble(),
      avgCompAmpPh1: json['avg_comp_amp_ph1']?.toDouble(),
      avgCompAmpPh2: json['avg_comp_amp_ph2']?.toDouble(),
      avgCompAmpPh3: json['avg_comp_amp_ph3']?.toDouble(),

      // Pressure with timestamps
      avgLowSidePressure: json['avg_low_side_pressure']?.toDouble(),
      minLowSidePressure: json['min_low_side_pressure']?.toDouble(),
      maxLowSidePressure: json['max_low_side_pressure']?.toDouble(),
      minLowSidePressureTimestamp:
          json['min_low_side_pressure_timestamp'] != null
              ? DateTime.parse(json['min_low_side_pressure_timestamp'])
              : null,
      maxLowSidePressureTimestamp:
          json['max_low_side_pressure_timestamp'] != null
              ? DateTime.parse(json['max_low_side_pressure_timestamp'])
              : null,

      avgHighSidePressure: json['avg_high_side_pressure']?.toDouble(),
      minHighSidePressure: json['min_high_side_pressure']?.toDouble(),
      maxHighSidePressure: json['max_high_side_pressure']?.toDouble(),
      minHighSidePressureTimestamp:
          json['min_high_side_pressure_timestamp'] != null
              ? DateTime.parse(json['min_high_side_pressure_timestamp'])
              : null,
      maxHighSidePressureTimestamp:
          json['max_high_side_pressure_timestamp'] != null
              ? DateTime.parse(json['max_high_side_pressure_timestamp'])
              : null,

      // Runtime - Note: compressor_on_count is missing from JSON response
      compressorOnCount: json['compressor_on_count'],
      compressorOffCount: json['compressor_off_count'],
      compressorRuntimePercentage:
          json['compressor_runtime_percentage']?.toDouble(),

      // Data quality - Note: these fields are missing from JSON response
      totalReadings: json['total_readings'],
      validTempAirReadings: json['valid_temp_air_readings'],
      validPressureReadings: json['valid_pressure_readings'],
      firstReadingTime: json['first_reading_time'],
      lastReadingTime: json['last_reading_time'],

      // NEW: Uptime Analysis
      deviceUptimePercentage: json['device_uptime_percentage']?.toDouble(),
      unitOperationalPercentage:
          json['unit_operational_percentage']?.toDouble(),
      deviceOnReadings: json['device_on_readings'],
      unitOperationalReadings: json['unit_operational_readings'],
      expectedTotalReadings: json['expected_total_readings'],
      dataTransmissionPercentage:
          json['data_transmission_percentage']?.toDouble(),
      dataQualityPercentage: json['data_quality_percentage']?.toDouble(),
      deviceStatus: json['device_status'],
      unitStatus: json['unit_status'],
    );
  }

  // Helper methods for uptime analysis
  bool get isDeviceOnline => (dataTransmissionPercentage ?? 0) >= 95;
  bool get isUnitOperational => (unitOperationalPercentage ?? 0) >= 85;
  bool get hasGoodDataQuality => (dataQualityPercentage ?? 0) >= 90;

  String get overallHealthStatus {
    if (isDeviceOnline && isUnitOperational && hasGoodDataQuality) {
      return 'Excellent';
    } else if ((dataTransmissionPercentage ?? 0) >= 80 &&
        (unitOperationalPercentage ?? 0) >= 60) {
      return 'Good';
    } else if ((dataTransmissionPercentage ?? 0) >= 50 &&
        (unitOperationalPercentage ?? 0) >= 30) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  // Calculate missed data points
  int get missedReadings => (expectedTotalReadings ?? 0) - (totalReadings ?? 0);

  // Calculate data transmission reliability (use the more accurate field)
  double get dataTransmissionReliability => dataTransmissionPercentage ?? 0.0;
}

class HourlyAggregate {
  final String? hourBucket;

  // Temperature metrics
  final double? avgTempAir;
  final double? minTempAir;
  final double? maxTempAir;
  final double? avgTemp;
  final double? minTemp;
  final double? maxTemp;
  final double? avgTempCoil;
  final double? avgTempDrain;

  // Compressor metrics
  final int? compressorOnCount;
  final double? compressorRuntimePercentage;

  // Pressure metrics
  final double? avgLowSidePressure;
  final double? minLowSidePressure;
  final double? maxLowSidePressure;
  final double? avgHighSidePressure;
  final double? minHighSidePressure;
  final double? maxHighSidePressure;

  // Amp metrics
  final double? avgCompAmp;
  final double? maxCompAmp;
  final double? avgCompAmpPh1;
  final double? avgCompAmpPh2;
  final double? avgCompAmpPh3;

  // Door and ice events
  final int? doorOpenCount;
  final int? iceEvents;

  // Data quality
  final int? totalReadings;
  final int? validReadings;

  // Energy efficiency
  final double? energyEfficiencyRatio;

  HourlyAggregate({
    this.hourBucket,
    this.avgTempAir,
    this.minTempAir,
    this.maxTempAir,
    this.avgTemp,
    this.minTemp,
    this.maxTemp,
    this.avgTempCoil,
    this.avgTempDrain,
    this.compressorOnCount,
    this.compressorRuntimePercentage,
    this.avgLowSidePressure,
    this.minLowSidePressure,
    this.maxLowSidePressure,
    this.avgHighSidePressure,
    this.minHighSidePressure,
    this.maxHighSidePressure,
    this.avgCompAmp,
    this.maxCompAmp,
    this.avgCompAmpPh1,
    this.avgCompAmpPh2,
    this.avgCompAmpPh3,
    this.doorOpenCount,
    this.iceEvents,
    this.totalReadings,
    this.validReadings,
    this.energyEfficiencyRatio,
  });

  factory HourlyAggregate.fromJson(Map<String, dynamic> json) {
    return HourlyAggregate(
      hourBucket: json['hour_bucket'],
      avgTempAir: json['avg_temp_air']?.toDouble(),
      minTempAir: json['min_temp_air']?.toDouble(),
      maxTempAir: json['max_temp_air']?.toDouble(),
      avgTemp: json['avg_temp']?.toDouble(),
      minTemp: json['min_temp']?.toDouble(),
      maxTemp: json['max_temp']?.toDouble(),
      avgTempCoil: json['avg_temp_coil']?.toDouble(),
      avgTempDrain: json['avg_temp_drain']?.toDouble(),
      compressorOnCount: json['compressor_on_count'],
      compressorRuntimePercentage:
          json['compressor_runtime_percentage']?.toDouble(),
      avgLowSidePressure: json['avg_low_side_pressure']?.toDouble(),
      minLowSidePressure: json['min_low_side_pressure']?.toDouble(),
      maxLowSidePressure: json['max_low_side_pressure']?.toDouble(),
      avgHighSidePressure: json['avg_high_side_pressure']?.toDouble(),
      minHighSidePressure: json['min_high_side_pressure']?.toDouble(),
      maxHighSidePressure: json['max_high_side_pressure']?.toDouble(),
      avgCompAmp: json['avg_comp_amp']?.toDouble(),
      maxCompAmp: json['max_comp_amp']?.toDouble(),
      avgCompAmpPh1: json['avg_comp_amp_ph1']?.toDouble(),
      avgCompAmpPh2: json['avg_comp_amp_ph2']?.toDouble(),
      avgCompAmpPh3: json['avg_comp_amp_ph3']?.toDouble(),
      doorOpenCount: json['door_open_count'],
      iceEvents: json['ice_events'],
      totalReadings: json['total_readings'],
      validReadings: json['valid_readings'],
      energyEfficiencyRatio: json['energy_efficiency_ratio']?.toDouble(),
    );
  }
}

class LatestDeviceData {
  final String? deviceId;
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

  // Enhanced calculated metrics
  final double? avgCompAmp;
  final double? maxCompAmp;
  final double? minCompAmp;
  final double? ampImbalance;
  final double? tempDifferential;
  final double? efficiencyRatio;
  final String? systemStatus;
  final int? performanceScore;
  final List<String>? alerts;

  // Compressor status fields
  final String? compressorStatus; // 'ON' or 'OFF'
  final DateTime? lastOffTimestamp;

  // New door analysis fields
  final DateTime? lastDoorOpenTimestamp;
  final DateTime? lastDoorCloseTimestamp;

  LatestDeviceData({
    this.deviceId,
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
    this.avgCompAmp,
    this.maxCompAmp,
    this.minCompAmp,
    this.ampImbalance,
    this.tempDifferential,
    this.efficiencyRatio,
    this.systemStatus,
    this.performanceScore,
    this.alerts,
    this.compressorStatus,
    this.lastOffTimestamp,
    this.lastDoorOpenTimestamp,
    this.lastDoorCloseTimestamp,
  });

  factory LatestDeviceData.fromJson(Map<String, dynamic> json) {
    print("fggghh ${json}");
    return LatestDeviceData(
      deviceId: json['device_id'],
      time: json['time'],
      temperature: json['temperature']?.toDouble(),
      temperatureAir: json['temperatureAir']?.toDouble(),
      temperatureCoil: json['temperatureCoil']?.toDouble(),
      temperatureDrain: json['temperatureDrain']?.toDouble(),
      door: json['door'],
      iceBuiltUp: json['iceBuiltUp'],
      comp: json['comp'],
      compressorLow: json['compressorLow']?.toDouble(),
      compressorHigh: json['compressorHigh']?.toDouble(),
      compAmpPh1: json['compAmpPh1']?.toDouble(),
      compAmpPh2: json['compAmpPh2']?.toDouble(),
      compAmpPh3: json['compAmpPh3']?.toDouble(),
      avgCompAmp: json['avgCompAmp']?.toDouble(),
      maxCompAmp: json['maxCompAmp']?.toDouble(),
      minCompAmp: json['minCompAmp']?.toDouble(),
      ampImbalance: json['ampImbalance']?.toDouble(),
      tempDifferential: json['tempDifferential']?.toDouble(),
      efficiencyRatio: json['efficiencyRatio']?.toDouble(),
      systemStatus: json['systemStatus'],
      performanceScore: json['performanceScore'],
      alerts: json['alerts'] != null ? List<String>.from(json['alerts']) : null,
      compressorStatus: json['compressorStatus'],
      lastOffTimestamp: json['lastOffTimestamp'] != null
          ? DateTime.parse(json['lastOffTimestamp'])
          : null,
      lastDoorOpenTimestamp: json['lastDoorOpenTimestamp'] != null
          ? DateTime.parse(json['lastDoorOpenTimestamp'])
          : null,
      lastDoorCloseTimestamp: json['lastDoorCloseTimestamp'] != null
          ? DateTime.parse(json['lastDoorCloseTimestamp'])
          : null,
    );
  }
}

class DeviceStatus {
  final String deviceId;
  final String currentStatus;
  final String latitude;
  final String longitude;
  final String lastModified;

  DeviceStatus({
    required this.deviceId,
    required this.currentStatus,
    required this.latitude,
    required this.longitude,
    required this.lastModified,
  });

  // Factory method to create an instance from JSON
  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      deviceId: json['device_id'] as String,
      currentStatus: json['current_status'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      lastModified: json['last_modified'] as String,
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'current_status': currentStatus,
      'latitude': latitude,
      'longitude': longitude,
      'last_modified': lastModified,
    };
  }
}

class AlertData {
  final String? id;
  final String? deviceId;
  final String? deviceName;
  final String? deviceLocation;
  final String? deviceType;
  final String? timestamp;
  final String? alertType;
  final String? message;
  final String? severity;
  final String? status;
  final String? details;
  final String? recommendedAction;
  final int? priority;
  final Map<String, dynamic>? sensorValues;
  final Map<String, dynamic>? targetRanges;

  AlertData({
    this.id,
    this.deviceId,
    this.deviceName,
    this.deviceLocation,
    this.deviceType,
    this.timestamp,
    this.alertType,
    this.message,
    this.severity,
    this.status,
    this.details,
    this.recommendedAction,
    this.priority,
    this.sensorValues,
    this.targetRanges,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      id: json['id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceLocation: json['device_location'],
      deviceType: json['device_type'],
      timestamp: json['timestamp'],
      alertType: json['alert_type'],
      message: json['message'],
      severity: json['severity'],
      status: json['status'],
      details: json['details'],
      recommendedAction: json['recommended_action'],
      priority: json['priority'],
      sensorValues: json['sensor_values'],
      targetRanges: json['target_ranges'],
    );
  }
}

class CompressorTransition {
  final DateTime timestamp;
  final String status;
  final String? previousStatus;

  CompressorTransition({
    required this.timestamp,
    required this.status,
    this.previousStatus,
  });

  factory CompressorTransition.fromJson(Map<String, dynamic> json) {
    return CompressorTransition(
      timestamp: DateTime.parse(json['time']),
      status: json['status'],
      previousStatus: json['previous_status'],
    );
  }
}

// Device Info model
class DeviceInfo {
  final String deviceName;
  final String? location;
  final String? deviceType;
  final DateTime? installationDate;

  DeviceInfo({
    required this.deviceName,
    this.location,
    this.deviceType,
    this.installationDate,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceName: json['device_name'],
      location: json['location'],
      deviceType: json['device_type'],
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'])
          : null,
    );
  }
}

// Enhanced summary card data model
class EnhancedSummaryCard {
  final String title;
  final String value;
  final String unit;
  final String? subtitle;
  final String? trend;
  final String? trendDirection; // 'up', 'down', 'stable'
  final Color cardColor;
  final Color accentColor;
  final IconData icon;
  final List<String>? alerts;

  EnhancedSummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    this.subtitle,
    this.trend,
    this.trendDirection,
    required this.cardColor,
    required this.accentColor,
    required this.icon,
    this.alerts,
  });
}

// Performance metrics model
class PerformanceMetrics {
  final int? performanceScore;
  final String? systemStatus;
  final double? efficiencyRatio;
  final double? uptimePercentage;
  final int? totalAlerts;
  final int? criticalAlerts;
  final String? lastMaintenanceDate;
  final String? nextMaintenanceDate;

  PerformanceMetrics({
    this.performanceScore,
    this.systemStatus,
    this.efficiencyRatio,
    this.uptimePercentage,
    this.totalAlerts,
    this.criticalAlerts,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
  });
}

// Temperature range model
class TemperatureRange {
  final String sensor;
  final double? current;
  final double? min;
  final double? max;
  final double? avg;
  final String? status;
  DateTime? minTimestamp;
  DateTime? maxTimestamp; // 'normal', 'warning', 'critical'

  TemperatureRange({
    required this.sensor,
    this.current,
    this.min,
    this.max,
    this.avg,
    this.status,
    this.minTimestamp,
    this.maxTimestamp,
  });
}

// Pressure metrics model
class PressureMetrics {
  final double? lowSideCurrent;
  final double? lowSideMin;
  final double? lowSideMax;
  final double? lowSideAvg;
  final double? highSideCurrent;
  final double? highSideMin;
  final double? highSideMax;
  final double? highSideAvg;
  final String? status;
  final DateTime? lowSideMinTimestamp;
  final DateTime? lowSideMaxTimestamp;
  final DateTime? highSideMinTimestamp;
  final DateTime? highSideMaxTimestamp;
  final DateTime? maxHighSidePressureTimestamp;

  PressureMetrics({
    this.lowSideCurrent,
    this.lowSideMin,
    this.lowSideMax,
    this.lowSideAvg,
    this.highSideCurrent,
    this.highSideMin,
    this.highSideMax,
    this.highSideAvg,
    this.status,
    this.lowSideMinTimestamp,
    this.lowSideMaxTimestamp,
    this.highSideMinTimestamp,
    this.highSideMaxTimestamp,
    this.maxHighSidePressureTimestamp,
  });
}

// Compressor metrics model
class CompressorMetrics {
  final double? avgAmp;
  final double? maxAmp;
  final double? ph1Amp;
  final double? ph2Amp;
  final double? ph3Amp;
  final double? imbalance;
  final double? runtimePercentage;
  final int? onCount;
  final String? status;

  CompressorMetrics({
    this.avgAmp,
    this.maxAmp,
    this.ph1Amp,
    this.ph2Amp,
    this.ph3Amp,
    this.imbalance,
    this.runtimePercentage,
    this.onCount,
    this.status,
  });
}
