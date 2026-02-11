import 'dart:ui';

import 'package:flutter/cupertino.dart';

// Helper function to convert dynamic values (number or string) to double
double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

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
      deviceId: json['device_id']?.toString(),
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
      deviceId: json['device_id']?.toString(),
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
  final String? deviceType;

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
    this.deviceType,
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
    final deviceType = json['device_type']?.toString();

    // Normalize temperature fields based on device type
    double? avgTempAir, minTempAir, maxTempAir;
    double? avgTempCoil, minTempCoil, maxTempCoil;
    double? avgTempDrain, minTempDrain, maxTempDrain;
    DateTime? minTempAirTimestamp, maxTempAirTimestamp;
    DateTime? minTempCoilTimestamp, maxTempCoilTimestamp;
    DateTime? minTempDrainTimestamp, maxTempDrainTimestamp;

    if (deviceType == 'device2') {
      // Device2: multi-sensor (temp1-temp8), map first 3 to standard fields
      avgTempAir = _toDoubleOrNull(json['avg_temp1']);
      minTempAir = _toDoubleOrNull(json['min_temp1']);
      maxTempAir = _toDoubleOrNull(json['max_temp1']);
      avgTempCoil = _toDoubleOrNull(json['avg_temp2']);
      minTempCoil = _toDoubleOrNull(json['min_temp2']);
      maxTempCoil = _toDoubleOrNull(json['max_temp2']);
      avgTempDrain = _toDoubleOrNull(json['avg_temp3']);
      minTempDrain = _toDoubleOrNull(json['min_temp3']);
      maxTempDrain = _toDoubleOrNull(json['max_temp3']);
      // Device2 daily aggregates don't include timestamps
    } else if (deviceType == 'device3') {
      // Device3: ice machine (air_temp, hs_temp, ls_temp, ice_temp)
      avgTempAir = _toDoubleOrNull(json['avg_air_temp']);
      minTempAir = _toDoubleOrNull(json['min_air_temp']);
      maxTempAir = _toDoubleOrNull(json['max_air_temp']);
      avgTempCoil = _toDoubleOrNull(json['avg_hs_temp']);
      minTempCoil = _toDoubleOrNull(json['min_hs_temp']);
      maxTempCoil = _toDoubleOrNull(json['max_hs_temp']);
      avgTempDrain = _toDoubleOrNull(json['avg_ice_temp']);
      minTempDrain = _toDoubleOrNull(json['min_ice_temp']);
      maxTempDrain = _toDoubleOrNull(json['max_ice_temp']);
      // Device3 daily aggregates don't include timestamps
    } else {
      // Device1: refrigeration (temp_air, temp_coil, temp_drain)
      avgTempAir = _toDoubleOrNull(json['avg_temp_air']);
      minTempAir = _toDoubleOrNull(json['min_temp_air']);
      maxTempAir = _toDoubleOrNull(json['max_temp_air']);
      minTempAirTimestamp = json['min_temp_air_timestamp'] != null
          ? DateTime.parse(json['min_temp_air_timestamp'])
          : null;
      maxTempAirTimestamp = json['max_temp_air_timestamp'] != null
          ? DateTime.parse(json['max_temp_air_timestamp'])
          : null;
      avgTempCoil = _toDoubleOrNull(json['avg_temp_coil']);
      minTempCoil = _toDoubleOrNull(json['min_temp_coil']);
      maxTempCoil = _toDoubleOrNull(json['max_temp_coil']);
      minTempCoilTimestamp = json['min_temp_coil_timestamp'] != null
          ? DateTime.parse(json['min_temp_coil_timestamp'])
          : null;
      maxTempCoilTimestamp = json['max_temp_coil_timestamp'] != null
          ? DateTime.parse(json['max_temp_coil_timestamp'])
          : null;
      avgTempDrain = _toDoubleOrNull(json['avg_temp_drain']);
      minTempDrain = _toDoubleOrNull(json['min_temp_drain']);
      maxTempDrain = _toDoubleOrNull(json['max_temp_drain']);
      minTempDrainTimestamp = json['min_temp_drain_timestamp'] != null
          ? DateTime.parse(json['min_temp_drain_timestamp'])
          : null;
      maxTempDrainTimestamp = json['max_temp_drain_timestamp'] != null
          ? DateTime.parse(json['max_temp_drain_timestamp'])
          : null;
    }

    return DailyAggregate(
      dayBucket: json['day_bucket'],
      deviceId: json['device_id']?.toString(),
      deviceType: deviceType,

      // Normalized temperature fields
      avgTempAir: avgTempAir,
      minTempAir: minTempAir,
      maxTempAir: maxTempAir,
      minTempAirTimestamp: minTempAirTimestamp,
      maxTempAirTimestamp: maxTempAirTimestamp,
      avgTempCoil: avgTempCoil,
      minTempCoil: minTempCoil,
      maxTempCoil: maxTempCoil,
      minTempCoilTimestamp: minTempCoilTimestamp,
      maxTempCoilTimestamp: maxTempCoilTimestamp,
      avgTempDrain: avgTempDrain,
      minTempDrain: minTempDrain,
      maxTempDrain: maxTempDrain,
      minTempDrainTimestamp: minTempDrainTimestamp,
      maxTempDrainTimestamp: maxTempDrainTimestamp,

      // General temperature
      avgTemp: _toDoubleOrNull(json['avg_temp'] ?? json['avg_temp_overall']),
      minTemp: _toDoubleOrNull(json['min_temp']),
      maxTemp: _toDoubleOrNull(json['max_temp']),

      // Events
      iceEvents: json['ice_events'],

      // Door analysis
      doorOpenCount: json['door_open_count'],
      doorClosedCount: json['door_closed_count'],
      totalDoorOpenMinutes: _toDoubleOrNull(json['total_door_open_minutes']),
      doorStabilityStatus: json['door_stability_status'],

      // Compressor
      avgCompAmp: _toDoubleOrNull(json['avg_comp_amp']),
      maxCompAmp: _toDoubleOrNull(json['max_comp_amp']),
      avgCompAmpPh1: _toDoubleOrNull(json['avg_comp_amp_ph1']),
      avgCompAmpPh2: _toDoubleOrNull(json['avg_comp_amp_ph2']),
      avgCompAmpPh3: _toDoubleOrNull(json['avg_comp_amp_ph3']),

      // Pressure with timestamps
      avgLowSidePressure: _toDoubleOrNull(json['avg_low_side_pressure']),
      minLowSidePressure: _toDoubleOrNull(json['min_low_side_pressure']),
      maxLowSidePressure: _toDoubleOrNull(json['max_low_side_pressure']),
      minLowSidePressureTimestamp:
          json['min_low_side_pressure_timestamp'] != null
              ? DateTime.parse(json['min_low_side_pressure_timestamp'])
              : null,
      maxLowSidePressureTimestamp:
          json['max_low_side_pressure_timestamp'] != null
              ? DateTime.parse(json['max_low_side_pressure_timestamp'])
              : null,

      avgHighSidePressure: _toDoubleOrNull(json['avg_high_side_pressure']),
      minHighSidePressure: _toDoubleOrNull(json['min_high_side_pressure']),
      maxHighSidePressure: _toDoubleOrNull(json['max_high_side_pressure']),
      minHighSidePressureTimestamp:
          json['min_high_side_pressure_timestamp'] != null
              ? DateTime.parse(json['min_high_side_pressure_timestamp'])
              : null,
      maxHighSidePressureTimestamp:
          json['max_high_side_pressure_timestamp'] != null
              ? DateTime.parse(json['max_high_side_pressure_timestamp'])
              : null,

      // Runtime
      compressorOnCount: json['compressor_on_count'],
      compressorOffCount: json['compressor_off_count'],
      compressorRuntimePercentage:
          _toDoubleOrNull(json['compressor_runtime_percentage']),

      // Data quality
      totalReadings: json['total_readings'],
      validTempAirReadings: json['valid_temp_air_readings'],
      validPressureReadings: json['valid_pressure_readings'],
      firstReadingTime: json['first_reading_time'],
      lastReadingTime: json['last_reading_time'],

      // Uptime Analysis
      deviceUptimePercentage: _toDoubleOrNull(json['device_uptime_percentage']),
      unitOperationalPercentage:
          _toDoubleOrNull(json['unit_operational_percentage']),
      deviceOnReadings: json['device_on_readings'],
      unitOperationalReadings: json['unit_operational_readings'],
      expectedTotalReadings: json['expected_total_readings'],
      dataTransmissionPercentage:
          _toDoubleOrNull(json['data_transmission_percentage']),
      dataQualityPercentage: _toDoubleOrNull(json['data_quality_percentage']),
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
      avgTempAir: _toDoubleOrNull(json['avg_temp_air']),
      minTempAir: _toDoubleOrNull(json['min_temp_air']),
      maxTempAir: _toDoubleOrNull(json['max_temp_air']),
      avgTemp: _toDoubleOrNull(json['avg_temp']),
      minTemp: _toDoubleOrNull(json['min_temp']),
      maxTemp: _toDoubleOrNull(json['max_temp']),
      avgTempCoil: _toDoubleOrNull(json['avg_temp_coil']),
      avgTempDrain: _toDoubleOrNull(json['avg_temp_drain']),
      compressorOnCount: json['compressor_on_count'],
      compressorRuntimePercentage:
          _toDoubleOrNull(json['compressor_runtime_percentage']),
      avgLowSidePressure: _toDoubleOrNull(json['avg_low_side_pressure']),
      minLowSidePressure: _toDoubleOrNull(json['min_low_side_pressure']),
      maxLowSidePressure: _toDoubleOrNull(json['max_low_side_pressure']),
      avgHighSidePressure: _toDoubleOrNull(json['avg_high_side_pressure']),
      minHighSidePressure: _toDoubleOrNull(json['min_high_side_pressure']),
      maxHighSidePressure: _toDoubleOrNull(json['max_high_side_pressure']),
      avgCompAmp: _toDoubleOrNull(json['avg_comp_amp']),
      maxCompAmp: _toDoubleOrNull(json['max_comp_amp']),
      avgCompAmpPh1: _toDoubleOrNull(json['avg_comp_amp_ph1']),
      avgCompAmpPh2: _toDoubleOrNull(json['avg_comp_amp_ph2']),
      avgCompAmpPh3: _toDoubleOrNull(json['avg_comp_amp_ph3']),
      doorOpenCount: json['door_open_count'],
      iceEvents: json['ice_events'],
      totalReadings: json['total_readings'],
      validReadings: json['valid_readings'],
      energyEfficiencyRatio: _toDoubleOrNull(json['energy_efficiency_ratio']),
    );
  }
}

