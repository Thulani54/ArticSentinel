import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../constants/Constants.dart';
import '../widgets/compact_header.dart';

// Fixed model classes with proper type handling

class DeviceAnalytics {
  final TemperatureAnalytics temperatureAnalytics;
  final EnhancedTemperatureAnalytics enhancedTemperatureAnalytics;
  final CompressorAnalytics compressorAnalytics;
  final EnhancedCompressorAnalytics enhancedCompressorAnalytics;
  final DoorAnalytics doorAnalytics;
  final IceAnalytics iceAnalytics;
  final PowerConsumptionAnalytics powerConsumptionAnalytics;
  final PressureAnalytics pressureAnalytics;
  final EnhancedPressureAnalytics enhancedPressureAnalytics;
  final TemperatureStabilityAnalytics temperatureStabilityAnalytics;
  final OperationalCyclesAnalytics operationalCyclesAnalytics;
  final EnergyEfficiencyAnalytics energyEfficiencyAnalytics;
  final MaintenanceIndicatorsAnalytics maintenanceIndicatorsAnalytics;
  final PhaseBalanceAnalytics phaseBalanceAnalytics;
  final CorrelationsAnalytics correlationsAnalytics;
  final DailySummaryAnalytics dailySummaryAnalytics;
  final PeakPerformanceAnalytics peakPerformanceAnalytics;
  final RealTimeInsights realTimeInsights;

  DeviceAnalytics({
    required this.temperatureAnalytics,
    required this.enhancedTemperatureAnalytics,
    required this.compressorAnalytics,
    required this.enhancedCompressorAnalytics,
    required this.doorAnalytics,
    required this.iceAnalytics,
    required this.powerConsumptionAnalytics,
    required this.pressureAnalytics,
    required this.enhancedPressureAnalytics,
    required this.temperatureStabilityAnalytics,
    required this.operationalCyclesAnalytics,
    required this.energyEfficiencyAnalytics,
    required this.maintenanceIndicatorsAnalytics,
    required this.phaseBalanceAnalytics,
    required this.correlationsAnalytics,
    required this.dailySummaryAnalytics,
    required this.peakPerformanceAnalytics,
    required this.realTimeInsights,
  });

  factory DeviceAnalytics.fromJson(Map<String, dynamic> json) {
    return DeviceAnalytics(
      temperatureAnalytics:
          TemperatureAnalytics.fromJson(json['temperature_analytics'] ?? {}),
      enhancedTemperatureAnalytics: EnhancedTemperatureAnalytics.fromJson(
          json['enhanced_temperature_analytics'] ?? {}),
      compressorAnalytics:
          CompressorAnalytics.fromJson(json['compressor_analytics'] ?? {}),
      enhancedCompressorAnalytics: EnhancedCompressorAnalytics.fromJson(
          json['enhanced_compressor_analytics'] ?? {}),
      doorAnalytics: DoorAnalytics.fromJson(json['door_analytics'] ?? {}),
      iceAnalytics: IceAnalytics.fromJson(json['ice_analytics'] ?? {}),
      powerConsumptionAnalytics: PowerConsumptionAnalytics.fromJson(
          json['power_consumption_analytics'] ?? {}),
      pressureAnalytics:
          PressureAnalytics.fromJson(json['pressure_analytics'] ?? {}),
      enhancedPressureAnalytics: EnhancedPressureAnalytics.fromJson(
          json['enhanced_pressure_analytics'] ?? {}),
      temperatureStabilityAnalytics: TemperatureStabilityAnalytics.fromJson(
          json['temperature_stability_analytics'] ?? {}),
      operationalCyclesAnalytics: OperationalCyclesAnalytics.fromJson(
          json['operational_cycles_analytics'] ?? {}),
      energyEfficiencyAnalytics: EnergyEfficiencyAnalytics.fromJson(
          json['energy_efficiency_analytics'] ?? {}),
      maintenanceIndicatorsAnalytics: MaintenanceIndicatorsAnalytics.fromJson(
          json['maintenance_indicators_analytics'] ?? {}),
      phaseBalanceAnalytics:
          PhaseBalanceAnalytics.fromJson(json['phase_balance_analytics'] ?? {}),
      correlationsAnalytics:
          CorrelationsAnalytics.fromJson(json['correlations_analytics'] ?? {}),
      dailySummaryAnalytics:
          DailySummaryAnalytics.fromJson(json['daily_summary_analytics'] ?? {}),
      peakPerformanceAnalytics: PeakPerformanceAnalytics.fromJson(
          json['peak_performance_analytics'] ?? {}),
      realTimeInsights:
          RealTimeInsights.fromJson(json['real_time_insights'] ?? {}),
    );
  }
}

// Helper function for safe list conversion
List<T> _fromDynamicList<T>(dynamic list, T Function(dynamic) converter) {
  if (list == null) return [];
  if (list is List) {
    return list.map(converter).toList();
  }
  return [];
}

// Enhanced Temperature Analytics with timestamps
class EnhancedTemperatureAnalytics {
  final double minTemperature;
  final double maxTemperature;
  final double avgTemperature;
  final double temperatureVariance;
  final int totalReadings;
  final String? minTempTimestamp;
  final String? maxTempTimestamp;

  // Air temperature fields
  final double minAirTemperature;
  final double maxAirTemperature;
  final double avgAirTemperature;
  final double airTemperatureVariance;
  final String? minAirTempTimestamp;
  final String? maxAirTempTimestamp;

  // Coil temperature fields
  final double minCoilTemperature;
  final double maxCoilTemperature;
  final double avgCoilTemperature;
  final double coilTemperatureVariance;
  final String? minCoilTempTimestamp;
  final String? maxCoilTempTimestamp;

  // Drain temperature fields
  final double minDrainTemperature;
  final double maxDrainTemperature;
  final double avgDrainTemperature;
  final double drainTemperatureVariance;
  final String? minDrainTempTimestamp;
  final String? maxDrainTempTimestamp;

  EnhancedTemperatureAnalytics({
    required this.minTemperature,
    required this.maxTemperature,
    required this.avgTemperature,
    required this.temperatureVariance,
    required this.totalReadings,
    this.minTempTimestamp,
    this.maxTempTimestamp,
    required this.minAirTemperature,
    required this.maxAirTemperature,
    required this.avgAirTemperature,
    required this.airTemperatureVariance,
    this.minAirTempTimestamp,
    this.maxAirTempTimestamp,
    required this.minCoilTemperature,
    required this.maxCoilTemperature,
    required this.avgCoilTemperature,
    required this.coilTemperatureVariance,
    this.minCoilTempTimestamp,
    this.maxCoilTempTimestamp,
    required this.minDrainTemperature,
    required this.maxDrainTemperature,
    required this.avgDrainTemperature,
    required this.drainTemperatureVariance,
    this.minDrainTempTimestamp,
    this.maxDrainTempTimestamp,
  });

  factory EnhancedTemperatureAnalytics.fromJson(Map<String, dynamic> json) {
    return EnhancedTemperatureAnalytics(
      minTemperature: (json['min_temperature'] ?? 0.0).toDouble(),
      maxTemperature: (json['max_temperature'] ?? 0.0).toDouble(),
      avgTemperature: (json['avg_temperature'] ?? 0.0).toDouble(),
      temperatureVariance: (json['temperature_variance'] ?? 0.0).toDouble(),
      totalReadings: json['total_readings'] ?? 0,
      minTempTimestamp: json['min_temp_timestamp'],
      maxTempTimestamp: json['max_temp_timestamp'],

      // Air temperature mappings
      minAirTemperature: (json['min_air_temperature'] ?? 0.0).toDouble(),
      maxAirTemperature: (json['max_air_temperature'] ?? 0.0).toDouble(),
      avgAirTemperature: (json['avg_air_temperature'] ?? 0.0).toDouble(),
      airTemperatureVariance:
          (json['air_temperature_variance'] ?? 0.0).toDouble(),
      minAirTempTimestamp: json['min_air_temp_timestamp'],
      maxAirTempTimestamp: json['max_air_temp_timestamp'],

      // Coil temperature mappings
      minCoilTemperature: (json['min_coil_temperature'] ?? 0.0).toDouble(),
      maxCoilTemperature: (json['max_coil_temperature'] ?? 0.0).toDouble(),
      avgCoilTemperature: (json['avg_coil_temperature'] ?? 0.0).toDouble(),
      coilTemperatureVariance:
          (json['coil_temperature_variance'] ?? 0.0).toDouble(),
      minCoilTempTimestamp: json['min_coil_temp_timestamp'],
      maxCoilTempTimestamp: json['max_coil_temp_timestamp'],

      // Drain temperature mappings
      minDrainTemperature: (json['min_drain_temperature'] ?? 0.0).toDouble(),
      maxDrainTemperature: (json['max_drain_temperature'] ?? 0.0).toDouble(),
      avgDrainTemperature: (json['avg_drain_temperature'] ?? 0.0).toDouble(),
      drainTemperatureVariance:
          (json['drain_temperature_variance'] ?? 0.0).toDouble(),
      minDrainTempTimestamp: json['min_drain_temp_timestamp'],
      maxDrainTempTimestamp: json['max_drain_temp_timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_temperature': minTemperature,
      'max_temperature': maxTemperature,
      'avg_temperature': avgTemperature,
      'temperature_variance': temperatureVariance,
      'total_readings': totalReadings,
      'min_temp_timestamp': minTempTimestamp,
      'max_temp_timestamp': maxTempTimestamp,
      'min_air_temperature': minAirTemperature,
      'max_air_temperature': maxAirTemperature,
      'avg_air_temperature': avgAirTemperature,
      'air_temperature_variance': airTemperatureVariance,
      'min_air_temp_timestamp': minAirTempTimestamp,
      'max_air_temp_timestamp': maxAirTempTimestamp,
      'min_coil_temperature': minCoilTemperature,
      'max_coil_temperature': maxCoilTemperature,
      'avg_coil_temperature': avgCoilTemperature,
      'coil_temperature_variance': coilTemperatureVariance,
      'min_coil_temp_timestamp': minCoilTempTimestamp,
      'max_coil_temp_timestamp': maxCoilTempTimestamp,
      'min_drain_temperature': minDrainTemperature,
      'max_drain_temperature': maxDrainTemperature,
      'avg_drain_temperature': avgDrainTemperature,
      'drain_temperature_variance': drainTemperatureVariance,
      'min_drain_temp_timestamp': minDrainTempTimestamp,
      'max_drain_temp_timestamp': maxDrainTempTimestamp,
    };
  }
}

// Enhanced Pressure Analytics with timestamps
class EnhancedPressureAnalytics {
  final double minPressureLow;
  final double maxPressureLow;
  final double minPressureHigh;
  final double maxPressureHigh;
  final double avgPressureLow;
  final double avgPressureHigh;
  final double avgPressureDifferential;
  final int totalReadings;
  final String? minPressureLowTimestamp;
  final String? maxPressureLowTimestamp;
  final String? minPressureHighTimestamp;
  final String? maxPressureHighTimestamp;

  EnhancedPressureAnalytics({
    required this.minPressureLow,
    required this.maxPressureLow,
    required this.minPressureHigh,
    required this.maxPressureHigh,
    required this.avgPressureLow,
    required this.avgPressureHigh,
    required this.avgPressureDifferential,
    required this.totalReadings,
    this.minPressureLowTimestamp,
    this.maxPressureLowTimestamp,
    this.minPressureHighTimestamp,
    this.maxPressureHighTimestamp,
  });

  factory EnhancedPressureAnalytics.fromJson(Map<String, dynamic> json) {
    return EnhancedPressureAnalytics(
      minPressureLow: (json['min_pressure_low'] ?? 0.0).toDouble(),
      maxPressureLow: (json['max_pressure_low'] ?? 0.0).toDouble(),
      minPressureHigh: (json['min_pressure_high'] ?? 0.0).toDouble(),
      maxPressureHigh: (json['max_pressure_high'] ?? 0.0).toDouble(),
      avgPressureLow: (json['avg_pressure_low'] ?? 0.0).toDouble(),
      avgPressureHigh: (json['avg_pressure_high'] ?? 0.0).toDouble(),
      avgPressureDifferential:
          (json['avg_pressure_differential'] ?? 0.0).toDouble(),
      totalReadings: json['total_readings'] ?? 0,
      minPressureLowTimestamp: json['min_pressure_low_timestamp'],
      maxPressureLowTimestamp: json['max_pressure_low_timestamp'],
      minPressureHighTimestamp: json['min_pressure_high_timestamp'],
      maxPressureHighTimestamp: json['max_pressure_high_timestamp'],
    );
  }
}

// Enhanced Compressor Analytics with comprehensive operational data
class EnhancedCompressorAnalytics {
  final CompressorCurrentStatus currentStatus;
  final CompressorAnalyticsData analytics;
  final CompressorStatistics statistics;

  EnhancedCompressorAnalytics({
    required this.currentStatus,
    required this.analytics,
    required this.statistics,
  });

  factory EnhancedCompressorAnalytics.fromJson(Map<String, dynamic> json) {
    return EnhancedCompressorAnalytics(
      currentStatus:
          CompressorCurrentStatus.fromJson(json['current_status'] ?? {}),
      analytics: CompressorAnalyticsData.fromJson(json['analytics'] ?? {}),
      statistics: CompressorStatistics.fromJson(json['statistics'] ?? {}),
    );
  }
}

class CompressorCurrentStatus {
  final bool isRunning;
  final double currentAmpPh1;
  final double currentAmpPh2;
  final double currentAmpPh3;
  final double currentTotalAmps;
  final String? lastReadingTime;

  CompressorCurrentStatus({
    required this.isRunning,
    required this.currentAmpPh1,
    required this.currentAmpPh2,
    required this.currentAmpPh3,
    required this.currentTotalAmps,
    this.lastReadingTime,
  });

  factory CompressorCurrentStatus.fromJson(Map<String, dynamic> json) {
    return CompressorCurrentStatus(
      isRunning: json['is_running'] ?? false,
      currentAmpPh1: (json['current_amp_ph1'] ?? 0.0).toDouble(),
      currentAmpPh2: (json['current_amp_ph2'] ?? 0.0).toDouble(),
      currentAmpPh3: (json['current_amp_ph3'] ?? 0.0).toDouble(),
      currentTotalAmps: (json['current_total_amps'] ?? 0.0).toDouble(),
      lastReadingTime: json['last_reading_time'],
    );
  }
}

class CompressorAnalyticsData {
  final double minTotalAmps;
  final double maxTotalAmps;
  final double avgTotalAmps;
  final double avgAmpsWhenRunning;
  final String? minAmpTimestamp;
  final double minAmpValue;
  final bool compStateAtMinAmp;
  final String? maxAmpTimestamp;
  final double maxAmpValue;
  final bool compStateAtMaxAmp;
  final String? lastOffStart;
  final double lastOffDurationMinutes;
  final String? lastOnStart;
  final double lastOnDurationMinutes;
  final double longestOnDurationMinutes;
  final String? longestOnStart;
  final double currentStateDurationMinutes;

  // New fields for additional cycle analytics
  final double shortestOnDurationMinutes;
  final String? shortestOnStart;
  final double longestOffDurationMinutes;
  final String? longestOffStart;
  final double shortestOffDurationMinutes;
  final String? shortestOffStart;
  final String? lastOnWhileOffStart;
  final double lastOnDurationWhileOffMinutes;

  CompressorAnalyticsData({
    required this.minTotalAmps,
    required this.maxTotalAmps,
    required this.avgTotalAmps,
    required this.avgAmpsWhenRunning,
    this.minAmpTimestamp,
    required this.minAmpValue,
    required this.compStateAtMinAmp,
    this.maxAmpTimestamp,
    required this.maxAmpValue,
    required this.compStateAtMaxAmp,
    this.lastOffStart,
    required this.lastOffDurationMinutes,
    this.lastOnStart,
    required this.lastOnDurationMinutes,
    required this.longestOnDurationMinutes,
    this.longestOnStart,
    required this.currentStateDurationMinutes,
    // New parameters
    required this.shortestOnDurationMinutes,
    this.shortestOnStart,
    required this.longestOffDurationMinutes,
    this.longestOffStart,
    required this.shortestOffDurationMinutes,
    this.shortestOffStart,
    this.lastOnWhileOffStart,
    required this.lastOnDurationWhileOffMinutes,
  });

  factory CompressorAnalyticsData.fromJson(Map<String, dynamic> json) {
    return CompressorAnalyticsData(
      minTotalAmps: (json['min_total_amps'] ?? 0.0).toDouble(),
      maxTotalAmps: (json['max_total_amps'] ?? 0.0).toDouble(),
      avgTotalAmps: (json['avg_total_amps'] ?? 0.0).toDouble(),
      avgAmpsWhenRunning: (json['avg_amps_when_running'] ?? 0.0).toDouble(),
      minAmpTimestamp: json['min_amp_timestamp'],
      minAmpValue: (json['min_amp_value'] ?? 0.0).toDouble(),
      compStateAtMinAmp: json['comp_state_at_min_amp'] ?? false,
      maxAmpTimestamp: json['max_amp_timestamp'],
      maxAmpValue: (json['max_amp_value'] ?? 0.0).toDouble(),
      compStateAtMaxAmp: json['comp_state_at_max_amp'] ?? false,
      lastOffStart: json['last_off_start'],
      lastOffDurationMinutes:
          (json['last_off_duration_minutes'] ?? 0.0).toDouble(),
      lastOnStart: json['last_on_start'],
      lastOnDurationMinutes:
          (json['last_on_duration_minutes'] ?? 0.0).toDouble(),
      longestOnDurationMinutes:
          (json['longest_on_duration_minutes'] ?? 0.0).toDouble(),
      longestOnStart: json['longest_on_start'],
      currentStateDurationMinutes:
          (json['current_state_duration_minutes'] ?? 0.0).toDouble(),
      // New field mappings
      shortestOnDurationMinutes:
          (json['shortest_on_duration_minutes'] ?? 0.0).toDouble(),
      shortestOnStart: json['shortest_on_start'],
      longestOffDurationMinutes:
          (json['longest_off_duration_minutes'] ?? 0.0).toDouble(),
      longestOffStart: json['longest_off_start'],
      shortestOffDurationMinutes:
          (json['shortest_off_duration_minutes'] ?? 0.0).toDouble(),
      shortestOffStart: json['shortest_off_start'],
      lastOnWhileOffStart: json['last_on_while_off_start'],
      lastOnDurationWhileOffMinutes:
          (json['last_on_duration_while_off_minutes'] ?? 0.0).toDouble(),
    );
  }
}

class CompressorStatistics {
  final int totalOnReadings;
  final int totalOffReadings;
  final int totalReadings;
  final double dutyCyclePercentage;
  final int totalStartCycles;
  final int totalStopCycles;
  final double avgRunningAmps;
  final double ampVarianceWhenRunning;

  CompressorStatistics({
    required this.totalOnReadings,
    required this.totalOffReadings,
    required this.totalReadings,
    required this.dutyCyclePercentage,
    required this.totalStartCycles,
    required this.totalStopCycles,
    required this.avgRunningAmps,
    required this.ampVarianceWhenRunning,
  });

  factory CompressorStatistics.fromJson(Map<String, dynamic> json) {
    return CompressorStatistics(
      totalOnReadings: json['total_on_readings'] ?? 0,
      totalOffReadings: json['total_off_readings'] ?? 0,
      totalReadings: json['total_readings'] ?? 0,
      dutyCyclePercentage: (json['duty_cycle_percentage'] ?? 0.0).toDouble(),
      totalStartCycles: json['total_start_cycles'] ?? 0,
      totalStopCycles: json['total_stop_cycles'] ?? 0,
      avgRunningAmps: (json['avg_running_amps'] ?? 0.0).toDouble(),
      ampVarianceWhenRunning:
          (json['amp_variance_when_running'] ?? 0.0).toDouble(),
    );
  }
}

// Real-time insights from the enhanced API
class RealTimeInsights {
  final DeviceHealthScore deviceHealthScore;
  final EfficiencyRating efficiencyRating;
  final MaintenanceUrgency maintenanceUrgency;
  final EnergyCostEstimate energyCostEstimate;
  final PerformanceTrends performanceTrends;

  RealTimeInsights({
    required this.deviceHealthScore,
    required this.efficiencyRating,
    required this.maintenanceUrgency,
    required this.energyCostEstimate,
    required this.performanceTrends,
  });

  factory RealTimeInsights.fromJson(Map<String, dynamic> json) {
    return RealTimeInsights(
      deviceHealthScore:
          DeviceHealthScore.fromJson(json['device_health_score'] ?? {}),
      efficiencyRating:
          EfficiencyRating.fromJson(json['efficiency_rating'] ?? {}),
      maintenanceUrgency:
          MaintenanceUrgency.fromJson(json['maintenance_urgency'] ?? {}),
      energyCostEstimate:
          EnergyCostEstimate.fromJson(json['energy_cost_estimate'] ?? {}),
      performanceTrends:
          PerformanceTrends.fromJson(json['performance_trends'] ?? {}),
    );
  }
}

class DeviceHealthScore {
  final double overallScore;
  final String healthGrade;
  final List<String> contributingFactors;
  final String recommendation;

  DeviceHealthScore({
    required this.overallScore,
    required this.healthGrade,
    required this.contributingFactors,
    required this.recommendation,
  });

  factory DeviceHealthScore.fromJson(Map<String, dynamic> json) {
    return DeviceHealthScore(
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      healthGrade: json['health_grade'] ?? 'Unknown',
      contributingFactors:
          _fromDynamicList(json['contributing_factors'], (e) => e.toString()),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class EfficiencyRating {
  final double efficiencyScore;
  final String efficiencyGrade;
  final double avgDutyCycle;
  final double avgPowerPerDegree;
  final double annualCostEstimate;

  EfficiencyRating({
    required this.efficiencyScore,
    required this.efficiencyGrade,
    required this.avgDutyCycle,
    required this.avgPowerPerDegree,
    required this.annualCostEstimate,
  });

  factory EfficiencyRating.fromJson(Map<String, dynamic> json) {
    return EfficiencyRating(
      efficiencyScore: (json['efficiency_score'] ?? 0.0).toDouble(),
      efficiencyGrade: json['efficiency_grade'] ?? 'Unknown',
      avgDutyCycle: (json['avg_duty_cycle'] ?? 0.0).toDouble(),
      avgPowerPerDegree: (json['avg_power_per_degree'] ?? 0.0).toDouble(),
      annualCostEstimate: (json['annual_cost_estimate'] ?? 0.0).toDouble(),
    );
  }
}

class MaintenanceUrgency {
  final String urgencyLevel;
  final double urgencyScore;
  final int totalAlerts;
  final Map<String, dynamic> alertBreakdown;
  final String recommendedAction;

  MaintenanceUrgency({
    required this.urgencyLevel,
    required this.urgencyScore,
    required this.totalAlerts,
    required this.alertBreakdown,
    required this.recommendedAction,
  });

  factory MaintenanceUrgency.fromJson(Map<String, dynamic> json) {
    return MaintenanceUrgency(
      urgencyLevel: json['urgency_level'] ?? 'Low',
      urgencyScore: (json['urgency_score'] ?? 0.0).toDouble(),
      totalAlerts: json['total_alerts'] ?? 0,
      alertBreakdown: Map<String, dynamic>.from(json['alert_breakdown'] ?? {}),
      recommendedAction: json['recommended_action'] ?? '',
    );
  }
}

class EnergyCostEstimate {
  final double currentPowerKw;
  final double avgPowerKw;
  final double hourlyCostUsd;
  final double dailyCostUsd;
  final double monthlyCostUsd;
  final double annualCostUsd;
  final double costPerKwh;

  EnergyCostEstimate({
    required this.currentPowerKw,
    required this.avgPowerKw,
    required this.hourlyCostUsd,
    required this.dailyCostUsd,
    required this.monthlyCostUsd,
    required this.annualCostUsd,
    required this.costPerKwh,
  });

  factory EnergyCostEstimate.fromJson(Map<String, dynamic> json) {
    return EnergyCostEstimate(
      currentPowerKw: (json['current_power_kw'] ?? 0.0).toDouble(),
      avgPowerKw: (json['avg_power_kw'] ?? 0.0).toDouble(),
      hourlyCostUsd: (json['hourly_cost_usd'] ?? 0.0).toDouble(),
      dailyCostUsd: (json['daily_cost_usd'] ?? 0.0).toDouble(),
      monthlyCostUsd: (json['monthly_cost_usd'] ?? 0.0).toDouble(),
      annualCostUsd: (json['annual_cost_usd'] ?? 0.0).toDouble(),
      costPerKwh: (json['cost_per_kwh'] ?? 0.0).toDouble(),
    );
  }
}

class PerformanceTrends {
  final String temperatureTrend;
  final String efficiencyTrend;
  final String overallPerformance;
  final String trendConfidence;

  PerformanceTrends({
    required this.temperatureTrend,
    required this.efficiencyTrend,
    required this.overallPerformance,
    required this.trendConfidence,
  });

  factory PerformanceTrends.fromJson(Map<String, dynamic> json) {
    return PerformanceTrends(
      temperatureTrend: json['temperature_trend'] ?? 'stable',
      efficiencyTrend: json['efficiency_trend'] ?? 'stable',
      overallPerformance: json['overall_performance'] ?? 'stable',
      trendConfidence: json['trend_confidence'] ?? 'medium',
    );
  }
}

// Original classes with fixed type handling
class TemperatureAnalytics {
  final List<String> labels;
  final List<double> avgTemperature;
  final List<double> avgAirTemperature;
  final List<double> avgCoilTemperature;
  final List<double> avgDrainTemperature;
  final List<double> minTemperature;
  final List<double> maxTemperature;

  TemperatureAnalytics({
    required this.labels,
    required this.avgTemperature,
    required this.avgAirTemperature,
    required this.avgCoilTemperature,
    required this.avgDrainTemperature,
    required this.minTemperature,
    required this.maxTemperature,
  });

  factory TemperatureAnalytics.fromJson(Map<String, dynamic> json) {
    return TemperatureAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      avgTemperature: _fromDynamicList(
          json['avg_temperature'], (e) => (e as num).toDouble()),
      avgAirTemperature: _fromDynamicList(
          json['avg_air_temperature'], (e) => (e as num).toDouble()),
      avgCoilTemperature: _fromDynamicList(
          json['avg_coil_temperature'], (e) => (e as num).toDouble()),
      avgDrainTemperature: _fromDynamicList(
          json['avg_drain_temperature'], (e) => (e as num).toDouble()),
      minTemperature: _fromDynamicList(
          json['min_temperature'], (e) => (e as num).toDouble()),
      maxTemperature: _fromDynamicList(
          json['max_temperature'], (e) => (e as num).toDouble()),
    );
  }
}

class CompressorAnalytics {
  final List<String> labels;
  final List<double> avgAmpPh1;
  final List<double> avgAmpPh2;
  final List<double> avgAmpPh3;
  final List<double> avgTotalAmp;
  final List<double> avgPressureLow;
  final List<double> avgPressureHigh;
  final List<int> compressorOnCount;
  final List<int> compressorOffCount;
  final List<int> totalReadings;

  CompressorAnalytics({
    required this.labels,
    required this.avgAmpPh1,
    required this.avgAmpPh2,
    required this.avgAmpPh3,
    required this.avgTotalAmp,
    required this.avgPressureLow,
    required this.avgPressureHigh,
    required this.compressorOnCount,
    required this.compressorOffCount,
    required this.totalReadings,
  });

  factory CompressorAnalytics.fromJson(Map<String, dynamic> json) {
    return CompressorAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      avgAmpPh1:
          _fromDynamicList(json['avg_amp_ph1'], (e) => (e as num).toDouble()),
      avgAmpPh2:
          _fromDynamicList(json['avg_amp_ph2'], (e) => (e as num).toDouble()),
      avgAmpPh3:
          _fromDynamicList(json['avg_amp_ph3'], (e) => (e as num).toDouble()),
      avgTotalAmp:
          _fromDynamicList(json['avg_total_amp'], (e) => (e as num).toDouble()),
      avgPressureLow: _fromDynamicList(
          json['avg_pressure_low'], (e) => (e as num).toDouble()),
      avgPressureHigh: _fromDynamicList(
          json['avg_pressure_high'], (e) => (e as num).toDouble()),
      compressorOnCount: _fromDynamicList(
          json['compressor_on_count'], (e) => (e as num).toInt()),
      compressorOffCount: _fromDynamicList(
          json['compressor_off_count'], (e) => (e as num).toInt()),
      totalReadings:
          _fromDynamicList(json['total_readings'], (e) => (e as num).toInt()),
    );
  }
}

class DoorAnalytics {
  final List<String> labels;
  final List<int> doorOpenCount;
  final List<int> doorClosedCount;
  final List<int> totalReadings;
  final List<double> doorOpenPercentage;

  DoorAnalytics({
    required this.labels,
    required this.doorOpenCount,
    required this.doorClosedCount,
    required this.totalReadings,
    required this.doorOpenPercentage,
  });

  factory DoorAnalytics.fromJson(Map<String, dynamic> json) {
    return DoorAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      doorOpenCount:
          _fromDynamicList(json['door_open_count'], (e) => (e as num).toInt()),
      doorClosedCount: _fromDynamicList(
          json['door_closed_count'], (e) => (e as num).toInt()),
      totalReadings:
          _fromDynamicList(json['total_readings'], (e) => (e as num).toInt()),
      doorOpenPercentage: _fromDynamicList(
          json['door_open_percentage'], (e) => (e as num).toDouble()),
    );
  }
}

class IceAnalytics {
  final List<String> labels;
  final List<int> iceDetectedCount;
  final List<int> noIceCount;
  final List<int> totalReadings;
  final List<double> icePercentage;