class LatestDeviceData {
  final String? deviceId;
  final String? time;
  final String? deviceType; // 'device1', 'device2', 'device3'
  final double? temperature;

  // Device 1 specific fields (Refrigeration units)
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

  // Device 2 specific fields (Multi-zone temperature monitoring)
  final double? temp1;
  final double? temp2;
  final double? temp3;
  final double? temp4;
  final double? temp5;
  final double? temp6;
  final double? temp7;
  final double? temp8;
  // Device 2 min/max values (24-hour)
  final double? temp1Min;
  final double? temp1Max;
  final double? temp2Min;
  final double? temp2Max;
  final double? temp3Min;
  final double? temp3Max;
  final double? temp4Min;
  final double? temp4Max;
  final double? temp5Min;
  final double? temp5Max;
  final double? temp6Min;
  final double? temp6Max;
  final double? temp7Min;
  final double? temp7Max;
  final double? temp8Min;
  final double? temp8Max;
  // Device 2 min/max timestamps (24-hour)
  final String? temp1MinTime;
  final String? temp1MaxTime;
  final String? temp2MinTime;
  final String? temp2MaxTime;
  final String? temp3MinTime;
  final String? temp3MaxTime;
  final String? temp4MinTime;
  final String? temp4MaxTime;
  final String? temp5MinTime;
  final String? temp5MaxTime;
  final String? temp6MinTime;
  final String? temp6MaxTime;
  final String? temp7MinTime;
  final String? temp7MaxTime;
  final String? temp8MinTime;
  final String? temp8MaxTime;