  IceAnalytics({
    required this.labels,
    required this.iceDetectedCount,
    required this.noIceCount,
    required this.totalReadings,
    required this.icePercentage,
  });

  factory IceAnalytics.fromJson(Map<String, dynamic> json) {
    return IceAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      iceDetectedCount: _fromDynamicList(
          json['ice_detected_count'], (e) => (e as num).toInt()),
      noIceCount:
          _fromDynamicList(json['no_ice_count'], (e) => (e as num).toInt()),
      totalReadings:
          _fromDynamicList(json['total_readings'], (e) => (e as num).toInt()),
      icePercentage: _fromDynamicList(
          json['ice_percentage'], (e) => (e as num).toDouble()),
    );
  }
}

class PowerConsumptionAnalytics {
  final List<String> labels;
  final List<double> avgAmpPh1;
  final List<double> avgAmpPh2;
  final List<double> avgAmpPh3;
  final List<double> maxAmpPh1;
  final List<double> maxAmpPh2;
  final List<double> maxAmpPh3;
  final List<double> totalPowerAvg;
  final List<double> powerVariance;

  PowerConsumptionAnalytics({
    required this.labels,
    required this.avgAmpPh1,
    required this.avgAmpPh2,
    required this.avgAmpPh3,
    required this.maxAmpPh1,
    required this.maxAmpPh2,
    required this.maxAmpPh3,
    required this.totalPowerAvg,
    required this.powerVariance,
  });

  factory PowerConsumptionAnalytics.fromJson(Map<String, dynamic> json) {
    return PowerConsumptionAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      avgAmpPh1:
          _fromDynamicList(json['avg_amp_ph1'], (e) => (e as num).toDouble()),
      avgAmpPh2:
          _fromDynamicList(json['avg_amp_ph2'], (e) => (e as num).toDouble()),
      avgAmpPh3:
          _fromDynamicList(json['avg_amp_ph3'], (e) => (e as num).toDouble()),
      maxAmpPh1:
          _fromDynamicList(json['max_amp_ph1'], (e) => (e as num).toDouble()),
      maxAmpPh2:
          _fromDynamicList(json['max_amp_ph2'], (e) => (e as num).toDouble()),
      maxAmpPh3:
          _fromDynamicList(json['max_amp_ph3'], (e) => (e as num).toDouble()),
      totalPowerAvg: _fromDynamicList(
          json['total_power_avg'], (e) => (e as num).toDouble()),
      powerVariance: _fromDynamicList(
          json['power_variance'], (e) => (e as num).toDouble()),
    );
  }
}

class PressureAnalytics {
  final List<String> labels;
  final List<double> avgPressureLow;
  final List<double> avgPressureHigh;
  final List<double> avgPressureDifferential;
  final List<int> highPressureLowEvents;
  final List<int> highPressureHighEvents;

  PressureAnalytics({
    required this.labels,
    required this.avgPressureLow,
    required this.avgPressureHigh,
    required this.avgPressureDifferential,
    required this.highPressureLowEvents,
    required this.highPressureHighEvents,
  });

  factory PressureAnalytics.fromJson(Map<String, dynamic> json) {
    return PressureAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      avgPressureLow: _fromDynamicList(
          json['avg_pressure_low'], (e) => (e as num).toDouble()),
      avgPressureHigh: _fromDynamicList(
          json['avg_pressure_high'], (e) => (e as num).toDouble()),
      avgPressureDifferential: _fromDynamicList(
          json['avg_pressure_differential'], (e) => (e as num).toDouble()),
      highPressureLowEvents: _fromDynamicList(
          json['high_pressure_low_events'], (e) => (e as num).toInt()),
      highPressureHighEvents: _fromDynamicList(
          json['high_pressure_high_events'], (e) => (e as num).toInt()),
    );
  }
}

class TemperatureStabilityAnalytics {
  final List<String> labels;
  final List<double> tempVariance;
  final List<double> airTempVariance;
  final List<double> coilTempVariance;
  final List<double> drainTempVariance;
  final List<double> tempRange;
  final List<double> tempFluctuationRate;
  final List<int> tempSpikeCount;
  final List<double> airTempDifference;
  final List<double> coilTempDifference;

  TemperatureStabilityAnalytics({
    required this.labels,
    required this.tempVariance,
    required this.airTempVariance,
    required this.coilTempVariance,
    required this.drainTempVariance,
    required this.tempRange,
    required this.tempFluctuationRate,
    required this.tempSpikeCount,
    required this.airTempDifference,
    required this.coilTempDifference,
  });

  factory TemperatureStabilityAnalytics.fromJson(Map<String, dynamic> json) {
    return TemperatureStabilityAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      tempVariance:
          _fromDynamicList(json['temp_variance'], (e) => (e as num).toDouble()),
      airTempVariance: _fromDynamicList(
          json['air_temp_variance'], (e) => (e as num).toDouble()),
      coilTempVariance: _fromDynamicList(
          json['coil_temp_variance'], (e) => (e as num).toDouble()),
      drainTempVariance: _fromDynamicList(
          json['drain_temp_variance'], (e) => (e as num).toDouble()),
      tempRange:
          _fromDynamicList(json['temp_range'], (e) => (e as num).toDouble()),
      tempFluctuationRate: _fromDynamicList(
          json['temp_fluctuation_rate'], (e) => (e as num).toDouble()),
      tempSpikeCount:
          _fromDynamicList(json['temp_spike_count'], (e) => (e as num).toInt()),
      airTempDifference: _fromDynamicList(
          json['air_temp_difference'], (e) => (e as num).toDouble()),
      coilTempDifference: _fromDynamicList(
          json['coil_temp_difference'], (e) => (e as num).toDouble()),
    );
  }

  static List<T> _fromDynamicList<T>(
      dynamic list, T Function(dynamic) converter) {
    if (list == null) return <T>[];
    return (list as List).map((e) => converter(e)).toList();
  }
}

class OperationalCyclesAnalytics {
  final List<String> labels;
  final List<int> compressorStartCycles;
  final List<int> doorOpenCycles;
  final List<double> avgCompressorRuntimeSeconds;
  final List<double> avgDoorOpenDurationSeconds; // Add this line

  OperationalCyclesAnalytics({
    required this.labels,
    required this.compressorStartCycles,
    required this.doorOpenCycles,
    required this.avgCompressorRuntimeSeconds,
    required this.avgDoorOpenDurationSeconds, // Add this line
  });

  factory OperationalCyclesAnalytics.fromJson(Map<String, dynamic> json) {
    return OperationalCyclesAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      compressorStartCycles: _fromDynamicList(
          json['compressor_start_cycles'], (e) => (e as num).toInt()),
      doorOpenCycles:
          _fromDynamicList(json['door_open_cycles'], (e) => (e as num).toInt()),
      avgCompressorRuntimeSeconds: _fromDynamicList(
          json['avg_compressor_runtime_seconds'], (e) => (e as num).toDouble()),
      avgDoorOpenDurationSeconds: _fromDynamicList(
          // Add this block
          json['avg_door_open_duration_seconds'],
          (e) => (e as num).toDouble()),
    );
  }
}

class EnergyEfficiencyAnalytics {
  final List<String> labels;
  final List<double> avgTotalPower;
  final List<double> avgPowerWhenRunning;
  final List<double> compressorDutyCycle;
  final List<double> powerPerDegree;

  EnergyEfficiencyAnalytics({
    required this.labels,
    required this.avgTotalPower,
    required this.avgPowerWhenRunning,
    required this.compressorDutyCycle,
    required this.powerPerDegree,
  });

  factory EnergyEfficiencyAnalytics.fromJson(Map<String, dynamic> json) {
    return EnergyEfficiencyAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      avgTotalPower: _fromDynamicList(
          json['avg_total_power'], (e) => (e as num).toDouble()),
      avgPowerWhenRunning: _fromDynamicList(
          json['avg_power_when_running'], (e) => (e as num).toDouble()),
      compressorDutyCycle: _fromDynamicList(
          json['compressor_duty_cycle'], (e) => (e as num).toDouble()),
      powerPerDegree: _fromDynamicList(
          json['power_per_degree'], (e) => (e as num).toDouble()),
    );
  }
}

class MaintenanceIndicatorsAnalytics {
  final List<String> labels;
  final List<double> iceBuildupPercentage;
  final List<int> highTempAlerts;
  final List<int> highPressureAlerts;
  final List<int> highPowerConsumptionAlerts;

  MaintenanceIndicatorsAnalytics({
    required this.labels,
    required this.iceBuildupPercentage,
    required this.highTempAlerts,
    required this.highPressureAlerts,
    required this.highPowerConsumptionAlerts,
  });

  factory MaintenanceIndicatorsAnalytics.fromJson(Map<String, dynamic> json) {
    return MaintenanceIndicatorsAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      iceBuildupPercentage: _fromDynamicList(
          json['ice_buildup_percentage'], (e) => (e as num).toDouble()),
      highTempAlerts:
          _fromDynamicList(json['high_temp_alerts'], (e) => (e as num).toInt()),
      highPressureAlerts: _fromDynamicList(
          json['high_pressure_alerts'], (e) => (e as num).toInt()),
      highPowerConsumptionAlerts: _fromDynamicList(
          json['high_power_consumption_alerts'], (e) => (e as num).toInt()),
    );
  }
}

class PhaseBalanceAnalytics {
  final List<String> labels;
  final List<double> avgPh1;
  final List<double> avgPh2;
  final List<double> avgPh3;
  final List<double> phaseImbalancePercentage;

  PhaseBalanceAnalytics({
    required this.labels,
    required this.avgPh1,
    required this.avgPh2,
    required this.avgPh3,
    required this.phaseImbalancePercentage,
  });

  factory PhaseBalanceAnalytics.fromJson(Map<String, dynamic> json) {
    return PhaseBalanceAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      avgPh1: _fromDynamicList(json['avg_ph1'], (e) => (e as num).toDouble()),
      avgPh2: _fromDynamicList(json['avg_ph2'], (e) => (e as num).toDouble()),
      avgPh3: _fromDynamicList(json['avg_ph3'], (e) => (e as num).toDouble()),
      phaseImbalancePercentage: _fromDynamicList(
          json['phase_imbalance_percentage'], (e) => (e as num).toDouble()),
    );
  }
}

class CorrelationsAnalytics {
  final List<String> labels;
  final List<double> tempPowerCorrelation;
  final List<double> doorTempImpact;

  CorrelationsAnalytics({
    required this.labels,
    required this.tempPowerCorrelation,
    required this.doorTempImpact,
  });

  factory CorrelationsAnalytics.fromJson(Map<String, dynamic> json) {
    return CorrelationsAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      tempPowerCorrelation: _fromDynamicList(
          json['temp_power_correlation'], (e) => (e as num).toDouble()),
      doorTempImpact: _fromDynamicList(
          json['door_temp_impact'], (e) => (e as num).toDouble()),
    );
  }
}

class DailySummaryAnalytics {
  final List<String> labels;
  final List<double> dailyAvgTemp;
  final List<double> dailyAvgPower;
  final List<double> dailyDutyCycle;
  final List<int> dailyTempViolations;

  DailySummaryAnalytics({
    required this.labels,
    required this.dailyAvgTemp,
    required this.dailyAvgPower,
    required this.dailyDutyCycle,
    required this.dailyTempViolations,
  });

  factory DailySummaryAnalytics.fromJson(Map<String, dynamic> json) {
    return DailySummaryAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      dailyAvgTemp: _fromDynamicList(
          json['daily_avg_temp'], (e) => (e as num).toDouble()),
      dailyAvgPower: _fromDynamicList(
          json['daily_avg_power'], (e) => (e as num).toDouble()),
      dailyDutyCycle: _fromDynamicList(
          json['daily_duty_cycle'], (e) => (e as num).toDouble()),
      dailyTempViolations: _fromDynamicList(
          json['daily_temp_violations'], (e) => (e as num).toInt()),
    );
  }
}

class PeakPerformanceAnalytics {
  final double peakPowerConsumption;
  final double lowestTemperatureReached;
  final double highestTemperatureReached;
  final String? peakPowerTime;
  final String? lowestTempTime;
  final String? highestTempTime;

  PeakPerformanceAnalytics({
    required this.peakPowerConsumption,
    required this.lowestTemperatureReached,
    required this.highestTemperatureReached,
    this.peakPowerTime,
    this.lowestTempTime,
    this.highestTempTime,
  });

  factory PeakPerformanceAnalytics.fromJson(Map<String, dynamic> json) {
    return PeakPerformanceAnalytics(
      peakPowerConsumption: (json['peak_power_consumption'] ?? 0.0).toDouble(),
      lowestTemperatureReached:
          (json['lowest_temperature_reached'] ?? 0.0).toDouble(),
      highestTemperatureReached:
          (json['highest_temperature_reached'] ?? 0.0).toDouble(),
      peakPowerTime: json['peak_power_time'],
      lowestTempTime: json['lowest_temp_time'],
      highestTempTime: json['highest_temp_time'],
    );
  }
}

// Helper extension methods for easy access to enhanced data
extension DeviceAnalyticsExtensions on DeviceAnalytics {
  // Quick access to current compressor status
  bool get isCompressorRunning =>
      enhancedCompressorAnalytics.currentStatus.isRunning;

  double get currentTotalAmps =>
      enhancedCompressorAnalytics.currentStatus.currentTotalAmps;

  // Quick access to extreme values with timestamps
  String get lowestTempInfo =>
      '${enhancedTemperatureAnalytics.minTemperature.toStringAsFixed(2)}°C at ${_formatDateTime(enhancedTemperatureAnalytics.minTempTimestamp)}';

  String get highestTempInfo =>
      '${enhancedTemperatureAnalytics.maxTemperature.toStringAsFixed(2)}°C at ${_formatDateTime(enhancedTemperatureAnalytics.maxTempTimestamp)}';

  String get lowestPressureInfo =>
      'Low: ${enhancedPressureAnalytics.minPressureLow.toStringAsFixed(1)} PSI at ${_formatDateTime(enhancedPressureAnalytics.minPressureLowTimestamp)}';

  String get highestPressureInfo =>
      'High: ${enhancedPressureAnalytics.maxPressureHigh.toStringAsFixed(1)} PSI at ${_formatDateTime(enhancedPressureAnalytics.maxPressureHighTimestamp)}';

  // Quick access to health and efficiency
  String get healthGrade => realTimeInsights.deviceHealthScore.healthGrade;

  double get healthScore => realTimeInsights.deviceHealthScore.overallScore;

  String get efficiencyGrade =>
      realTimeInsights.efficiencyRating.efficiencyGrade;

  double get annualCostEstimate =>
      realTimeInsights.energyCostEstimate.annualCostUsd;

  // Quick access to maintenance info
  String get maintenanceUrgency =>
      realTimeInsights.maintenanceUrgency.urgencyLevel;

  String get maintenanceAction =>
      realTimeInsights.maintenanceUrgency.recommendedAction;

  // Compressor runtime information
  String get lastOffInfo => enhancedCompressorAnalytics
              .analytics.lastOffStart !=
          null
      ? 'Off for ${enhancedCompressorAnalytics.analytics.lastOffDurationMinutes.toStringAsFixed(1)} min at ${_formatDateTime(enhancedCompressorAnalytics.analytics.lastOffStart)}'
      : 'No recent off period';

  String get lastOnInfo => enhancedCompressorAnalytics.analytics.lastOnStart !=
          null
      ? 'On for ${enhancedCompressorAnalytics.analytics.lastOnDurationMinutes.toStringAsFixed(1)} min at ${_formatDateTime(enhancedCompressorAnalytics.analytics.lastOnStart)}'
      : 'No recent on period';

  String get longestOnInfo => enhancedCompressorAnalytics
              .analytics.longestOnStart !=
          null
      ? 'Longest: ${enhancedCompressorAnalytics.analytics.longestOnDurationMinutes.toStringAsFixed(1)} min at ${_formatDateTime(enhancedCompressorAnalytics.analytics.longestOnStart)}'
      : 'No long run periods';

  String get currentStateInfo => isCompressorRunning
      ? 'Running for ${enhancedCompressorAnalytics.analytics.currentStateDurationMinutes.toStringAsFixed(1)} minutes'
      : 'Stopped for ${enhancedCompressorAnalytics.analytics.currentStateDurationMinutes.toStringAsFixed(1)} minutes';

  // Amperage extremes info
  String get minAmpsInfo =>
      '${enhancedCompressorAnalytics.analytics.minAmpValue.toStringAsFixed(1)}A at ${_formatDateTime(enhancedCompressorAnalytics.analytics.minAmpTimestamp)} (Comp: ${enhancedCompressorAnalytics.analytics.compStateAtMinAmp ? "ON" : "OFF"})';

  String get maxAmpsInfo =>
      '${enhancedCompressorAnalytics.analytics.maxAmpValue.toStringAsFixed(1)}A at ${_formatDateTime(enhancedCompressorAnalytics.analytics.maxAmpTimestamp)} (Comp: ${enhancedCompressorAnalytics.analytics.compStateAtMaxAmp ? "ON" : "OFF"})';

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

// Device 2 Analytics (Multi-zone temperature monitoring)
class Device2Analytics {
  final String deviceType;
  final Device2TemperatureAnalytics temperatureAnalytics;
  final Device2ZoneSummary zoneSummary;
  final RealTimeInsights realTimeInsights;

  Device2Analytics({
    required this.deviceType,
    required this.temperatureAnalytics,
    required this.zoneSummary,
    required this.realTimeInsights,
  });

  factory Device2Analytics.fromJson(Map<String, dynamic> json) {
    return Device2Analytics(
      deviceType: json['device_type'] ?? 'device2',
      temperatureAnalytics: Device2TemperatureAnalytics.fromJson(json['temperature_analytics'] ?? {}),
      zoneSummary: Device2ZoneSummary.fromJson(json['zone_summary'] ?? {}),
      realTimeInsights: RealTimeInsights.fromJson(json['real_time_insights'] ?? {}),
    );
  }
}

class Device2TemperatureAnalytics {
  final List<String> labels;
  final List<double> zone1;
  final List<double> zone2;
  final List<double> zone3;
  final List<double> zone4;
  final List<double> zone5;
  final List<double> zone6;
  final List<double> zone7;
  final List<double> zone8;
  final List<double> minTemperature;
  final List<double> maxTemperature;

  Device2TemperatureAnalytics({
    required this.labels,
    required this.zone1,
    required this.zone2,
    required this.zone3,
    required this.zone4,
    required this.zone5,
    required this.zone6,
    required this.zone7,
    required this.zone8,
    required this.minTemperature,
    required this.maxTemperature,
  });

  factory Device2TemperatureAnalytics.fromJson(Map<String, dynamic> json) {
    return Device2TemperatureAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      zone1: _fromDynamicList(json['zone1'], (e) => (e ?? 0.0).toDouble()),
      zone2: _fromDynamicList(json['zone2'], (e) => (e ?? 0.0).toDouble()),
      zone3: _fromDynamicList(json['zone3'], (e) => (e ?? 0.0).toDouble()),
      zone4: _fromDynamicList(json['zone4'], (e) => (e ?? 0.0).toDouble()),
      zone5: _fromDynamicList(json['zone5'], (e) => (e ?? 0.0).toDouble()),
      zone6: _fromDynamicList(json['zone6'], (e) => (e ?? 0.0).toDouble()),
      zone7: _fromDynamicList(json['zone7'], (e) => (e ?? 0.0).toDouble()),
      zone8: _fromDynamicList(json['zone8'], (e) => (e ?? 0.0).toDouble()),
      minTemperature: _fromDynamicList(json['min_temperature'], (e) => (e ?? 0.0).toDouble()),
      maxTemperature: _fromDynamicList(json['max_temperature'], (e) => (e ?? 0.0).toDouble()),
    );
  }

  List<double> getZone(int zoneNumber) {
    switch (zoneNumber) {
      case 1: return zone1;
      case 2: return zone2;
      case 3: return zone3;
      case 4: return zone4;
      case 5: return zone5;
      case 6: return zone6;
      case 7: return zone7;
      case 8: return zone8;
      default: return [];
    }
  }
}

class Device2ZoneSummary {
  final List<ZoneStats> zones;
  final int totalReadings;

  Device2ZoneSummary({required this.zones, required this.totalReadings});

  factory Device2ZoneSummary.fromJson(Map<String, dynamic> json) {
    return Device2ZoneSummary(
      zones: _fromDynamicList(json['zones'] ?? [], (e) => ZoneStats.fromJson(e)),
      totalReadings: json['total_readings'] ?? 0,
    );
  }
}

class ZoneStats {
  final int zone;
  final double? min;
  final double? max;
  final double? avg;
  final String? minTime;
  final String? maxTime;

  ZoneStats({required this.zone, this.min, this.max, this.avg, this.minTime, this.maxTime});

  factory ZoneStats.fromJson(Map<String, dynamic> json) {
    return ZoneStats(
      zone: json['zone'] ?? 0,
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
      avg: json['avg']?.toDouble(),
      minTime: json['min_time'],
      maxTime: json['max_time'],
    );
  }
}

// Device 3 Analytics (Ice machine monitoring)
class Device3Analytics {
  final String deviceType;
  final Device3TemperatureAnalytics temperatureAnalytics;
  final Device3WaterAnalytics waterAnalytics;
  final Device3HarvestAnalytics harvestAnalytics;
  final Device3Summary iceMachineSummary;
  final RealTimeInsights realTimeInsights;

  Device3Analytics({
    required this.deviceType,
    required this.temperatureAnalytics,
    required this.waterAnalytics,
    required this.harvestAnalytics,
    required this.iceMachineSummary,
    required this.realTimeInsights,
  });

  factory Device3Analytics.fromJson(Map<String, dynamic> json) {
    return Device3Analytics(
      deviceType: json['device_type'] ?? 'device3',
      temperatureAnalytics: Device3TemperatureAnalytics.fromJson(json['temperature_analytics'] ?? {}),
      waterAnalytics: Device3WaterAnalytics.fromJson(json['water_analytics'] ?? {}),
      harvestAnalytics: Device3HarvestAnalytics.fromJson(json['harvest_analytics'] ?? {}),
      iceMachineSummary: Device3Summary.fromJson(json['ice_machine_summary'] ?? {}),
      realTimeInsights: RealTimeInsights.fromJson(json['real_time_insights'] ?? {}),
    );
  }
}

class Device3TemperatureAnalytics {
  final List<String> labels;
  final List<double> hsTemp;
  final List<double> lsTemp;
  final List<double> iceTemp;
  final List<double> airTemp;

  Device3TemperatureAnalytics({
    required this.labels,
    required this.hsTemp,
    required this.lsTemp,
    required this.iceTemp,
    required this.airTemp,
  });

  factory Device3TemperatureAnalytics.fromJson(Map<String, dynamic> json) {
    return Device3TemperatureAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      hsTemp: _fromDynamicList(json['hs_temp'], (e) => (e ?? 0.0).toDouble()),
      lsTemp: _fromDynamicList(json['ls_temp'], (e) => (e ?? 0.0).toDouble()),
      iceTemp: _fromDynamicList(json['ice_temp'], (e) => (e ?? 0.0).toDouble()),
      airTemp: _fromDynamicList(json['air_temp'], (e) => (e ?? 0.0).toDouble()),
    );
  }
}

class Device3WaterAnalytics {
  final List<String> labels;
  final List<double> waterLevel;

  Device3WaterAnalytics({required this.labels, required this.waterLevel});

  factory Device3WaterAnalytics.fromJson(Map<String, dynamic> json) {
    return Device3WaterAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      waterLevel: _fromDynamicList(json['water_level'], (e) => (e ?? 0.0).toDouble()),
    );
  }
}

class Device3HarvestAnalytics {
  final List<String> labels;
  final List<int> harvestCount;
  final List<int> readings;

  Device3HarvestAnalytics({required this.labels, required this.harvestCount, required this.readings});

  factory Device3HarvestAnalytics.fromJson(Map<String, dynamic> json) {
    return Device3HarvestAnalytics(
      labels: _fromDynamicList(json['labels'], (e) => e.toString()),
      harvestCount: _fromDynamicList(json['harvest_count'], (e) => (e ?? 0) as int),
      readings: _fromDynamicList(json['readings'], (e) => (e ?? 0) as int),
    );
  }
}

class Device3Summary {
  final TempStats? highSideTemp;
  final TempStats? lowSideTemp;
  final TempStats? iceTemp;
  final TempStats? airTemp;
  final TempStats? waterLevel;
  final int totalHarvests;
  final int totalReadings;

  Device3Summary({
    this.highSideTemp,
    this.lowSideTemp,
    this.iceTemp,
    this.airTemp,
    this.waterLevel,
    required this.totalHarvests,
    required this.totalReadings,
  });

  factory Device3Summary.fromJson(Map<String, dynamic> json) {
    return Device3Summary(
      highSideTemp: json['high_side_temp'] != null ? TempStats.fromJson(json['high_side_temp']) : null,
      lowSideTemp: json['low_side_temp'] != null ? TempStats.fromJson(json['low_side_temp']) : null,
      iceTemp: json['ice_temp'] != null ? TempStats.fromJson(json['ice_temp']) : null,
      airTemp: json['air_temp'] != null ? TempStats.fromJson(json['air_temp']) : null,
      waterLevel: json['water_level'] != null ? TempStats.fromJson(json['water_level']) : null,
      totalHarvests: json['total_harvests'] ?? 0,
      totalReadings: json['total_readings'] ?? 0,
    );
  }
}

class TempStats {
  final double? min;
  final double? max;
  final double? avg;

  TempStats({this.min, this.max, this.avg});

  factory TempStats.fromJson(Map<String, dynamic> json) {
    return TempStats(
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
      avg: json['avg']?.toDouble(),
    );
  }
}

class Device {
  final int id;
  final String deviceId;
  final String name;
  final String deviceType;

  Device({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.deviceType,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      deviceId: json['device_id'],
      name: json['name'],
      deviceType: json['device_type'] ?? 'device1',
    );
  }
}

class ApiService {
  static String baseUrl = Constants.articBaseUrl2;

  static Future<List<Device>> getDevices(int companyId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/companies/$companyId/devices/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['devices'] as List)
          .map((device) => Device.fromJson(device))
          .toList();
    } else {
      throw Exception('Failed to load devices');
    }
  }

  static Future<DeviceAnalytics> getDeviceAnalytics({
    required String deviceId,
    required String startDate,
    required String endDate,
    required int companyId,
  }) async {
    final queryParams = {
      'device_id': deviceId,
      'start_date': startDate,
      'end_date': endDate,
      'company_id': companyId.toString(),
    };
    print("gfghgh $queryParams");

    final uri = Uri.parse('${baseUrl}api/device-metrics/')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      //print("fgghghghj ${response.body}");
      return DeviceAnalytics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load analytics: ${response.body}');
    }
  }

  // Get raw analytics data for device-type specific parsing
  static Future<Map<String, dynamic>> getDeviceAnalyticsRaw({
    required String deviceId,
    required String startDate,
    required String endDate,
    required int companyId,
  }) async {
    final queryParams = {
      'device_id': deviceId,
      'start_date': startDate,
      'end_date': endDate,
      'company_id': companyId.toString(),
    };

    final uri = Uri.parse('${baseUrl}api/device-metrics/')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load analytics: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getDeviceDetail(String deviceId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/devices/$deviceId/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load device details');
    }
  }
}

class DevicePeformanceDashboard extends StatefulWidget {
  final int companyId;

  const DevicePeformanceDashboard({Key? key, required this.companyId})
      : super(key: key);

  @override
  State<DevicePeformanceDashboard> createState() =>
      _DevicePeformanceDashboardState();
}

class _DevicePeformanceDashboardState extends State<DevicePeformanceDashboard> {
  List<Device> devices = [];
  Device? selectedDevice;
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  DeviceAnalytics? analyticsData;
  Device2Analytics? device2AnalyticsData;
  Device3Analytics? device3AnalyticsData;
  bool isLoading = false;
  bool isInitialLoad = true;
  String? errorMessage;
  Timer? _refreshTimer;