  // Device 3 specific fields (Ice machine monitoring)
  final double? hsTemp;  // High side temperature
  final double? lsTemp;  // Low side temperature
  final double? iceTemp; // Ice temperature
  final double? airTemp; // Air temperature
  final bool? harvsw;    // Harvest switch
  final double? wtrlvl;  // Water level
  final String? wtrlvlLastEmpty;  // Last time water level was 0%
  final String? wtrlvlLastFull;   // Last time water level was 100%
  // Device 3 min/max values (24-hour)
  final double? hsTempMin;
  final double? hsTempMax;
  final double? lsTempMin;
  final double? lsTempMax;
  final double? iceTempMin;
  final double? iceTempMax;
  final double? airTempMin;
  final double? airTempMax;
  // Device 3 min/max timestamps (24-hour)
  final String? hsTempMinTime;
  final String? hsTempMaxTime;
  final String? lsTempMinTime;
  final String? lsTempMaxTime;
  final String? iceTempMinTime;
  final String? iceTempMaxTime;
  final String? airTempMinTime;
  final String? airTempMaxTime;
  // Device 3 last harvest timestamp
  final String? lastHarvestTime;
  // Device 3 harvest count (last 24 hours)
  final int? harvestCount;

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
    this.deviceType,
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
    // Device 2 fields
    this.temp1,
    this.temp2,
    this.temp3,
    this.temp4,
    this.temp5,
    this.temp6,
    this.temp7,
    this.temp8,
    // Device 2 min/max
    this.temp1Min,
    this.temp1Max,
    this.temp2Min,
    this.temp2Max,
    this.temp3Min,
    this.temp3Max,
    this.temp4Min,
    this.temp4Max,
    this.temp5Min,
    this.temp5Max,
    this.temp6Min,
    this.temp6Max,
    this.temp7Min,
    this.temp7Max,
    this.temp8Min,
    this.temp8Max,
    // Device 2 min/max timestamps
    this.temp1MinTime,
    this.temp1MaxTime,
    this.temp2MinTime,
    this.temp2MaxTime,
    this.temp3MinTime,
    this.temp3MaxTime,
    this.temp4MinTime,
    this.temp4MaxTime,
    this.temp5MinTime,
    this.temp5MaxTime,
    this.temp6MinTime,
    this.temp6MaxTime,
    this.temp7MinTime,
    this.temp7MaxTime,
    this.temp8MinTime,
    this.temp8MaxTime,
    // Device 3 fields
    this.hsTemp,
    this.lsTemp,
    this.iceTemp,
    this.airTemp,
    this.harvsw,
    this.wtrlvl,
    this.wtrlvlLastEmpty,
    this.wtrlvlLastFull,
    // Device 3 min/max
    this.hsTempMin,
    this.hsTempMax,
    this.lsTempMin,
    this.lsTempMax,
    this.iceTempMin,
    this.iceTempMax,
    this.airTempMin,
    this.airTempMax,
    // Device 3 min/max timestamps
    this.hsTempMinTime,
    this.hsTempMaxTime,
    this.lsTempMinTime,
    this.lsTempMaxTime,
    this.iceTempMinTime,
    this.iceTempMaxTime,
    this.airTempMinTime,
    this.airTempMaxTime,
    // Device 3 last harvest
    this.lastHarvestTime,
    this.harvestCount,
    // Calculated metrics
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