  // Helper method to check if screen is mobile
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (selectedDevice != null) {
        _loadAnalytics(
            showLoading: false); // Background refresh without loading indicator
      }
    });
  }

  Future<void> _loadDevices() async {
    try {
      final deviceList = await ApiService.getDevices(widget.companyId);
      setState(() {
        devices = deviceList;
        if (deviceList.isNotEmpty) {
          selectedDevice = deviceList.first;
          _loadAnalytics();
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadAnalytics({bool showLoading = true}) async {
    if (selectedDevice == null) return;

    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final deviceType = selectedDevice!.deviceType;

      // Get raw JSON first to determine parsing strategy
      final rawData = await ApiService.getDeviceAnalyticsRaw(
        deviceId: selectedDevice!.deviceId,
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
        companyId: widget.companyId,
      );

      setState(() {
        // Parse based on device type
        if (deviceType == 'device2') {
          device2AnalyticsData = Device2Analytics.fromJson(rawData);
          analyticsData = null;
          device3AnalyticsData = null;
        } else if (deviceType == 'device3') {
          device3AnalyticsData = Device3Analytics.fromJson(rawData);
          analyticsData = null;
          device2AnalyticsData = null;
        } else {
          analyticsData = DeviceAnalytics.fromJson(rawData);
          device2AnalyticsData = null;
          device3AnalyticsData = null;
        }
        isLoading = false;
        isInitialLoad = false;
      });
    } catch (e) {
      if (showLoading) {
        setState(() {
          errorMessage = e.toString();
          print(errorMessage);
          isLoading = false;
        });
      }
      // For background updates, silently fail to avoid disrupting UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const CompactHeader(
            title: "Device Performance",
            description: "Monitor and analyze device analytics in real-time",
            icon: Icons.analytics_rounded,
          ),
          _buildControlPanel(),
          Expanded(
            child: isLoading && isInitialLoad
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Constants.ctaColorLight,
                            strokeWidth: 3.0,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading device analytics...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red.shade300),
                            SizedBox(height: 16),
                            Text(
                              'Error: $errorMessage',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (analyticsData != null || device2AnalyticsData != null || device3AnalyticsData != null)
                        ? Stack(
                            children: [
                              _buildDashboard(),
                              // Show small loading indicator for background updates
                              if (isLoading && !isInitialLoad)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Constants.ctaColorLight,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Updating...',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                SizedBox(height: 16),
                                Text(
                                  'Select a device to view analytics',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    final isMobile = _isMobile(context);

    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        isMobile
            ? Column(
                children: [
                  // ───────── Device selector ─────────
                  Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDevice?.deviceId,
                    hint: Text(
                      'Select Device',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: Constants.ctaColorLight),
                    isExpanded: true,
                    items: [
                      // "All devices" option
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'All Devices',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // real devices
                      ...devices.map((device) => DropdownMenuItem<String>(
                            value: device.deviceId,
                            child: Row(
                              children: [
                                // coloured status dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Constants.ctaColorLight,
                                  ),
                                ),
                                // device name + status
                                Expanded(
                                  child: Text(
                                    device.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDevice =
                            devices.firstWhere((d) => d.deviceId == newValue);
                      });
                      _loadAnalytics(); // reload stats for the choice
                    },
                  ),
                ),
              ),
                  const SizedBox(height: 12),

                  // ───────── Start date ─────────
                  Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  onTap: () => _selectDate(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Constants.ctaColorLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy').format(startDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Constants.ctaColorLight,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                  const SizedBox(height: 12),

                  // ───────── End date ─────────
                  Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  onTap: () => _selectDate(false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Constants.ctaColorLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'End Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy').format(endDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Constants.ctaColorLight,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                  const SizedBox(height: 12),

                  // ───────── Refresh button ─────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  // ───────── Device selector ─────────
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDevice?.deviceId,
                          hint: Text(
                            'Select Device',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Constants.ctaColorLight),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Devices',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...devices.map((device) => DropdownMenuItem<String>(
                                  value: device.deviceId,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Constants.ctaColorLight,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          device.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDevice = devices
                                  .firstWhere((d) => d.deviceId == newValue);
                            });
                            _loadAnalytics();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ───────── Start date ─────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: Constants.ctaColorLight,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(startDate),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Constants.ctaColorLight,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ───────── End date ─────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: Constants.ctaColorLight,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(endDate),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Constants.ctaColorLight,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ───────── Refresh button ─────────
                  ElevatedButton.icon(
                    onPressed: _loadAnalytics,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
                    label: Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ]),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Widget _buildTemperatureDetailsCard() {
    final tempAnalytics = analyticsData!.enhancedTemperatureAnalytics;
    final isMobile = _isMobile(context);

    // Check for temperature errors/warnings - updated to use coil temperature for broader range
    bool hasError = tempAnalytics.maxCoilTemperature > 80 ||
        tempAnalytics.minCoilTemperature < -10 ||
        tempAnalytics.maxAirTemperature > 40 ||
        tempAnalytics.minAirTemperature < -5;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFF1F5F9),
          width: hasError ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.thermostat_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temperature Analysis',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${tempAnalytics.totalReadings} total readings',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasError)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'WARNING',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Temperature breakdown - FIXED coil temperature section
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildInfoSection4(
                          'Air Temperature',
                          '${tempAnalytics.minAirTemperature.toStringAsFixed(1)}°C - ${tempAnalytics.maxAirTemperature.toStringAsFixed(1)}°C',
                          'Average: ${tempAnalytics.avgAirTemperature.toStringAsFixed(1)}°C | Variance: ±${tempAnalytics.airTemperatureVariance.toStringAsFixed(1)}',
                          'Low: ${_formatTimestamp(tempAnalytics.minAirTempTimestamp ?? "")} • High: ${_formatTimestamp(tempAnalytics.maxAirTempTimestamp ?? "")}',
                          Icons.air_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoSection4(
                          'Drain Temperature',
                          '${tempAnalytics.minDrainTemperature.toStringAsFixed(1)}°C - ${tempAnalytics.maxDrainTemperature.toStringAsFixed(1)}°C',
                          'Average: ${tempAnalytics.avgDrainTemperature.toStringAsFixed(1)}°C | Variance: ±${tempAnalytics.drainTemperatureVariance.toStringAsFixed(1)}',
                          'Low: ${_formatTimestamp(tempAnalytics.minDrainTempTimestamp ?? "")} • High: ${_formatTimestamp(tempAnalytics.maxDrainTempTimestamp ?? "")}',
                          Icons.water_drop_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoSection4(
                          'Coil Temperature',
                          '${tempAnalytics.minCoilTemperature.toStringAsFixed(1)}°C - ${tempAnalytics.maxCoilTemperature.toStringAsFixed(1)}°C',
                          'Average: ${tempAnalytics.avgCoilTemperature.toStringAsFixed(1)}°C | Variance: ±${tempAnalytics.coilTemperatureVariance.toStringAsFixed(1)}',
                          'Low: ${_formatTimestamp(tempAnalytics.minCoilTempTimestamp ?? "")} • High: ${_formatTimestamp(tempAnalytics.maxCoilTempTimestamp ?? "")}',
                          Icons.device_thermostat_rounded,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildInfoSection4(
                            'Air Temperature',
                            '${tempAnalytics.minAirTemperature.toStringAsFixed(1)}°C - ${tempAnalytics.maxAirTemperature.toStringAsFixed(1)}°C',
                            'Average: ${tempAnalytics.avgAirTemperature.toStringAsFixed(1)}°C | Variance: ±${tempAnalytics.airTemperatureVariance.toStringAsFixed(1)}',
                            'Low: ${_formatTimestamp(tempAnalytics.minAirTempTimestamp ?? "")} • High: ${_formatTimestamp(tempAnalytics.maxAirTempTimestamp ?? "")}',
                            Icons.air_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoSection4(
                            'Drain Temperature',
                            '${tempAnalytics.minDrainTemperature.toStringAsFixed(1)}°C - ${tempAnalytics.maxDrainTemperature.toStringAsFixed(1)}°C',
                            'Average: ${tempAnalytics.avgDrainTemperature.toStringAsFixed(1)}°C | Variance: ±${tempAnalytics.drainTemperatureVariance.toStringAsFixed(1)}',
                            'Low: ${_formatTimestamp(tempAnalytics.minDrainTempTimestamp ?? "")} • High: ${_formatTimestamp(tempAnalytics.maxDrainTempTimestamp ?? "")}',
                            Icons.water_drop_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoSection4(
                            'Coil Temperature',
                            '${tempAnalytics.minCoilTemperature.toStringAsFixed(1)}°C - ${tempAnalytics.maxCoilTemperature.toStringAsFixed(1)}°C',
                            'Average: ${tempAnalytics.avgCoilTemperature.toStringAsFixed(1)}°C | Variance: ±${tempAnalytics.coilTemperatureVariance.toStringAsFixed(1)}',
                            'Low: ${_formatTimestamp(tempAnalytics.minCoilTempTimestamp ?? "")} • High: ${_formatTimestamp(tempAnalytics.maxCoilTempTimestamp ?? "")}',
                            Icons.device_thermostat_rounded,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection4(String title, String value, String subtitle,
      String timestamps, IconData icon) {
    final isMobile = _isMobile(context);
    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timestamps,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureDetailsCard() {
    final pressureAnalytics = analyticsData!.enhancedPressureAnalytics;
    final isMobile = _isMobile(context);

    // Check for pressure errors
    bool hasError = pressureAnalytics.avgPressureDifferential > 50 ||
        pressureAnalytics.avgPressureHigh > 200;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFF1F5F9),
          width: hasError ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pressure Analysis',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${pressureAnalytics.totalReadings} total readings',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasError)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HIGH PRESSURE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Pressure metrics
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildMetricCard(
                          'Low Pressure',
                          '${pressureAnalytics.avgPressureLow.toStringAsFixed(1)} PSI',
                          '${pressureAnalytics.minPressureLow.toStringAsFixed(1)} - ${pressureAnalytics.maxPressureLow.toStringAsFixed(1)} PSI',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'High Pressure',
                          '${pressureAnalytics.avgPressureHigh.toStringAsFixed(1)} PSI',
                          '${pressureAnalytics.minPressureHigh.toStringAsFixed(1)} - ${pressureAnalytics.maxPressureHigh.toStringAsFixed(1)} PSI',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Differential',
                          '${pressureAnalytics.avgPressureDifferential.toStringAsFixed(1)} PSI',
                          'Average difference',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildMetricCard(
                          'Low Pressure',
                          '${pressureAnalytics.avgPressureLow.toStringAsFixed(1)} PSI',
                          '${pressureAnalytics.minPressureLow.toStringAsFixed(1)} - ${pressureAnalytics.maxPressureLow.toStringAsFixed(1)} PSI',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'High Pressure',
                          '${pressureAnalytics.avgPressureHigh.toStringAsFixed(1)} PSI',
                          '${pressureAnalytics.minPressureHigh.toStringAsFixed(1)} - ${pressureAnalytics.maxPressureHigh.toStringAsFixed(1)} PSI',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Differential',
                          '${pressureAnalytics.avgPressureDifferential.toStringAsFixed(1)} PSI',
                          'Average difference',
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Pressure extremes with timestamps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pressure Extremes',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: isMobile
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lowest Pressure',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pressureAnalytics.minPressureLow.toStringAsFixed(2)} PSI',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  if (pressureAnalytics.minPressureLowTimestamp !=
                                      null)
                                    Text(
                                      _formatTimestamp(
                                          pressureAnalytics.minPressureLowTimestamp ??
                                              ""),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Highest Pressure',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pressureAnalytics.maxPressureHigh.toStringAsFixed(2)} PSI',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  if (pressureAnalytics.maxPressureHighTimestamp !=
                                      null)
                                    Text(
                                      _formatTimestamp(pressureAnalytics
                                              .maxPressureHighTimestamp ??
                                          ""),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lowest Pressure',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pressureAnalytics.minPressureLow.toStringAsFixed(2)} PSI',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Constants.ctaColorLight,
                                      ),
                                    ),
                                    if (pressureAnalytics.minPressureLowTimestamp !=
                                        null)
                                      Text(
                                        _formatTimestamp(
                                            pressureAnalytics.minPressureLowTimestamp ??
                                                ""),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Highest Pressure',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pressureAnalytics.maxPressureHigh.toStringAsFixed(2)} PSI',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Constants.ctaColorLight,
                                      ),
                                    ),
                                    if (pressureAnalytics.maxPressureHighTimestamp !=
                                        null)
                                      Text(
                                        _formatTimestamp(pressureAnalytics
                                                .maxPressureHighTimestamp ??
                                            ""),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: isMobile
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Highest Pressure (Low Side)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pressureAnalytics.maxPressureLow.toStringAsFixed(2)} PSI',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  if (pressureAnalytics.maxPressureLowTimestamp !=
                                      null)
                                    Text(
                                      _formatTimestamp(
                                          pressureAnalytics.maxPressureLowTimestamp ??
                                              ""),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                width: double.infinity,
                                color: const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lowest Pressure (High Side)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pressureAnalytics.minPressureHigh.toStringAsFixed(2)} PSI',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  if (pressureAnalytics.minPressureHighTimestamp !=
                                      null)
                                    Text(
                                      _formatTimestamp(pressureAnalytics
                                              .minPressureHighTimestamp ??
                                          ""),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Highest Pressure (Low Side)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Constants.ctaColorLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pressureAnalytics.maxPressureLow.toStringAsFixed(2)} PSI',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Constants.ctaColorLight,
                                      ),
                                    ),
                                    if (pressureAnalytics.maxPressureLowTimestamp !=
                                        null)
                                      Text(
                                        _formatTimestamp(
                                            pressureAnalytics.maxPressureLowTimestamp ??
                                                ""),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lowest Pressure (High Side)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pressureAnalytics.minPressureHigh.toStringAsFixed(2)} PSI',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Constants.ctaColorLight,
                                      ),
                                    ),
                                    if (pressureAnalytics.minPressureHighTimestamp !=
                                        null)
                                      Text(
                                        _formatTimestamp(pressureAnalytics
                                                .minPressureHighTimestamp ??
                                            ""),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressorDetailsCard() {
    final enhanced = analyticsData!.enhancedCompressorAnalytics;
    final analytics = enhanced.analytics;
    final status = enhanced.currentStatus;
    final isMobile = _isMobile(context);

    // Check for compressor errors
    bool hasError = status.currentTotalAmps > 30 ||
        enhanced.statistics.dutyCyclePercentage > 80;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFF1F5F9),
          width: hasError ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compressor Analysis',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status.isRunning
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.isRunning
                                ? 'Currently Running'
                                : 'Currently Stopped',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11 : 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasError)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HIGH LOAD',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Compressor metrics - First row
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildMetricCard(
                          'Start Cycles',
                          '${enhanced.statistics.totalStartCycles}',
                          'Compressor start events',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Stop Cycles',
                          '${enhanced.statistics.totalStopCycles}',
                          'Compressor stop events',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Duty Cycle',
                          '${enhanced.statistics.dutyCyclePercentage.toStringAsFixed(1)}%',
                          'Runtime percentage',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildMetricCard(
                          'Start Cycles',
                          '${enhanced.statistics.totalStartCycles}',
                          'Compressor start events',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Stop Cycles',
                          '${enhanced.statistics.totalStopCycles}',
                          'Compressor stop events',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Duty Cycle',
                          '${enhanced.statistics.dutyCyclePercentage.toStringAsFixed(1)}%',
                          'Runtime percentage',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // Second row - Load and readings
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildMetricCard(
                          'Current Load',
                          '${status.currentTotalAmps.toStringAsFixed(1)}A',
                          'Running avg: ${analytics.avgAmpsWhenRunning.toStringAsFixed(1)}A',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'On Readings',
                          '${enhanced.statistics.totalOnReadings}',
                          'Off: ${enhanced.statistics.totalOffReadings}',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Runtime',
                          '${analytics.currentStateDurationMinutes.toStringAsFixed(0)} min',
                          status.isRunning ? 'Current session' : 'Since stopped',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildMetricCard(
                          'Current Load',
                          '${status.currentTotalAmps.toStringAsFixed(1)}A',
                          'Running avg: ${analytics.avgAmpsWhenRunning.toStringAsFixed(1)}A',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'On Readings',
                          '${enhanced.statistics.totalOnReadings}',
                          'Off: ${enhanced.statistics.totalOffReadings}',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Runtime',
                          '${analytics.currentStateDurationMinutes.toStringAsFixed(0)} min',
                          status.isRunning ? 'Current session' : 'Since stopped',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Performance summary
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildInfoCompressorSection(
                          'Longest Off',
                          analytics.longestOffStart != null
                              ? '${analytics.longestOffDurationMinutes.toStringAsFixed(1)} min'
                              : 'No data',
                          analytics.longestOffStart != null
                              ? 'Started: ${_formatTimestamp(analytics.longestOffStart!)}'
                              : 'No off periods recorded',
                          Icons.power_off_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCompressorSection(
                          'Longest On',
                          analytics.longestOnStart != null
                              ? '${analytics.longestOnDurationMinutes.toStringAsFixed(1)} min'
                              : 'No data',
                          analytics.longestOnStart != null
                              ? 'Started: ${_formatTimestamp(analytics.longestOnStart!)}'
                              : 'No on periods recorded',
                          Icons.power_rounded,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildInfoCompressorSection(
                            'Longest Off',
                            analytics.longestOffStart != null
                                ? '${analytics.longestOffDurationMinutes.toStringAsFixed(1)} min'
                                : 'No data',
                            analytics.longestOffStart != null
                                ? 'Started: ${_formatTimestamp(analytics.longestOffStart!)}'
                                : 'No off periods recorded',
                            Icons.power_off_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCompressorSection(
                            'Longest On',
                            analytics.longestOnStart != null
                                ? '${analytics.longestOnDurationMinutes.toStringAsFixed(1)} min'
                                : 'No data',
                            analytics.longestOnStart != null
                                ? 'Started: ${_formatTimestamp(analytics.longestOnStart!)}'
                                : 'No on periods recorded',
                            Icons.power_rounded,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle) {
    final isMobile = _isMobile(context);
    final card = Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return isMobile ? card : Expanded(child: card);
  }

  Widget _buildInfoSection(
      String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSectionTemp(String title, String value, String subtitle,
      String timestamps, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timestamps,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    // Route to device-specific dashboard based on device type
    final deviceType = selectedDevice?.deviceType ?? 'device1';

    if (deviceType == 'device2') {
      if (device2AnalyticsData == null) {
        return Center(
          child: isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                )
              : Text(
                  'No data available for this device',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
        );
      }
      return _buildDevice2Dashboard();
    } else if (deviceType == 'device3') {
      if (device3AnalyticsData == null) {
        return Center(
          child: isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                )
              : Text(
                  'No data available for this device',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
        );
      }
      return _buildDevice3Dashboard();
    } else {
      if (analyticsData == null) {
        return Center(
          child: isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                )
              : Text(
                  'No data available for this device',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
        );
      }
      return _buildDevice1Dashboard();
    }
  }

  // Device 2 Dashboard (Multi-zone temperature monitoring)
  Widget _buildDevice2Dashboard() {
    final isMobile = _isMobile(context);
    final padding = isMobile ? 12.0 : 16.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with health score
          _buildDevice2Header(),
          SizedBox(height: spacing),

          // Zone Temperature Grid
          _buildDevice2ZoneGrid(),
          SizedBox(height: spacing),

          // All Zones Temperature Trends Chart
          _buildChart('All Zones Temperature Trends', _buildDevice2AllZonesChart()),
          SizedBox(height: spacing),

          // Min/Max Temperature Range Chart
          _buildChart('Temperature Range (Min/Max)', _buildDevice2MinMaxChart()),
          SizedBox(height: spacing),

          // Zone Comparison Bar Chart
          _buildChart('Zone Temperature Comparison', _buildDevice2ZoneComparisonChart()),
          SizedBox(height: spacing),

          // Zone Statistics Summary
          _buildDevice2ZoneSummary(),
        ],
      ),
    );
  }

  Widget _buildDevice2Header() {
    final data = device2AnalyticsData;
    final healthScore = data?.realTimeInsights.deviceHealthScore.overallScore ?? 0.0;
    final healthGrade = data?.realTimeInsights.deviceHealthScore.healthGrade ?? 'N/A';
    final totalReadings = data?.zoneSummary.totalReadings ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Multi-Zone Temperature Monitor',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Monitoring 8 temperature zones | $totalReadings readings',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getHealthColor(healthScore).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getHealthColor(healthScore).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('Health', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                Text('${healthScore.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _getHealthColor(healthScore))),
                Text(healthGrade, style: GoogleFonts.inter(fontSize: 10, color: _getHealthColor(healthScore))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDevice2ZoneGrid() {
    final isMobile = _isMobile(context);
    final data = device2AnalyticsData;

    List<Map<String, dynamic>> zones = [];
    if (data != null) {
      final tempData = data.temperatureAnalytics;
      for (int i = 1; i <= 8; i++) {
        final zoneValues = tempData.getZone(i);
        final currentTemp = zoneValues.isNotEmpty ? zoneValues.last : 0.0;
        final zoneStat = data.zoneSummary.zones.length >= i ? data.zoneSummary.zones[i - 1] : null;
        zones.add({
          'zone': i,
          'name': 'Zone $i',
          'current': currentTemp,
          'avg': zoneStat?.avg ?? 0.0,
          'min': zoneStat?.min ?? 0.0,
          'max': zoneStat?.max ?? 0.0,
          'minTime': zoneStat?.minTime,
          'maxTime': zoneStat?.maxTime,
        });
      }
    } else {
      for (int i = 1; i <= 8; i++) {
        zones.add({'zone': i, 'name': 'Zone $i', 'current': 0.0, 'avg': 0.0, 'min': 0.0, 'max': 0.0, 'minTime': null, 'maxTime': null});
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Zone Temperatures', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 1.0 : 1.1,
            ),
            itemCount: 8,
            itemBuilder: (context, index) => _buildZoneCard(zones[index]),
          ),
        ],
      ),
    );
  }

  String _formatZoneTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null) return '--:--';
    try {
      final dt = DateTime.parse(isoTimestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final temp = zone['current'] as double;
    final minTemp = zone['min'] as double;
    final maxTemp = zone['max'] as double;
    final minTime = zone['minTime'] as String?;
    final maxTime = zone['maxTime'] as String?;
    final isNormal = temp < 5 && temp > -25;
    final color = isNormal ? Constants.ctaColorLight : Colors.red;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(zone['name'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
              Icon(isNormal ? Icons.check_circle : Icons.warning, color: color, size: 12),
            ],
          ),
          SizedBox(height: 2),
          Text('${temp.toStringAsFixed(1)}°C',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          // Min/Max row with timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text("Min", style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[500])),
                  Text("${minTemp.toStringAsFixed(1)}°",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
                  Text(_formatZoneTimestamp(minTime),
                      style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[400])),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                margin: EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
              ),
              Column(
                children: [
                  Text("Max", style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[500])),
                  Text("${maxTemp.toStringAsFixed(1)}°",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red)),
                  Text(_formatZoneTimestamp(maxTime),
                      style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevice2AllZonesChart() {
    final data = device2AnalyticsData;
    if (data == null || data.temperatureAnalytics.labels.isEmpty) {
      return Container(
        height: 300,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final tempData = data.temperatureAnalytics;
    final labels = tempData.labels;

    // Zone colors
    final zoneColors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.pink, Colors.indigo,
    ];

    List<LineChartBarData> lineBars = [];
    for (int i = 1; i <= 8; i++) {
      final zoneValues = tempData.getZone(i);
      if (zoneValues.isNotEmpty) {
        lineBars.add(LineChartBarData(
          spots: List.generate(zoneValues.length, (index) => FlSpot(index.toDouble(), zoneValues[index])),
          isCurved: true,
          color: zoneColors[i - 1],
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }

    return Container(
      height: 300,
      padding: EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 12 ? (labels.length / 6).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    final label = labels[index];
                    final time = label.split(' ').length > 1 ? label.split(' ')[1].substring(0, 5) : label;
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}°',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBars,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) =>
                LineTooltipItem('Zone ${spot.barIndex + 1}: ${spot.y.toStringAsFixed(1)}°C',
                    TextStyle(color: zoneColors[spot.barIndex], fontSize: 12))).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevice2MinMaxChart() {
    final data = device2AnalyticsData;
    if (data == null || data.temperatureAnalytics.labels.isEmpty) {
      return Container(
        height: 250,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final tempData = data.temperatureAnalytics;
    final labels = tempData.labels;
    final minTemp = tempData.minTemperature;
    final maxTemp = tempData.maxTemperature;

    return Container(
      height: 250,
      padding: EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 12 ? (labels.length / 6).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    final label = labels[index];
                    final time = label.split(' ').length > 1 ? label.split(' ')[1].substring(0, 5) : label;
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}°',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(maxTemp.length, (i) => FlSpot(i.toDouble(), maxTemp[i])),
              isCurved: true,
              color: Colors.red,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
            ),
            LineChartBarData(
              spots: List.generate(minTemp.length, (i) => FlSpot(i.toDouble(), minTemp[i])),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) =>
                LineTooltipItem(
                  spot.barIndex == 0 ? 'Max: ${spot.y.toStringAsFixed(1)}°C' : 'Min: ${spot.y.toStringAsFixed(1)}°C',
                  TextStyle(color: spot.barIndex == 0 ? Colors.red : Colors.blue, fontSize: 12),
                )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevice2ZoneComparisonChart() {
    final data = device2AnalyticsData;
    if (data == null || data.zoneSummary.zones.isEmpty) {
      return Container(
        height: 250,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final zones = data.zoneSummary.zones;
    final zoneColors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.pink, Colors.indigo,
    ];

    return Container(
      height: 250,
      padding: EdgeInsets.only(right: 16, top: 16, left: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: zones.map((z) => z.max ?? 0.0).reduce((a, b) => a > b ? a : b) + 5,
          minY: zones.map((z) => z.min ?? 0.0).reduce((a, b) => a < b ? a : b) - 5,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final zone = zones[groupIndex];
                return BarTooltipItem(
                  'Zone ${zone.zone}\nAvg: ${zone.avg?.toStringAsFixed(1)}°C\nMin: ${zone.min?.toStringAsFixed(1)}°C\nMax: ${zone.max?.toStringAsFixed(1)}°C',
                  GoogleFonts.inter(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < zones.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Z${zones[index].zone}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}°',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(zones.length, (index) {
            final zone = zones[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: zone.avg ?? 0.0,
                  color: zoneColors[index % zoneColors.length],
                  width: 20,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDevice2ZoneSummary() {
    final data = device2AnalyticsData;
    final isMobile = _isMobile(context);

    if (data == null || data.zoneSummary.zones.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Center(child: Text('No zone statistics available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final zones = data.zoneSummary.zones;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Zone Statistics', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${data.zoneSummary.totalReadings} readings', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 16),
          // Table header
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Zone', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Min', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Max', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Avg', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          SizedBox(height: 8),
          ...zones.map((zone) {
            final isNormal = (zone.avg ?? 0) < 5 && (zone.avg ?? 0) > -25;
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Zone ${zone.zone}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
                  Expanded(flex: 2, child: Text('${zone.min?.toStringAsFixed(1) ?? '--'}°C', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue))),
                  Expanded(flex: 2, child: Text('${zone.max?.toStringAsFixed(1) ?? '--'}°C', style: GoogleFonts.inter(fontSize: 12, color: Colors.red))),
                  Expanded(flex: 2, child: Text('${zone.avg?.toStringAsFixed(1) ?? '--'}°C', style: GoogleFonts.inter(fontSize: 12))),
                  Expanded(flex: 2, child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isNormal ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isNormal ? 'OK' : 'Alert', style: GoogleFonts.inter(fontSize: 10, color: isNormal ? Colors.green : Colors.red, fontWeight: FontWeight.w500)),
                  )),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Device 3 Dashboard (Ice machine monitoring)
  Widget _buildDevice3Dashboard() {
    final isMobile = _isMobile(context);
    final padding = isMobile ? 12.0 : 16.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with health score
          _buildDevice3Header(),
          SizedBox(height: spacing),

          // Ice Machine Metrics Grid
          _buildDevice3MetricsGrid(),
          SizedBox(height: spacing),

          // All Temperatures Chart
          _buildChart('Temperature Trends', _buildDevice3TemperatureChart()),
          SizedBox(height: spacing),

          // High Side vs Low Side Comparison
          _buildChart('Refrigerant Pressure Temps (HS vs LS)', _buildDevice3PressureTempsChart()),
          SizedBox(height: spacing),

          // Water Level Chart
          _buildChart('Water Level Trends', _buildDevice3WaterLevelChart()),
          SizedBox(height: spacing),

          // Harvest Activity Chart
          _buildChart('Harvest Cycles', _buildDevice3HarvestChart()),
          SizedBox(height: spacing),

          // Summary Statistics
          _buildDevice3SummaryStats(),
        ],
      ),
    );
  }

  Widget _buildDevice3Header() {
    final data = device3AnalyticsData;
    final healthScore = data?.realTimeInsights.deviceHealthScore.overallScore ?? 0.0;
    final healthGrade = data?.realTimeInsights.deviceHealthScore.healthGrade ?? 'N/A';
    final totalReadings = data?.iceMachineSummary.totalReadings ?? 0;
    final totalHarvests = data?.iceMachineSummary.totalHarvests ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ice Machine Monitor',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('$totalReadings readings | $totalHarvests harvest cycles',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getHealthColor(healthScore).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getHealthColor(healthScore).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('Health', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                Text('${healthScore.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _getHealthColor(healthScore))),
                Text(healthGrade, style: GoogleFonts.inter(fontSize: 10, color: _getHealthColor(healthScore))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevice3MetricsGrid() {
    final isMobile = _isMobile(context);
    final data = device3AnalyticsData;
    final summary = data?.iceMachineSummary;
    final tempData = data?.temperatureAnalytics;
    final waterData = data?.waterAnalytics;

    // Get current values (last in series)
    final iceTemp = tempData?.iceTemp.isNotEmpty == true ? tempData!.iceTemp.last : 0.0;
    final hsTemp = tempData?.hsTemp.isNotEmpty == true ? tempData!.hsTemp.last : 0.0;
    final lsTemp = tempData?.lsTemp.isNotEmpty == true ? tempData!.lsTemp.last : 0.0;
    final airTemp = tempData?.airTemp.isNotEmpty == true ? tempData!.airTemp.last : 0.0;
    final waterLevel = waterData?.waterLevel.isNotEmpty == true ? waterData!.waterLevel.last : 0.0;
    final totalHarvests = summary?.totalHarvests ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Readings', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildDevice3MetricCard('Ice Temp', '${iceTemp.toStringAsFixed(1)}°C', Icons.ac_unit, Colors.blue, summary?.iceTemp),
              _buildDevice3MetricCard('High Side', '${hsTemp.toStringAsFixed(1)}°C', Icons.arrow_upward, Colors.orange, summary?.highSideTemp),
              _buildDevice3MetricCard('Low Side', '${lsTemp.toStringAsFixed(1)}°C', Icons.arrow_downward, Colors.cyan, summary?.lowSideTemp),
              _buildDevice3MetricCard('Air Temp', '${airTemp.toStringAsFixed(1)}°C', Icons.air, Colors.green, summary?.airTemp),
              _buildDevice3MetricCard('Water Level', '${waterLevel.toStringAsFixed(1)}%', Icons.water_drop, Colors.indigo, summary?.waterLevel),
              _buildDevice3MetricCard('Harvests', '$totalHarvests', Icons.cyclone, Colors.purple, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevice3MetricCard(String title, String value, IconData icon, Color color, TempStats? stats) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (stats != null)
                Text('Avg: ${stats.avg?.toStringAsFixed(1) ?? '--'}',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDevice3TemperatureChart() {
    final data = device3AnalyticsData;
    if (data == null || data.temperatureAnalytics.labels.isEmpty) {
      return Container(
        height: 300,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final tempData = data.temperatureAnalytics;
    final labels = tempData.labels;

    return Container(
      height: 300,
      padding: EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 12 ? (labels.length / 6).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    final label = labels[index];
                    final time = label.split(' ').length > 1 ? label.split(' ')[1].substring(0, 5) : label;
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}°',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(tempData.hsTemp.length, (i) => FlSpot(i.toDouble(), tempData.hsTemp[i])),
              isCurved: true,
              color: Colors.orange,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(tempData.lsTemp.length, (i) => FlSpot(i.toDouble(), tempData.lsTemp[i])),
              isCurved: true,
              color: Colors.cyan,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(tempData.iceTemp.length, (i) => FlSpot(i.toDouble(), tempData.iceTemp[i])),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(tempData.airTemp.length, (i) => FlSpot(i.toDouble(), tempData.airTemp[i])),
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                final labels = ['High Side', 'Low Side', 'Ice', 'Air'];
                final colors = [Colors.orange, Colors.cyan, Colors.blue, Colors.green];
                return spots.map((spot) =>
                  LineTooltipItem('${labels[spot.barIndex]}: ${spot.y.toStringAsFixed(1)}°C',
                      TextStyle(color: colors[spot.barIndex], fontSize: 11))).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevice3PressureTempsChart() {
    final data = device3AnalyticsData;
    if (data == null || data.temperatureAnalytics.labels.isEmpty) {
      return Container(
        height: 250,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final tempData = data.temperatureAnalytics;
    final labels = tempData.labels;

    return Container(
      height: 250,
      padding: EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 12 ? (labels.length / 6).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    final label = labels[index];
                    final time = label.split(' ').length > 1 ? label.split(' ')[1].substring(0, 5) : label;
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}°',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(tempData.hsTemp.length, (i) => FlSpot(i.toDouble(), tempData.hsTemp[i])),
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
            ),
            LineChartBarData(
              spots: List.generate(tempData.lsTemp.length, (i) => FlSpot(i.toDouble(), tempData.lsTemp[i])),
              isCurved: true,
              color: Colors.cyan,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.cyan.withOpacity(0.1)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) =>
                LineTooltipItem(
                  spot.barIndex == 0 ? 'High Side: ${spot.y.toStringAsFixed(1)}°C' : 'Low Side: ${spot.y.toStringAsFixed(1)}°C',
                  TextStyle(color: spot.barIndex == 0 ? Colors.orange : Colors.cyan, fontSize: 12),
                )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevice3WaterLevelChart() {
    final data = device3AnalyticsData;
    if (data == null || data.waterAnalytics.labels.isEmpty) {
      return Container(
        height: 200,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final waterData = data.waterAnalytics;
    final labels = waterData.labels;
    final levels = waterData.waterLevel;

    return Container(
      height: 200,
      padding: EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 12 ? (labels.length / 6).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    final label = labels[index];
                    final time = label.split(' ').length > 1 ? label.split(' ')[1].substring(0, 5) : label;
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(levels.length, (i) => FlSpot(i.toDouble(), levels[i])),
              isCurved: true,
              color: Colors.indigo,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.indigo.withOpacity(0.3), Colors.indigo.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) =>
                LineTooltipItem('Water Level: ${spot.y.toStringAsFixed(1)}%',
                    TextStyle(color: Colors.indigo, fontSize: 12))).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevice3HarvestChart() {
    final data = device3AnalyticsData;
    if (data == null || data.harvestAnalytics.labels.isEmpty) {
      return Container(
        height: 200,
        child: Center(child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final harvestData = data.harvestAnalytics;
    final labels = harvestData.labels;
    final counts = harvestData.harvestCount;

    return Container(
      height: 200,
      padding: EdgeInsets.only(right: 16, top: 16, left: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b).toDouble() : 10) + 2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = groupIndex < labels.length ? labels[groupIndex] : '';
                return BarTooltipItem(
                  '$label\n${rod.toY.toInt()} harvests',
                  GoogleFonts.inter(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 12 ? (labels.length / 6).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    final label = labels[index];
                    final time = label.split(' ').length > 1 ? label.split(' ')[1].substring(0, 5) : label;
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(time, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600])),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(counts.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: counts[index].toDouble(),
                  color: Colors.purple,
                  width: labels.length > 24 ? 6 : 12,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDevice3SummaryStats() {
    final data = device3AnalyticsData;
    final isMobile = _isMobile(context);

    if (data == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Center(child: Text('No summary available', style: GoogleFonts.inter(color: Colors.grey[600]))),
      );
    }

    final summary = data.iceMachineSummary;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statistics Summary', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${summary.totalReadings} readings', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 16),
          // Table header
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Metric', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Min', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Max', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Avg', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          SizedBox(height: 8),
          _buildDevice3StatRow('High Side Temp', summary.highSideTemp, Colors.orange),
          _buildDevice3StatRow('Low Side Temp', summary.lowSideTemp, Colors.cyan),
          _buildDevice3StatRow('Ice Temp', summary.iceTemp, Colors.blue),
          _buildDevice3StatRow('Air Temp', summary.airTemp, Colors.green),
          _buildDevice3StatRow('Water Level', summary.waterLevel, Colors.indigo, unit: '%'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cyclone, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text('Total Harvest Cycles: ', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
                Text('${summary.totalHarvests}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevice3StatRow(String name, TempStats? stats, Color color, {String unit = '°C'}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          )),
          Expanded(flex: 2, child: Text('${stats?.min?.toStringAsFixed(1) ?? '--'}$unit', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue))),
          Expanded(flex: 2, child: Text('${stats?.max?.toStringAsFixed(1) ?? '--'}$unit', style: GoogleFonts.inter(fontSize: 12, color: Colors.red))),
          Expanded(flex: 2, child: Text('${stats?.avg?.toStringAsFixed(1) ?? '--'}$unit', style: GoogleFonts.inter(fontSize: 12))),
        ],
      ),
    );
  }

  // Device 1 Dashboard (Original refrigeration unit dashboard)
  Widget _buildDevice1Dashboard() {
    final isMobile = _isMobile(context);
    final padding = isMobile ? 12.0 : 16.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          // Real-time Insights Summary Cards
          _buildRealTimeInsightsCards(),
          SizedBox(height: spacing),

          // Enhanced Analytics Section
          _buildEnhancedAnalyticsCards(),
          SizedBox(height: spacing),

          // Peak Performance Summary Card
          _buildPeakPerformanceCard(),
          SizedBox(height: spacing),

          // Temperature Analytics Row
          Row(
            children: [
              Expanded(
                child:
                    _buildChart('Temperature Trends', _buildTemperatureChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: _buildChart2(
                    'Temperature Stability', _buildTemperatureStabilityChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Power Analytics Row
          Row(
            children: [
              Expanded(
                child: _buildChart(
                    'Power Consumption', _buildPowerConsumptionChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: _buildChart('Phase Balance', _buildPhaseBalanceChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Compressor Analytics Row
          Row(
            children: [
              Expanded(
                child: _buildChart(
                    'Compressor Performance', _buildCompressorChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child:
                    _buildChart('Energy Efficiency', _buildEfficiencyChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Door and Ice Analytics Row
          Row(
            children: [
              Expanded(
                child: _buildChart('Door Status', _buildDoorAnalyticsChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: _buildChart('Ice Detection', _buildIceAnalyticsChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Maintenance and Pressure Row
          Row(
            children: [
              Expanded(
                child:
                    _buildChart('Maintenance Alerts', _buildMaintenanceChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: _buildChart('Pressure Analytics', _buildPressureChart()),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Operational Cycles and Correlations Row
          Row(
            children: [
              Expanded(
                child: _buildChart('Correlations', _buildCorrelationsChart()),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Daily Summary
          _buildChart('Daily Summary', _buildDailySummaryChart()),
        ],
      ),
    );
  }

  Widget _buildDoorAnalysisCard() {
    final doorData = analyticsData!.doorAnalytics;
    final operationalData = analyticsData!.operationalCyclesAnalytics;
    final isMobile = _isMobile(context);

    // Calculate total door open time and statistics
    double totalDoorOpenTime = 0;
    double longestDoorOpenTime = 0;
    String longestDoorOpenTimestamp = '';

    // Calculate from operational data if available
    if (operationalData.avgDoorOpenDurationSeconds.isNotEmpty) {
      for (int i = 0;
          i < doorData.doorOpenCount.length &&
              i < operationalData.avgDoorOpenDurationSeconds.length;
          i++) {
        double sessionTime = (doorData.doorOpenCount[i] *
                operationalData.avgDoorOpenDurationSeconds[i]) /
            60; // Convert to minutes
        totalDoorOpenTime += sessionTime;

        if (operationalData.avgDoorOpenDurationSeconds[i] >
            longestDoorOpenTime) {
          longestDoorOpenTime = operationalData.avgDoorOpenDurationSeconds[i];
          if (i < doorData.labels.length) {
            longestDoorOpenTimestamp = doorData.labels[i];
          }
        }
      }
    }

    // Calculate door stability (based on variance of open percentages)
    double avgOpenPercentage = doorData.doorOpenPercentage.isNotEmpty
        ? doorData.doorOpenPercentage.reduce((a, b) => a + b) /
            doorData.doorOpenPercentage.length
        : 0;

    double variance = 0;
    if (doorData.doorOpenPercentage.length > 1) {
      for (double percentage in doorData.doorOpenPercentage) {
        variance +=
            (percentage - avgOpenPercentage) * (percentage - avgOpenPercentage);
      }
      variance = variance / doorData.doorOpenPercentage.length;
    }

    String stabilityStatus = variance < 5
        ? 'Stable'
        : variance < 15
            ? 'Moderate'
            : 'Unstable';

    bool isUnstable = variance >= 15;
    bool hasLongOpenings = longestDoorOpenTime > 300; // 5 minutes

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isUnstable || hasLongOpenings)
              ? const Color(0xFFEF4444)
              : const Color(0xFFF1F5F9),
          width: (isUnstable || hasLongOpenings) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isUnstable || hasLongOpenings)
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.door_front_door_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Door Analysis',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnstable
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stabilityStatus.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Main door metrics - First row
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildMetricCard(
                          'Total Opens',
                          '${doorData.doorOpenCount.fold(0, (sum, count) => sum + count)}',
                          'Avg: ${(doorData.doorOpenCount.fold(0, (sum, count) => sum + count) / doorData.doorOpenCount.length).toStringAsFixed(1)}/period',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Total Closes',
                          '${doorData.doorClosedCount.fold(0, (sum, count) => sum + count)}',
                          'Avg: ${(doorData.doorClosedCount.fold(0, (sum, count) => sum + count) / doorData.doorClosedCount.length).toStringAsFixed(1)}/period',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Total Open Time',
                          totalDoorOpenTime > 60
                              ? '${(totalDoorOpenTime / 60).toStringAsFixed(1)} hours'
                              : '${totalDoorOpenTime.toStringAsFixed(1)} minutes',
                          'Avg: ${avgOpenPercentage.toStringAsFixed(1)}% open',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildMetricCard(
                          'Total Opens',
                          '${doorData.doorOpenCount.fold(0, (sum, count) => sum + count)}',
                          'Avg: ${(doorData.doorOpenCount.fold(0, (sum, count) => sum + count) / doorData.doorOpenCount.length).toStringAsFixed(1)}/period',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Total Closes',
                          '${doorData.doorClosedCount.fold(0, (sum, count) => sum + count)}',
                          'Avg: ${(doorData.doorClosedCount.fold(0, (sum, count) => sum + count) / doorData.doorClosedCount.length).toStringAsFixed(1)}/period',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Total Open Time',
                          totalDoorOpenTime > 60
                              ? '${(totalDoorOpenTime / 60).toStringAsFixed(1)} hours'
                              : '${totalDoorOpenTime.toStringAsFixed(1)} minutes',
                          'Avg: ${avgOpenPercentage.toStringAsFixed(1)}% open',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // Second row
            isMobile
                ? _buildMetricCard(
                    'Longest Opening',
                    '${(longestDoorOpenTime / 60).toStringAsFixed(1)} minutes',
                    'Time: ${_formatTimestamp(longestDoorOpenTimestamp)}',
                  )
                : Row(
                    children: [
                      _buildMetricCard(
                        'Longest Opening',
                        '${(longestDoorOpenTime / 60).toStringAsFixed(1)} minutes',
                        'Time: ${_formatTimestamp(longestDoorOpenTimestamp)}',
                      ),
                      const SizedBox(width: 12),
                      // Add some padding to balance the row
                      Expanded(child: Container()),
                      Expanded(child: Container()),
                    ],
                  ),
            const SizedBox(height: 16),

            // Stability analysis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnstable
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnstable
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: isUnstable
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stability Analysis (${variance.toStringAsFixed(1)}% variance)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDoorStabilityDescription(
                              stabilityStatus, variance),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAnalyticsCards() {
    final enhanced = analyticsData!.enhancedCompressorAnalytics;

    return Column(
      children: [
        // Temperature Details Card
        _buildTemperatureDetailsCard(),
        const SizedBox(height: 12),

        // Pressure Details Card
        _buildPressureDetailsCard(),
        const SizedBox(height: 12),

        // Compressor Details Card
        _buildCompressorDetailsCard(),
        const SizedBox(height: 12),

        // Door Analysis Card
        _buildDoorAnalysisCard(),
        const SizedBox(height: 12),

        // Enhanced Overview Card
        _buildEnhancedCompressorDetailsCard(),
      ],
    );
  }

  Widget _buildEnhancedCompressorDetailsCard() {
    final enhanced = analyticsData!.enhancedCompressorAnalytics;
    final tempAnalytics = analyticsData!.enhancedTemperatureAnalytics;
    final pressureAnalytics = analyticsData!.enhancedPressureAnalytics;
    final isMobile = _isMobile(context);

    // Check for any critical conditions
    bool hasCriticalCondition = enhanced.statistics.dutyCyclePercentage > 80 ||
        enhanced.currentStatus.currentTotalAmps > 30 ||
        tempAnalytics.avgTemperature > 8 ||
        pressureAnalytics.avgPressureDifferential > 50;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCriticalCondition
              ? const Color(0xFFEF4444)
              : const Color(0xFFF1F5F9),
          width: hasCriticalCondition ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasCriticalCondition
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enhanced Analytics Overview',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (hasCriticalCondition)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CRITICAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Compressor Status Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: enhanced.currentStatus.isRunning
                    ? const Color(0xFFFAFAFA)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enhanced.currentStatus.isRunning
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compressor Status',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          enhanced.currentStatus.isRunning
                              ? "Currently Running"
                              : "Currently Stopped",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${enhanced.currentStatus.currentTotalAmps.toStringAsFixed(1)}A Total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Grid
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildMetricCard(
                          'Duty Cycle',
                          '${enhanced.statistics.dutyCyclePercentage.toStringAsFixed(1)}%',
                          '${enhanced.statistics.totalStartCycles} cycles',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Avg Air Temperature',
                          '${tempAnalytics.avgAirTemperature.toStringAsFixed(1)}°C',
                          '±${tempAnalytics.temperatureVariance.toStringAsFixed(1)}',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Avg Pressure',
                          '${pressureAnalytics.avgPressureDifferential.toStringAsFixed(1)} PSI',
                          'Differential',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildMetricCard(
                          'Duty Cycle',
                          '${enhanced.statistics.dutyCyclePercentage.toStringAsFixed(1)}%',
                          '${enhanced.statistics.totalStartCycles} cycles',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Avg Air Temperature',
                          '${tempAnalytics.avgAirTemperature.toStringAsFixed(1)}°C',
                          '±${tempAnalytics.temperatureVariance.toStringAsFixed(1)}',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          'Avg Pressure',
                          '${pressureAnalytics.avgPressureDifferential.toStringAsFixed(1)} PSI',
                          'Differential',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDoorStabilityDescription(String status, double variance) {
    switch (status) {
      case 'Stable':
        return 'Door usage patterns are consistent with low variance. This indicates predictable usage patterns.';
      case 'Moderate':
        return 'Door usage shows moderate variation. Some fluctuation in usage patterns observed.';
      case 'Unstable':
        return 'Door usage is highly variable. Consider investigating usage patterns or potential issues.';
      default:
        return 'Door usage analysis unavailable.';
    }
  }

  Widget _buildRealTimeInsightsCards() {
    final insights = analyticsData!.realTimeInsights;
    final isMobile = _isMobile(context);

    // Check for any critical issues
    bool hasCriticalIssue =
        insights.maintenanceUrgency.urgencyLevel.toLowerCase() == 'critical' ||
            insights.deviceHealthScore.overallScore < 50 ||
            insights.efficiencyRating.efficiencyScore < 40;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCriticalIssue
              ? const Color(0xFFEF4444)
              : const Color(0xFFF1F5F9),
          width: hasCriticalIssue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasCriticalIssue
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Real-Time Device Insights',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (hasCriticalIssue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CRITICAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Insights metrics
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        _buildInsightMetricCard(
                          'Health Score',
                          '${insights.deviceHealthScore.overallScore.toStringAsFixed(0)}/100',
                          insights.deviceHealthScore.healthGrade,
                          Icons.favorite_rounded,
                          _isHealthCritical(insights.deviceHealthScore.healthGrade),
                        ),
                        const SizedBox(height: 12),
                        _buildInsightMetricCard(
                          'Efficiency',
                          '${insights.efficiencyRating.efficiencyScore.toStringAsFixed(0)}/100',
                          insights.efficiencyRating.efficiencyGrade,
                          Icons.eco_rounded,
                          _isEfficiencyCritical(
                              insights.efficiencyRating.efficiencyGrade),
                        ),
                        const SizedBox(height: 12),
                        _buildInsightMetricCard(
                          'Maintenance',
                          '${insights.maintenanceUrgency.totalAlerts} alerts',
                          insights.maintenanceUrgency.urgencyLevel,
                          Icons.build_rounded,
                          _isMaintenanceCritical(
                              insights.maintenanceUrgency.urgencyLevel),
                        ),
                        const SizedBox(height: 12),
                        _buildInsightMetricCard(
                          'Annual Cost',
                          'R${insights.energyCostEstimate.annualCostUsd.toStringAsFixed(0)}',
                          'Estimated',
                          Icons.attach_money_rounded,
                          false,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildInsightMetricCard(
                          'Health Score',
                          '${insights.deviceHealthScore.overallScore.toStringAsFixed(0)}/100',
                          insights.deviceHealthScore.healthGrade,
                          Icons.favorite_rounded,
                          _isHealthCritical(insights.deviceHealthScore.healthGrade),
                        ),
                        const SizedBox(width: 12),
                        _buildInsightMetricCard(
                          'Efficiency',
                          '${insights.efficiencyRating.efficiencyScore.toStringAsFixed(0)}/100',
                          insights.efficiencyRating.efficiencyGrade,
                          Icons.eco_rounded,
                          _isEfficiencyCritical(
                              insights.efficiencyRating.efficiencyGrade),
                        ),
                        const SizedBox(width: 12),
                        _buildInsightMetricCard(
                          'Maintenance',
                          '${insights.maintenanceUrgency.totalAlerts} alerts',
                          insights.maintenanceUrgency.urgencyLevel,
                          Icons.build_rounded,
                          _isMaintenanceCritical(
                              insights.maintenanceUrgency.urgencyLevel),
                        ),
                        const SizedBox(width: 12),
                        _buildInsightMetricCard(
                          'Annual Cost',
                          'R${insights.energyCostEstimate.annualCostUsd.toStringAsFixed(0)}',
                          'Estimated',
                          Icons.attach_money_rounded,
                          false,
                        ),
                      ],
                    ),
            ),

            // Recommendation section
            if (insights.maintenanceUrgency.recommendedAction.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isMaintenanceCritical(
                          insights.maintenanceUrgency.urgencyLevel)
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isMaintenanceCritical(
                            insights.maintenanceUrgency.urgencyLevel)
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _isMaintenanceCritical(
                              insights.maintenanceUrgency.urgencyLevel)
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended Action',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insights.maintenanceUrgency.recommendedAction,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    bool isError,
  ) {
    final isMobile = _isMobile(context);

    final cardContent = Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isError ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  isError ? const Color(0xFFEF4444) : const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return isMobile ? cardContent : Expanded(child: cardContent);
  }

  bool _isHealthCritical(String grade) {
    return grade.toUpperCase() == 'D' || grade.toUpperCase() == 'F';
  }

  bool _isEfficiencyCritical(String grade) {
    return grade.toLowerCase() == 'poor' || grade.toLowerCase() == 'critical';
  }

  bool _isMaintenanceCritical(String level) {
    return level.toLowerCase() == 'critical' || level.toLowerCase() == 'high';
  }

  Widget _buildOperationalCyclesChart() {
    final data = analyticsData!.operationalCyclesAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Operational Cycles',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFF64748B), 'Compressor Starts'),
                const SizedBox(width: 24),
                _buildLegendItem(const Color(0xFF94A3B8), 'Door Opens'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Cycle Count',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time Period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  barGroups:
                      data.compressorStartCycles.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          color: const Color(0xFF64748B),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: data.doorOpenCycles[e.key].toDouble(),
                          color: const Color(0xFF94A3B8),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationsChart() {
    final data = analyticsData!.correlationsAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Correlations',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFF64748B), 'Temp-Power'),
                const SizedBox(width: 24),
                _buildLegendItem(const Color(0xFF94A3B8), 'Door Impact'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Correlation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time Period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.tempPowerCorrelation
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF64748B),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: data.doorTempImpact
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF94A3B8),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakPerformanceCard() {
    final peak = analyticsData!.peakPerformanceAnalytics;

    // Check for critical peak values
    bool hasCriticalPeak =
        peak.peakPowerConsumption > 25 || peak.highestTemperatureReached > 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCriticalPeak
              ? const Color(0xFFEF4444)
              : const Color(0xFFF1F5F9),
          width: hasCriticalPeak ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasCriticalPeak
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Peak Performance Summary',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (hasCriticalPeak)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HIGH PEAKS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _buildMetricCard(
                  'Peak Power',
                  '${peak.peakPowerConsumption.toStringAsFixed(1)} A',
                  'Maximum consumption',
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  'Lowest Air Temp',
                  '${peak.lowestTemperatureReached.toStringAsFixed(1)}°C',
                  'Minimum reached',
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  'Highest Air Temp',
                  '${peak.highestTemperatureReached.toStringAsFixed(1)}°C',
                  'Maximum reached',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(String title, Widget chart) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildChart2(String title, Widget chart) {
    return Container(
      height: 700,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildIceAnalyticsChart() {
    final data = analyticsData!.iceAnalytics;
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.lightBlue, 'Ice Buildup Percentage'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Percentage (%)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Time Period',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              barGroups: data.icePercentage.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: Colors.lightBlue,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceChart() {
    final data = analyticsData!.maintenanceIndicatorsAnalytics;
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.red, 'High Temp'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange, 'High Pressure'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.purple, 'High Power'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Alert Count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Time Period',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              barGroups: data.highTempAlerts.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: Colors.red,
                      width: 6,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: data.highPressureAlerts[e.key].toDouble(),
                      color: Colors.orange,
                      width: 6,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: data.highPowerConsumptionAlerts[e.key].toDouble(),
                      color: Colors.purple,
                      width: 6,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPressureChart() {
    final data = analyticsData!.pressureAnalytics;
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.red, 'High Pressure'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.blue, 'Low Pressure'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Pressure (PSI)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Time (Hours)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: data.avgPressureHigh
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: data.avgPressureLow
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryChart() {
    final data = analyticsData!.dailySummaryAnalytics;
    return Column(
      children: [
        // Legend

        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(Colors.blue, 'Daily Avg Temperature'),
                    Text(
                      'Daily Average Temperature',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toStringAsFixed(2)}°C',
                                  style: GoogleFonts.inter(fontSize: 8),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 20,
                                getTitlesWidget: (value, meta) => Text(
                                  'D${value.toInt() + 1}',
                                  style: GoogleFonts.inter(fontSize: 8),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          barGroups: data.dailyAvgTemp.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: Colors.blue,
                                  width: 12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(Colors.green, 'Daily Duty Cycle'),
                    Text(
                      'Daily Duty Cycle',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toStringAsFixed(2)}%',
                                  style: GoogleFonts.inter(fontSize: 8),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 20,
                                getTitlesWidget: (value, meta) => Text(
                                  'D${value.toInt() + 1}',
                                  style: GoogleFonts.inter(fontSize: 8),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          barGroups:
                              data.dailyDutyCycle.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: Colors.green,
                                  width: 12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for creating legend items
  Widget _buildLegendItem2(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem3(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureChart() {
    final data = analyticsData!.temperatureAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.thermostat_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Temperature Trends',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, 'Drain Temperature'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.orange, 'Air Temp'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.green, 'Coil Temp'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Temperature (°C)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time of Day',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt().toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.avgDrainTemperature
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: data.avgAirTemperature
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: data.avgCoilTemperature
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureStabilityChart() {
    final data = analyticsData!.temperatureStabilityAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Temperature Stability',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                _buildLegendItem(Colors.purple, 'Main Temp'),
                _buildLegendItem(Colors.blue, 'Air Temp'),
                _buildLegendItem(Colors.orange, 'Coil Temp'),
                _buildLegendItem(Colors.green, 'Drain Temp'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Variance (°C²)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time Period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  barGroups: data.tempVariance.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: Colors.purple,
                          width: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: e.key < data.airTempVariance.length
                              ? data.airTempVariance[e.key]
                              : 0,
                          color: Colors.blue,
                          width: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: e.key < data.coilTempVariance.length
                              ? data.coilTempVariance[e.key]
                              : 0,
                          color: Colors.orange,
                          width: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: e.key < data.drainTempVariance.length
                              ? data.drainTempVariance[e.key]
                              : 0,
                          color: Colors.green,
                          width: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Section
            Text(
              'Temperature Statistics',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Stats in single row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Spikes',
                    data.tempSpikeCount
                        .fold(0, (sum, count) => sum + count)
                        .toString(),
                    'Temperature spikes',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Max Fluctuation',
                    data.tempFluctuationRate.isNotEmpty
                        ? '${data.tempFluctuationRate.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}°C/h'
                        : '0.00°C/h',
                    'Rate of change',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Air Temp Diff',
                    data.airTempDifference.isNotEmpty
                        ? '${data.airTempDifference.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}°C'
                        : '0.00°C',
                    'Air temperature delta',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Coil Temp Diff',
                    data.coilTempDifference.isNotEmpty
                        ? '${data.coilTempDifference.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}°C'
                        : '0.00°C',
                    'Coil temperature delta',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerConsumptionChart() {
    final data = analyticsData!.powerConsumptionAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Power Consumption',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.red, 'Total Power Consumption'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Power (kW)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time of Day',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt().toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.totalPowerAvg
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseBalanceChart() {
    final data = analyticsData!.phaseBalanceAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.electrical_services_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Phase Balance',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.red, 'Phase 1'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.yellow, 'Phase 2'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.blue, 'Phase 3'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Current (A)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time of Day',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt().toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.avgPh1
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: data.avgPh2
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: false,
                      color: Colors.yellow,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: data.avgPh3
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressorChart() {
    final data = analyticsData!.compressorAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Compressor Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Compressor On'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.red.shade400, 'Compressor Off'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Count',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time Period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  barGroups: data.compressorOnCount.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        // Compressor On
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          color: Colors.green,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Compressor Off
                        BarChartRodData(
                          toY: e.key < data.compressorOffCount.length
                              ? data.compressorOffCount[e.key].toDouble()
                              : 0.0,
                          color: Colors.red.shade400,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyChart() {
    final data = analyticsData!.energyEfficiencyAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Energy Efficiency',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.teal, 'Compressor Duty Cycle'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Duty Cycle (%)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time of Day',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt().toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.compressorDutyCycle
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorAnalyticsChart() {
    final data = analyticsData!.doorAnalytics;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.door_front_door_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Door Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.amber, 'Door Opens'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.blueGrey, 'Door Closes'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Count',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Time Period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1),
                  ),
                  barGroups: data.doorOpenCount.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        // Door Opens
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          color: Colors.amber,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Door Closes
                        BarChartRodData(
                          toY: e.key < data.doorClosedCount.length
                              ? data.doorClosedCount[e.key].toDouble()
                              : 0.0,
                          color: Colors.blueGrey,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCompressorSection(
      String title, String value, String subtitle, IconData icon) {
    final isMobile = _isMobile(context);
    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(String isoString) {
  if (isoString.isEmpty) return 'Unknown';
  try {
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return 'Invalid Date';
  }
}