  // Helper method to get device type
  String get resolvedDeviceType {
    if (deviceType != null && deviceType!.isNotEmpty) return deviceType!;
    // Infer device type from available fields
    if (temp1 != null || temp2 != null) return 'device2';
    if (hsTemp != null || lsTemp != null || iceTemp != null) return 'device3';
    return 'device1';
  }

  // Helper method to get average temperature for Device 2
  double? get device2AvgTemp {
    final temps = [temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8]
        .whereType<double>()
        .toList();
    if (temps.isEmpty) return null;
    return temps.reduce((a, b) => a + b) / temps.length;
  }

  factory LatestDeviceData.fromJson(Map<String, dynamic> json) {
    print("LatestDeviceData.fromJson: ${json}");
    return LatestDeviceData(
      deviceId: json['device_id']?.toString(),
      time: json['time'],
      deviceType: json['device_type'],
      temperature: json['temperature']?.toDouble(),
      // Device 1 fields
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
      // Device 2 fields
      temp1: json['temp1']?.toDouble(),
      temp2: json['temp2']?.toDouble(),
      temp3: json['temp3']?.toDouble(),
      temp4: json['temp4']?.toDouble(),
      temp5: json['temp5']?.toDouble(),
      temp6: json['temp6']?.toDouble(),
      temp7: json['temp7']?.toDouble(),
      temp8: json['temp8']?.toDouble(),
      // Device 2 min/max
      temp1Min: json['temp1_min']?.toDouble(),
      temp1Max: json['temp1_max']?.toDouble(),
      temp2Min: json['temp2_min']?.toDouble(),
      temp2Max: json['temp2_max']?.toDouble(),
      temp3Min: json['temp3_min']?.toDouble(),
      temp3Max: json['temp3_max']?.toDouble(),
      temp4Min: json['temp4_min']?.toDouble(),
      temp4Max: json['temp4_max']?.toDouble(),
      temp5Min: json['temp5_min']?.toDouble(),
      temp5Max: json['temp5_max']?.toDouble(),
      temp6Min: json['temp6_min']?.toDouble(),
      temp6Max: json['temp6_max']?.toDouble(),
      temp7Min: json['temp7_min']?.toDouble(),
      temp7Max: json['temp7_max']?.toDouble(),
      temp8Min: json['temp8_min']?.toDouble(),
      temp8Max: json['temp8_max']?.toDouble(),
      // Device 2 min/max timestamps
      temp1MinTime: json['temp1_min_time'],
      temp1MaxTime: json['temp1_max_time'],
      temp2MinTime: json['temp2_min_time'],
      temp2MaxTime: json['temp2_max_time'],
      temp3MinTime: json['temp3_min_time'],
      temp3MaxTime: json['temp3_max_time'],
      temp4MinTime: json['temp4_min_time'],
      temp4MaxTime: json['temp4_max_time'],
      temp5MinTime: json['temp5_min_time'],
      temp5MaxTime: json['temp5_max_time'],
      temp6MinTime: json['temp6_min_time'],
      temp6MaxTime: json['temp6_max_time'],
      temp7MinTime: json['temp7_min_time'],
      temp7MaxTime: json['temp7_max_time'],
      temp8MinTime: json['temp8_min_time'],
      temp8MaxTime: json['temp8_max_time'],
      // Device 3 fields
      hsTemp: json['hs_temp']?.toDouble(),
      lsTemp: json['ls_temp']?.toDouble(),
      iceTemp: json['ice_temp']?.toDouble(),
      airTemp: json['air_temp']?.toDouble(),
      harvsw: json['harvsw'],
      wtrlvl: json['wtrlvl']?.toDouble(),
      wtrlvlLastEmpty: json['wtrlvlLastEmpty'],
      wtrlvlLastFull: json['wtrlvlLastFull'],
      // Device 3 min/max
      hsTempMin: json['hs_temp_min']?.toDouble(),
      hsTempMax: json['hs_temp_max']?.toDouble(),
      lsTempMin: json['ls_temp_min']?.toDouble(),
      lsTempMax: json['ls_temp_max']?.toDouble(),
      iceTempMin: json['ice_temp_min']?.toDouble(),
      iceTempMax: json['ice_temp_max']?.toDouble(),
      airTempMin: json['air_temp_min']?.toDouble(),
      airTempMax: json['air_temp_max']?.toDouble(),
      // Device 3 min/max timestamps
      hsTempMinTime: json['hs_temp_min_time'],
      hsTempMaxTime: json['hs_temp_max_time'],
      lsTempMinTime: json['ls_temp_min_time'],
      lsTempMaxTime: json['ls_temp_max_time'],
      iceTempMinTime: json['ice_temp_min_time'],
      iceTempMaxTime: json['ice_temp_max_time'],
      airTempMinTime: json['air_temp_min_time'],
      airTempMaxTime: json['air_temp_max_time'],
      // Device 3 last harvest
      lastHarvestTime: json['last_harvest_time'],
      harvestCount: json['harvest_count'],
      // Calculated metrics
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
      deviceId: json['device_id']?.toString() ?? '',
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
      id: json['id']?.toString(),
      deviceId: json['device_id']?.toString(),
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
