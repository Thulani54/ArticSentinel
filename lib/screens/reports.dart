import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../constants/models/device.dart';

class DevicePerformanceData {
  final String deviceId;
  final String deviceName;
  final double avgTemperature;
  final double minTemperature;
  final double maxTemperature;
  final double avgPressure;
  final int doorOpenCount;
  final double powerConsumption;
  final double uptime;
  final String healthGrade;
  final List<Map<String, dynamic>>? dailyTemperatureData;
  final List<Map<String, dynamic>>? dailyPressureData;
  final List<Map<String, dynamic>>? dailyDoorData;
  final List<Map<String, dynamic>>? dailyPowerData;
  final List<Map<String, dynamic>>? dailyUptimeData;

  DevicePerformanceData({
    required this.deviceId,
    required this.deviceName,
    required this.avgTemperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.avgPressure,
    required this.doorOpenCount,
    required this.powerConsumption,
    required this.uptime,
    required this.healthGrade,
    this.dailyTemperatureData,
    this.dailyPressureData,
    this.dailyDoorData,
    this.dailyPowerData,
    this.dailyUptimeData,
  });
}

// API Service for Device Performance
class DevicePerformanceApiService {
  static String baseUrl = Constants.articBaseUrl2;

  static Future<List<DeviceModel3>> getDevices(int businessId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_devices_by_client/$businessId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var responsedata = jsonDecode(response.body);
        List<DeviceModel3> devices = [];

        for (var device in responsedata) {
          DeviceModel3 deviceModel = DeviceModel3.fromJson(device);
          devices.add(deviceModel);
        }

        return devices;
      } else {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching devices: $e');
    }
  }

  static Future<DevicePerformanceData> getDevicePerformance({
    required String deviceId,
    required String deviceName,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url =
          '$baseUrl/api/devices/$deviceId/analytics/?start_date=$startDate&end_date=$endDate';
      print('Fetching device performance from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('API Response: ${response.body}');
        final data = json.decode(response.body);

        // Extract temperature analytics
        final tempAnalytics = data['temperature_analytics'] ?? {};
        final avgTemp =
            (tempAnalytics['average_temperature'] ?? 0.0).toDouble();
        final minTemp = (tempAnalytics['min_temperature'] ?? 0.0).toDouble();
        final maxTemp = (tempAnalytics['max_temperature'] ?? 0.0).toDouble();

        // Extract pressure analytics
        final pressureAnalytics = data['pressure_analytics'] ?? {};
        final avgPressure =
            (pressureAnalytics['average_pressure'] ?? 0.0).toDouble();

        // Extract door analytics
        final doorAnalytics = data['door_analytics'] ?? {};
        final doorOpenCount = doorAnalytics['open_count'] ?? 0;

        // Extract power consumption
        final powerAnalytics = data['power_consumption_analytics'] ?? {};
        final powerConsumption =
            (powerAnalytics['total_consumption'] ?? 0.0).toDouble();

        // Extract uptime
        final compressorAnalytics = data['compressor_analytics'] ?? {};
        final uptime =
            (compressorAnalytics['uptime_percentage'] ?? 0.0).toDouble();

        // Extract health score
        final deviceHealth = data['device_health_score'] ?? {};
        final healthGrade = deviceHealth['health_grade'] ?? 'N/A';

        // Extract daily data
        final dailyTempData = tempAnalytics['daily_data'] as List<dynamic>?;
        final dailyPresData = pressureAnalytics['daily_data'] as List<dynamic>?;
        final dailyDoorData = doorAnalytics['daily_data'] as List<dynamic>?;
        final dailyPowData = powerAnalytics['daily_data'] as List<dynamic>?;
        final dailyUptimeData =
            compressorAnalytics['daily_data'] as List<dynamic>?;

        return DevicePerformanceData(
          deviceId: deviceId,
          deviceName: deviceName,
          avgTemperature: avgTemp,
          minTemperature: minTemp,
          maxTemperature: maxTemp,
          avgPressure: avgPressure,
          doorOpenCount: doorOpenCount,
          powerConsumption: powerConsumption,
          uptime: uptime,
          healthGrade: healthGrade,
          dailyTemperatureData:
              dailyTempData?.map((e) => e as Map<String, dynamic>).toList(),
          dailyPressureData:
              dailyPresData?.map((e) => e as Map<String, dynamic>).toList(),
          dailyDoorData:
              dailyDoorData?.map((e) => e as Map<String, dynamic>).toList(),
          dailyPowerData:
              dailyPowData?.map((e) => e as Map<String, dynamic>).toList(),
          dailyUptimeData:
              dailyUptimeData?.map((e) => e as Map<String, dynamic>).toList(),
        );
      } else {
        print(
            'Failed to load device analytics. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load device analytics');
      }
    } catch (e) {
      // Log the error for debugging
      print('ERROR in getDevicePerformance for device $deviceId: $e');

      // Return default data on error
      return DevicePerformanceData(
        deviceId: deviceId,
        deviceName: deviceName,
        avgTemperature: 0.0,
        minTemperature: 0.0,
        maxTemperature: 0.0,
        avgPressure: 0.0,
        doorOpenCount: 0,
        powerConsumption: 0.0,
        uptime: 0.0,
        healthGrade: 'N/A',
      );
    }
  }
}

// Temperature Analysis Data Model
class TemperatureAnalysisData {
  final String deviceId;
  final String deviceName;
  final double avgTemperature;
  final double minTemperature;
  final double maxTemperature;
  final double stdDeviation;
  final int totalReadings;
  final Map<String, dynamic> sensorStats;
  final List<Map<String, dynamic>> dailyTrends;
  final Map<String, dynamic> violations;
  final Map<String, dynamic> timeInRanges;

  TemperatureAnalysisData({
    required this.deviceId,
    required this.deviceName,
    required this.avgTemperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.stdDeviation,
    required this.totalReadings,
    required this.sensorStats,
    required this.dailyTrends,
    required this.violations,
    required this.timeInRanges,
  });
}

// Temperature Analysis API Service
class TemperatureAnalysisApiService {
  static String baseUrl = Constants.articBaseUrl2;

  static Future<TemperatureAnalysisData> getTemperatureAnalysis({
    required String deviceId,
    required String deviceName,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url =
          '$baseUrl/api/devices/$deviceId/temperature-analytics/?start_date=$startDate&end_date=$endDate';
      print('Fetching temperature analysis from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Temperature Analysis API Response received');
        final data = json.decode(response.body);

        final overallStats = data['overall_statistics'] ?? {};
        final sensorStats = data['sensor_statistics'] ?? {};
        final violations = data['violations'] ?? {};
        final timeInRanges = data['time_in_ranges'] ?? {};
        final dailyTrends = (data['daily_trends'] as List<dynamic>?) ?? [];

        return TemperatureAnalysisData(
          deviceId: deviceId,
          deviceName: deviceName,
          avgTemperature:
              (overallStats['average_temperature'] ?? 0.0).toDouble(),
          minTemperature: (overallStats['min_temperature'] ?? 0.0).toDouble(),
          maxTemperature: (overallStats['max_temperature'] ?? 0.0).toDouble(),
          stdDeviation: (overallStats['std_deviation'] ?? 0.0).toDouble(),
          totalReadings: overallStats['total_readings'] ?? 0,
          sensorStats: sensorStats,
          dailyTrends:
              dailyTrends.map((e) => e as Map<String, dynamic>).toList(),
          violations: violations,
          timeInRanges: timeInRanges,
        );
      } else {
        print(
            'Failed to load temperature analysis. Status: ${response.statusCode}');
        throw Exception('Failed to load temperature analysis');
      }
    } catch (e) {
      print('ERROR in getTemperatureAnalysis: $e');
      // Return default data on error
      return TemperatureAnalysisData(
        deviceId: deviceId,
        deviceName: deviceName,
        avgTemperature: 0.0,
        minTemperature: 0.0,
        maxTemperature: 0.0,
        stdDeviation: 0.0,
        totalReadings: 0,
        sensorStats: {},
        dailyTrends: [],
        violations: {},
        timeInRanges: {},
      );
    }
  }
}

// Alerts Summary Data Model
class AlertsSummaryData {
  final Map<String, dynamic> overallStats;
  final List<Map<String, dynamic>> alertsBySeverity;
  final List<Map<String, dynamic>> alertsByDevice;
  final List<Map<String, dynamic>> alertsByType;
  final List<Map<String, dynamic>> dailyTrend;
  final List<Map<String, dynamic>> hourlyDistribution;
  final List<Map<String, dynamic>> recentActiveAlerts;

  AlertsSummaryData({
    required this.overallStats,
    required this.alertsBySeverity,
    required this.alertsByDevice,
    required this.alertsByType,
    required this.dailyTrend,
    required this.hourlyDistribution,
    required this.recentActiveAlerts,
  });
}

// Alerts Summary API Service
class AlertsSummaryApiService {
  static String baseUrl = Constants.articBaseUrl2;

  static Future<AlertsSummaryData> getAlertsSummary({
    required int businessId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url =
          '$baseUrl/api/alerts/summary/?business_id=$businessId&start_date=$startDate&end_date=$endDate';
      print('Fetching alerts summary from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Alerts Summary API Response received');
        final data = json.decode(response.body);

        return AlertsSummaryData(
          overallStats: data['overall_statistics'] ?? {},
          alertsBySeverity: (data['alerts_by_severity'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          alertsByDevice: (data['alerts_by_device'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          alertsByType: (data['alerts_by_type'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          dailyTrend: (data['daily_trend'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          hourlyDistribution: (data['hourly_distribution'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          recentActiveAlerts: (data['recent_active_alerts'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
        );
      } else {
        print('Failed to load alerts summary. Status: ${response.statusCode}');
        throw Exception('Failed to load alerts summary');
      }
    } catch (e) {
      print('ERROR in getAlertsSummary: $e');
      // Return default data on error
      return AlertsSummaryData(
        overallStats: {},
        alertsBySeverity: [],
        alertsByDevice: [],
        alertsByType: [],
        dailyTrend: [],
        hourlyDistribution: [],
        recentActiveAlerts: [],
      );
    }
  }
}

// Maintenance Report Data Model
class MaintenanceReportData {
  final Map<String, dynamic> overallStats;
  final List<Map<String, dynamic>> maintenanceByType;
  final List<Map<String, dynamic>> maintenanceByDevice;
  final List<Map<String, dynamic>> maintenanceByPriority;
  final List<Map<String, dynamic>> monthlyTrend;
  final Map<String, dynamic> costAnalysis;
  final Map<String, dynamic> durationAnalysis;
  final List<Map<String, dynamic>> recentCompleted;
  final List<Map<String, dynamic>> upcomingMaintenance;
  final List<Map<String, dynamic>> overdueMaintenance;

  MaintenanceReportData({
    required this.overallStats,
    required this.maintenanceByType,
    required this.maintenanceByDevice,
    required this.maintenanceByPriority,
    required this.monthlyTrend,
    required this.costAnalysis,
    required this.durationAnalysis,
    required this.recentCompleted,
    required this.upcomingMaintenance,
    required this.overdueMaintenance,
  });
}

// Maintenance Report API Service
class MaintenanceReportApiService {
  static String baseUrl = Constants.articBaseUrl2;

  static Future<MaintenanceReportData> getMaintenanceReport({
    required int businessId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url = '$baseUrl/api/maintenance/report/?business_id=$businessId&start_date=$startDate&end_date=$endDate';
      print('Fetching maintenance report from: $url');

      final response = await http.get(Uri.parse(url));
      print('Maintenance report response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return MaintenanceReportData(
          overallStats: data['overall_statistics'] ?? {},
          maintenanceByType: (data['maintenance_by_type'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          maintenanceByDevice: (data['maintenance_by_device'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          maintenanceByPriority: (data['maintenance_by_priority'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          monthlyTrend: (data['monthly_trend'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          costAnalysis: data['cost_analysis'] ?? {},
          durationAnalysis: data['duration_analysis'] ?? {},
          recentCompleted: (data['recent_completed'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          upcomingMaintenance: (data['upcoming_maintenance'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
          overdueMaintenance: (data['overdue_maintenance'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
        );
      } else {
        print('Failed to load maintenance report. Status: ${response.statusCode}');
        throw Exception('Failed to load maintenance report');
      }
    } catch (e) {
      print('ERROR in getMaintenanceReport: $e');
      // Return default data on error
      return MaintenanceReportData(
        overallStats: {},
        maintenanceByType: [],
        maintenanceByDevice: [],
        maintenanceByPriority: [],
        monthlyTrend: [],
        costAnalysis: {},
        durationAnalysis: {},
        recentCompleted: [],
        upcomingMaintenance: [],
        overdueMaintenance: [],
      );
    }
  }
}

// API Service for Report Management
class ReportApiService {
  static String baseUrl = Constants.articBaseUrl2;

  static Future<Map<String, dynamic>> saveReport({
    required String reportType,
    required String reportName,
    required int businessId,
    required List<String> deviceIds,
    required String startDate,
    required String endDate,
    required String period,
    required bool includeCharts,
    required bool includeRawData,
    required Map<String, dynamic> reportData,
    required String generatedBy,
    required int pageCount,
    required String fileSize,
  }) async {
    try {
      final url = '${baseUrl}api/reports/generate/';
      print('Saving report to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'report_type': reportType,
          'report_name': reportName,
          'business_id': businessId,
          'device_ids': deviceIds,
          'start_date': startDate,
          'end_date': endDate,
          'period': period,
          'include_charts': includeCharts,
          'include_raw_data': includeRawData,
          'report_data': reportData,
          'generated_by': generatedBy,
          'page_count': pageCount,
          'file_size': fileSize,
        }),
      );

      if (response.statusCode == 201) {
        print('Report saved successfully');
        return json.decode(response.body);
      } else {
        print(
            'Failed to save report. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to save report');
      }
    } catch (e) {
      print('ERROR in saveReport: $e');
      throw Exception('Error saving report: $e');
    }
  }

  static Future<List<dynamic>> getReportHistory({
    required int businessId,
    String? reportType,
    int limit = 50,
  }) async {
    try {
      var url = '${baseUrl}api/reports/history/$businessId/?limit=$limit';
      if (reportType != null && reportType.isNotEmpty) {
        url += '&report_type=$reportType';
      }

      print('Fetching report history from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reports'] ?? [];
      } else {
        print('Failed to load report history. Status: ${response.statusCode}');
        throw Exception('Failed to load report history');
      }
    } catch (e) {
      print('ERROR in getReportHistory: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getReportDetail(String reportId) async {
    try {
      final url = '${baseUrl}api/reports/$reportId/';
      print('Fetching report detail from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load report detail. Status: ${response.statusCode}');
        throw Exception('Failed to load report detail');
      }
    } catch (e) {
      print('ERROR in getReportDetail: $e');
      throw Exception('Error fetching report detail: $e');
    }
  }

  static Future<void> deleteReport(String reportId) async {
    try {
      final url = '${baseUrl}api/reports/$reportId/delete/';
      print('Deleting report: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Report deleted successfully');
      } else {
        print('Failed to delete report. Status: ${response.statusCode}');
        throw Exception('Failed to delete report');
      }
    } catch (e) {
      print('ERROR in deleteReport: $e');
      throw Exception('Error deleting report: $e');
    }
  }
}

class ReportType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  ReportType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class Reports extends StatefulWidget {
  final int companyId;

  const Reports({Key? key, this.companyId = 1}) : super(key: key);

  @override
  State<Reports> createState() => _ReportsState();
}

class ScheduledReport {
  final String id;
  final String name;
  final String frequency;
  final String nextRun;
  final String format;
  final bool isActive;
  final IconData icon;
  final Color color;

  ScheduledReport({
    required this.id,
    required this.name,
    required this.frequency,
    required this.nextRun,
    required this.format,
    required this.isActive,
    required this.icon,
    required this.color,
  });
}

class DownloadedReport {
  final String id;
  final String name;
  final String downloadedBy;
  final String downloadDate;
  final String fileSize;
  final String format;
  final IconData icon;
  final Color color;

  DownloadedReport({
    required this.id,
    required this.name,
    required this.downloadedBy,
    required this.downloadDate,
    required this.fileSize,
    required this.format,
    required this.icon,
    required this.color,
  });
}

class GeneratedReport {
  final String id;
  final String name;
  final String generatedBy;
  final String generatedDate;
  final String status;
  final String fileSize;
  final String format;
  final IconData icon;
  final Color color;

  GeneratedReport({
    required this.id,
    required this.name,
    required this.generatedBy,
    required this.generatedDate,
    required this.status,
    required this.fileSize,
    required this.format,
    required this.icon,
    required this.color,
  });
}

class _ReportsState extends State<Reports> {
  String selectedPeriod = 'Last 7 Days';
  String? selectedReportType;
  bool isGenerating = false;
  int currentPage = 0;
  int downloadsCurrentPage = 0;
  int generatedCurrentPage = 0;
  int itemsPerPage = 5;

  // Store generated report data
  List<DevicePerformanceData>? lastGeneratedReportData;
  String? lastGeneratedReportDevice;
  String? lastGeneratedReportMetric;
  String? lastGeneratedReportStartDate;
  String? lastGeneratedReportEndDate;
  String? lastGeneratedReportPeriod;

  // Report history from backend
  List<dynamic> downloadedReports = [];
  bool isLoadingReports = false;
  int currentReportPage = 0;
  int reportsPerPage = 10;

  // Temperature Analysis report data
  List<TemperatureAnalysisData>? lastGeneratedTempReportData;
  String? lastGeneratedTempReportDevice;
  String? lastGeneratedTempReportStartDate;
  String? lastGeneratedTempReportEndDate;
  String? lastGeneratedTempReportPeriod;

  // Alerts Summary report data
  AlertsSummaryData? lastGeneratedAlertsReportData;
  String? lastGeneratedAlertsReportStartDate;
  String? lastGeneratedAlertsReportEndDate;
  String? lastGeneratedAlertsReportPeriod;

  // Maintenance Report data
  MaintenanceReportData? lastGeneratedMaintenanceReportData;
  String? lastGeneratedMaintenanceReportStartDate;
  String? lastGeneratedMaintenanceReportEndDate;
  String? lastGeneratedMaintenanceReportPeriod;

  final List<String> periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
    'Custom Range',
  ];

  // Helper method for mobile responsiveness
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  final List<ScheduledReport> scheduledReports = [
    ScheduledReport(
      id: '1',
      name: 'Daily Device Performance',
      frequency: 'Daily at 8:00 AM',
      nextRun: 'Tomorrow, 8:00 AM',
      format: 'PDF',
      isActive: true,
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    ScheduledReport(
      id: '2',
      name: 'Weekly Temperature Summary',
      frequency: 'Weekly on Monday',
      nextRun: 'Monday, 8:00 AM',
      format: 'Excel',
      isActive: true,
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    ScheduledReport(
      id: '3',
      name: 'Monthly Compliance Report',
      frequency: 'Monthly on 1st',
      nextRun: 'Jan 1, 2025',
      format: 'PDF',
      isActive: true,
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
    ScheduledReport(
      id: '4',
      name: 'Weekly Maintenance Summary',
      frequency: 'Weekly on Friday',
      nextRun: 'Friday, 5:00 PM',
      format: 'PDF',
      isActive: false,
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    ScheduledReport(
      id: '5',
      name: 'Daily Alerts Report',
      frequency: 'Daily at 6:00 PM',
      nextRun: 'Today, 6:00 PM',
      format: 'Excel',
      isActive: true,
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    ScheduledReport(
      id: '6',
      name: 'Monthly Energy Report',
      frequency: 'Monthly on 15th',
      nextRun: 'Jan 15, 2025',
      format: 'PDF',
      isActive: true,
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    ScheduledReport(
      id: '7',
      name: 'Bi-Weekly Device Health',
      frequency: 'Every 2 weeks',
      nextRun: 'Dec 28, 2024',
      format: 'Excel',
      isActive: false,
      icon: FontAwesomeIcons.heartPulse,
      color: Color(0xFFFF6B6B),
    ),
    ScheduledReport(
      id: '8',
      name: 'Quarterly Analytics',
      frequency: 'Quarterly',
      nextRun: 'Jan 1, 2025',
      format: 'PDF',
      isActive: true,
      icon: FontAwesomeIcons.chartPie,
      color: Color(0xFF4ECDC4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReportHistory();
  }

  Future<void> _loadReportHistory() async {
    setState(() {
      isLoadingReports = true;
    });

    try {
      final reports = await ReportApiService.getReportHistory(
        businessId: widget.companyId,
        limit: 100,
      );
      setState(() {
        downloadedReports = reports;
        currentReportPage = 0;
        isLoadingReports = false;
      });
    } catch (e) {
      print('Error loading report history: $e');
      setState(() {
        isLoadingReports = false;
      });
    }
  }

  // Remove old static list - now using dynamic data from backend
  /*final List<DownloadedReport> downloadedReports = [
    DownloadedReport(
      id: '1',
      name: 'Device Performance Report',
      downloadedBy: 'John Doe',
      downloadDate: 'Dec 14, 2024 - 10:30 AM',
      fileSize: '2.4 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    DownloadedReport(
      id: '2',
      name: 'Temperature Analytics',
      downloadedBy: 'Jane Smith',
      downloadDate: 'Dec 13, 2024 - 3:15 PM',
      fileSize: '1.8 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    DownloadedReport(
      id: '3',
      name: 'Alerts Summary',
      downloadedBy: 'John Doe',
      downloadDate: 'Dec 13, 2024 - 11:20 AM',
      fileSize: '1.2 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    DownloadedReport(
      id: '4',
      name: 'Monthly Compliance Report',
      downloadedBy: 'Sarah Johnson',
      downloadDate: 'Dec 12, 2024 - 9:00 AM',
      fileSize: '3.5 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
    DownloadedReport(
      id: '5',
      name: 'Energy Consumption Report',
      downloadedBy: 'Mike Wilson',
      downloadDate: 'Dec 11, 2024 - 2:45 PM',
      fileSize: '2.1 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    DownloadedReport(
      id: '6',
      name: 'Maintenance History',
      downloadedBy: 'Jane Smith',
      downloadDate: 'Dec 10, 2024 - 4:30 PM',
      fileSize: '1.9 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    DownloadedReport(
      id: '7',
      name: 'Device Performance Report',
      downloadedBy: 'John Doe',
      downloadDate: 'Dec 9, 2024 - 8:15 AM',
      fileSize: '2.3 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    DownloadedReport(
      id: '8',
      name: 'Weekly Temperature Summary',
      downloadedBy: 'Sarah Johnson',
      downloadDate: 'Dec 8, 2024 - 1:00 PM',
      fileSize: '1.7 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    DownloadedReport(
      id: '9',
      name: 'Alerts Summary',
      downloadedBy: 'Mike Wilson',
      downloadDate: 'Dec 7, 2024 - 5:20 PM',
      fileSize: '1.1 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    DownloadedReport(
      id: '10',
      name: 'Device Health Report',
      downloadedBy: 'Jane Smith',
      downloadDate: 'Dec 6, 2024 - 10:45 AM',
      fileSize: '2.8 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.heartPulse,
      color: Color(0xFFFF6B6B),
    ),
    DownloadedReport(
      id: '11',
      name: 'Energy Consumption Report',
      downloadedBy: 'John Doe',
      downloadDate: 'Dec 5, 2024 - 3:30 PM',
      fileSize: '2.0 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    DownloadedReport(
      id: '12',
      name: 'Compliance Report',
      downloadedBy: 'Sarah Johnson',
      downloadDate: 'Dec 4, 2024 - 11:15 AM',
      fileSize: '3.2 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
    DownloadedReport(
      id: '13',
      name: 'Maintenance History',
      downloadedBy: 'Mike Wilson',
      downloadDate: 'Dec 3, 2024 - 9:45 AM',
      fileSize: '1.6 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    DownloadedReport(
      id: '14',
      name: 'Device Performance Report',
      downloadedBy: 'Jane Smith',
      downloadDate: 'Dec 2, 2024 - 2:00 PM',
      fileSize: '2.5 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    DownloadedReport(
      id: '15',
      name: 'Temperature Analytics',
      downloadedBy: 'John Doe',
      downloadDate: 'Dec 1, 2024 - 4:15 PM',
      fileSize: '1.9 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    DownloadedReport(
      id: '16',
      name: 'Quarterly Analytics',
      downloadedBy: 'Sarah Johnson',
      downloadDate: 'Nov 30, 2024 - 10:00 AM',
      fileSize: '4.1 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartPie,
      color: Color(0xFF4ECDC4),
    ),
    DownloadedReport(
      id: '17',
      name: 'Alerts Summary',
      downloadedBy: 'Mike Wilson',
      downloadDate: 'Nov 29, 2024 - 1:30 PM',
      fileSize: '1.3 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    DownloadedReport(
      id: '18',
      name: 'Energy Consumption Report',
      downloadedBy: 'Jane Smith',
      downloadDate: 'Nov 28, 2024 - 3:45 PM',
      fileSize: '2.2 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
  ];*/

  final List<GeneratedReport> generatedReports = [
    GeneratedReport(
      id: '1',
      name: 'Device Performance Report',
      generatedBy: 'System',
      generatedDate: 'Dec 14, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '2.4 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    GeneratedReport(
      id: '2',
      name: 'Weekly Temperature Summary',
      generatedBy: 'John Doe',
      generatedDate: 'Dec 13, 2024 - 9:30 AM',
      status: 'Ready',
      fileSize: '1.7 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    GeneratedReport(
      id: '3',
      name: 'Monthly Compliance Report',
      generatedBy: 'System',
      generatedDate: 'Dec 12, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '3.2 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
    GeneratedReport(
      id: '4',
      name: 'Alerts Summary',
      generatedBy: 'Jane Smith',
      generatedDate: 'Dec 11, 2024 - 6:00 PM',
      status: 'Ready',
      fileSize: '1.1 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    GeneratedReport(
      id: '5',
      name: 'Energy Consumption Report',
      generatedBy: 'Mike Wilson',
      generatedDate: 'Dec 10, 2024 - 3:15 PM',
      status: 'Ready',
      fileSize: '2.0 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    GeneratedReport(
      id: '6',
      name: 'Maintenance History',
      generatedBy: 'Sarah Johnson',
      generatedDate: 'Dec 9, 2024 - 11:45 AM',
      status: 'Ready',
      fileSize: '1.8 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    GeneratedReport(
      id: '7',
      name: 'Device Performance Report',
      generatedBy: 'System',
      generatedDate: 'Dec 8, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '2.3 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    GeneratedReport(
      id: '8',
      name: 'Temperature Analytics',
      generatedBy: 'John Doe',
      generatedDate: 'Dec 7, 2024 - 2:30 PM',
      status: 'Ready',
      fileSize: '1.9 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    GeneratedReport(
      id: '9',
      name: 'Alerts Summary',
      generatedBy: 'System',
      generatedDate: 'Dec 6, 2024 - 6:00 PM',
      status: 'Ready',
      fileSize: '1.2 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    GeneratedReport(
      id: '10',
      name: 'Device Health Report',
      generatedBy: 'Jane Smith',
      generatedDate: 'Dec 5, 2024 - 10:00 AM',
      status: 'Ready',
      fileSize: '2.5 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.heartPulse,
      color: Color(0xFFFF6B6B),
    ),
    GeneratedReport(
      id: '11',
      name: 'Energy Consumption Report',
      generatedBy: 'Mike Wilson',
      generatedDate: 'Dec 4, 2024 - 1:20 PM',
      status: 'Ready',
      fileSize: '2.1 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    GeneratedReport(
      id: '12',
      name: 'Compliance Report',
      generatedBy: 'System',
      generatedDate: 'Dec 3, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '3.0 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
    GeneratedReport(
      id: '13',
      name: 'Maintenance History',
      generatedBy: 'Sarah Johnson',
      generatedDate: 'Dec 2, 2024 - 4:45 PM',
      status: 'Ready',
      fileSize: '1.7 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    GeneratedReport(
      id: '14',
      name: 'Device Performance Report',
      generatedBy: 'System',
      generatedDate: 'Dec 1, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '2.4 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    GeneratedReport(
      id: '15',
      name: 'Weekly Temperature Summary',
      generatedBy: 'John Doe',
      generatedDate: 'Nov 30, 2024 - 9:15 AM',
      status: 'Ready',
      fileSize: '1.6 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    GeneratedReport(
      id: '16',
      name: 'Quarterly Analytics',
      generatedBy: 'Mike Wilson',
      generatedDate: 'Nov 29, 2024 - 3:00 PM',
      status: 'Ready',
      fileSize: '4.2 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartPie,
      color: Color(0xFF4ECDC4),
    ),
    GeneratedReport(
      id: '17',
      name: 'Alerts Summary',
      generatedBy: 'System',
      generatedDate: 'Nov 28, 2024 - 6:00 PM',
      status: 'Ready',
      fileSize: '1.3 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    GeneratedReport(
      id: '18',
      name: 'Energy Consumption Report',
      generatedBy: 'Jane Smith',
      generatedDate: 'Nov 27, 2024 - 11:30 AM',
      status: 'Ready',
      fileSize: '2.2 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    GeneratedReport(
      id: '19',
      name: 'Device Health Report',
      generatedBy: 'Sarah Johnson',
      generatedDate: 'Nov 26, 2024 - 2:15 PM',
      status: 'Processing',
      fileSize: '-',
      format: 'PDF',
      icon: FontAwesomeIcons.heartPulse,
      color: Color(0xFFFF6B6B),
    ),
    GeneratedReport(
      id: '20',
      name: 'Maintenance History',
      generatedBy: 'Mike Wilson',
      generatedDate: 'Nov 25, 2024 - 10:45 AM',
      status: 'Ready',
      fileSize: '1.9 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    GeneratedReport(
      id: '21',
      name: 'Device Performance Report',
      generatedBy: 'System',
      generatedDate: 'Nov 24, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '2.3 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    GeneratedReport(
      id: '22',
      name: 'Temperature Analytics',
      generatedBy: 'John Doe',
      generatedDate: 'Nov 23, 2024 - 1:00 PM',
      status: 'Ready',
      fileSize: '1.8 MB',
      format: 'Excel',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    GeneratedReport(
      id: '23',
      name: 'Compliance Report',
      generatedBy: 'System',
      generatedDate: 'Nov 22, 2024 - 8:00 AM',
      status: 'Ready',
      fileSize: '3.1 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
    GeneratedReport(
      id: '24',
      name: 'Alerts Summary',
      generatedBy: 'Jane Smith',
      generatedDate: 'Nov 21, 2024 - 5:30 PM',
      status: 'Ready',
      fileSize: '1.0 MB',
      format: 'PDF',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
  ];

  final List<ReportType> reportTypes = [
    ReportType(
      id: 'device_performance',
      name: 'Device Performance',
      description: 'Comprehensive analysis of device metrics and performance',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF4A90E2),
    ),
    ReportType(
      id: 'temperature_analytics',
      name: 'Temperature Analytics',
      description: 'Temperature trends and variations across devices',
      icon: FontAwesomeIcons.temperatureHalf,
      color: Color(0xFFE94B3C),
    ),
    ReportType(
      id: 'alerts_summary',
      name: 'Alerts Summary',
      description: 'Overview of all alerts and notifications',
      icon: FontAwesomeIcons.bellConcierge,
      color: Color(0xFFF5A623),
    ),
    ReportType(
      id: 'maintenance_history',
      name: 'Maintenance History',
      description: 'Maintenance activities and service records',
      icon: FontAwesomeIcons.screwdriverWrench,
      color: Color(0xFF7B68EE),
    ),
    ReportType(
      id: 'energy_consumption',
      name: 'Energy Consumption',
      description: 'Power usage analysis and efficiency metrics',
      icon: FontAwesomeIcons.bolt,
      color: Color(0xFF50C878),
    ),
    ReportType(
      id: 'compliance_report',
      name: 'Compliance Report',
      description: 'Regulatory compliance and audit trail',
      icon: FontAwesomeIcons.shieldHalved,
      color: Color(0xFF9B59B6),
    ),
  ];

  void _generateReport(ReportType reportType) {
    // Show report configuration dialog based on type
    switch (reportType.id) {
      case 'device_performance':
        _showDevicePerformanceDialog();
        break;
      case 'temperature_analytics':
        _showTemperatureAnalyticsDialog();
        break;
      case 'alerts_summary':
        _showAlertsSummaryDialog();
        break;
      case 'maintenance_history':
        _showMaintenanceHistoryDialog();
        break;
      case 'energy_consumption':
        _showEnergyConsumptionDialog();
        break;
      case 'compliance_report':
        _showComplianceReportDialog();
        break;
    }
  }

  Future<void> _generateDevicePerformanceReport({
    required String selectedDevice,
    required String selectedMetric,
    required bool includeCharts,
    required bool includeRawData,
    required List<DeviceModel3> deviceList,
  }) async {
    // Calculate date range based on selected period
    final endDate = DateTime.now();
    final startDate = _getStartDate(endDate);

    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    List<DevicePerformanceData> reportData = [];

    if (selectedDevice == 'all') {
      // Fetch data for all devices
      for (var device in deviceList) {
        try {
          final data = await DevicePerformanceApiService.getDevicePerformance(
            deviceId: device.deviceId,
            deviceName: device.name,
            startDate: startDateStr,
            endDate: endDateStr,
          );
          reportData.add(data);
        } catch (e) {
          print('Error fetching data for ${device.deviceId}: $e');
        }
      }
    } else {
      // Fetch data for selected device
      final device = deviceList.firstWhere(
        (d) => d.deviceId == selectedDevice,
        orElse: () => DeviceModel3(
          id: 0,
          deviceId: selectedDevice,
          name: 'Unknown',
          deviceType: 'Unknown',
          isActive: false,
          isOnline: false,
          isInRepairMode: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentStatus: 'Unknown',
          latitude: '0',
          longitude: '0',
        ),
      );
      try {
        final data = await DevicePerformanceApiService.getDevicePerformance(
          deviceId: device.deviceId,
          deviceName: device.name,
          startDate: startDateStr,
          endDate: endDateStr,
        );
        reportData.add(data);
      } catch (e) {
        print('Error fetching data for ${device.deviceId}: $e');
      }
    }

    // Store the generated report data
    setState(() {
      lastGeneratedReportData = reportData;
      lastGeneratedReportDevice = selectedDevice;
      lastGeneratedReportMetric = selectedMetric;
      lastGeneratedReportStartDate = startDateStr;
      lastGeneratedReportEndDate = endDateStr;
      lastGeneratedReportPeriod = selectedPeriod;
    });

    // Save report to backend
    try {
      final reportName =
          'Device Performance Report - ${DateTime.now().toString().substring(0, 16)}';
      final deviceIdsList = selectedDevice == 'all'
          ? deviceList.map((d) => d.deviceId).toList()
          : [selectedDevice];

      // Convert report data to JSON format
      final reportDataJson = {
        'devices': reportData
            .map((d) => {
                  'device_id': d.deviceId,
                  'device_name': d.deviceName,
                  'avg_temperature': d.avgTemperature,
                  'min_temperature': d.minTemperature,
                  'max_temperature': d.maxTemperature,
                  'avg_pressure': d.avgPressure,
                  'door_open_count': d.doorOpenCount,
                  'power_consumption': d.powerConsumption,
                  'uptime': d.uptime,
                  'health_grade': d.healthGrade,
                })
            .toList(),
        'summary': {
          'total_devices': reportData.length,
          'period': selectedPeriod,
          'metric': selectedMetric,
        }
      };

      await ReportApiService.saveReport(
        reportType: 'device_performance',
        reportName: reportName,
        businessId: widget.companyId,
        deviceIds: deviceIdsList,
        startDate: startDateStr,
        endDate: endDateStr,
        period: selectedPeriod,
        includeCharts: includeCharts,
        includeRawData: includeRawData,
        reportData: reportDataJson,
        generatedBy: Constants.myDisplayname.isNotEmpty
            ? Constants.myDisplayname
            : 'User',
        pageCount: 10,
        fileSize: '${(reportData.length * 0.5).toStringAsFixed(1)} MB',
      );
      print('Report saved to backend successfully');
    } catch (e) {
      print('Failed to save report to backend: $e');
      // Continue anyway - report is still available locally
    }
  }

  Future<void> _generateTemperatureAnalysisReport({
    required String selectedDevice,
    required List<DeviceModel3> deviceList,
  }) async {
    final endDate = DateTime.now();
    final startDate = _getStartDate(endDate);
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    List<TemperatureAnalysisData> reportData = [];

    if (selectedDevice == 'all') {
      for (var device in deviceList) {
        try {
          final data =
              await TemperatureAnalysisApiService.getTemperatureAnalysis(
            deviceId: device.deviceId,
            deviceName: device.name,
            startDate: startDateStr,
            endDate: endDateStr,
          );
          reportData.add(data);
        } catch (e) {
          print('Error fetching temperature data for ${device.deviceId}: $e');
        }
      }
    } else {
      final device = deviceList.firstWhere(
        (d) => d.deviceId == selectedDevice,
        orElse: () => DeviceModel3(
          id: 0,
          deviceId: selectedDevice,
          name: 'Unknown',
          deviceType: 'Unknown',
          isActive: false,
          isOnline: false,
          isInRepairMode: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentStatus: 'Unknown',
          latitude: '0',
          longitude: '0',
        ),
      );
      try {
        final data = await TemperatureAnalysisApiService.getTemperatureAnalysis(
          deviceId: device.deviceId,
          deviceName: device.name,
          startDate: startDateStr,
          endDate: endDateStr,
        );
        reportData.add(data);
      } catch (e) {
        print('Error fetching temperature data for ${device.deviceId}: $e');
      }
    }

    setState(() {
      lastGeneratedTempReportData = reportData;
      lastGeneratedTempReportDevice = selectedDevice;
      lastGeneratedTempReportStartDate = startDateStr;
      lastGeneratedTempReportEndDate = endDateStr;
      lastGeneratedTempReportPeriod = selectedPeriod;
    });

    // Save to backend
    try {
      final reportName =
          'Temperature Analysis Report - ${DateTime.now().toString().substring(0, 16)}';
      final deviceIdsList = selectedDevice == 'all'
          ? deviceList.map((d) => d.deviceId).toList()
          : [selectedDevice];

      final reportDataJson = {
        'devices': reportData
            .map((d) => {
                  'device_id': d.deviceId,
                  'device_name': d.deviceName,
                  'avg_temperature': d.avgTemperature,
                  'min_temperature': d.minTemperature,
                  'max_temperature': d.maxTemperature,
                  'std_deviation': d.stdDeviation,
                  'total_readings': d.totalReadings,
                  'violations': d.violations,
                })
            .toList(),
        'summary': {
          'total_devices': reportData.length,
          'period': selectedPeriod,
        }
      };

      await ReportApiService.saveReport(
        reportType: 'temperature_analysis',
        reportName: reportName,
        businessId: widget.companyId,
        deviceIds: deviceIdsList,
        startDate: startDateStr,
        endDate: endDateStr,
        period: selectedPeriod,
        includeCharts: true,
        includeRawData: false,
        reportData: reportDataJson,
        generatedBy: Constants.myDisplayname.isNotEmpty
            ? Constants.myDisplayname
            : 'User',
        pageCount: 8,
        fileSize: '${(reportData.length * 0.4).toStringAsFixed(1)} MB',
      );
      print('Temperature report saved to backend successfully');
    } catch (e) {
      print('Failed to save temperature report to backend: $e');
    }
  }

  // Generate Alerts Summary Report
  Future<void> _generateAlertsSummaryReport({
    required String selectedPeriod,
  }) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = _getStartDate(endDate);

    String startDateStr = startDate.toIso8601String();
    String endDateStr = endDate.toIso8601String();

    try {
      final data = await AlertsSummaryApiService.getAlertsSummary(
        businessId: widget.companyId,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      setState(() {
        lastGeneratedAlertsReportData = data;
        lastGeneratedAlertsReportStartDate = startDateStr;
        lastGeneratedAlertsReportEndDate = endDateStr;
        lastGeneratedAlertsReportPeriod = selectedPeriod;
      });

      // Save to backend
      try {
        final reportName =
            'Alerts Summary Report - ${DateTime.now().toString().substring(0, 16)}';

        final reportDataJson = {
          'overall_statistics': data.overallStats,
          'alerts_by_severity': data.alertsBySeverity,
          'alerts_by_device': data.alertsByDevice,
          'alerts_by_type': data.alertsByType,
          'daily_trend': data.dailyTrend,
          'hourly_distribution': data.hourlyDistribution,
          'recent_active_alerts': data.recentActiveAlerts,
        };

        await ReportApiService.saveReport(
          reportType: 'alerts_summary',
          reportName: reportName,
          businessId: widget.companyId,
          deviceIds: [],
          startDate: startDateStr,
          endDate: endDateStr,
          period: selectedPeriod,
          includeCharts: true,
          includeRawData: false,
          reportData: reportDataJson,
          generatedBy: Constants.myDisplayname.isNotEmpty
              ? Constants.myDisplayname
              : 'User',
          pageCount: 5,
          fileSize:
              '${(data.alertsByDevice.length * 0.3 + 0.5).toStringAsFixed(1)} MB',
        );
        print('Alerts summary report saved to backend successfully');
      } catch (e) {
        print('Failed to save alerts summary report to backend: $e');
      }
    } catch (e) {
      print('Error fetching alerts summary: $e');
    }
  }

  // Generate Maintenance Report
  Future<void> _generateMaintenanceReport({
    required String selectedPeriod,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = _getStartDate(endDate);

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      print(
          'Fetching maintenance report for business: ${widget.companyId}, from $startDateStr to $endDateStr');

      final data = await MaintenanceReportApiService.getMaintenanceReport(
        businessId: widget.companyId,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      print('Maintenance report data received:');
      print('  - Overall stats: ${data.overallStats}');
      print('  - Maintenance by type count: ${data.maintenanceByType.length}');
      print('  - Maintenance by device count: ${data.maintenanceByDevice.length}');
      print('  - Recent completed count: ${data.recentCompleted.length}');

      setState(() {
        lastGeneratedMaintenanceReportData = data;
        lastGeneratedMaintenanceReportStartDate = startDateStr;
        lastGeneratedMaintenanceReportEndDate = endDateStr;
        lastGeneratedMaintenanceReportPeriod = selectedPeriod;
      });

      print('Maintenance report data loaded successfully and stored in state');

      // Save report to backend
      try {
        final reportDataMap = {
          'overall_statistics': data.overallStats,
          'maintenance_by_type': data.maintenanceByType,
          'maintenance_by_device': data.maintenanceByDevice,
          'maintenance_by_priority': data.maintenanceByPriority,
          'monthly_trend': data.monthlyTrend,
          'cost_analysis': data.costAnalysis,
          'duration_analysis': data.durationAnalysis,
          'recent_completed': data.recentCompleted,
          'upcoming_maintenance': data.upcomingMaintenance,
          'overdue_maintenance': data.overdueMaintenance,
        };

        await ReportApiService.saveReport(
          reportType: 'maintenance_report',
          reportName: 'Maintenance Report - $selectedPeriod',
          businessId: widget.companyId,
          deviceIds: [],
          startDate: startDateStr,
          endDate: endDateStr,
          period: selectedPeriod,
          includeCharts: true,
          includeRawData: false,
          reportData: reportDataMap,
          generatedBy: Constants.myDisplayname.isNotEmpty
              ? Constants.myDisplayname
              : 'User',
          pageCount: 8,
          fileSize:
              '${(data.maintenanceByDevice.length * 0.5 + 1.0).toStringAsFixed(1)} MB',
        );
        print('Maintenance report saved to backend successfully');
      } catch (e) {
        print('Failed to save maintenance report to backend: $e');
      }
    } catch (e) {
      print('Error fetching maintenance report: $e');
    }
  }

  Future<void> _downloadMaintenanceSampleData() async {
    try {
      // Create sample maintenance data
      List<List<dynamic>> rows = [
        // Header row
        ['Device Name', 'Device ID', 'Maintenance Type', 'Scheduled Date', 'Priority', 'Status', 'Estimated Cost', 'Actual Cost', 'Estimated Duration (hrs)', 'Actual Duration (hrs)', 'Description'],
        // Sample data rows
        ['Chiller Unit A1', 'DEV001', 'Preventive Maintenance', '2025-01-15', 'Normal', 'Scheduled', '500', '', '2', '', 'Quarterly maintenance check'],
        ['Freezer Room B2', 'DEV002', 'Emergency Repair', '2025-01-10', 'Critical', 'Completed', '1200', '1350', '4', '5', 'Compressor replacement'],
        ['Chiller Unit C3', 'DEV003', 'Inspection', '2025-01-20', 'Low', 'Scheduled', '200', '', '1', '', 'Annual safety inspection'],
        ['Freezer Unit D4', 'DEV004', 'Calibration Check', '2025-01-12', 'Normal', 'In Progress', '300', '', '1.5', '', 'Temperature sensor calibration'],
        ['Chiller Room E5', 'DEV005', 'Preventive Maintenance', '2025-01-25', 'Normal', 'Scheduled', '450', '', '2', '', 'Filter replacement and cleaning'],
        ['Freezer Unit F6', 'DEV006', 'Component Replacement', '2024-12-28', 'High', 'Overdue', '800', '', '3', '', 'Replace worn evaporator fan'],
        ['Chiller Unit G7', 'DEV007', 'Preventive Maintenance', '2024-12-20', 'Normal', 'Completed', '500', '520', '2', '2.5', 'Routine maintenance completed'],
        ['Freezer Room H8', 'DEV008', 'System Upgrade', '2025-01-30', 'Low', 'Scheduled', '2000', '', '8', '', 'Control system firmware update'],
        ['Chiller Unit I9', 'DEV009', 'Emergency Repair', '2024-12-15', 'Emergency', 'Completed', '1500', '1450', '6', '5.5', 'Refrigerant leak repair'],
        ['Freezer Unit J10', 'DEV010', 'Inspection', '2025-01-18', 'Normal', 'Scheduled', '250', '', '1', '', 'Monthly inspection'],
      ];

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        // Web download
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'maintenance_sample_data.csv';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // Desktop/Mobile download
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final String path = '${directory.path}/maintenance_sample_data.csv';
          final File file = File(path);
          await file.writeAsString(csv);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sample data downloaded to: $path'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error downloading sample data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading sample data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadSampleMaintenancePDFReport() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('MMMM dd, yyyy');
      final timeFormat = DateFormat('HH:mm');

      // Sample data for 10 devices
      final sampleDevices = [
        {'name': 'Chiller Unit A1', 'id': 'DEV001', 'location': 'Building A - Floor 1', 'status': 'Operational'},
        {'name': 'Freezer Room B2', 'id': 'DEV002', 'location': 'Building B - Floor 2', 'status': 'Operational'},
        {'name': 'Chiller Unit C3', 'id': 'DEV003', 'location': 'Building C - Floor 3', 'status': 'Operational'},
        {'name': 'Freezer Unit D4', 'id': 'DEV004', 'location': 'Building D - Floor 1', 'status': 'Maintenance'},
        {'name': 'Chiller Room E5', 'id': 'DEV005', 'location': 'Building E - Floor 2', 'status': 'Operational'},
        {'name': 'Freezer Unit F6', 'id': 'DEV006', 'location': 'Building F - Floor 3', 'status': 'Alert'},
        {'name': 'Chiller Unit G7', 'id': 'DEV007', 'location': 'Building G - Floor 1', 'status': 'Operational'},
        {'name': 'Freezer Room H8', 'id': 'DEV008', 'location': 'Building H - Floor 2', 'status': 'Operational'},
        {'name': 'Chiller Unit I9', 'id': 'DEV009', 'location': 'Building I - Floor 3', 'status': 'Operational'},
        {'name': 'Freezer Unit J10', 'id': 'DEV010', 'location': 'Building J - Floor 1', 'status': 'Operational'},
      ];

      final maintenanceRecords = [
        {'device': 'DEV001', 'type': 'Preventive', 'date': '2025-01-15', 'priority': 'Normal', 'status': 'Scheduled', 'cost': '\$500', 'duration': '2.0 hrs'},
        {'device': 'DEV002', 'type': 'Emergency', 'date': '2025-01-10', 'priority': 'Critical', 'status': 'Completed', 'cost': '\$1,350', 'duration': '5.0 hrs'},
        {'device': 'DEV003', 'type': 'Inspection', 'date': '2025-01-20', 'priority': 'Low', 'status': 'Scheduled', 'cost': '\$200', 'duration': '1.0 hrs'},
        {'device': 'DEV004', 'type': 'Calibration', 'date': '2025-01-12', 'priority': 'Normal', 'status': 'In Progress', 'cost': '\$300', 'duration': '1.5 hrs'},
        {'device': 'DEV005', 'type': 'Preventive', 'date': '2025-01-25', 'priority': 'Normal', 'status': 'Scheduled', 'cost': '\$450', 'duration': '2.0 hrs'},
        {'device': 'DEV006', 'type': 'Component Replace', 'date': '2024-12-28', 'priority': 'High', 'status': 'Overdue', 'cost': '\$800', 'duration': '3.0 hrs'},
        {'device': 'DEV007', 'type': 'Preventive', 'date': '2024-12-20', 'priority': 'Normal', 'status': 'Completed', 'cost': '\$520', 'duration': '2.5 hrs'},
        {'device': 'DEV008', 'type': 'System Upgrade', 'date': '2025-01-30', 'priority': 'Low', 'status': 'Scheduled', 'cost': '\$2,000', 'duration': '8.0 hrs'},
        {'device': 'DEV009', 'type': 'Emergency', 'date': '2024-12-15', 'priority': 'Emergency', 'status': 'Completed', 'cost': '\$1,450', 'duration': '5.5 hrs'},
        {'device': 'DEV010', 'type': 'Inspection', 'date': '2025-01-18', 'priority': 'Normal', 'status': 'Scheduled', 'cost': '\$250', 'duration': '1.0 hrs'},
      ];

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Container(
              padding: pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.blue800)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MAINTENANCE REPORT',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Sample Report - Fully Populated Data',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Report Date: ${dateFormat.format(now)}', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Generated: ${timeFormat.format(now)}', style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Executive Summary
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPdfSummaryBox('Total Devices', '10', PdfColors.blue800),
                      _buildPdfSummaryBox('Total Maintenance', '10', PdfColors.green800),
                      _buildPdfSummaryBox('Completed', '2', PdfColors.teal800),
                      _buildPdfSummaryBox('Overdue', '1', PdfColors.red800),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Device List
            pw.Text('Device Inventory', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            _buildPdfDeviceTable(sampleDevices),
            pw.SizedBox(height: 24),

            // Maintenance Records
            pw.Text('Maintenance Records', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            _buildPdfMaintenanceTable(maintenanceRecords),
            pw.SizedBox(height: 24),

            // Cost Analysis
            pw.Text('Cost Analysis', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _buildPdfCostRow('Total Estimated Cost', '\$8,770', false),
                  pw.Divider(),
                  _buildPdfCostRow('Total Actual Cost (Completed)', '\$1,870', false),
                  pw.Divider(),
                  _buildPdfCostRow('Average Cost per Maintenance', '\$877', false),
                  pw.Divider(),
                  _buildPdfCostRow('Budget Variance', '+\$420', true),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Maintenance by Priority
            pw.Text('Maintenance by Priority', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfPriorityCard('Emergency', '1', PdfColors.red),
                _buildPdfPriorityCard('Critical', '1', PdfColors.orange),
                _buildPdfPriorityCard('High', '1', PdfColors.amber),
                _buildPdfPriorityCard('Normal', '5', PdfColors.blue),
                _buildPdfPriorityCard('Low', '2', PdfColors.green),
              ],
            ),
            pw.SizedBox(height: 24),

            // Recommendations
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 20,
                        color: PdfColors.amber800,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('Recommendations', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  _buildPdfBulletPoint('Address overdue maintenance on Freezer Unit F6 (DEV006) immediately'),
                  _buildPdfBulletPoint('Schedule preventive maintenance for all operational units within next 30 days'),
                  _buildPdfBulletPoint('Monitor DEV004 currently under maintenance for completion status'),
                  _buildPdfBulletPoint('Budget allocation: Additional \$6,900 needed for scheduled maintenance'),
                ],
              ),
            ),

            // Footer
            pw.SizedBox(height: 32),
            pw.Container(
              padding: pw.EdgeInsets.only(top: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Arctic Sentinel - Maintenance Management System', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ),
          ],
        ),
      );

      // Save PDF
      final bytes = await pdf.save();

      if (kIsWeb) {
        // Web download
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'sample_maintenance_report_${DateFormat('yyyyMMdd').format(now)}.pdf';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sample PDF report downloaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Desktop/Mobile
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final String path = '${directory.path}/sample_maintenance_report_${DateFormat('yyyyMMdd').format(now)}.pdf';
          final File file = File(path);
          await file.writeAsBytes(bytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sample PDF report saved to:\n$path'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await Printing.sharePdf(bytes: bytes, filename: 'sample_maintenance_report.pdf');
                    } catch (e) {
                      print('Error opening PDF: $e');
                    }
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error generating sample PDF report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDeviceTable(List<Map<String, String>> devices) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPdfTableHeader('Device Name'),
            _buildPdfTableHeader('Device ID'),
            _buildPdfTableHeader('Location'),
            _buildPdfTableHeader('Status'),
          ],
        ),
        // Data rows
        ...devices.map((device) => pw.TableRow(
          children: [
            _buildPdfTableCell(device['name']!),
            _buildPdfTableCell(device['id']!),
            _buildPdfTableCell(device['location']!),
            _buildPdfTableCell(device['status']!, getPdfStatusColor(device['status']!)),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildPdfMaintenanceTable(List<Map<String, String>> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPdfTableHeader('Device'),
            _buildPdfTableHeader('Type'),
            _buildPdfTableHeader('Date'),
            _buildPdfTableHeader('Priority'),
            _buildPdfTableHeader('Status'),
            _buildPdfTableHeader('Cost'),
            _buildPdfTableHeader('Duration'),
          ],
        ),
        // Data rows
        ...records.map((record) => pw.TableRow(
          children: [
            _buildPdfTableCell(record['device']!, null, 8),
            _buildPdfTableCell(record['type']!, null, 8),
            _buildPdfTableCell(record['date']!, null, 8),
            _buildPdfTableCell(record['priority']!, getPdfPriorityColor(record['priority']!), 8),
            _buildPdfTableCell(record['status']!, getPdfStatusColor(record['status']!), 8),
            _buildPdfTableCell(record['cost']!, null, 8),
            _buildPdfTableCell(record['duration']!, null, 8),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, [PdfColor? bgColor, double fontSize = 10]) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      color: bgColor,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, color: bgColor != null ? PdfColors.white : PdfColors.black),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  PdfColor getPdfStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return PdfColors.green700;
      case 'in progress':
        return PdfColors.blue700;
      case 'scheduled':
        return PdfColors.teal700;
      case 'overdue':
        return PdfColors.red700;
      case 'alert':
        return PdfColors.orange700;
      default:
        return PdfColors.grey700;
    }
  }

  PdfColor getPdfPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return PdfColors.red800;
      case 'critical':
        return PdfColors.orange800;
      case 'high':
        return PdfColors.amber800;
      case 'normal':
        return PdfColors.blue800;
      case 'low':
        return PdfColors.green800;
      default:
        return PdfColors.grey800;
    }
  }

  pw.Widget _buildPdfCostRow(String label, String amount, bool isBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(amount, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  pw.Widget _buildPdfPriorityCard(String label, String count, PdfColor color) {
    return pw.Container(
      width: 70,
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(count, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfBulletPoint(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  DateTime _getStartDate(DateTime endDate) {
    switch (selectedPeriod) {
      case 'Last 7 Days':
        return endDate.subtract(Duration(days: 7));
      case 'Last 30 Days':
        return endDate.subtract(Duration(days: 30));
      case 'Last 3 Months':
        return endDate.subtract(Duration(days: 90));
      case 'Last 6 Months':
        return endDate.subtract(Duration(days: 180));
      case 'Last Year':
        return endDate.subtract(Duration(days: 365));
      default:
        return endDate.subtract(Duration(days: 7));
    }
  }

  void _showDevicePerformanceDialog() async {
    String selectedDevice = 'all';
    String selectedMetric = 'all';
    bool includeCharts = true;
    bool includeRawData = false;
    bool isLoadingDevices = true;
    List<DeviceModel3> deviceList = [];
    String? errorMessage;

    // Fetch devices
    try {
      deviceList =
          await DevicePerformanceApiService.getDevices(widget.companyId);
    } catch (e) {
      errorMessage = 'Failed to load devices: $e';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          FontAwesomeIcons.chartLine,
                          color: Color(0xFF4A90E2),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Performance Report',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Configure report parameters',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Device Selection
                  Text(
                    'Select Device',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDevice,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Constants.ctaColorLight),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Devices'),
                            ),
                            ...deviceList.map((device) => DropdownMenuItem(
                                  value: device.deviceId,
                                  child: Text(
                                      '${device.name} (${device.deviceId}) - ${device.deviceType}'),
                                )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDevice = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Metric Selection
                  Text(
                    'Performance Metrics',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMetric,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Constants.ctaColorLight),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Metrics'),
                          ),
                          DropdownMenuItem(
                            value: 'temperature',
                            child: Text('Temperature Only'),
                          ),
                          DropdownMenuItem(
                            value: 'pressure',
                            child: Text('Pressure Only'),
                          ),
                          DropdownMenuItem(
                            value: 'power',
                            child: Text('Power Consumption'),
                          ),
                          DropdownMenuItem(
                            value: 'uptime',
                            child: Text('Uptime Statistics'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMetric = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Options
                  Text(
                    'Report Options',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(
                      'Include Charts & Graphs',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    value: includeCharts,
                    onChanged: (value) {
                      setDialogState(() {
                        includeCharts = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Include Raw Data',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    value: includeRawData,
                    onChanged: (value) {
                      setDialogState(() {
                        includeRawData = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 24),

                  // Footer buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              isGenerating = true;
                              selectedReportType = 'device_performance';
                            });

                            try {
                              // Fetch real device data
                              await _generateDevicePerformanceReport(
                                selectedDevice: selectedDevice,
                                selectedMetric: selectedMetric,
                                includeCharts: includeCharts,
                                includeRawData: includeRawData,
                                deviceList: deviceList,
                              );
                            } catch (e) {
                              print('Error generating report: $e');
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isGenerating = false;
                                });
                                _showSuccessDialog('Device Performance Report');
                              }
                            }
                          },
                          child: Text(
                            'Generate Report',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTemperatureAnalyticsDialog() async {
    String selectedDevice = 'all';
    String temperatureRange = 'all';
    bool includeAnomalies = true;
    List<DeviceModel3> deviceList = [];

    // Fetch devices
    try {
      deviceList =
          await DevicePerformanceApiService.getDevices(widget.companyId);
    } catch (e) {
      print('Error loading devices: $e');
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFE94B3C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          FontAwesomeIcons.temperatureHalf,
                          color: Color(0xFFE94B3C),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temperature Analytics Report',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Configure temperature analysis',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Device Selection
                  Text(
                    'Select Device',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDevice,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Constants.ctaColorLight),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Devices')),
                          DropdownMenuItem(
                              value: 'device_001',
                              child: Text('Device 001 - Chiller A')),
                          DropdownMenuItem(
                              value: 'device_002',
                              child: Text('Device 002 - Freezer B')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDevice = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Temperature Range
                  Text(
                    'Temperature Range',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: temperatureRange,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Constants.ctaColorLight),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Temperatures')),
                          DropdownMenuItem(
                              value: 'normal',
                              child: Text('Normal Range Only')),
                          DropdownMenuItem(
                              value: 'high', child: Text('Above Threshold')),
                          DropdownMenuItem(
                              value: 'low', child: Text('Below Threshold')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            temperatureRange = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Options
                  CheckboxListTile(
                    title: Text(
                      'Highlight Temperature Anomalies',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    value: includeAnomalies,
                    onChanged: (value) {
                      setDialogState(() {
                        includeAnomalies = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 24),

                  // Footer buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              isGenerating = true;
                              selectedReportType = 'temperature_analytics';
                            });

                            await _generateTemperatureAnalysisReport(
                              selectedDevice: selectedDevice,
                              deviceList: deviceList,
                            );

                            if (mounted) {
                              setState(() {
                                isGenerating = false;
                              });
                              _showPDFPreviewDialog(
                                  'Temperature Analysis Report',
                                  'temperature_analysis');
                            }
                          },
                          child: Text(
                            'Generate Report',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAlertsSummaryDialog() {
    _showGenericReportDialog(
      'Alerts Summary Report',
      'Configure alert filters',
      FontAwesomeIcons.bellConcierge,
      Color(0xFFF5A623),
      'alerts_summary',
      [
        {
          'label': 'Alert Severity',
          'options': [
            'All Severities',
            'Critical Only',
            'High Priority',
            'Medium & Low'
          ]
        },
        {
          'label': 'Alert Type',
          'options': [
            'All Types',
            'Temperature Alerts',
            'System Alerts',
            'Door Alerts'
          ]
        },
      ],
    );
  }

  void _showMaintenanceHistoryDialog() {
    _showGenericReportDialog(
      'Maintenance History Report',
      'Configure maintenance records',
      FontAwesomeIcons.screwdriverWrench,
      Color(0xFF7B68EE),
      'maintenance_report',  // Changed from 'maintenance_history' to 'maintenance_report'
      [
        {
          'label': 'Maintenance Type',
          'options': ['All Types', 'Preventive', 'Corrective', 'Emergency']
        },
        {
          'label': 'Status',
          'options': ['All Status', 'Completed', 'Pending', 'Scheduled']
        },
      ],
    );
  }

  void _showEnergyConsumptionDialog() {
    _showGenericReportDialog(
      'Energy Consumption Report',
      'Configure energy analysis',
      FontAwesomeIcons.bolt,
      Color(0xFF50C878),
      'energy_consumption',
      [
        {
          'label': 'Measurement',
          'options': [
            'All Measurements',
            'Power Usage',
            'Energy Cost',
            'Efficiency Rating'
          ]
        },
        {
          'label': 'Comparison',
          'options': [
            'No Comparison',
            'Month over Month',
            'Year over Year',
            'Device vs Device'
          ]
        },
      ],
    );
  }

  void _showComplianceReportDialog() {
    _showGenericReportDialog(
      'Compliance Report',
      'Configure compliance audit',
      FontAwesomeIcons.shieldHalved,
      Color(0xFF9B59B6),
      'compliance_report',
      [
        {
          'label': 'Compliance Standard',
          'options': ['All Standards', 'FDA', 'ISO 9001', 'HACCP', 'Custom']
        },
        {
          'label': 'Report Level',
          'options': ['Summary', 'Detailed', 'Audit Trail', 'Executive Summary']
        },
      ],
    );
  }

  void _showGenericReportDialog(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String reportId,
    List<Map<String, dynamic>> dropdowns,
  ) {
    Map<String, String> selectedValues = {};
    for (var dropdown in dropdowns) {
      selectedValues[dropdown['label']] = dropdown['options'][0];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Dynamic Dropdowns
                  ...dropdowns.map((dropdown) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dropdown['label'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedValues[dropdown['label']],
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: Constants.ctaColorLight),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              items: (dropdown['options'] as List<String>)
                                  .map((option) => DropdownMenuItem(
                                        value: option,
                                        child: Text(option),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedValues[dropdown['label']] = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    );
                  }).toList(),

                  SizedBox(height: 8),

                  // Download Sample Data Buttons (only for maintenance_report)
                  if (reportId == 'maintenance_report') ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No maintenance data? Download sample data to populate your database.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _downloadMaintenanceSampleData();
                                  },
                                  icon: Icon(Icons.table_chart, color: Colors.white, size: 16),
                                  label: Text(
                                    'CSV Data',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _downloadSampleMaintenancePDFReport();
                                  },
                                  icon: Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                                  label: Text(
                                    'PDF Report',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Footer buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              isGenerating = true;
                              selectedReportType = reportId;
                            });

                            // Generate the appropriate report based on reportId
                            if (reportId == 'alerts_summary') {
                              await _generateAlertsSummaryReport(
                                  selectedPeriod: selectedPeriod);
                              if (mounted) {
                                setState(() {
                                  isGenerating = false;
                                });
                                _showPDFPreviewDialog(title, reportId);
                              }
                            } else if (reportId == 'maintenance_report') {
                              await _generateMaintenanceReport(
                                  selectedPeriod: selectedPeriod);
                              if (mounted) {
                                setState(() {
                                  isGenerating = false;
                                });
                                _showPDFPreviewDialog(title, reportId);
                              }
                            } else {
                              // Default behavior for other reports (simulated delay)
                              Future.delayed(Duration(seconds: 2), () {
                                if (mounted) {
                                  setState(() {
                                    isGenerating = false;
                                  });
                                  _showSuccessDialog(title);
                                }
                              });
                            }
                          },
                          child: Text(
                            'Generate Report',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showScheduledReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int totalPages = (scheduledReports.length / itemsPerPage).ceil();
          int startIndex = currentPage * itemsPerPage;
          int endIndex = (startIndex + itemsPerPage < scheduledReports.length)
              ? startIndex + itemsPerPage
              : scheduledReports.length;
          List<ScheduledReport> currentPageReports =
              scheduledReports.sublist(startIndex, endIndex);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 800, maxHeight: 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.time,
                              color: Colors.purple,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Reports',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${scheduledReports.length} total schedules',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Report List
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentPageReports.length,
                      itemBuilder: (context, index) {
                        final report = currentPageReports[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: report.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  report.icon,
                                  color: report.color,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Report Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: report.isActive
                                                ? Colors.green
                                                    .withValues(alpha: 0.1)
                                                : Colors.grey
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            report.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: report.isActive
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.clock,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          report.frequency,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Icon(
                                          CupertinoIcons.arrow_right_circle,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          report.nextRun,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.doc,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Format: ${report.format}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.pencil,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {},
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.trash,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {},
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Pagination
                  if (totalPages > 1) ...[
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${startIndex + 1}-$endIndex of ${scheduledReports.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.chevron_left,
                                size: 18,
                              ),
                              onPressed: currentPage > 0
                                  ? () {
                                      setDialogState(() {
                                        currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            ...List.generate(totalPages, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    currentPage = index;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: currentPage == index
                                        ? Constants.ctaColorLight
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: currentPage == index
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                              ),
                              onPressed: currentPage < totalPages - 1
                                  ? () {
                                      setDialogState(() {
                                        currentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Footer buttons
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Add create new schedule logic here
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create New',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Reset page when dialog closes
      setState(() {
        currentPage = 0;
      });
    });
  }

  void _showDownloadsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int totalPages = (downloadedReports.length / itemsPerPage).ceil();
          int startIndex = downloadsCurrentPage * itemsPerPage;
          int endIndex = (startIndex + itemsPerPage < downloadedReports.length)
              ? startIndex + itemsPerPage
              : downloadedReports.length;
          var currentPageReports =
              downloadedReports.sublist(startIndex, endIndex);

          // Helper function to get icon and color by report type
          IconData _getReportIcon(String reportType) {
            switch (reportType) {
              case 'device_performance':
                return FontAwesomeIcons.chartLine;
              case 'temperature_analysis':
                return FontAwesomeIcons.temperatureHalf;
              case 'alerts_summary':
                return FontAwesomeIcons.bellConcierge;
              case 'maintenance':
                return FontAwesomeIcons.screwdriverWrench;
              case 'energy_consumption':
                return FontAwesomeIcons.bolt;
              case 'compliance':
                return FontAwesomeIcons.shieldHalved;
              default:
                return FontAwesomeIcons.fileLines;
            }
          }

          Color _getReportColor(String reportType) {
            switch (reportType) {
              case 'device_performance':
                return Color(0xFF4A90E2);
              case 'temperature_analysis':
                return Color(0xFFE94B3C);
              case 'alerts_summary':
                return Color(0xFFF5A623);
              case 'maintenance':
                return Color(0xFF7B68EE);
              case 'energy_consumption':
                return Color(0xFF50C878);
              case 'compliance':
                return Color(0xFF9B59B6);
              default:
                return Colors.grey;
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 900, maxHeight: 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_down_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Downloads This Month',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${downloadedReports.length} total downloads',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Report List
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentPageReports.length,
                      itemBuilder: (context, index) {
                        final report = currentPageReports[index];
                        final reportType = report['report_type'] ?? '';
                        final reportName =
                            report['report_name'] ?? 'Unknown Report';
                        final generatedBy = report['generated_by'] ?? 'Unknown';
                        final generatedAt = report['generated_at'] ?? '';
                        final fileSize = report['file_size'] ?? '0 MB';
                        final pageCount = report['page_count'] ?? 0;
                        final icon = _getReportIcon(reportType);
                        final color = _getReportColor(reportType);

                        // Format the date
                        String formattedDate = generatedAt;
                        try {
                          final dateTime = DateTime.parse(generatedAt);
                          formattedDate =
                              '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                        } catch (e) {
                          // Use as is if parsing fails
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Report Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reportName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.person,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          generatedBy,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Icon(
                                          CupertinoIcons.clock,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          formattedDate,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.doc,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PDF • $fileSize • $pageCount pages',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.eye,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {},
                                    tooltip: 'View',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.cloud_download,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {},
                                    tooltip: 'Download Again',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Pagination
                  if (totalPages > 1) ...[
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${startIndex + 1}-$endIndex of ${downloadedReports.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.chevron_left,
                                size: 18,
                              ),
                              onPressed: downloadsCurrentPage > 0
                                  ? () {
                                      setDialogState(() {
                                        downloadsCurrentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            ...List.generate(totalPages, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    downloadsCurrentPage = index;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: downloadsCurrentPage == index
                                        ? Constants.ctaColorLight
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: downloadsCurrentPage == index
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                              ),
                              onPressed: downloadsCurrentPage < totalPages - 1
                                  ? () {
                                      setDialogState(() {
                                        downloadsCurrentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Footer buttons
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Export downloads list
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.square_arrow_up,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Export List',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Reset page when dialog closes
      setState(() {
        downloadsCurrentPage = 0;
      });
    });
  }

  void _showGeneratedReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int totalPages = (generatedReports.length / itemsPerPage).ceil();
          int startIndex = generatedCurrentPage * itemsPerPage;
          int endIndex = (startIndex + itemsPerPage < generatedReports.length)
              ? startIndex + itemsPerPage
              : generatedReports.length;
          List<GeneratedReport> currentPageReports =
              generatedReports.sublist(startIndex, endIndex);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 900, maxHeight: 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.doc_text,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reports Generated',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${generatedReports.length} total reports',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Report List
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentPageReports.length,
                      itemBuilder: (context, index) {
                        final report = currentPageReports[index];
                        final isProcessing = report.status == 'Processing';

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: report.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  report.icon,
                                  color: report.color,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Report Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isProcessing
                                                ? Colors.orange
                                                    .withValues(alpha: 0.1)
                                                : Colors.green
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isProcessing)
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 4),
                                                  child: SizedBox(
                                                    width: 10,
                                                    height: 10,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              Text(
                                                report.status,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isProcessing
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.person,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          report.generatedBy,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Icon(
                                          CupertinoIcons.clock,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          report.generatedDate,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.doc,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${report.format}${!isProcessing ? ' • ${report.fileSize}' : ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.eye,
                                      size: 18,
                                      color: isProcessing
                                          ? Colors.grey
                                          : Colors.blue,
                                    ),
                                    onPressed: isProcessing ? null : () {},
                                    tooltip: 'View',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.cloud_download,
                                      size: 18,
                                      color: isProcessing
                                          ? Colors.grey
                                          : Colors.green,
                                    ),
                                    onPressed: isProcessing ? null : () {},
                                    tooltip: 'Download',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.trash,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {},
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Pagination
                  if (totalPages > 1) ...[
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${startIndex + 1}-$endIndex of ${generatedReports.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.chevron_left,
                                size: 18,
                              ),
                              onPressed: generatedCurrentPage > 0
                                  ? () {
                                      setDialogState(() {
                                        generatedCurrentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            ...List.generate(totalPages, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    generatedCurrentPage = index;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: generatedCurrentPage == index
                                        ? Constants.ctaColorLight
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: generatedCurrentPage == index
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                              ),
                              onPressed: generatedCurrentPage < totalPages - 1
                                  ? () {
                                      setDialogState(() {
                                        generatedCurrentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Footer buttons
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Generate new report
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.add_circled,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Generate New',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Reset page when dialog closes
      setState(() {
        generatedCurrentPage = 0;
      });
    });
  }

  void _showSuccessDialog(String reportName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Report Generated',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$reportName has been generated successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showPDFPreviewDialog(reportName);
                      },
                      child: Text(
                        'Preview',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDownloadDialog(
                          reportName,
                          onGenerate: () => _generateAndSavePDF('temperature_analysis'),
                        );
                      },
                      child: Text(
                        'Download',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPDFPreviewDialog(String reportName, [String? reportType]) {
    int currentPage = 1;
    int totalPages = reportType == 'alerts_summary'
        ? 5
        : (reportType == 'temperature_analysis'
            ? 8
            : (reportType == 'maintenance_report' ? 8 : 10));
    double zoomLevel = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text_fill,
                          color: Constants.ctaColorLight,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reportName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'PDF Preview',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.xmark, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Toolbar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Zoom Out
                        IconButton(
                          icon: Icon(CupertinoIcons.minus_circle, size: 20),
                          onPressed: zoomLevel > 0.5
                              ? () {
                                  setDialogState(() {
                                    zoomLevel -= 0.25;
                                  });
                                }
                              : null,
                          tooltip: 'Zoom Out',
                        ),
                        // Zoom Level
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${(zoomLevel * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Zoom In
                        IconButton(
                          icon: Icon(CupertinoIcons.plus_circle, size: 20),
                          onPressed: zoomLevel < 2.0
                              ? () {
                                  setDialogState(() {
                                    zoomLevel += 0.25;
                                  });
                                }
                              : null,
                          tooltip: 'Zoom In',
                        ),
                        SizedBox(width: 16),
                        // Fit to Width
                        TextButton.icon(
                          icon: Icon(CupertinoIcons.arrow_left_right, size: 16),
                          label: Text('Fit Width'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              zoomLevel = 1.0;
                            });
                          },
                        ),
                        SizedBox(width: 8),
                        // Fit to Page
                        TextButton.icon(
                          icon: Icon(CupertinoIcons.arrow_up_down, size: 16),
                          label: Text('Fit Page'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              zoomLevel = 0.75;
                            });
                          },
                        ),
                        Spacer(),
                        // Page Navigation
                        IconButton(
                          icon: Icon(CupertinoIcons.chevron_left, size: 20),
                          onPressed: currentPage > 1
                              ? () {
                                  setDialogState(() {
                                    currentPage--;
                                  });
                                }
                              : null,
                          tooltip: 'Previous Page',
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$currentPage / $totalPages',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.chevron_right, size: 20),
                          onPressed: currentPage < totalPages
                              ? () {
                                  setDialogState(() {
                                    currentPage++;
                                  });
                                }
                              : null,
                          tooltip: 'Next Page',
                        ),
                      ],
                    ),
                  ),

                  // PDF Preview Area
                  Expanded(
                    child: Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            width: 600 * zoomLevel,
                            margin: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: AspectRatio(
                              aspectRatio: 8.5 / 11,
                              child: Container(
                                padding: EdgeInsets.all(40 * zoomLevel),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Artic Sentinel',
                                              style: GoogleFonts.inter(
                                                fontSize: 20 * zoomLevel,
                                                fontWeight: FontWeight.w700,
                                                color: Constants.ctaColorLight,
                                              ),
                                            ),
                                            SizedBox(height: 4 * zoomLevel),
                                            Text(
                                              'Device Monitoring System',
                                              style: GoogleFonts.inter(
                                                fontSize: 10 * zoomLevel,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Page $currentPage',
                                          style: GoogleFonts.inter(
                                            fontSize: 10 * zoomLevel,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20 * zoomLevel),
                                    Divider(
                                        thickness: 1,
                                        color:
                                            Colors.grey.withValues(alpha: 0.3)),
                                    SizedBox(height: 20 * zoomLevel),
                                    // Report Title
                                    Text(
                                      reportName,
                                      style: GoogleFonts.inter(
                                        fontSize: 18 * zoomLevel,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 8 * zoomLevel),
                                    Text(
                                      'Generated on: ${DateTime.now().toString().substring(0, 16)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10 * zoomLevel,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (lastGeneratedReportStartDate != null &&
                                        lastGeneratedReportEndDate != null) ...[
                                      SizedBox(height: 4 * zoomLevel),
                                      Text(
                                        'Report Period: ${lastGeneratedReportStartDate} to ${lastGeneratedReportEndDate}',
                                        style: GoogleFonts.inter(
                                          fontSize: 10 * zoomLevel,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (lastGeneratedReportPeriod != null) ...[
                                      SizedBox(height: 2 * zoomLevel),
                                      Text(
                                        'Time Range: $lastGeneratedReportPeriod',
                                        style: GoogleFonts.inter(
                                          fontSize: 9 * zoomLevel,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 20 * zoomLevel),

                                    // Page-specific content
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: _buildPageContent(currentPage,
                                            zoomLevel, reportName, reportType),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.1),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDownloadDialog(
                                reportName,
                                onGenerate: () => _generateAndSavePDF('alerts_summary'),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.cloud_download,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Download',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageContent(int pageNumber, double zoomLevel, String reportName,
      [String? reportType]) {
    // Alerts Summary Report pages
    if (reportType == 'alerts_summary') {
      if (lastGeneratedAlertsReportData == null) {
        return _buildPlaceholderContent(pageNumber, zoomLevel);
      }

      switch (pageNumber) {
        case 1:
          return _buildAlertsSummaryOverviewPage(zoomLevel);
        case 2:
          return _buildAlertsBySeverityPage(zoomLevel);
        case 3:
          return _buildAlertsByDevicePage(zoomLevel);
        case 4:
          return _buildAlertsTrendsPage(zoomLevel);
        case 5:
          return _buildActiveAlertsPage(zoomLevel);
        default:
          return _buildPlaceholderContent(pageNumber, zoomLevel);
      }
    }

    // Temperature Analysis Report pages
    if (reportType == 'temperature_analysis') {
      if (lastGeneratedTempReportData == null ||
          lastGeneratedTempReportData!.isEmpty) {
        return _buildPlaceholderContent(pageNumber, zoomLevel);
      }

      switch (pageNumber) {
        case 1:
          return _buildTempAnalysisSummaryPage(zoomLevel);
        case 2:
          return _buildTempSensorComparisonPage(zoomLevel);
        case 3:
          return _buildTempDailyTrendsPage(zoomLevel);
        case 4:
          return _buildTempDistributionPage(zoomLevel);
        case 5:
          return _buildTempViolationsPage(zoomLevel);
        case 6:
          return _buildTempRangeAnalysisPage(zoomLevel);
        case 7:
          return _buildTempDetailedStatsPage(zoomLevel);
        case 8:
          return _buildTempRecommendationsPage(zoomLevel);
        default:
          return _buildPlaceholderContent(pageNumber, zoomLevel);
      }
    }

    // Maintenance Report pages
    if (reportType == 'maintenance_report') {
      if (lastGeneratedMaintenanceReportData == null) {
        return _buildPlaceholderContent(pageNumber, zoomLevel);
      }

      switch (pageNumber) {
        case 1:
          return _buildMaintenanceSummaryPage(zoomLevel);
        case 2:
          return _buildMaintenanceByTypePage(zoomLevel);
        case 3:
          return _buildMaintenanceByDevicePage(zoomLevel);
        case 4:
          return _buildMaintenanceCostAnalysisPage(zoomLevel);
        case 5:
          return _buildMaintenanceTrendsPage(zoomLevel);
        case 6:
          return _buildRecentCompletedMaintenancePage(zoomLevel);
        case 7:
          return _buildUpcomingMaintenancePage(zoomLevel);
        case 8:
          return _buildOverdueMaintenancePage(zoomLevel);
        default:
          return _buildPlaceholderContent(pageNumber, zoomLevel);
      }
    }

    // Device Performance Report pages (default)
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(pageNumber, zoomLevel);
    }

    switch (pageNumber) {
      case 1:
        return _buildExecutiveSummaryPage(zoomLevel);
      case 2:
        return _buildDetailedMetricsTablePage(zoomLevel);
      case 3:
        return _buildTemperatureAnalyticsPage(zoomLevel);
      case 4:
        return _buildPowerConsumptionPage(zoomLevel);
      case 5:
        return _buildOperationalMetricsPage(zoomLevel);
      case 6:
        return _buildDeviceComparisonPage(zoomLevel);
      case 7:
        return _buildHealthScorePage(zoomLevel);
      case 8:
        return _buildDailyAveragesPage(zoomLevel);
      case 9:
        return _buildDailyTrendsChartsPage(zoomLevel);
      case 10:
        return _buildRecommendationsPage(zoomLevel);
      default:
        return _buildPlaceholderContent(pageNumber, zoomLevel);
    }
  }

  Widget _buildExecutiveSummaryPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(1, zoomLevel);
    }

    // Calculate comprehensive statistics
    final avgTemp = lastGeneratedReportData!
            .map((d) => d.avgTemperature)
            .reduce((a, b) => a + b) /
        lastGeneratedReportData!.length;
    final avgUptime =
        lastGeneratedReportData!.map((d) => d.uptime).reduce((a, b) => a + b) /
            lastGeneratedReportData!.length;
    final totalPower = lastGeneratedReportData!
        .map((d) => d.powerConsumption)
        .reduce((a, b) => a + b);
    final avgPower = totalPower / lastGeneratedReportData!.length;
    final totalDoors = lastGeneratedReportData!
        .map((d) => d.doorOpenCount)
        .reduce((a, b) => a + b);
    final avgPressure = lastGeneratedReportData!
            .map((d) => d.avgPressure)
            .reduce((a, b) => a + b) /
        lastGeneratedReportData!.length;

    // Best and worst performers
    final bestUptime =
        lastGeneratedReportData!.reduce((a, b) => a.uptime > b.uptime ? a : b);
    final worstUptime =
        lastGeneratedReportData!.reduce((a, b) => a.uptime < b.uptime ? a : b);
    final highestPower = lastGeneratedReportData!
        .reduce((a, b) => a.powerConsumption > b.powerConsumption ? a : b);

    // Health distribution
    final healthCounts = <String, int>{};
    for (var device in lastGeneratedReportData!) {
      healthCounts[device.healthGrade] =
          (healthCounts[device.healthGrade] ?? 0) + 1;
    }
    final healthyDevices = (healthCounts['A'] ?? 0) + (healthCounts['B'] ?? 0);
    final criticalDevices = (healthCounts['D'] ?? 0) + (healthCounts['F'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Executive Summary',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6 * zoomLevel),
        Text(
          'This comprehensive report analyzes ${lastGeneratedReportData!.length} device${lastGeneratedReportData!.length > 1 ? "s" : ""} over the specified period, providing detailed insights into performance, efficiency, and operational health.',
          style: GoogleFonts.inter(
            fontSize: 9 * zoomLevel,
            color: Colors.black54,
            height: 1.4,
          ),
        ),

        SizedBox(height: 12 * zoomLevel),

        // Key Findings Box
        Container(
          padding: EdgeInsets.all(10 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 12 * zoomLevel, color: Colors.blue),
                  SizedBox(width: 6 * zoomLevel),
                  Text(
                    'Key Findings',
                    style: GoogleFonts.inter(
                      fontSize: 11 * zoomLevel,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * zoomLevel),
              _buildFindingItem(
                  'Fleet Health: $healthyDevices/${lastGeneratedReportData!.length} devices in good condition',
                  avgUptime > 85 ? Icons.check_circle : Icons.warning,
                  avgUptime > 85 ? Colors.green : Colors.orange,
                  zoomLevel),
              _buildFindingItem(
                  'Average Uptime: ${avgUptime.toStringAsFixed(1)}% ${avgUptime > 90 ? "(Excellent)" : avgUptime > 80 ? "(Good)" : "(Needs Attention)"}',
                  Icons.access_time,
                  avgUptime > 85 ? Colors.green : Colors.orange,
                  zoomLevel),
              _buildFindingItem(
                  'Total Power Consumption: ${totalPower.toStringAsFixed(1)} kWh across all devices',
                  Icons.bolt,
                  Colors.orange,
                  zoomLevel),
              if (criticalDevices > 0)
                _buildFindingItem(
                    '$criticalDevices device${criticalDevices > 1 ? "s" : ""} require immediate attention',
                    Icons.error_outline,
                    Colors.red,
                    zoomLevel),
            ],
          ),
        ),

        SizedBox(height: 10 * zoomLevel),

        // Performance Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                  'Devices',
                  '${lastGeneratedReportData!.length}',
                  Icons.devices,
                  Colors.blue,
                  zoomLevel),
            ),
            SizedBox(width: 8 * zoomLevel),
            Expanded(
              child: _buildMetricCard(
                  'Avg Temp',
                  '${avgTemp.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  Colors.cyan,
                  zoomLevel),
            ),
            SizedBox(width: 8 * zoomLevel),
            Expanded(
              child: _buildMetricCard(
                  'Uptime',
                  '${avgUptime.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.green,
                  zoomLevel),
            ),
            SizedBox(width: 8 * zoomLevel),
            Expanded(
              child: _buildMetricCard(
                  'Power',
                  '${avgPower.toStringAsFixed(1)}kW',
                  Icons.bolt,
                  Colors.orange,
                  zoomLevel),
            ),
          ],
        ),

        SizedBox(height: 10 * zoomLevel),

        // Performance Highlights Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8 * zoomLevel),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Text('Performance Highlights',
                    style: GoogleFonts.inter(
                        fontSize: 10 * zoomLevel, fontWeight: FontWeight.w600)),
              ),
              _buildTableRow(
                  'Best Uptime',
                  bestUptime.deviceName,
                  '${bestUptime.uptime.toStringAsFixed(1)}%',
                  Colors.green,
                  zoomLevel),
              _buildTableRow(
                  'Lowest Uptime',
                  worstUptime.deviceName,
                  '${worstUptime.uptime.toStringAsFixed(1)}%',
                  Colors.orange,
                  zoomLevel),
              _buildTableRow(
                  'Highest Power Usage',
                  highestPower.deviceName,
                  '${highestPower.powerConsumption.toStringAsFixed(1)} kWh',
                  Colors.red,
                  zoomLevel),
              _buildTableRow('Total Door Operations', 'All Devices',
                  '$totalDoors', Colors.blue, zoomLevel),
            ],
          ),
        ),

        SizedBox(height: 10 * zoomLevel),

        // Quick Recommendations
        Container(
          padding: EdgeInsets.all(8 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Quick Recommendations',
                style: GoogleFonts.inter(
                  fontSize: 10 * zoomLevel,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 6 * zoomLevel),
              if (avgUptime < 85)
                _buildRecommendationBullet(
                    'Focus on improving uptime for devices below 80%',
                    zoomLevel),
              if (criticalDevices > 0)
                _buildRecommendationBullet(
                    'Schedule immediate maintenance for $criticalDevices critical device${criticalDevices > 1 ? "s" : ""}',
                    zoomLevel),
              if (totalPower > lastGeneratedReportData!.length * 20)
                _buildRecommendationBullet(
                    'Review energy efficiency - power consumption is above normal',
                    zoomLevel),
              _buildRecommendationBullet(
                  'Review detailed analytics on pages 2-7 for specific insights',
                  zoomLevel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFindingItem(
      String text, IconData icon, Color color, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4 * zoomLevel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 10 * zoomLevel, color: color),
          SizedBox(width: 6 * zoomLevel),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 8 * zoomLevel, color: Colors.black87, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon,
      Color color, double zoomLevel) {
    return Container(
      padding: EdgeInsets.all(8 * zoomLevel),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16 * zoomLevel, color: color),
          SizedBox(height: 4 * zoomLevel),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 7 * zoomLevel, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String device, String value, Color color,
      double zoomLevel) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 8 * zoomLevel, vertical: 6 * zoomLevel),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 8 * zoomLevel, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(device,
                style: GoogleFonts.inter(
                    fontSize: 8 * zoomLevel, color: Colors.black54)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 8 * zoomLevel,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationBullet(String text, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * zoomLevel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.inter(
                  fontSize: 8 * zoomLevel, color: Colors.green.shade700)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 8 * zoomLevel, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricsTablePage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(2, zoomLevel);
    }

    // Calculate statistics
    final totalPower = lastGeneratedReportData!
        .map((d) => d.powerConsumption)
        .reduce((a, b) => a + b);
    final avgUptime =
        lastGeneratedReportData!.map((d) => d.uptime).reduce((a, b) => a + b) /
            lastGeneratedReportData!.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Device Metrics',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8 * zoomLevel),

        // Summary stats row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(6 * zoomLevel),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text('${lastGeneratedReportData!.length}',
                        style: GoogleFonts.inter(
                            fontSize: 12 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    Text('Total Devices',
                        style: GoogleFonts.inter(
                            fontSize: 7 * zoomLevel, color: Colors.black54)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 6 * zoomLevel),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(6 * zoomLevel),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text('${avgUptime.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                            fontSize: 12 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    Text('Avg Uptime',
                        style: GoogleFonts.inter(
                            fontSize: 7 * zoomLevel, color: Colors.black54)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 6 * zoomLevel),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(6 * zoomLevel),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text('${totalPower.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 12 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    Text('Total kWh',
                        style: GoogleFonts.inter(
                            fontSize: 7 * zoomLevel, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 10 * zoomLevel),

        // Main metrics table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6 * zoomLevel, vertical: 6 * zoomLevel),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('Device',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        child: Text('Temp',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text('Uptime',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text('Power',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text('Health',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Table Rows
              ...lastGeneratedReportData!.map((device) => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6 * zoomLevel, vertical: 5 * zoomLevel),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1))),
                      color: device.uptime < 80
                          ? Colors.red.withValues(alpha: 0.02)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            device.deviceName,
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${device.avgTemperature.toStringAsFixed(1)}°C',
                            style: GoogleFonts.inter(fontSize: 7 * zoomLevel),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: device.uptime > 90
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : device.uptime > 80
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${device.uptime.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w600,
                                color: device.uptime > 90
                                    ? Colors.green
                                    : device.uptime > 80
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${device.powerConsumption.toStringAsFixed(1)}',
                            style: GoogleFonts.inter(fontSize: 7 * zoomLevel),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getHealthColor(device.healthGrade)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              device.healthGrade,
                              style: GoogleFonts.inter(
                                  fontSize: 7 * zoomLevel,
                                  fontWeight: FontWeight.w600,
                                  color: _getHealthColor(device.healthGrade)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        SizedBox(height: 10 * zoomLevel),

        // Additional details table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(6 * zoomLevel),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Text('Operational Details',
                    style: GoogleFonts.inter(
                        fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6 * zoomLevel, vertical: 4 * zoomLevel),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('Device',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        child: Text('Min T',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text('Max T',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text('Pressure',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text('Doors',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
              ...lastGeneratedReportData!.map((device) => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6 * zoomLevel, vertical: 4 * zoomLevel),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(device.deviceName,
                                style:
                                    GoogleFonts.inter(fontSize: 7 * zoomLevel),
                                overflow: TextOverflow.ellipsis)),
                        Expanded(
                            child: Text(
                                '${device.minTemperature.toStringAsFixed(1)}°',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel,
                                    color: Colors.blue),
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(
                                '${device.maxTemperature.toStringAsFixed(1)}°',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel, color: Colors.red),
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(
                                '${device.avgPressure.toStringAsFixed(0)}',
                                style:
                                    GoogleFonts.inter(fontSize: 7 * zoomLevel),
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text('${device.doorOpenCount}',
                                style:
                                    GoogleFonts.inter(fontSize: 7 * zoomLevel),
                                textAlign: TextAlign.center)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureAnalyticsPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(3, zoomLevel);
    }

    final minTemp = lastGeneratedReportData!
        .map((d) => d.minTemperature)
        .reduce((a, b) => a < b ? a : b);
    final maxTemp = lastGeneratedReportData!
        .map((d) => d.maxTemperature)
        .reduce((a, b) => a > b ? a : b);
    final avgTemp = lastGeneratedReportData!
            .map((d) => d.avgTemperature)
            .reduce((a, b) => a + b) /
        lastGeneratedReportData!.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temperature Analytics',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * zoomLevel),

        // Line Chart
        Container(
          height: 200 * zoomLevel,
          padding: EdgeInsets.all(12 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Temperature Trends',
                  style: GoogleFonts.inter(
                      fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
              SizedBox(height: 8 * zoomLevel),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30 * zoomLevel,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}°C',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel, color: Colors.black54),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20 * zoomLevel,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() <
                                lastGeneratedReportData!.length) {
                              return Text(
                                'D${value.toInt() + 1}',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel,
                                    color: Colors.black54),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2))),
                    lineBarsData: [
                      // Average temperature line
                      LineChartBarData(
                        spots: lastGeneratedReportData!
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                e.key.toDouble(), e.value.avgTemperature))
                            .toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1)),
                      ),
                      // Max temperature line
                      LineChartBarData(
                        spots: lastGeneratedReportData!
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                e.key.toDouble(), e.value.maxTemperature))
                            .toList(),
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 1.5,
                        dotData: FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                      // Min temperature line
                      LineChartBarData(
                        spots: lastGeneratedReportData!
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                e.key.toDouble(), e.value.minTemperature))
                            .toList(),
                        isCurved: true,
                        color: Colors.cyan,
                        barWidth: 1.5,
                        dotData: FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8 * zoomLevel),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Avg', Colors.blue, zoomLevel),
                  SizedBox(width: 12 * zoomLevel),
                  _buildLegendItem('Max', Colors.red, zoomLevel),
                  SizedBox(width: 12 * zoomLevel),
                  _buildLegendItem('Min', Colors.cyan, zoomLevel),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Container(
          padding: EdgeInsets.all(10 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _buildMetricRow('Minimum Temperature',
                  '${minTemp.toStringAsFixed(1)}°C', zoomLevel),
              _buildMetricRow('Maximum Temperature',
                  '${maxTemp.toStringAsFixed(1)}°C', zoomLevel),
              _buildMetricRow('Average Temperature',
                  '${avgTemp.toStringAsFixed(1)}°C', zoomLevel),
              _buildMetricRow('Temperature Range',
                  '${(maxTemp - minTemp).toStringAsFixed(1)}°C', zoomLevel),
            ],
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Text(
          'Device Temperature Distribution',
          style: GoogleFonts.inter(
            fontSize: 11 * zoomLevel,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8 * zoomLevel),
        ...lastGeneratedReportData!.map((device) => Padding(
              padding: EdgeInsets.only(bottom: 6 * zoomLevel),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(device.deviceName,
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          height: 12 * zoomLevel,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor:
                              (device.avgTemperature.abs() / 30).clamp(0, 1),
                          child: Container(
                            height: 12 * zoomLevel,
                            decoration: BoxDecoration(
                              color:
                                  _getTemperatureColor(device.avgTemperature),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * zoomLevel),
                  Text('${device.avgTemperature.toStringAsFixed(1)}°C',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPowerConsumptionPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(4, zoomLevel);
    }

    final totalPower = lastGeneratedReportData!
        .map((d) => d.powerConsumption)
        .reduce((a, b) => a + b);
    final avgPower = totalPower / lastGeneratedReportData!.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Power Consumption Analytics',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * zoomLevel),

        // Pie Chart
        Container(
          height: 250 * zoomLevel,
          padding: EdgeInsets.all(12 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text('Power Distribution by Device',
                  style: GoogleFonts.inter(
                      fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
              SizedBox(height: 8 * zoomLevel),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40 * zoomLevel,
                          sections:
                              lastGeneratedReportData!.asMap().entries.map((e) {
                            final percentage =
                                (e.value.powerConsumption / totalPower * 100);
                            return PieChartSectionData(
                              color: _getPowerColor(e.key),
                              value: e.value.powerConsumption,
                              title: '${percentage.toStringAsFixed(1)}%',
                              radius: 50 * zoomLevel,
                              titleStyle: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * zoomLevel),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: lastGeneratedReportData!
                              .asMap()
                              .entries
                              .map((e) => Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 6 * zoomLevel),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10 * zoomLevel,
                                          height: 10 * zoomLevel,
                                          decoration: BoxDecoration(
                                            color: _getPowerColor(e.key),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        SizedBox(width: 6 * zoomLevel),
                                        Expanded(
                                          child: Text(
                                            e.value.deviceName,
                                            style: GoogleFonts.inter(
                                                fontSize: 7 * zoomLevel),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Container(
          padding: EdgeInsets.all(10 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _buildMetricRow('Total Power Consumption',
                  '${totalPower.toStringAsFixed(1)} kWh', zoomLevel),
              _buildMetricRow('Average per Device',
                  '${avgPower.toStringAsFixed(1)} kWh', zoomLevel),
              _buildMetricRow('Number of Devices',
                  '${lastGeneratedReportData!.length}', zoomLevel),
            ],
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Text(
          'Power Consumption by Device',
          style: GoogleFonts.inter(
            fontSize: 11 * zoomLevel,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8 * zoomLevel),
        ...lastGeneratedReportData!.map((device) => Padding(
              padding: EdgeInsets.only(bottom: 6 * zoomLevel),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(device.deviceName,
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          height: 12 * zoomLevel,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (device.powerConsumption / totalPower)
                              .clamp(0, 1),
                          child: Container(
                            height: 12 * zoomLevel,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * zoomLevel),
                  Text('${device.powerConsumption.toStringAsFixed(1)} kWh',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildOperationalMetricsPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(5, zoomLevel);
    }

    final avgUptime =
        lastGeneratedReportData!.map((d) => d.uptime).reduce((a, b) => a + b) /
            lastGeneratedReportData!.length;
    final totalDoors = lastGeneratedReportData!
        .map((d) => d.doorOpenCount)
        .reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Metrics',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * zoomLevel),

        // Bar Chart for Uptime
        Container(
          height: 220 * zoomLevel,
          padding: EdgeInsets.all(12 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Uptime Comparison',
                  style: GoogleFonts.inter(
                      fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
              SizedBox(height: 8 * zoomLevel),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30 * zoomLevel,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel, color: Colors.black54),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30 * zoomLevel,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() <
                                lastGeneratedReportData!.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 4 * zoomLevel),
                                child: Text(
                                  'D${value.toInt() + 1}',
                                  style: GoogleFonts.inter(
                                      fontSize: 7 * zoomLevel,
                                      color: Colors.black54),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2))),
                    barGroups:
                        lastGeneratedReportData!.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.uptime,
                            color: e.value.uptime > 80
                                ? Colors.green
                                : Colors.orange,
                            width: 16 * zoomLevel,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
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

        SizedBox(height: 12 * zoomLevel),
        Container(
          padding: EdgeInsets.all(10 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _buildMetricRow('Average Uptime',
                  '${avgUptime.toStringAsFixed(1)}%', zoomLevel),
              _buildMetricRow(
                  'Total Door Operations', '$totalDoors', zoomLevel),
              _buildMetricRow(
                  'Avg Pressure',
                  '${(lastGeneratedReportData!.map((d) => d.avgPressure).reduce((a, b) => a + b) / lastGeneratedReportData!.length).toStringAsFixed(1)}',
                  zoomLevel),
            ],
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Text(
          'Device Status Details',
          style: GoogleFonts.inter(
            fontSize: 11 * zoomLevel,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8 * zoomLevel),
        ...lastGeneratedReportData!.map((device) => Padding(
              padding: EdgeInsets.only(bottom: 6 * zoomLevel),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(device.deviceName,
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          height: 12 * zoomLevel,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (device.uptime / 100).clamp(0, 1),
                          child: Container(
                            height: 12 * zoomLevel,
                            decoration: BoxDecoration(
                              color: device.uptime > 80
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * zoomLevel),
                  Text('${device.uptime.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildDeviceComparisonPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(6, zoomLevel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Comparison',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * zoomLevel),
        Text(
          'This page compares all devices across key performance metrics.',
          style: GoogleFonts.inter(
            fontSize: 10 * zoomLevel,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16 * zoomLevel),
        ...lastGeneratedReportData!.map((device) => Container(
              margin: EdgeInsets.only(bottom: 12 * zoomLevel),
              padding: EdgeInsets.all(10 * zoomLevel),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(device.deviceName,
                          style: GoogleFonts.inter(
                              fontSize: 11 * zoomLevel,
                              fontWeight: FontWeight.w600)),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getHealthColor(device.healthGrade)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(device.healthGrade,
                            style: GoogleFonts.inter(
                                fontSize: 9 * zoomLevel,
                                fontWeight: FontWeight.w600,
                                color: _getHealthColor(device.healthGrade))),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * zoomLevel),
                  Row(
                    children: [
                      Expanded(
                          child: _buildSmallMetric(
                              'Temp',
                              '${device.avgTemperature.toStringAsFixed(1)}°C',
                              zoomLevel)),
                      Expanded(
                          child: _buildSmallMetric(
                              'Uptime',
                              '${device.uptime.toStringAsFixed(1)}%',
                              zoomLevel)),
                      Expanded(
                          child: _buildSmallMetric(
                              'Power',
                              '${device.powerConsumption.toStringAsFixed(1)}kWh',
                              zoomLevel)),
                      Expanded(
                          child: _buildSmallMetric(
                              'Doors', '${device.doorOpenCount}', zoomLevel)),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHealthScorePage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(7, zoomLevel);
    }

    final healthCounts = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0, 'N/A': 0};
    for (var device in lastGeneratedReportData!) {
      healthCounts[device.healthGrade] =
          (healthCounts[device.healthGrade] ?? 0) + 1;
    }
    final nonZeroHealthCounts =
        healthCounts.entries.where((e) => e.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Health Scores',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * zoomLevel),

        // Health Pie Chart
        Container(
          height: 250 * zoomLevel,
          padding: EdgeInsets.all(12 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text('Health Grade Distribution',
                  style: GoogleFonts.inter(
                      fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
              SizedBox(height: 8 * zoomLevel),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40 * zoomLevel,
                          sections: nonZeroHealthCounts.map((entry) {
                            final percentage = (entry.value /
                                lastGeneratedReportData!.length *
                                100);
                            return PieChartSectionData(
                              color: _getHealthColor(entry.key),
                              value: entry.value.toDouble(),
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: 50 * zoomLevel,
                              titleStyle: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * zoomLevel),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: nonZeroHealthCounts
                            .map((entry) => Padding(
                                  padding:
                                      EdgeInsets.only(bottom: 8 * zoomLevel),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16 * zoomLevel,
                                        height: 16 * zoomLevel,
                                        decoration: BoxDecoration(
                                          color: _getHealthColor(entry.key),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Center(
                                          child: Text(
                                            entry.key,
                                            style: GoogleFonts.inter(
                                              fontSize: 9 * zoomLevel,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8 * zoomLevel),
                                      Expanded(
                                        child: Text(
                                          '${entry.value} device${entry.value > 1 ? "s" : ""}',
                                          style: GoogleFonts.inter(
                                              fontSize: 8 * zoomLevel),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Container(
          padding: EdgeInsets.all(10 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nonZeroHealthCounts
                .map((entry) => _buildMetricRow(
                      'Grade ${entry.key}',
                      '${entry.value} device${entry.value > 1 ? "s" : ""} (${(entry.value / lastGeneratedReportData!.length * 100).toStringAsFixed(1)}%)',
                      zoomLevel,
                    ))
                .toList(),
          ),
        ),

        SizedBox(height: 12 * zoomLevel),
        Text(
          'Devices Requiring Attention',
          style: GoogleFonts.inter(
            fontSize: 11 * zoomLevel,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8 * zoomLevel),
        ...lastGeneratedReportData!
            .where((d) => ['C', 'D', 'F'].contains(d.healthGrade))
            .map((device) => Container(
                  margin: EdgeInsets.only(bottom: 6 * zoomLevel),
                  padding: EdgeInsets.all(8 * zoomLevel),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          size: 14 * zoomLevel, color: Colors.orange),
                      SizedBox(width: 8 * zoomLevel),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device.deviceName,
                                style: GoogleFonts.inter(
                                    fontSize: 9 * zoomLevel,
                                    fontWeight: FontWeight.w600)),
                            Text(
                                'Health Grade: ${device.healthGrade} - Requires maintenance',
                                style: GoogleFonts.inter(
                                    fontSize: 8 * zoomLevel,
                                    color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
      ],
    );
  }

  Widget _buildDailyAveragesPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(8, zoomLevel);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Averages',
            style: GoogleFonts.inter(
              fontSize: 14 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12 * zoomLevel),

          // Daily Temperature Averages Table
          Text(
            'Daily Temperature Averages (°C)',
            style: GoogleFonts.inter(
              fontSize: 11 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8 * zoomLevel),
          _buildDailyTemperatureTable(zoomLevel),

          SizedBox(height: 16 * zoomLevel),

          // Daily Door Operations Table
          Text(
            'Daily Door Operations',
            style: GoogleFonts.inter(
              fontSize: 11 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8 * zoomLevel),
          _buildDailyDoorTable(zoomLevel),

          SizedBox(height: 16 * zoomLevel),

          // Daily Power Consumption Table
          Text(
            'Daily Power Consumption (kWh)',
            style: GoogleFonts.inter(
              fontSize: 11 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8 * zoomLevel),
          _buildDailyPowerTable(zoomLevel),
        ],
      ),
    );
  }

  Widget _buildDailyTemperatureTable(double zoomLevel) {
    // Get all unique dates from all devices
    final allDailyData = <String, Map<String, dynamic>>{};

    for (var device in lastGeneratedReportData!) {
      if (device.dailyTemperatureData != null) {
        for (var dayData in device.dailyTemperatureData!) {
          final date = dayData['date'] ?? '';
          if (!allDailyData.containsKey(date)) {
            allDailyData[date] = {
              'avg': [],
              'min': [],
              'max': [],
            };
          }
          allDailyData[date]!['avg'].add(dayData['avg_temperature'] ?? 0.0);
          allDailyData[date]!['min'].add(dayData['min_temperature'] ?? 0.0);
          allDailyData[date]!['max'].add(dayData['max_temperature'] ?? 0.0);
        }
      }
    }

    if (allDailyData.isEmpty) {
      return Text('No daily temperature data available',
          style: GoogleFonts.inter(
              fontSize: 9 * zoomLevel, color: Colors.black54));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 8 * zoomLevel, horizontal: 12 * zoomLevel),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('Avg',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Min',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Max',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          // Rows
          ...allDailyData.entries.take(10).map((entry) {
            final avgList = entry.value['avg'] as List;
            final minList = entry.value['min'] as List;
            final maxList = entry.value['max'] as List;

            final avgTemp = avgList.isEmpty
                ? 0.0
                : avgList.reduce((a, b) => a + b) / avgList.length;
            final minTemp =
                minList.isEmpty ? 0.0 : minList.reduce((a, b) => a < b ? a : b);
            final maxTemp =
                maxList.isEmpty ? 0.0 : maxList.reduce((a, b) => a > b ? a : b);

            return Container(
              padding: EdgeInsets.symmetric(
                  vertical: 6 * zoomLevel, horizontal: 12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key,
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
                  ),
                  Expanded(
                    child: Text('${avgTemp.toStringAsFixed(1)}°',
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('${minTemp.toStringAsFixed(1)}°',
                        style: GoogleFonts.inter(
                            fontSize: 8 * zoomLevel, color: Colors.blue),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('${maxTemp.toStringAsFixed(1)}°',
                        style: GoogleFonts.inter(
                            fontSize: 8 * zoomLevel, color: Colors.red),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDailyDoorTable(double zoomLevel) {
    // Get all unique dates from all devices
    final allDailyData = <String, int>{};

    for (var device in lastGeneratedReportData!) {
      if (device.dailyDoorData != null) {
        for (var dayData in device.dailyDoorData!) {
          final date = dayData['date'] ?? '';
          final operations = (dayData['door_operations'] ?? 0) as int;
          allDailyData[date] = (allDailyData[date] ?? 0) + operations;
        }
      }
    }

    if (allDailyData.isEmpty) {
      return Text('No daily door operations data available',
          style: GoogleFonts.inter(
              fontSize: 9 * zoomLevel, color: Colors.black54));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 8 * zoomLevel, horizontal: 12 * zoomLevel),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('Operations',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          // Rows
          ...allDailyData.entries.take(10).map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(
                  vertical: 6 * zoomLevel, horizontal: 12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key,
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
                  ),
                  Expanded(
                    child: Text('${entry.value}',
                        style: GoogleFonts.inter(
                            fontSize: 8 * zoomLevel,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDailyPowerTable(double zoomLevel) {
    // Get all unique dates from all devices
    final allDailyData = <String, Map<String, double>>{};

    for (var device in lastGeneratedReportData!) {
      if (device.dailyPowerData != null) {
        for (var dayData in device.dailyPowerData!) {
          final date = dayData['date'] ?? '';
          if (!allDailyData.containsKey(date)) {
            allDailyData[date] = {
              'phase1': 0.0,
              'phase2': 0.0,
              'phase3': 0.0,
              'total': 0.0,
            };
          }
          allDailyData[date]!['phase1'] =
              (allDailyData[date]!['phase1'] ?? 0.0) +
                  (dayData['phase1_consumption'] ?? 0.0);
          allDailyData[date]!['phase2'] =
              (allDailyData[date]!['phase2'] ?? 0.0) +
                  (dayData['phase2_consumption'] ?? 0.0);
          allDailyData[date]!['phase3'] =
              (allDailyData[date]!['phase3'] ?? 0.0) +
                  (dayData['phase3_consumption'] ?? 0.0);
          allDailyData[date]!['total'] = (allDailyData[date]!['total'] ?? 0.0) +
              (dayData['total_consumption'] ?? 0.0);
        }
      }
    }

    if (allDailyData.isEmpty) {
      return Text('No daily power consumption data available',
          style: GoogleFonts.inter(
              fontSize: 9 * zoomLevel, color: Colors.black54));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 8 * zoomLevel, horizontal: 12 * zoomLevel),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('Phase 1',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Phase 2',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Phase 3',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Total',
                      style: GoogleFonts.inter(
                          fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          // Rows
          ...allDailyData.entries.take(10).map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(
                  vertical: 6 * zoomLevel, horizontal: 12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key,
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
                  ),
                  Expanded(
                    child: Text('${entry.value['phase1']!.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('${entry.value['phase2']!.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('${entry.value['phase3']!.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(fontSize: 8 * zoomLevel),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('${entry.value['total']!.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(
                            fontSize: 8 * zoomLevel,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDailyTrendsChartsPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(9, zoomLevel);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Trends Visualization',
            style: GoogleFonts.inter(
              fontSize: 14 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Daily Temperature Trend Chart
          Container(
            height: 200 * zoomLevel,
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Temperature Trends',
                    style: GoogleFonts.inter(
                        fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
                SizedBox(height: 8 * zoomLevel),
                Expanded(
                  child: _buildDailyTemperatureChart(zoomLevel),
                ),
              ],
            ),
          ),

          SizedBox(height: 16 * zoomLevel),

          // Daily Power Consumption Chart
          Container(
            height: 200 * zoomLevel,
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Power Consumption Trends',
                    style: GoogleFonts.inter(
                        fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
                SizedBox(height: 8 * zoomLevel),
                Expanded(
                  child: _buildDailyPowerChart(zoomLevel),
                ),
              ],
            ),
          ),

          SizedBox(height: 16 * zoomLevel),

          // Daily Door Operations Chart
          Container(
            height: 180 * zoomLevel,
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Door Operations',
                    style: GoogleFonts.inter(
                        fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600)),
                SizedBox(height: 8 * zoomLevel),
                Expanded(
                  child: _buildDailyDoorChart(zoomLevel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTemperatureChart(double zoomLevel) {
    // Collect all daily temperature data
    final dailyData = <String, Map<String, List<double>>>{};

    for (var device in lastGeneratedReportData!) {
      if (device.dailyTemperatureData != null) {
        for (var dayData in device.dailyTemperatureData!) {
          final date = dayData['date'] ?? '';
          if (!dailyData.containsKey(date)) {
            dailyData[date] = {'avg': [], 'min': [], 'max': []};
          }
          dailyData[date]!['avg']!.add(dayData['avg_temperature'] ?? 0.0);
          dailyData[date]!['min']!.add(dayData['min_temperature'] ?? 0.0);
          dailyData[date]!['max']!.add(dayData['max_temperature'] ?? 0.0);
        }
      }
    }

    if (dailyData.isEmpty) {
      return Center(
        child: Text('No daily temperature data available',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54)),
      );
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35 * zoomLevel,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}°',
                style: GoogleFonts.inter(
                    fontSize: 7 * zoomLevel, color: Colors.black54),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25 * zoomLevel,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final date = sortedEntries[index].key;
                  return Padding(
                    padding: EdgeInsets.only(top: 4 * zoomLevel),
                    child: Text(
                      date.substring(5),
                      style: GoogleFonts.inter(
                          fontSize: 6 * zoomLevel, color: Colors.black54),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        lineBarsData: [
          // Average line
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              final avgList = entry.value.value['avg']!;
              final avg = avgList.reduce((a, b) => a + b) / avgList.length;
              return FlSpot(entry.key.toDouble(), avg);
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 2 * zoomLevel,
            dotData: FlDotData(show: false),
          ),
          // Min line
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              final minList = entry.value.value['min']!;
              final min = minList.reduce((a, b) => a < b ? a : b);
              return FlSpot(entry.key.toDouble(), min);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 1.5 * zoomLevel,
            dotData: FlDotData(show: false),
          ),
          // Max line
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              final maxList = entry.value.value['max']!;
              final max = maxList.reduce((a, b) => a > b ? a : b);
              return FlSpot(entry.key.toDouble(), max);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 1.5 * zoomLevel,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPowerChart(double zoomLevel) {
    // Collect all daily power data
    final dailyData = <String, Map<String, double>>{};

    for (var device in lastGeneratedReportData!) {
      if (device.dailyPowerData != null) {
        for (var dayData in device.dailyPowerData!) {
          final date = dayData['date'] ?? '';
          if (!dailyData.containsKey(date)) {
            dailyData[date] = {
              'phase1': 0.0,
              'phase2': 0.0,
              'phase3': 0.0,
              'total': 0.0
            };
          }
          dailyData[date]!['phase1'] = (dailyData[date]!['phase1'] ?? 0.0) +
              (dayData['phase1_consumption'] ?? 0.0);
          dailyData[date]!['phase2'] = (dailyData[date]!['phase2'] ?? 0.0) +
              (dayData['phase2_consumption'] ?? 0.0);
          dailyData[date]!['phase3'] = (dailyData[date]!['phase3'] ?? 0.0) +
              (dayData['phase3_consumption'] ?? 0.0);
          dailyData[date]!['total'] = (dailyData[date]!['total'] ?? 0.0) +
              (dayData['total_consumption'] ?? 0.0);
        }
      }
    }

    if (dailyData.isEmpty) {
      return Center(
        child: Text('No daily power consumption data available',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54)),
      );
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35 * zoomLevel,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: GoogleFonts.inter(
                    fontSize: 7 * zoomLevel, color: Colors.black54),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25 * zoomLevel,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final date = sortedEntries[index].key;
                  return Padding(
                    padding: EdgeInsets.only(top: 4 * zoomLevel),
                    child: Text(
                      date.substring(5),
                      style: GoogleFonts.inter(
                          fontSize: 6 * zoomLevel, color: Colors.black54),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        lineBarsData: [
          // Total line
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value['total']!);
            }).toList(),
            isCurved: true,
            color: Colors.deepOrange,
            barWidth: 2 * zoomLevel,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDoorChart(double zoomLevel) {
    // Collect all daily door data
    final dailyData = <String, int>{};

    for (var device in lastGeneratedReportData!) {
      if (device.dailyDoorData != null) {
        for (var dayData in device.dailyDoorData!) {
          final date = dayData['date'] ?? '';
          final operations = (dayData['door_operations'] ?? 0) as int;
          dailyData[date] = (dailyData[date] ?? 0) + operations;
        }
      }
    }

    if (dailyData.isEmpty) {
      return Center(
        child: Text('No daily door operations data available',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54)),
      );
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30 * zoomLevel,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: GoogleFonts.inter(
                    fontSize: 7 * zoomLevel, color: Colors.black54),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25 * zoomLevel,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final date = sortedEntries[index].key;
                  return Padding(
                    padding: EdgeInsets.only(top: 4 * zoomLevel),
                    child: Text(
                      date.substring(5),
                      style: GoogleFonts.inter(
                          fontSize: 6 * zoomLevel, color: Colors.black54),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: Constants.ctaColorGreen,
                width: 12 * zoomLevel,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendationsPage(double zoomLevel) {
    if (lastGeneratedReportData == null || lastGeneratedReportData!.isEmpty) {
      return _buildPlaceholderContent(10, zoomLevel);
    }

    final avgUptime =
        lastGeneratedReportData!.map((d) => d.uptime).reduce((a, b) => a + b) /
            lastGeneratedReportData!.length;
    final lowUptimeDevices =
        lastGeneratedReportData!.where((d) => d.uptime < 80).length;
    final highPowerDevices =
        lastGeneratedReportData!.where((d) => d.powerConsumption > 15).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * zoomLevel),
        if (avgUptime < 90)
          _buildRecommendationCard(
            'Improve Overall Uptime',
            'Average uptime is ${avgUptime.toStringAsFixed(1)}%. Consider investigating devices with low uptime.',
            Icons.trending_up,
            Colors.orange,
            zoomLevel,
          ),
        if (lowUptimeDevices > 0)
          _buildRecommendationCard(
            'Address Low Uptime Devices',
            '$lowUptimeDevices device(s) have uptime below 80%. Schedule maintenance checks.',
            Icons.build,
            Colors.red,
            zoomLevel,
          ),
        if (highPowerDevices > 0)
          _buildRecommendationCard(
            'Review Power Consumption',
            '$highPowerDevices device(s) show high power consumption. Review for efficiency improvements.',
            Icons.bolt,
            Colors.amber,
            zoomLevel,
          ),
        _buildRecommendationCard(
          'Regular Maintenance',
          'Schedule regular maintenance checks for all devices to maintain optimal performance.',
          Icons.schedule,
          Colors.blue,
          zoomLevel,
        ),
        _buildRecommendationCard(
          'Monitor Temperature',
          'Continue monitoring temperature trends to prevent equipment failure.',
          Icons.thermostat,
          Colors.cyan,
          zoomLevel,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String description,
      IconData icon, Color color, double zoomLevel) {
    return Container(
      margin: EdgeInsets.only(bottom: 10 * zoomLevel),
      padding: EdgeInsets.all(10 * zoomLevel),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20 * zoomLevel, color: color),
          SizedBox(width: 10 * zoomLevel),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 11 * zoomLevel,
                        fontWeight: FontWeight.w600,
                        color: color)),
                SizedBox(height: 4 * zoomLevel),
                Text(description,
                    style: GoogleFonts.inter(
                        fontSize: 9 * zoomLevel,
                        color: Colors.black54,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String label, String value, double zoomLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 8 * zoomLevel, color: Colors.black54)),
        SizedBox(height: 2 * zoomLevel),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPlaceholderContent(int pageNumber, double zoomLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(20 * zoomLevel),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange, size: 24 * zoomLevel),
                  SizedBox(width: 12 * zoomLevel),
                  Expanded(
                    child: Text(
                      'No Data Available',
                      style: GoogleFonts.inter(
                        fontSize: 14 * zoomLevel,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * zoomLevel),
              Text(
                'This page does not have data to display. This could be because:',
                style: GoogleFonts.inter(
                  fontSize: 10 * zoomLevel,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8 * zoomLevel),
              _buildBulletPoint(
                  'No devices were selected for the report', zoomLevel),
              _buildBulletPoint(
                  'The selected devices have no data in the specified date range',
                  zoomLevel),
              _buildBulletPoint(
                  'There was an error fetching data from the server',
                  zoomLevel),
              SizedBox(height: 12 * zoomLevel),
              Text(
                'Please try:',
                style: GoogleFonts.inter(
                  fontSize: 10 * zoomLevel,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6 * zoomLevel),
              _buildBulletPoint('Selecting a different date range', zoomLevel),
              _buildBulletPoint('Choosing different devices', zoomLevel),
              _buildBulletPoint('Checking your network connection', zoomLevel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.only(left: 12 * zoomLevel, bottom: 4 * zoomLevel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.inter(
                  fontSize: 10 * zoomLevel, color: Colors.black54)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 9 * zoomLevel, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTemperatureColor(double temp) {
    if (temp < -20) return Colors.blue;
    if (temp < -10) return Colors.lightBlue;
    if (temp < 0) return Colors.cyan;
    if (temp < 10) return Colors.orange;
    return Colors.red;
  }

  Color _getPowerColor(int index) {
    final colors = [
      Colors.orange,
      Colors.deepOrange,
      Colors.amber,
      Colors.orangeAccent,
      Colors.deepOrangeAccent,
      Colors.yellow.shade700,
      Colors.orange.shade300,
      Colors.deepOrange.shade300,
    ];
    return colors[index % colors.length];
  }

  Widget _buildLegendItem(String label, Color color, double zoomLevel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12 * zoomLevel,
          height: 3 * zoomLevel,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(width: 4 * zoomLevel),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8 * zoomLevel,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * zoomLevel),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10 * zoomLevel,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _generateAndSavePDF(String reportType) async {
    // This method generates a PDF from the last generated report data and saves it
    // Returns the file path where the PDF was saved

    final now = DateTime.now();
    String filename = '${reportType}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';

    // Create PDF document
    final pdf = pw.Document();

    // Generate PDF content based on report type with actual data
    if (reportType == 'temperature_analysis' && lastGeneratedTempReportData != null) {
      // Add temperature analysis pages
      pdf.addPage(pw.Page(
        build: (context) => _buildTemperaturePDFContent(),
      ));
    } else if (reportType == 'alerts_summary' && lastGeneratedAlertsReportData != null) {
      // Add alerts summary pages
      pdf.addPage(pw.Page(
        build: (context) => _buildAlertsPDFContent(),
      ));
    } else if (reportType == 'maintenance_report' && lastGeneratedMaintenanceReportData != null) {
      // Add maintenance report pages
      pdf.addPage(pw.Page(
        build: (context) => _buildMaintenancePDFContent(),
      ));
    } else {
      // Fallback: create simple report if data not available
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Report: ${reportType.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Report data not available in session.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Please regenerate the report to download with full data.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Generate PDF bytes
    final bytes = await pdf.save();

    // Save or download the bytes
    final savedBytes = bytes;

    if (kIsWeb) {
      // Web: trigger download
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = filename;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Downloads/$filename'; // Return virtual path for web
    } else {
      // Desktop/Mobile: save to file system
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        directory = await getDownloadsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final String path = '${directory.path}/$filename';
        final File file = File(path);
        await file.writeAsBytes(savedBytes);
        return path;
      } else {
        throw Exception('Could not determine download directory');
      }
    }
  }

  // PDF Content Builders for each report type
  pw.Widget _buildTemperaturePDFContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Temperature Analysis Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Period: ${lastGeneratedTempReportPeriod ?? "N/A"}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        if (lastGeneratedTempReportData != null) ...[
          pw.Text('Total Devices: ${lastGeneratedTempReportData!.length}'),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildPdfTableHeader('Device'),
                  _buildPdfTableHeader('Avg Temp'),
                  _buildPdfTableHeader('Min Temp'),
                  _buildPdfTableHeader('Max Temp'),
                ],
              ),
              ...lastGeneratedTempReportData!.take(20).map((device) => pw.TableRow(
                children: [
                  _buildPdfTableCell(device.deviceName),
                  _buildPdfTableCell('${device.avgTemperature.toStringAsFixed(1)}°C'),
                  _buildPdfTableCell('${device.minTemperature.toStringAsFixed(1)}°C'),
                  _buildPdfTableCell('${device.maxTemperature.toStringAsFixed(1)}°C'),
                ],
              )),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _buildAlertsPDFContent() {
    final data = lastGeneratedAlertsReportData!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Alerts Summary Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Period: ${lastGeneratedAlertsReportPeriod ?? "N/A"}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Summary Statistics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildPdfTableHeader('Metric'),
                _buildPdfTableHeader('Value'),
              ],
            ),
            pw.TableRow(children: [
              _buildPdfTableCell('Total Alerts'),
              _buildPdfTableCell('${data.overallStats['total_alerts'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Critical Alerts'),
              _buildPdfTableCell('${data.overallStats['critical_alerts'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Warning Alerts'),
              _buildPdfTableCell('${data.overallStats['warning_alerts'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Resolved Alerts'),
              _buildPdfTableCell('${data.overallStats['resolved_alerts'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Pending Alerts'),
              _buildPdfTableCell('${data.overallStats['pending_alerts'] ?? 0}'),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMaintenancePDFContent() {
    final data = lastGeneratedMaintenanceReportData!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Maintenance Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Period: ${lastGeneratedMaintenanceReportPeriod ?? "N/A"}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Summary Statistics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildPdfTableHeader('Metric'),
                _buildPdfTableHeader('Value'),
              ],
            ),
            pw.TableRow(children: [
              _buildPdfTableCell('Total Maintenance Tasks'),
              _buildPdfTableCell('${data.overallStats['total_maintenance'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Completed Tasks'),
              _buildPdfTableCell('${data.overallStats['completed_maintenance'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Pending Tasks'),
              _buildPdfTableCell('${data.overallStats['pending_maintenance'] ?? 0}'),
            ]),
            pw.TableRow(children: [
              _buildPdfTableCell('Overdue Tasks'),
              _buildPdfTableCell('${data.overallStats['overdue_maintenance'] ?? 0}'),
            ]),
          ],
        ),
      ],
    );
  }

  void _showDownloadDialog(String reportName, {String? filePath, Future<String>? Function()? onGenerate}) {
    double progress = 0.0;
    String status = 'Preparing download...';
    bool isCompleted = false;
    String? savedFilePath = filePath;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (progress == 0.0) {
            // If onGenerate is provided, actually generate the file
            if (onGenerate != null) {
              Future.delayed(Duration(milliseconds: 100), () async {
                if (!context.mounted) return;

                try {
                  // Update status to generating
                  setDialogState(() {
                    progress = 0.2;
                    status = 'Generating PDF...';
                  });

                  // Generate the file and get the path
                  final path = await onGenerate();

                  if (!context.mounted) return;

                  // Update to show saving
                  setDialogState(() {
                    progress = 0.8;
                    status = 'Saving file...';
                    savedFilePath = path;
                  });

                  await Future.delayed(Duration(milliseconds: 500));

                  if (!context.mounted) return;

                  // Complete
                  setDialogState(() {
                    progress = 1.0;
                    status = 'Download complete!';
                    isCompleted = true;
                  });
                } catch (e) {
                  print('Error in download: $e');
                  if (context.mounted) {
                    setDialogState(() {
                      status = 'Error: $e';
                      isCompleted = false;
                    });
                  }
                }
              });
            } else {
              // Fallback: Simulate download progress if no generator provided
              Future.delayed(Duration(milliseconds: 500), () {
                if (context.mounted) {
                  Timer.periodic(Duration(milliseconds: 100), (timer) {
                    if (!context.mounted) {
                      timer.cancel();
                      return;
                    }
                    setDialogState(() {
                      progress += 0.05;
                      if (progress < 0.3) {
                        status = 'Preparing download...';
                      } else if (progress < 0.7) {
                        status = 'Downloading...';
                      } else if (progress < 1.0) {
                        status = 'Finalizing...';
                      } else {
                        progress = 1.0;
                        status = 'Download complete!';
                        isCompleted = true;
                        timer.cancel();
                      }
                    });
                  });
                }
              });
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withValues(alpha: 0.1)
                              : Constants.ctaColorLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCompleted
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.cloud_download,
                          color: isCompleted
                              ? Colors.green
                              : Constants.ctaColorLight,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted
                                  ? 'Download Complete'
                                  : 'Downloading Report',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              reportName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Constants.ctaColorLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? Colors.green
                                : Constants.ctaColorLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // File Info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          size: 20,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '2.4 MB • PDF Document',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isCompleted) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_alt_circle,
                            size: 20,
                            color: Colors.green,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'File saved to Downloads folder',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24),

                  // Footer Buttons
                  Row(
                    children: [
                      if (!isCompleted)
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.1),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      if (isCompleted) ...[
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.1),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              if (savedFilePath != null) {
                                try {
                                  if (kIsWeb) {
                                    // For web, download the file again or show in new tab
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('File has been downloaded to your Downloads folder'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  } else {
                                    // For desktop/mobile, open the file
                                    final result = await OpenFile.open(savedFilePath);
                                    if (result.type != ResultType.done) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Could not open file: ${result.message}'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                } catch (e) {
                                  print('Error opening file: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error opening file: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('File path not available'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Open File',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reports",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 24,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Generate and download comprehensive system reports",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 18,
                                color: Constants.ctaColorLight,
                              ),
                              SizedBox(width: 8),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPeriod,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Constants.ctaColorLight,
                                    size: 20,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: periods.map((String period) {
                                    return DropdownMenuItem<String>(
                                      value: period,
                                      child: Text(period),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedPeriod = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reports",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 28,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Generate and download comprehensive system reports",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Period Selector
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 18,
                                color: Constants.ctaColorLight,
                              ),
                              SizedBox(width: 8),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPeriod,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Constants.ctaColorLight,
                                    size: 20,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: periods.map((String period) {
                                    return DropdownMenuItem<String>(
                                      value: period,
                                      child: Text(period),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedPeriod = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 4),
            Divider(thickness: 0.5, color: Colors.grey),
            SizedBox(height: 32),

            // Quick Stats Section
            SizedBox(
              width: double.infinity,
              child: isMobile
                  ? Column(
                      children: [
                        CustomCard(
                          elevation: 2,
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: _showGeneratedReportsDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.doc_text,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${generatedReports.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Reports Generated',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.black54,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        CustomCard(
                          elevation: 2,
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: _showDownloadsDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.arrow_down_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${downloadedReports.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Downloads This Month',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.black54,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        CustomCard(
                          elevation: 2,
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: _showScheduledReportsDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.time,
                                      color: Colors.purple,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${scheduledReports.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Scheduled Reports',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.black54,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: CustomCard(
                            elevation: 2,
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _showGeneratedReportsDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.doc_text,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${generatedReports.length}',
                                            style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Reports Generated',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.black54,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: CustomCard(
                            elevation: 2,
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _showDownloadsDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.arrow_down_circle,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${downloadedReports.length}',
                                            style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Downloads This Month',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.black54,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: CustomCard(
                            elevation: 2,
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _showScheduledReportsDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.time,
                                        color: Colors.purple,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${scheduledReports.length}',
                                            style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Scheduled Reports',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.black54,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 32),

            // Report Types Section
            Text(
              "Report Types",
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),

            // Report Cards Grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 2.5 : 2.0,
              ),
              itemCount: reportTypes.length,
              itemBuilder: (context, index) {
                final reportType = reportTypes[index];
                final isGeneratingThis =
                    isGenerating && selectedReportType == reportType.id;

                return CustomCard(
                  elevation: 2,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap:
                        isGenerating ? null : () => _generateReport(reportType),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      reportType.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  reportType.icon,
                                  color: reportType.color,
                                  size: 24,
                                ),
                              ),
                              if (isGeneratingThis)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: reportType.color,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reportType.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                reportType.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                CupertinoIcons.arrow_right_circle_fill,
                                color: reportType.color,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 32),

            // Recent Reports Section
            Text(
              "Recent Reports",
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),

            CustomCard(
              elevation: 2,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: isLoadingReports
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : downloadedReports.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.folderOpen,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No reports generated yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report items
                              ...() {
                                final startIndex = currentReportPage * reportsPerPage;
                                final endIndex = (startIndex + reportsPerPage).clamp(0, downloadedReports.length);
                                final paginatedReports = downloadedReports.sublist(startIndex, endIndex);

                                return paginatedReports.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final report = entry.value;
                                  return Column(
                                    children: [
                                      if (index > 0) Divider(height: 24, thickness: 0.5),
                                      _buildRecentReportItemFromData(report),
                                    ],
                                  );
                                }).toList();
                              }(),

                              // Pagination controls
                              if (downloadedReports.length > reportsPerPage) ...[
                                SizedBox(height: 16),
                                Divider(height: 1),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Showing ${currentReportPage * reportsPerPage + 1}-${((currentReportPage + 1) * reportsPerPage).clamp(0, downloadedReports.length)} of ${downloadedReports.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.chevron_left),
                                          onPressed: currentReportPage > 0
                                              ? () {
                                                  setState(() {
                                                    currentReportPage--;
                                                  });
                                                }
                                              : null,
                                          iconSize: 20,
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Page ${currentReportPage + 1} of ${(downloadedReports.length / reportsPerPage).ceil()}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.chevron_right),
                                          onPressed: (currentReportPage + 1) * reportsPerPage < downloadedReports.length
                                              ? () {
                                                  setState(() {
                                                    currentReportPage++;
                                                  });
                                                }
                                              : null,
                                          iconSize: 20,
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportItem(
    String title,
    String date,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                CupertinoIcons.eye,
                color: Colors.black54,
                size: 20,
              ),
              onPressed: () {},
              tooltip: 'View',
            ),
            IconButton(
              icon: Icon(
                CupertinoIcons.cloud_download,
                color: Constants.ctaColorLight,
                size: 20,
              ),
              onPressed: () {},
              tooltip: 'Download',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentReportItemFromData(dynamic report) {
    // Map report types to icons and colors
    final reportTypeConfig = {
      'temperature_analysis': {
        'icon': FontAwesomeIcons.temperatureHalf,
        'color': Color(0xFFE94B3C),
      },
      'alerts_summary': {
        'icon': FontAwesomeIcons.bellConcierge,
        'color': Color(0xFFF5A623),
      },
      'maintenance_report': {
        'icon': FontAwesomeIcons.wrench,
        'color': Color(0xFF9B59B6),
      },
      'energy_consumption': {
        'icon': FontAwesomeIcons.bolt,
        'color': Color(0xFF27AE60),
      },
      'compliance_report': {
        'icon': FontAwesomeIcons.clipboardCheck,
        'color': Color(0xFF3498DB),
      },
    };

    final config = reportTypeConfig[report['report_type']] ?? {
      'icon': FontAwesomeIcons.chartLine,
      'color': Color(0xFF4A90E2),
    };

    // Format date
    String formattedDate = 'Unknown date';
    try {
      final generatedAt = DateTime.parse(report['generated_at']);
      formattedDate = 'Generated on ${DateFormat('MMM dd, yyyy').format(generatedAt)}';
    } catch (e) {
      print('Error parsing date: $e');
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (config['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            config['icon'] as IconData,
            color: config['color'] as Color,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report['report_name'] ?? 'Untitled Report',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                CupertinoIcons.eye,
                color: Colors.black54,
                size: 20,
              ),
              onPressed: () => _viewReport(report),
              tooltip: 'View',
            ),
            IconButton(
              icon: Icon(
                CupertinoIcons.cloud_download,
                color: Constants.ctaColorLight,
                size: 20,
              ),
              onPressed: () => _downloadReport(report),
              tooltip: 'Download',
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // REPORT VIEW AND DOWNLOAD METHODS
  // ============================================================================

  Future<void> _viewReport(dynamic report) async {
    bool loadingDialogShown = false;

    try {
      print('Viewing report: ${report['report_id']}');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading report...', style: GoogleFonts.inter()),
                ],
              ),
            ),
          ),
        ),
      );
      loadingDialogShown = true;

      // Fetch full report data from backend
      final reportData = await ReportApiService.getReportDetail(report['report_id']);

      if (!mounted) return;

      // Close loading dialog
      if (loadingDialogShown) {
        Navigator.pop(context);
        loadingDialogShown = false;
      }

      // Set the appropriate report data based on type and show preview dialog
      final reportType = reportData['report_type'];

      switch (reportType) {
        case 'temperature_analysis':
          await _viewTemperatureReport(reportData);
          break;
        case 'alerts_summary':
          await _viewAlertsReport(reportData);
          break;
        case 'maintenance_report':
          await _viewMaintenanceReport(reportData);
          break;
        default:
          // Show basic report details dialog for unknown/unimplemented types
          await _showBasicReportDetails(reportData);
      }
    } catch (e) {
      print('Error viewing report: $e');
      if (mounted) {
        // Close loading dialog if it's still open
        if (loadingDialogShown) {
          try {
            Navigator.pop(context);
          } catch (navError) {
            print('Error popping navigator: $navError');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBasicReportDetails(dynamic report) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(FontAwesomeIcons.fileLines, size: 20, color: Constants.ctaColorLight),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  report['report_name'] ?? 'Report Details',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReportDetailRow('Report Type', _formatReportType(report['report_type'])),
                _buildReportDetailRow('Generated By', report['generated_by'] ?? 'Unknown'),
                _buildReportDetailRow('Generated At', _formatDateTime(report['generated_at'])),
                _buildReportDetailRow('Period', report['period'] ?? 'N/A'),
                _buildReportDetailRow('Start Date', _formatDate(report['start_date'])),
                _buildReportDetailRow('End Date', _formatDate(report['end_date'])),
                _buildReportDetailRow('Page Count', '${report['page_count'] ?? 0} pages'),
                _buildReportDetailRow('File Size', report['file_size'] ?? 'N/A'),
                _buildReportDetailRow('Download Count', '${report['download_count'] ?? 0} times'),
                if (report['device_ids'] != null && report['device_ids'].isNotEmpty)
                  _buildReportDetailRow('Devices', '${report['device_ids'].length} device(s)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _downloadReport(report);
              },
              icon: Icon(Icons.download, size: 16),
              label: Text('Download', style: GoogleFonts.inter(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReportType(String? type) {
    if (type == null) return 'Unknown';
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _downloadReport(dynamic report) async {
    try {
      print('Downloading report: ${report['report_id']}');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Preparing report for download...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Fetch full report data if not already available
      final reportData = await ReportApiService.getReportDetail(report['report_id']);

      if (!mounted) return;

      // Generate PDF based on report type
      final reportType = reportData['report_type'];

      switch (reportType) {
        case 'temperature_analysis':
          await _downloadTemperatureReportPDF(reportData);
          break;
        case 'alerts_summary':
          await _downloadAlertsReportPDF(reportData);
          break;
        case 'maintenance_report':
          await _downloadMaintenanceReportPDF(reportData);
          break;
        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download not yet implemented for this report type'),
                backgroundColor: Colors.orange,
              ),
            );
          }
      }
    } catch (e) {
      print('Error downloading report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // VIEW REPORT METHODS BY TYPE
  // ============================================================================

  Future<void> _viewTemperatureReport(dynamic reportData) async {
    // For temperature reports, regenerate and view using stored data
    // TODO: This could be enhanced to show full preview with charts
    // For now, trigger the generation dialog with pre-filled data
    await _showBasicReportDetails(reportData);
  }

  Future<void> _viewAlertsReport(dynamic reportData) async {
    // For alerts reports, show summary details
    await _showBasicReportDetails(reportData);
  }

  Future<void> _viewMaintenanceReport(dynamic reportData) async {
    // For maintenance reports, show summary details
    await _showBasicReportDetails(reportData);
  }

  // ============================================================================
  // DOWNLOAD PDF METHODS BY TYPE
  // ============================================================================

  Future<void> _downloadTemperatureReportPDF(dynamic reportData) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generating Temperature Analysis PDF...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Parse the saved report data
      final tempData = reportData['report_data'];

      // TODO: Implement actual PDF download
      // This would regenerate the PDF from the saved data
      // For now, inform user that download will trigger report regeneration

      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Temperature report ready. Click "Generate Report" to download PDF.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () => _viewTemperatureReport(reportData),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _downloadTemperatureReportPDF: $e');
    }
  }

  Future<void> _downloadAlertsReportPDF(dynamic reportData) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerts Summary report ready. Click "Generate Report" to download PDF.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () => _viewAlertsReport(reportData),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _downloadAlertsReportPDF: $e');
    }
  }

  Future<void> _downloadMaintenanceReportPDF(dynamic reportData) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance report ready. Click "Generate Report" to download PDF.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () => _viewMaintenanceReport(reportData),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _downloadMaintenanceReportPDF: $e');
    }
  }

  // ============================================================================
  // COMMON HELPER WIDGETS FOR ALL REPORTS
  // ============================================================================

  Widget _buildTableHeader(String text, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.all(6 * zoomLevel),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8 * zoomLevel,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.all(6 * zoomLevel),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 7 * zoomLevel,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMetricRow2(String label, String value, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3 * zoomLevel),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 7 * zoomLevel,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 7 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem2(String label, Color color, double zoomLevel) {
    return Row(
      children: [
        Container(
          width: 12 * zoomLevel,
          height: 12 * zoomLevel,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4 * zoomLevel),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7 * zoomLevel,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TEMPERATURE ANALYSIS REPORT PAGE BUILDERS (8 pages)
  // ============================================================================

  Widget _buildTempAnalysisSummaryPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    // Calculate summary statistics across all devices
    double totalAvg = lastGeneratedTempReportData!
            .map((d) => d.avgTemperature)
            .reduce((a, b) => a + b) /
        lastGeneratedTempReportData!.length;
    double overallMin = lastGeneratedTempReportData!
        .map((d) => d.minTemperature)
        .reduce((a, b) => a < b ? a : b);
    double overallMax = lastGeneratedTempReportData!
        .map((d) => d.maxTemperature)
        .reduce((a, b) => a > b ? a : b);
    int totalReadings = lastGeneratedTempReportData!
        .map((d) => d.totalReadings)
        .reduce((a, b) => a + b);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Temperature Analysis Report',
            style: GoogleFonts.inter(
                fontSize: 18 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Executive Summary',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2 * zoomLevel),
          Text(
            'Period: ${lastGeneratedTempReportPeriod ?? "N/A"}',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          Text(
            'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Key Metrics Grid
          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Constants.ctaColorLight.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                          'Total Devices',
                          '${lastGeneratedTempReportData!.length}',
                          Icons.devices,
                          zoomLevel),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildSummaryMetric('Total Readings',
                          '$totalReadings', Icons.analytics, zoomLevel),
                    ),
                  ],
                ),
                SizedBox(height: 8 * zoomLevel),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                          'Avg Temperature',
                          '${totalAvg.toStringAsFixed(1)}°C',
                          Icons.thermostat,
                          zoomLevel),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildSummaryMetric(
                          'Temperature Range',
                          '${overallMin.toStringAsFixed(1)}°C to ${overallMax.toStringAsFixed(1)}°C',
                          Icons.trending_up,
                          zoomLevel),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16 * zoomLevel),

          // Device Summary Table
          Text(
            'Device Temperature Summary',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Table(
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              children: [
                TableRow(
                  decoration:
                      BoxDecoration(color: Colors.grey.withValues(alpha: 0.1)),
                  children: [
                    _buildTableHeader('Device Name', zoomLevel),
                    _buildTableHeader('Avg (°C)', zoomLevel),
                    _buildTableHeader('Min (°C)', zoomLevel),
                    _buildTableHeader('Max (°C)', zoomLevel),
                    _buildTableHeader('Status', zoomLevel),
                  ],
                ),
                ...lastGeneratedTempReportData!.map((device) {
                  String status =
                      device.avgTemperature > -18 ? 'Warning' : 'Normal';
                  Color statusColor = device.avgTemperature > -18
                      ? Colors.orange
                      : Colors.green;

                  return TableRow(
                    children: [
                      _buildTableCell(device.deviceName, zoomLevel),
                      _buildTableCell(
                          device.avgTemperature.toStringAsFixed(1), zoomLevel),
                      _buildTableCell(
                          device.minTemperature.toStringAsFixed(1), zoomLevel),
                      _buildTableCell(
                          device.maxTemperature.toStringAsFixed(1), zoomLevel),
                      Padding(
                        padding: EdgeInsets.all(6 * zoomLevel),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6 * zoomLevel,
                              vertical: 2 * zoomLevel),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                color: statusColor,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          SizedBox(height: 16 * zoomLevel),

          // Key Findings
          Text(
            'Key Findings',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),
          Container(
            padding: EdgeInsets.all(10 * zoomLevel),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFindingItem(
                    'Overall temperature performance is ${totalAvg > -18 ? "above" : "within"} the recommended range (-18°C)',
                    Icons.thermostat,
                    Colors.blue,
                    zoomLevel),
                _buildFindingItem(
                    '${lastGeneratedTempReportData!.where((d) => d.avgTemperature > -18).length} device(s) showing temperature warnings',
                    Icons.warning,
                    Colors.orange,
                    zoomLevel),
                _buildFindingItem(
                    'Temperature range spans ${(overallMax - overallMin).toStringAsFixed(1)}°C across all devices',
                    Icons.trending_up,
                    Colors.blue,
                    zoomLevel),
                _buildFindingItem(
                    'Total of $totalReadings temperature readings analyzed in this period',
                    Icons.analytics,
                    Colors.blue,
                    zoomLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempSensorComparisonPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Comparison Analysis',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Air, Coil, and Drain Temperature Sensors',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Sensor comparison for each device
          ...lastGeneratedTempReportData!.map((device) {
            final sensorStats = device.sensorStats;
            final airTemp =
                (sensorStats['air']?['average'] ?? 0.0).toDouble();
            final coilTemp =
                (sensorStats['coil']?['average'] ?? 0.0).toDouble();
            final drainTemp =
                (sensorStats['drain']?['average'] ?? 0.0).toDouble();

            return Container(
              margin: EdgeInsets.only(bottom: 16 * zoomLevel),
              padding: EdgeInsets.all(12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: GoogleFonts.inter(
                        fontSize: 10 * zoomLevel, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12 * zoomLevel),

                  // Bar chart comparison
                  SizedBox(
                    height: 120 * zoomLevel,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 5,
                        minY: -25,
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30 * zoomLevel,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}°C',
                                style:
                                    GoogleFonts.inter(fontSize: 7 * zoomLevel),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Air',
                                        style: GoogleFonts.inter(
                                            fontSize: 8 * zoomLevel));
                                  case 1:
                                    return Text('Coil',
                                        style: GoogleFonts.inter(
                                            fontSize: 8 * zoomLevel));
                                  case 2:
                                    return Text('Drain',
                                        style: GoogleFonts.inter(
                                            fontSize: 8 * zoomLevel));
                                  default:
                                    return Text('');
                                }
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(
                                toY: airTemp,
                                color: Colors.blue,
                                width: 20 * zoomLevel)
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(
                                toY: coilTemp,
                                color: Colors.orange,
                                width: 20 * zoomLevel)
                          ]),
                          BarChartGroupData(x: 2, barRods: [
                            BarChartRodData(
                                toY: drainTemp,
                                color: Colors.teal,
                                width: 20 * zoomLevel)
                          ]),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12 * zoomLevel),

                  // Sensor statistics table
                  Table(
                    columnWidths: {
                      0: FlexColumnWidth(1.5),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    border: TableBorder.all(
                        color: Colors.grey.withValues(alpha: 0.2)),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1)),
                        children: [
                          _buildTableHeader('Sensor', zoomLevel),
                          _buildTableHeader('Avg (°C)', zoomLevel),
                          _buildTableHeader('Min (°C)', zoomLevel),
                          _buildTableHeader('Max (°C)', zoomLevel),
                        ],
                      ),
                      _buildSensorRow(
                          'Air', sensorStats['air'], zoomLevel),
                      _buildSensorRow(
                          'Coil', sensorStats['coil'], zoomLevel),
                      _buildSensorRow(
                          'Drain', sensorStats['drain'], zoomLevel),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTempDailyTrendsPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Temperature Trends',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 16 * zoomLevel),
          ...lastGeneratedTempReportData!.map((device) {
            final dailyTrends = device.dailyTrends;

            return Container(
              margin: EdgeInsets.only(bottom: 20 * zoomLevel),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: GoogleFonts.inter(
                        fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8 * zoomLevel),

                  Container(
                    height: 180 * zoomLevel,
                    padding: EdgeInsets.all(12 * zoomLevel),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35 * zoomLevel,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}°C',
                                style:
                                    GoogleFonts.inter(fontSize: 7 * zoomLevel),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < dailyTrends.length) {
                                  final date =
                                      dailyTrends[value.toInt()]['date'] ?? '';
                                  return Text(
                                    date.split('T')[0].substring(5), // MM-DD
                                    style: GoogleFonts.inter(
                                        fontSize: 6 * zoomLevel),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dailyTrends.asMap().entries.map((e) {
                              return FlSpot(
                                  e.key.toDouble(),
                                  (e.value['average_temperature'] ?? 0.0)
                                      .toDouble());
                            }).toList(),
                            isCurved: true,
                            color: Constants.ctaColorLight,
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Constants.ctaColorLight
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12 * zoomLevel),

                  // Daily statistics table
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Table(
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.5),
                      },
                      border: TableBorder.symmetric(
                          inside: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2))),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1)),
                          children: [
                            _buildTableHeader('Date', zoomLevel),
                            _buildTableHeader('Avg (°C)', zoomLevel),
                            _buildTableHeader('Min (°C)', zoomLevel),
                            _buildTableHeader('Max (°C)', zoomLevel),
                          ],
                        ),
                        ...dailyTrends.take(7).map((day) {
                          return TableRow(
                            children: [
                              _buildTableCell(
                                  day['date']?.toString().split('T')[0] ?? '',
                                  zoomLevel),
                              _buildTableCell(
                                  (day['average_temperature'] ?? 0.0)
                                      .toStringAsFixed(1),
                                  zoomLevel),
                              _buildTableCell(
                                  (day['min_temperature'] ?? 0.0)
                                      .toStringAsFixed(1),
                                  zoomLevel),
                              _buildTableCell(
                                  (day['max_temperature'] ?? 0.0)
                                      .toStringAsFixed(1),
                                  zoomLevel),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTempDistributionPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature Distribution Analysis',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 16 * zoomLevel),
          ...lastGeneratedTempReportData!.map((device) {
            return Container(
              margin: EdgeInsets.only(bottom: 20 * zoomLevel),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: GoogleFonts.inter(
                        fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12 * zoomLevel),
                  Row(
                    children: [
                      // Statistical metrics
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.all(12 * zoomLevel),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statistical Summary',
                                style: GoogleFonts.inter(
                                    fontSize: 9 * zoomLevel,
                                    fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 8 * zoomLevel),
                              _buildMetricRow(
                                  'Mean',
                                  '${device.avgTemperature.toStringAsFixed(2)}°C',
                                  zoomLevel),
                              _buildMetricRow(
                                  'Std Deviation',
                                  '${device.stdDeviation.toStringAsFixed(2)}°C',
                                  zoomLevel),
                              _buildMetricRow(
                                  'Minimum',
                                  '${device.minTemperature.toStringAsFixed(2)}°C',
                                  zoomLevel),
                              _buildMetricRow(
                                  'Maximum',
                                  '${device.maxTemperature.toStringAsFixed(2)}°C',
                                  zoomLevel),
                              _buildMetricRow(
                                  'Range',
                                  '${(device.maxTemperature - device.minTemperature).toStringAsFixed(2)}°C',
                                  zoomLevel),
                              _buildMetricRow('Total Readings',
                                  '${device.totalReadings}', zoomLevel),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 12 * zoomLevel),

                      // Distribution visualization (simplified histogram)
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 160 * zoomLevel,
                          padding: EdgeInsets.all(12 * zoomLevel),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temperature Distribution',
                                style: GoogleFonts.inter(
                                    fontSize: 8 * zoomLevel,
                                    fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 8 * zoomLevel),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildDistributionBar('< -25°C', 0.1,
                                        Colors.blue[900]!, zoomLevel),
                                    _buildDistributionBar('-25 to -20°C', 0.3,
                                        Colors.blue[700]!, zoomLevel),
                                    _buildDistributionBar('-20 to -18°C', 0.6,
                                        Colors.blue, zoomLevel),
                                    _buildDistributionBar('-18 to -15°C', 0.8,
                                        Colors.orange, zoomLevel),
                                    _buildDistributionBar(
                                        '> -15°C', 0.4, Colors.red, zoomLevel),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTempViolationsPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature Violations & Alerts',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Threshold: -18°C (recommended cold storage temperature)',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Violations summary
          ...lastGeneratedTempReportData!.map((device) {
            final violations = device.violations;
            final violationCount = violations['count'] ?? 0;
            final violationPercentage =
                (violations['percentage'] ?? 0.0).toDouble();
            final avgViolationTemp =
                (violations['average_temp'] ?? 0.0).toDouble();
            final maxViolationTemp =
                (violations['max_temp'] ?? 0.0).toDouble();

            Color severityColor = violationPercentage > 20
                ? Colors.red
                : (violationPercentage > 10 ? Colors.orange : Colors.green);

            return Container(
              margin: EdgeInsets.only(bottom: 16 * zoomLevel),
              padding: EdgeInsets.all(12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
                color: severityColor.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.deviceName,
                          style: GoogleFonts.inter(
                              fontSize: 10 * zoomLevel,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8 * zoomLevel, vertical: 4 * zoomLevel),
                        decoration: BoxDecoration(
                          color: severityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          violationPercentage > 20
                              ? 'Critical'
                              : (violationPercentage > 10
                                  ? 'Warning'
                                  : 'Normal'),
                          style: GoogleFonts.inter(
                              fontSize: 8 * zoomLevel,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * zoomLevel),
                  Row(
                    children: [
                      Expanded(
                        child: _buildViolationMetric('Total Violations',
                            '$violationCount', Icons.warning_amber, zoomLevel),
                      ),
                      SizedBox(width: 8 * zoomLevel),
                      Expanded(
                        child: _buildViolationMetric(
                            'Violation Rate',
                            '${violationPercentage.toStringAsFixed(1)}%',
                            Icons.percent,
                            zoomLevel),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * zoomLevel),
                  Row(
                    children: [
                      Expanded(
                        child: _buildViolationMetric(
                            'Avg Violation Temp',
                            '${avgViolationTemp.toStringAsFixed(1)}°C',
                            Icons.thermostat,
                            zoomLevel),
                      ),
                      SizedBox(width: 8 * zoomLevel),
                      Expanded(
                        child: _buildViolationMetric(
                            'Max Violation Temp',
                            '${maxViolationTemp.toStringAsFixed(1)}°C',
                            Icons.trending_up,
                            zoomLevel),
                      ),
                    ],
                  ),
                  if (violationCount > 0) ...[
                    SizedBox(height: 12 * zoomLevel),
                    Container(
                      padding: EdgeInsets.all(8 * zoomLevel),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 12 * zoomLevel, color: Colors.orange[700]),
                          SizedBox(width: 6 * zoomLevel),
                          Expanded(
                            child: Text(
                              'This device has exceeded the -18°C threshold ${violationCount} times (${violationPercentage.toStringAsFixed(1)}% of readings)',
                              style: GoogleFonts.inter(
                                  fontSize: 7 * zoomLevel,
                                  color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTempRangeAnalysisPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature Range Analysis',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Time spent in different temperature ranges',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Range legend
          Container(
            padding: EdgeInsets.all(10 * zoomLevel),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRangeLegend(
                    'Ultra Cold', '< -25°C', Colors.blue[900]!, zoomLevel),
                _buildRangeLegend(
                    'Optimal', '-25 to -18°C', Colors.green, zoomLevel),
                _buildRangeLegend(
                    'Acceptable', '-18 to -15°C', Colors.blue, zoomLevel),
                _buildRangeLegend(
                    'Warning', '-15 to -10°C', Colors.orange, zoomLevel),
                _buildRangeLegend('Critical', '> -10°C', Colors.red, zoomLevel),
              ],
            ),
          ),

          SizedBox(height: 16 * zoomLevel),

          ...lastGeneratedTempReportData!.map((device) {
            final timeInRanges = device.timeInRanges;
            final ultraCold = (timeInRanges['ultra_cold'] is Map) ? ((timeInRanges['ultra_cold'] as Map)['percentage'] ?? 0.0).toDouble() : 0.0;
            final optimal = (timeInRanges['optimal'] is Map) ? ((timeInRanges['optimal'] as Map)['percentage'] ?? 0.0).toDouble() : 0.0;
            final acceptable = (timeInRanges['acceptable'] is Map) ? ((timeInRanges['acceptable'] as Map)['percentage'] ?? 0.0).toDouble() : 0.0;
            final warning = (timeInRanges['warning'] is Map) ? ((timeInRanges['warning'] as Map)['percentage'] ?? 0.0).toDouble() : 0.0;
            final critical = (timeInRanges['critical'] is Map) ? ((timeInRanges['critical'] as Map)['percentage'] ?? 0.0).toDouble() : 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: 16 * zoomLevel),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: GoogleFonts.inter(
                        fontSize: 10 * zoomLevel, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8 * zoomLevel),

                  // Stacked bar showing percentage distribution
                  Container(
                    height: 40 * zoomLevel,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        if (ultraCold > 0)
                          _buildRangeSegment(ultraCold, Colors.blue[900]!),
                        if (optimal > 0)
                          _buildRangeSegment(optimal, Colors.green),
                        if (acceptable > 0)
                          _buildRangeSegment(acceptable, Colors.blue),
                        if (warning > 0)
                          _buildRangeSegment(warning, Colors.orange),
                        if (critical > 0)
                          _buildRangeSegment(critical, Colors.red),
                      ],
                    ),
                  ),

                  SizedBox(height: 8 * zoomLevel),

                  // Percentage breakdown table
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Table(
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      border: TableBorder.symmetric(
                          inside: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2))),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1)),
                          children: [
                            _buildTableHeader('Range', zoomLevel),
                            _buildTableHeader('Percentage', zoomLevel),
                            _buildTableHeader('Status', zoomLevel),
                          ],
                        ),
                        _buildRangeRow('Ultra Cold (< -25°C)', ultraCold,
                            Colors.blue[900]!, zoomLevel),
                        _buildRangeRow('Optimal (-25 to -18°C)', optimal,
                            Colors.green, zoomLevel),
                        _buildRangeRow('Acceptable (-18 to -15°C)', acceptable,
                            Colors.blue, zoomLevel),
                        _buildRangeRow('Warning (-15 to -10°C)', warning,
                            Colors.orange, zoomLevel),
                        _buildRangeRow('Critical (> -10°C)', critical,
                            Colors.red, zoomLevel),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTempDetailedStatsPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Temperature Statistics',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Comprehensive statistics table for all devices
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1),
              },
              border: TableBorder.symmetric(
                  inside:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withValues(alpha: 0.1)),
                  children: [
                    _buildTableHeader('Device', zoomLevel),
                    _buildTableHeader('Mean (°C)', zoomLevel),
                    _buildTableHeader('Median (°C)', zoomLevel),
                    _buildTableHeader('Std Dev', zoomLevel),
                    _buildTableHeader('Range (°C)', zoomLevel),
                    _buildTableHeader('Readings', zoomLevel),
                  ],
                ),
                ...lastGeneratedTempReportData!.map((device) {
                  // Approximate median as mean for now (would need actual data for precise median)
                  final median = device.avgTemperature;
                  final range = device.maxTemperature - device.minTemperature;

                  return TableRow(
                    children: [
                      _buildTableCell(device.deviceName, zoomLevel),
                      _buildTableCell(
                          device.avgTemperature.toStringAsFixed(2), zoomLevel),
                      _buildTableCell(median.toStringAsFixed(2), zoomLevel),
                      _buildTableCell(
                          device.stdDeviation.toStringAsFixed(2), zoomLevel),
                      _buildTableCell(range.toStringAsFixed(2), zoomLevel),
                      _buildTableCell('${device.totalReadings}', zoomLevel),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          SizedBox(height: 20 * zoomLevel),

          // Advanced metrics
          Text(
            'Advanced Metrics',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),

          ...lastGeneratedTempReportData!.map((device) {
            final cv = (device.stdDeviation / device.avgTemperature.abs()) *
                100; // Coefficient of variation
            final stability = cv < 5
                ? 'Excellent'
                : (cv < 10 ? 'Good' : (cv < 15 ? 'Fair' : 'Poor'));

            return Container(
              margin: EdgeInsets.only(bottom: 12 * zoomLevel),
              padding: EdgeInsets.all(10 * zoomLevel),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: GoogleFonts.inter(
                        fontSize: 9 * zoomLevel, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6 * zoomLevel),
                  Row(
                    children: [
                      Expanded(
                          child: _buildMetricRow('Coefficient of Variation',
                              '${cv.toStringAsFixed(2)}%', zoomLevel)),
                      SizedBox(width: 8 * zoomLevel),
                      Expanded(
                          child: _buildMetricRow(
                              'Stability Rating', stability, zoomLevel)),
                    ],
                  ),
                  _buildMetricRow(
                      'Data Completeness',
                      '${((device.totalReadings / (24 * 7)) * 100).toStringAsFixed(1)}%',
                      zoomLevel),
                  _buildMetricRow(
                      'Temperature Variance',
                      '${(device.stdDeviation * device.stdDeviation).toStringAsFixed(2)}',
                      zoomLevel),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTempRecommendationsPage(double zoomLevel) {
    if (lastGeneratedTempReportData == null ||
        lastGeneratedTempReportData!.isEmpty) {
      return Center(child: Text('No temperature data available'));
    }

    // Analyze devices and generate recommendations
    List<Map<String, dynamic>> recommendations = [];

    for (var device in lastGeneratedTempReportData!) {
      if (device.avgTemperature > -18) {
        recommendations.add({
          'device': device.deviceName,
          'severity': 'High',
          'issue': 'Average temperature above recommended threshold',
          'recommendation':
              'Check refrigeration system, ensure proper airflow, and verify thermostat settings. Consider scheduling maintenance.',
        });
      }

      final violationPercentage =
          device.violations['violation_percentage'] ?? 0.0;
      if (violationPercentage > 10) {
        recommendations.add({
          'device': device.deviceName,
          'severity': 'Medium',
          'issue':
              'Frequent temperature violations (${violationPercentage.toStringAsFixed(1)}%)',
          'recommendation':
              'Review door opening frequency, check door seals, and verify load patterns.',
        });
      }

      if (device.stdDeviation > 3.0) {
        recommendations.add({
          'device': device.deviceName,
          'severity': 'Medium',
          'issue': 'High temperature variability',
          'recommendation':
              'Investigate temperature cycling issues. Check compressor performance and defrost settings.',
        });
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations & Action Items',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          SizedBox(height: 16 * zoomLevel),

          if (recommendations.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(16 * zoomLevel),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 24 * zoomLevel),
                  SizedBox(width: 12 * zoomLevel),
                  Expanded(
                    child: Text(
                      'All devices are operating within normal parameters. No immediate action required.',
                      style: GoogleFonts.inter(
                          fontSize: 10 * zoomLevel, color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Recommendations list
            ...recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final rec = entry.value;
              final severity = rec['severity'];
              final severityColor = severity == 'High'
                  ? Colors.red
                  : (severity == 'Medium' ? Colors.orange : Colors.blue);

              return Container(
                margin: EdgeInsets.only(bottom: 12 * zoomLevel),
                padding: EdgeInsets.all(12 * zoomLevel),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: severityColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: severityColor.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6 * zoomLevel,
                              vertical: 3 * zoomLevel),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            severity,
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 8 * zoomLevel),
                        Expanded(
                          child: Text(
                            rec['device'],
                            style: GoogleFonts.inter(
                                fontSize: 9 * zoomLevel,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * zoomLevel),
                    Text(
                      'Issue: ${rec['issue']}',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel,
                          fontWeight: FontWeight.w500,
                          color: severityColor[700]),
                    ),
                    SizedBox(height: 4 * zoomLevel),
                    Text(
                      'Recommendation: ${rec['recommendation']}',
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel, color: Colors.black87),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          SizedBox(height: 20 * zoomLevel),

          // Best practices
          Text(
            'General Best Practices',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),

          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBestPracticeItem(
                    'Maintain temperature at or below -18°C for optimal cold storage',
                    zoomLevel),
                _buildBestPracticeItem(
                    'Perform regular maintenance checks on refrigeration equipment',
                    zoomLevel),
                _buildBestPracticeItem(
                    'Monitor and log temperature readings daily', zoomLevel),
                _buildBestPracticeItem(
                    'Minimize door opening frequency and duration', zoomLevel),
                _buildBestPracticeItem(
                    'Ensure proper air circulation and avoid overloading',
                    zoomLevel),
                _buildBestPracticeItem(
                    'Calibrate temperature sensors quarterly', zoomLevel),
              ],
            ),
          ),

          SizedBox(height: 20 * zoomLevel),

          // Summary footer
          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Constants.ctaColorLight, size: 16 * zoomLevel),
                SizedBox(width: 8 * zoomLevel),
                Expanded(
                  child: Text(
                    'For additional support or questions about this report, please contact your system administrator.',
                    style: GoogleFonts.inter(
                        fontSize: 8 * zoomLevel, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets for Temperature Analysis pages

  Widget _buildSummaryMetric(
      String label, String value, IconData icon, double zoomLevel) {
    return Container(
      padding: EdgeInsets.all(8 * zoomLevel),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16 * zoomLevel, color: Constants.ctaColorLight),
          SizedBox(height: 4 * zoomLevel),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 10 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 7 * zoomLevel, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  TableRow _buildSensorRow(
      String sensorName, Map<String, dynamic>? sensorData, double zoomLevel) {
    final avg = (sensorData?['average'] ?? 0.0).toDouble();
    final min = (sensorData?['min'] ?? 0.0).toDouble();
    final max = (sensorData?['max'] ?? 0.0).toDouble();

    return TableRow(
      children: [
        _buildTableCell(sensorName, zoomLevel),
        _buildTableCell(avg.toStringAsFixed(1), zoomLevel),
        _buildTableCell(min.toStringAsFixed(1), zoomLevel),
        _buildTableCell(max.toStringAsFixed(1), zoomLevel),
      ],
    );
  }

  Widget _buildDistributionBar(
      String label, double percentage, Color color, double zoomLevel) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 100 * zoomLevel * percentage,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 6 * zoomLevel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildViolationMetric(
      String label, String value, IconData icon, double zoomLevel) {
    return Container(
      padding: EdgeInsets.all(8 * zoomLevel),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14 * zoomLevel, color: Constants.ctaColorLight),
          SizedBox(width: 6 * zoomLevel),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 9 * zoomLevel, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: 7 * zoomLevel, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeLegend(
      String label, String range, Color color, double zoomLevel) {
    return Column(
      children: [
        Container(
          width: 12 * zoomLevel,
          height: 12 * zoomLevel,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4 * zoomLevel),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 7 * zoomLevel, fontWeight: FontWeight.w600),
        ),
        Text(
          range,
          style:
              GoogleFonts.inter(fontSize: 6 * zoomLevel, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildRangeSegment(double percentage, Color color) {
    return Expanded(
      flex: (percentage * 100).toInt(),
      child: Container(
        color: color,
        child: Center(
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
                fontSize: 6, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  TableRow _buildRangeRow(
      String rangeName, double percentage, Color color, double zoomLevel) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(6 * zoomLevel),
          child: Row(
            children: [
              Container(
                width: 10 * zoomLevel,
                height: 10 * zoomLevel,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6 * zoomLevel),
              Text(rangeName,
                  style: GoogleFonts.inter(fontSize: 7 * zoomLevel)),
            ],
          ),
        ),
        _buildTableCell('${percentage.toStringAsFixed(1)}%', zoomLevel),
        Padding(
          padding: EdgeInsets.all(6 * zoomLevel),
          child: Container(
            height: 6 * zoomLevel,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestPracticeItem(String text, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * zoomLevel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 12 * zoomLevel, color: Colors.blue[700]),
          SizedBox(width: 6 * zoomLevel),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 8 * zoomLevel, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ALERTS SUMMARY REPORT PAGE BUILDERS (5 pages)
  // ============================================================================

  Widget _buildAlertsSummaryOverviewPage(double zoomLevel) {
    if (lastGeneratedAlertsReportData == null) {
      return Center(child: Text('No alerts data available'));
    }

    final stats = lastGeneratedAlertsReportData!.overallStats;
    final totalAlerts = stats['total_alerts'] ?? 0;
    final activeAlerts = stats['active_alerts'] ?? 0;
    final resolvedAlerts = stats['resolved_alerts'] ?? 0;
    final criticalCount = stats['critical_count'] ?? 0;
    final highCount = stats['high_count'] ?? 0;
    final avgResolutionTime =
        (stats['avg_resolution_time_minutes'] ?? 0.0).toDouble();
    final affectedDevices = stats['affected_devices'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerts Summary Report',
            style: GoogleFonts.inter(
                fontSize: 18 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5A623)),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Executive Overview',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2 * zoomLevel),
          Text(
            'Period: ${lastGeneratedAlertsReportPeriod ?? "N/A"}',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          Text(
            'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Key Metrics Grid
          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Color(0xFFF5A623).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Color(0xFFF5A623).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAlertMetric('Total Alerts', '$totalAlerts',
                          Icons.notifications, Color(0xFFF5A623), zoomLevel),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAlertMetric('Active', '$activeAlerts',
                          Icons.warning, Colors.red, zoomLevel),
                    ),
                  ],
                ),
                SizedBox(height: 8 * zoomLevel),
                Row(
                  children: [
                    Expanded(
                      child: _buildAlertMetric('Resolved', '$resolvedAlerts',
                          Icons.check_circle, Colors.green, zoomLevel),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAlertMetric(
                          'Affected Devices',
                          '$affectedDevices',
                          Icons.devices,
                          Colors.blue,
                          zoomLevel),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16 * zoomLevel),

          // Critical Metrics
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12 * zoomLevel),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.crisis_alert,
                          color: Colors.red, size: 24 * zoomLevel),
                      SizedBox(height: 6 * zoomLevel),
                      Text(
                        '$criticalCount',
                        style: GoogleFonts.inter(
                            fontSize: 18 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                      Text(
                        'Critical Alerts',
                        style: GoogleFonts.inter(
                            fontSize: 8 * zoomLevel, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12 * zoomLevel),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12 * zoomLevel),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.report_problem,
                          color: Colors.orange, size: 24 * zoomLevel),
                      SizedBox(height: 6 * zoomLevel),
                      Text(
                        '$highCount',
                        style: GoogleFonts.inter(
                            fontSize: 18 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                      Text(
                        'High Priority',
                        style: GoogleFonts.inter(
                            fontSize: 8 * zoomLevel, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12 * zoomLevel),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12 * zoomLevel),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.timer,
                          color: Colors.blue, size: 24 * zoomLevel),
                      SizedBox(height: 6 * zoomLevel),
                      Text(
                        '${avgResolutionTime.toStringAsFixed(0)} min',
                        style: GoogleFonts.inter(
                            fontSize: 14 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      Text(
                        'Avg Response Time',
                        style: GoogleFonts.inter(
                            fontSize: 7 * zoomLevel, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16 * zoomLevel),

          // Alert Status Breakdown
          Text(
            'Alert Distribution',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),

          SizedBox(
            height: 120 * zoomLevel,
            child: Row(
              children: [
                // Pie chart representation (simplified)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(12 * zoomLevel),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatusIndicator('Active', activeAlerts,
                                totalAlerts, Colors.red, zoomLevel),
                            _buildStatusIndicator('Resolved', resolvedAlerts,
                                totalAlerts, Colors.green, zoomLevel),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12 * zoomLevel),
                // Key insights
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(10 * zoomLevel),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key Insights',
                          style: GoogleFonts.inter(
                              fontSize: 9 * zoomLevel,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6 * zoomLevel),
                        _buildInsightItem(
                            '${((activeAlerts / (totalAlerts > 0 ? totalAlerts : 1)) * 100).toStringAsFixed(1)}% of alerts still active',
                            zoomLevel),
                        _buildInsightItem(
                            '${affectedDevices} devices generated alerts',
                            zoomLevel),
                        _buildInsightItem(
                            '${((criticalCount + highCount) / (totalAlerts > 0 ? totalAlerts : 1) * 100).toStringAsFixed(1)}% are high-severity',
                            zoomLevel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsBySeverityPage(double zoomLevel) {
    if (lastGeneratedAlertsReportData == null) {
      return Center(child: Text('No alerts data available'));
    }

    final severityData = lastGeneratedAlertsReportData!.alertsBySeverity;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerts by Severity',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5A623)),
          ),
          SizedBox(height: 16 * zoomLevel),
          ...severityData.map((severity) {
            final severityName = severity['severity'] ?? 'Unknown';
            final count = severity['count'] ?? 0;
            final resolvedCount = severity['resolved_count'] ?? 0;
            final activeCount = severity['active_count'] ?? 0;
            final avgResTime =
                (severity['avg_resolution_time_minutes'] ?? 0.0).toDouble();

            Color severityColor;
            IconData severityIcon;
            switch (severityName.toLowerCase()) {
              case 'critical':
                severityColor = Colors.red;
                severityIcon = Icons.crisis_alert;
                break;
              case 'high':
                severityColor = Colors.orange;
                severityIcon = Icons.report_problem;
                break;
              case 'medium':
                severityColor = Colors.amber;
                severityIcon = Icons.warning;
                break;
              default:
                severityColor = Colors.blue;
                severityIcon = Icons.info;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 16 * zoomLevel),
              padding: EdgeInsets.all(12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
                color: severityColor.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(severityIcon,
                          color: severityColor, size: 20 * zoomLevel),
                      SizedBox(width: 8 * zoomLevel),
                      Text(
                        '${severityName.toUpperCase()} Severity',
                        style: GoogleFonts.inter(
                            fontSize: 11 * zoomLevel,
                            fontWeight: FontWeight.bold,
                            color: severityColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * zoomLevel),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel,
                                    color: Colors.black54)),
                            Text('$count',
                                style: GoogleFonts.inter(
                                    fontSize: 16 * zoomLevel,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel,
                                    color: Colors.black54)),
                            Text('$activeCount',
                                style: GoogleFonts.inter(
                                    fontSize: 16 * zoomLevel,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resolved',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel,
                                    color: Colors.black54)),
                            Text('$resolvedCount',
                                style: GoogleFonts.inter(
                                    fontSize: 16 * zoomLevel,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avg Time',
                                style: GoogleFonts.inter(
                                    fontSize: 7 * zoomLevel,
                                    color: Colors.black54)),
                            Text('${avgResTime.toStringAsFixed(0)}m',
                                style: GoogleFonts.inter(
                                    fontSize: 14 * zoomLevel,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8 * zoomLevel),

                  // Progress bar
                  Container(
                    height: 8 * zoomLevel,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: count > 0 ? (resolvedCount / count) : 0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * zoomLevel),
                  Text(
                    '${count > 0 ? ((resolvedCount / count) * 100).toStringAsFixed(1) : "0"}% Resolved',
                    style: GoogleFonts.inter(
                        fontSize: 7 * zoomLevel, color: Colors.black54),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAlertsByDevicePage(double zoomLevel) {
    if (lastGeneratedAlertsReportData == null) {
      return Center(child: Text('No alerts data available'));
    }

    final deviceData = lastGeneratedAlertsReportData!.alertsByDevice;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerts by Device',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5A623)),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Top ${deviceData.length} devices with most alerts',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              border: TableBorder.symmetric(
                  inside:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                      color: Color(0xFFF5A623).withValues(alpha: 0.1)),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Text('Device Name',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600))),
                    Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Text('Total',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Text('Critical',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Text('High',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Text('Active',
                            style: GoogleFonts.inter(
                                fontSize: 8 * zoomLevel,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                  ],
                ),
                ...deviceData.take(15).map((device) {
                  return TableRow(
                    children: [
                      Padding(
                          padding: EdgeInsets.all(8 * zoomLevel),
                          child: Text(device['device_name'] ?? 'Unknown',
                              style:
                                  GoogleFonts.inter(fontSize: 7 * zoomLevel))),
                      Padding(
                          padding: EdgeInsets.all(8 * zoomLevel),
                          child: Text('${device['total_alerts'] ?? 0}',
                              style: GoogleFonts.inter(fontSize: 7 * zoomLevel),
                              textAlign: TextAlign.center)),
                      Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4 * zoomLevel,
                              vertical: 2 * zoomLevel),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${device['critical_alerts'] ?? 0}',
                              style: GoogleFonts.inter(
                                  fontSize: 7 * zoomLevel, color: Colors.red),
                              textAlign: TextAlign.center),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4 * zoomLevel,
                              vertical: 2 * zoomLevel),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${device['high_alerts'] ?? 0}',
                              style: GoogleFonts.inter(
                                  fontSize: 7 * zoomLevel,
                                  color: Colors.orange),
                              textAlign: TextAlign.center),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8 * zoomLevel),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4 * zoomLevel,
                              vertical: 2 * zoomLevel),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${device['active_alerts'] ?? 0}',
                              style: GoogleFonts.inter(
                                  fontSize: 7 * zoomLevel, color: Colors.blue),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTrendsPage(double zoomLevel) {
    if (lastGeneratedAlertsReportData == null) {
      return Center(child: Text('No alerts data available'));
    }

    final dailyTrend = lastGeneratedAlertsReportData!.dailyTrend;
    final hourlyDist = lastGeneratedAlertsReportData!.hourlyDistribution;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Trends & Patterns',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5A623)),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Daily Trend
          Text(
            'Daily Alert Trend',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),

          if (dailyTrend.isNotEmpty) ...[
            Container(
              height: 180 * zoomLevel,
              padding: EdgeInsets.all(12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30 * zoomLevel,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: GoogleFonts.inter(fontSize: 7 * zoomLevel),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < dailyTrend.length) {
                            final date =
                                dailyTrend[value.toInt()]['date']?.toString() ??
                                    '';
                            return Text(
                              date.split('T')[0].substring(5),
                              style: GoogleFonts.inter(fontSize: 6 * zoomLevel),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyTrend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(),
                            (e.value['total_alerts'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Color(0xFFF5A623),
                      barWidth: 2,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true,
                          color: Color(0xFFF5A623).withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 20 * zoomLevel),

          // Hourly Distribution
          Text(
            'Hourly Alert Distribution',
            style: GoogleFonts.inter(
                fontSize: 11 * zoomLevel, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8 * zoomLevel),

          if (hourlyDist.isNotEmpty) ...[
            Container(
              height: 150 * zoomLevel,
              padding: EdgeInsets.all(12 * zoomLevel),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30 * zoomLevel,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: GoogleFonts.inter(fontSize: 7 * zoomLevel),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 4 == 0) {
                            return Text('${value.toInt()}h',
                                style:
                                    GoogleFonts.inter(fontSize: 6 * zoomLevel));
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: hourlyDist.map((hour) {
                    final hourValue = (hour['hour'] ?? 0).toInt();
                    final count = (hour['count'] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: hourValue,
                      barRods: [
                        BarChartRodData(
                            toY: count,
                            color: Color(0xFFF5A623),
                            width: 6 * zoomLevel)
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveAlertsPage(double zoomLevel) {
    if (lastGeneratedAlertsReportData == null) {
      return Center(child: Text('No alerts data available'));
    }

    final activeAlerts = lastGeneratedAlertsReportData!.recentActiveAlerts;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Active Alerts',
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5A623)),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Most recent unresolved alerts requiring attention',
            style: GoogleFonts.inter(
                fontSize: 9 * zoomLevel, color: Colors.black54),
          ),
          SizedBox(height: 16 * zoomLevel),
          if (activeAlerts.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(20 * zoomLevel),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 32 * zoomLevel),
                  SizedBox(width: 12 * zoomLevel),
                  Expanded(
                    child: Text(
                      'No active alerts! All alerts have been resolved.',
                      style: GoogleFonts.inter(
                          fontSize: 11 * zoomLevel, color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...activeAlerts.map((alert) {
              final severity = alert['severity'] ?? 'Unknown';
              final alertType = alert['alert_type'] ?? 'Unknown';
              final message = alert['message'] ?? 'No message';
              final createdAt = alert['created_at']?.toString() ?? '';
              final deviceId = alert['device_id'] ?? 'Unknown';

              Color severityColor;
              switch (severity.toLowerCase()) {
                case 'critical':
                  severityColor = Colors.red;
                  break;
                case 'high':
                  severityColor = Colors.orange;
                  break;
                case 'medium':
                  severityColor = Colors.amber;
                  break;
                default:
                  severityColor = Colors.blue;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 12 * zoomLevel),
                padding: EdgeInsets.all(12 * zoomLevel),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: severityColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: severityColor.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6 * zoomLevel,
                              vertical: 3 * zoomLevel),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 7 * zoomLevel,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 8 * zoomLevel),
                        Expanded(
                          child: Text(
                            alertType,
                            style: GoogleFonts.inter(
                                fontSize: 9 * zoomLevel,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          createdAt.split('T')[0],
                          style: GoogleFonts.inter(
                              fontSize: 7 * zoomLevel, color: Colors.black54),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * zoomLevel),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                          fontSize: 8 * zoomLevel, color: Colors.black87),
                    ),
                    SizedBox(height: 6 * zoomLevel),
                    Row(
                      children: [
                        Icon(Icons.devices,
                            size: 10 * zoomLevel, color: Colors.black54),
                        SizedBox(width: 4 * zoomLevel),
                        Text(
                          'Device: $deviceId',
                          style: GoogleFonts.inter(
                              fontSize: 7 * zoomLevel, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // Helper widgets for Alerts Summary pages

  Widget _buildAlertMetric(String label, String value, IconData icon,
      Color color, double zoomLevel) {
    return Container(
      padding: EdgeInsets.all(8 * zoomLevel),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16 * zoomLevel, color: color),
          SizedBox(height: 4 * zoomLevel),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 14 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: color),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 7 * zoomLevel, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
      String label, int count, int total, Color color, double zoomLevel) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(0) : "0";
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        Text(
          label,
          style:
              GoogleFonts.inter(fontSize: 8 * zoomLevel, color: Colors.black54),
        ),
        Text(
          '$percentage%',
          style: GoogleFonts.inter(fontSize: 7 * zoomLevel, color: color),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String text, double zoomLevel) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4 * zoomLevel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.inter(fontSize: 8 * zoomLevel)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 7 * zoomLevel, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // MAINTENANCE REPORT PAGES (8 pages)
  // ========================================================================

  // Page 1: Maintenance Summary Page
  Widget _buildMaintenanceSummaryPage(double zoomLevel) {
    print('Building Maintenance Summary Page');
    print('Data is null: ${lastGeneratedMaintenanceReportData == null}');

    final data = lastGeneratedMaintenanceReportData!;
    final stats = data.overallStats;

    print('Overall stats: $stats');

    final totalMaintenance = stats['total_maintenance'] ?? 0;
    final completedCount = stats['completed_count'] ?? 0;
    final overdueCount = stats['overdue_count'] ?? 0;
    final completionRate = (stats['completion_rate'] ?? 0.0).toDouble();
    final avgCost = (stats['avg_cost'] ?? 0.0).toDouble();
    final totalCost = (stats['total_cost'] ?? 0.0).toDouble();
    final devicesServiced = stats['devices_serviced'] ?? 0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Maintenance Summary',
            style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 4 * zoomLevel),
          Text(
            'Period: ${lastGeneratedMaintenanceReportStartDate} to ${lastGeneratedMaintenanceReportEndDate}',
            style: GoogleFonts.inter(
              fontSize: 10 * zoomLevel,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Key Metrics Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 12 * zoomLevel,
            mainAxisSpacing: 12 * zoomLevel,
            childAspectRatio: 1.5,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildMaintenanceMetricCard(
                'Total Maintenance',
                totalMaintenance.toString(),
                Icons.build,
                Color(0xFF3498DB),
                zoomLevel,
              ),
              _buildMaintenanceMetricCard(
                'Completed',
                completedCount.toString(),
                Icons.check_circle,
                Color(0xFF27AE60),
                zoomLevel,
              ),
              _buildMaintenanceMetricCard(
                'Overdue',
                overdueCount.toString(),
                Icons.warning,
                Color(0xFFE74C3C),
                zoomLevel,
              ),
              _buildMaintenanceMetricCard(
                'Completion Rate',
                '${completionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Color(0xFF9B59B6),
                zoomLevel,
              ),
            ],
          ),
          SizedBox(height: 16 * zoomLevel),

          // Financial Summary
          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost Summary',
                  style: GoogleFonts.inter(
                    fontSize: 12 * zoomLevel,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 8 * zoomLevel),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCostMetric(
                      'Total Cost',
                      'R ${totalCost.toStringAsFixed(2)}',
                      Colors.blue,
                      zoomLevel,
                    ),
                    _buildCostMetric(
                      'Average Cost',
                      'R ${avgCost.toStringAsFixed(2)}',
                      Colors.green,
                      zoomLevel,
                    ),
                    _buildCostMetric(
                      'Devices Serviced',
                      devicesServiced.toString(),
                      Colors.orange,
                      zoomLevel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Status Breakdown
          Text(
            'Status Breakdown',
            style: GoogleFonts.inter(
              fontSize: 12 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8 * zoomLevel),
          Row(
            children: [
              Expanded(
                child: _buildStatusBar(
                  'Completed',
                  completedCount,
                  totalMaintenance,
                  Color(0xFF27AE60),
                  zoomLevel,
                ),
              ),
              SizedBox(width: 8 * zoomLevel),
              Expanded(
                child: _buildStatusBar(
                  'In Progress',
                  stats['in_progress_count'] ?? 0,
                  totalMaintenance,
                  Color(0xFF3498DB),
                  zoomLevel,
                ),
              ),
              SizedBox(width: 8 * zoomLevel),
              Expanded(
                child: _buildStatusBar(
                  'Scheduled',
                  stats['scheduled_count'] ?? 0,
                  totalMaintenance,
                  Color(0xFFF39C12),
                  zoomLevel,
                ),
              ),
              SizedBox(width: 8 * zoomLevel),
              Expanded(
                child: _buildStatusBar(
                  'Overdue',
                  overdueCount,
                  totalMaintenance,
                  Color(0xFFE74C3C),
                  zoomLevel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Page 2: Maintenance by Type
  Widget _buildMaintenanceByTypePage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final maintenanceByType = data.maintenanceByType;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance by Type',
            style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Table
          Table(
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Color(0xFF3498DB)),
                children: [
                  _buildTableHeader('Type', zoomLevel),
                  _buildTableHeader('Category', zoomLevel),
                  _buildTableHeader('Count', zoomLevel),
                  _buildTableHeader('Completed', zoomLevel),
                  _buildTableHeader('Avg Duration', zoomLevel),
                  _buildTableHeader('Avg Cost', zoomLevel),
                ],
              ),
              // Data rows
              ...maintenanceByType.take(15).map((item) {
                return TableRow(
                  children: [
                    _buildTableCell(item['maintenance_type'] ?? 'N/A', zoomLevel),
                    _buildTableCell(_formatCategory(item['category']), zoomLevel),
                    _buildTableCell((item['count'] ?? 0).toString(), zoomLevel),
                    _buildTableCell((item['completed'] ?? 0).toString(), zoomLevel),
                    _buildTableCell(
                      item['avg_duration'] != null
                          ? '${item['avg_duration'].toStringAsFixed(1)}h'
                          : 'N/A',
                      zoomLevel,
                    ),
                    _buildTableCell(
                      item['avg_cost'] != null
                          ? 'R${item['avg_cost'].toStringAsFixed(0)}'
                          : 'N/A',
                      zoomLevel,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // Page 3: Maintenance by Device
  Widget _buildMaintenanceByDevicePage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final maintenanceByDevice = data.maintenanceByDevice;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance by Device',
            style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Table
          Table(
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Color(0xFF3498DB)),
                children: [
                  _buildTableHeader('Device Name', zoomLevel),
                  _buildTableHeader('Device ID', zoomLevel),
                  _buildTableHeader('Total', zoomLevel),
                  _buildTableHeader('Completed', zoomLevel),
                  _buildTableHeader('Overdue', zoomLevel),
                  _buildTableHeader('Avg Cost', zoomLevel),
                ],
              ),
              // Data rows
              ...maintenanceByDevice.take(20).map((item) {
                return TableRow(
                  children: [
                    _buildTableCell(item['device_name'] ?? 'N/A', zoomLevel),
                    _buildTableCell(item['device_id'] ?? 'N/A', zoomLevel),
                    _buildTableCell((item['maintenance_count'] ?? 0).toString(), zoomLevel),
                    _buildTableCell((item['completed_count'] ?? 0).toString(), zoomLevel),
                    _buildTableCell(
                      (item['overdue_count'] ?? 0).toString(),
                      zoomLevel,
                    ),
                    _buildTableCell(
                      item['avg_cost'] != null
                          ? 'R${item['avg_cost'].toStringAsFixed(0)}'
                          : 'N/A',
                      zoomLevel,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // Page 4: Cost Analysis
  Widget _buildMaintenanceCostAnalysisPage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final costAnalysis = data.costAnalysis;
    final durationAnalysis = data.durationAnalysis;

    final totalEstimated = (costAnalysis['total_estimated_cost'] ?? 0.0).toDouble();
    final totalActual = (costAnalysis['total_actual_cost'] ?? 0.0).toDouble();
    final variance = (costAnalysis['total_cost_variance'] ?? 0.0).toDouble();
    final overBudget = costAnalysis['over_budget_count'] ?? 0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost & Duration Analysis',
            style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Cost Analysis Section
          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 14 * zoomLevel,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 12 * zoomLevel),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Estimated Cost',
                        'R ${totalEstimated.toStringAsFixed(2)}',
                        Colors.blue,
                        zoomLevel,
                      ),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Actual Cost',
                        'R ${totalActual.toStringAsFixed(2)}',
                        Colors.green,
                        zoomLevel,
                      ),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Variance',
                        'R ${variance.toStringAsFixed(2)}',
                        variance > 0 ? Colors.red : Colors.green,
                        zoomLevel,
                      ),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Over Budget',
                        overBudget.toString(),
                        Colors.orange,
                        zoomLevel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Duration Analysis Section
          Container(
            padding: EdgeInsets.all(12 * zoomLevel),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 14 * zoomLevel,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 12 * zoomLevel),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Avg Estimated',
                        '${(durationAnalysis['avg_estimated_duration'] ?? 0.0).toStringAsFixed(1)}h',
                        Colors.blue,
                        zoomLevel,
                      ),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Avg Actual',
                        '${(durationAnalysis['avg_actual_duration'] ?? 0.0).toStringAsFixed(1)}h',
                        Colors.green,
                        zoomLevel,
                      ),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Total Hours',
                        '${(durationAnalysis['total_hours_spent'] ?? 0.0).toStringAsFixed(1)}h',
                        Colors.purple,
                        zoomLevel,
                      ),
                    ),
                    SizedBox(width: 8 * zoomLevel),
                    Expanded(
                      child: _buildAnalysisMetric(
                        'Over Time',
                        (durationAnalysis['over_time_count'] ?? 0).toString(),
                        Colors.orange,
                        zoomLevel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 5: Maintenance Trends
  Widget _buildMaintenanceTrendsPage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final monthlyTrend = data.monthlyTrend;
    final maintenanceByPriority = data.maintenanceByPriority;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance Trends',
            style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Monthly Trend Table
          Text(
            'Monthly Trend',
            style: GoogleFonts.inter(
              fontSize: 12 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8 * zoomLevel),
          Table(
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFF3498DB)),
                children: [
                  _buildTableHeader('Month', zoomLevel),
                  _buildTableHeader('Total', zoomLevel),
                  _buildTableHeader('Completed', zoomLevel),
                  _buildTableHeader('Avg Cost', zoomLevel),
                  _buildTableHeader('Avg Duration', zoomLevel),
                ],
              ),
              ...monthlyTrend.take(12).map((item) {
                return TableRow(
                  children: [
                    _buildTableCell(item['month'] ?? 'N/A', zoomLevel),
                    _buildTableCell((item['count'] ?? 0).toString(), zoomLevel),
                    _buildTableCell((item['completed'] ?? 0).toString(), zoomLevel),
                    _buildTableCell(
                      item['avg_cost'] != null
                          ? 'R${item['avg_cost'].toStringAsFixed(0)}'
                          : 'N/A',
                      zoomLevel,
                    ),
                    _buildTableCell(
                      item['avg_duration'] != null
                          ? '${item['avg_duration'].toStringAsFixed(1)}h'
                          : 'N/A',
                      zoomLevel,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          SizedBox(height: 16 * zoomLevel),

          // Priority Breakdown
          Text(
            'Priority Distribution',
            style: GoogleFonts.inter(
              fontSize: 12 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8 * zoomLevel),
          Wrap(
            spacing: 12 * zoomLevel,
            runSpacing: 8 * zoomLevel,
            children: maintenanceByPriority.map((item) {
              return _buildPriorityBadge(
                _formatPriority(item['priority']),
                item['count'] ?? 0,
                _getPriorityColor(item['priority']),
                zoomLevel,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Page 6: Recent Completed Maintenance
  Widget _buildRecentCompletedMaintenancePage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final recentCompleted = data.recentCompleted;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Completed Maintenance',
            style: GoogleFonts.inter(
              fontSize: 18 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 16 * zoomLevel),

          // Table
          Table(
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFF27AE60)),
                children: [
                  _buildTableHeader('Device', zoomLevel),
                  _buildTableHeader('Type', zoomLevel),
                  _buildTableHeader('Completed', zoomLevel),
                  _buildTableHeader('Duration', zoomLevel),
                  _buildTableHeader('Cost', zoomLevel),
                  _buildTableHeader('Outcome', zoomLevel),
                ],
              ),
              ...recentCompleted.take(20).map((item) {
                final completedAt = item['actual_end_date'] ?? item['scheduled_date'];
                return TableRow(
                  children: [
                    _buildTableCell(item['device_name'] ?? 'N/A', zoomLevel),
                    _buildTableCell(item['maintenance_type'] ?? 'N/A', zoomLevel),
                    _buildTableCell(
                      completedAt != null
                          ? completedAt.toString().substring(0, 10)
                          : 'N/A',
                      zoomLevel,
                    ),
                    _buildTableCell(
                      item['actual_duration_hours'] != null
                          ? '${item['actual_duration_hours'].toStringAsFixed(1)}h'
                          : 'N/A',
                      zoomLevel,
                    ),
                    _buildTableCell(
                      item['actual_cost'] != null
                          ? 'R${item['actual_cost'].toStringAsFixed(0)}'
                          : 'N/A',
                      zoomLevel,
                    ),
                    _buildTableCell(_formatOutcome(item['outcome']), zoomLevel),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // Page 7: Upcoming Maintenance
  Widget _buildUpcomingMaintenancePage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final upcomingMaintenance = data.upcomingMaintenance;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF3498DB), size: 20 * zoomLevel),
              SizedBox(width: 8 * zoomLevel),
              Text(
                'Upcoming Maintenance (Next 30 Days)',
                style: GoogleFonts.inter(
                  fontSize: 18 * zoomLevel,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * zoomLevel),

          // Table
          if (upcomingMaintenance.isEmpty)
            Container(
              padding: EdgeInsets.all(24 * zoomLevel),
              alignment: Alignment.center,
              child: Text(
                'No upcoming maintenance scheduled',
                style: GoogleFonts.inter(
                  fontSize: 12 * zoomLevel,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            Table(
              border: TableBorder.all(color: Colors.grey[300]!, width: 1),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xFF3498DB)),
                  children: [
                    _buildTableHeader('Device', zoomLevel),
                    _buildTableHeader('Type', zoomLevel),
                    _buildTableHeader('Scheduled', zoomLevel),
                    _buildTableHeader('Priority', zoomLevel),
                    _buildTableHeader('Est. Cost', zoomLevel),
                    _buildTableHeader('Est. Duration', zoomLevel),
                  ],
                ),
                ...upcomingMaintenance.map((item) {
                  return TableRow(
                    children: [
                      _buildTableCell(item['device_name'] ?? 'N/A', zoomLevel),
                      _buildTableCell(item['maintenance_type'] ?? 'N/A', zoomLevel),
                      _buildTableCell(
                        item['scheduled_date'] != null
                            ? item['scheduled_date'].toString().substring(0, 10)
                            : 'N/A',
                        zoomLevel,
                      ),
                      _buildTableCell(_formatPriority(item['priority']), zoomLevel),
                      _buildTableCell(
                        item['estimated_cost'] != null
                            ? 'R${item['estimated_cost'].toStringAsFixed(0)}'
                            : 'N/A',
                        zoomLevel,
                      ),
                      _buildTableCell(
                        item['estimated_duration_hours'] != null
                            ? '${item['estimated_duration_hours'].toStringAsFixed(1)}h'
                            : 'N/A',
                        zoomLevel,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  // Page 8: Overdue Maintenance
  Widget _buildOverdueMaintenancePage(double zoomLevel) {
    final data = lastGeneratedMaintenanceReportData!;
    final overdueMaintenance = data.overdueMaintenance;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16 * zoomLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFE74C3C), size: 20 * zoomLevel),
              SizedBox(width: 8 * zoomLevel),
              Text(
                'Overdue Maintenance - Requires Immediate Attention',
                style: GoogleFonts.inter(
                  fontSize: 18 * zoomLevel,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * zoomLevel),

          // Table
          if (overdueMaintenance.isEmpty)
            Container(
              padding: EdgeInsets.all(24 * zoomLevel),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 40 * zoomLevel),
                  SizedBox(height: 8 * zoomLevel),
                  Text(
                    'No overdue maintenance - All on track!',
                    style: GoogleFonts.inter(
                      fontSize: 14 * zoomLevel,
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Table(
              border: TableBorder.all(color: Colors.grey[300]!, width: 1),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xFFE74C3C)),
                  children: [
                    _buildTableHeader('Device', zoomLevel),
                    _buildTableHeader('Type', zoomLevel),
                    _buildTableHeader('Scheduled', zoomLevel),
                    _buildTableHeader('Days Overdue', zoomLevel),
                    _buildTableHeader('Priority', zoomLevel),
                  ],
                ),
                ...overdueMaintenance.map((item) {
                  final daysOverdue = (item['days_overdue'] ?? 0).toInt();
                  return TableRow(
                    decoration: BoxDecoration(
                      color: daysOverdue > 7
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                    ),
                    children: [
                      _buildTableCell(item['device_name'] ?? 'N/A', zoomLevel),
                      _buildTableCell(item['maintenance_type'] ?? 'N/A', zoomLevel),
                      _buildTableCell(
                        item['scheduled_date'] != null
                            ? item['scheduled_date'].toString().substring(0, 10)
                            : 'N/A',
                        zoomLevel,
                      ),
                      _buildTableCell(
                        '$daysOverdue days',
                        zoomLevel,
                      ),
                      _buildTableCell(_formatPriority(item['priority']), zoomLevel),
                    ],
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  // Helper widgets for Maintenance Report pages
  Widget _buildMaintenanceMetricCard(
      String label, String value, IconData icon, Color color, double zoomLevel) {
    return Container(
      padding: EdgeInsets.all(10 * zoomLevel),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20 * zoomLevel, color: color),
          SizedBox(height: 6 * zoomLevel),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16 * zoomLevel,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2 * zoomLevel),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8 * zoomLevel,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCostMetric(String label, String value, Color color, double zoomLevel) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14 * zoomLevel,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4 * zoomLevel),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9 * zoomLevel,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(
      String label, int count, int total, Color color, double zoomLevel) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8 * zoomLevel,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4 * zoomLevel),
        Container(
          height: 20 * zoomLevel,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 8 * zoomLevel,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisMetric(
      String label, String value, Color color, double zoomLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8 * zoomLevel,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4 * zoomLevel),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12 * zoomLevel,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(
      String priority, int count, Color color, double zoomLevel) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * zoomLevel,
        vertical: 6 * zoomLevel,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            priority,
            style: GoogleFonts.inter(
              fontSize: 10 * zoomLevel,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(width: 8 * zoomLevel),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * zoomLevel,
              vertical: 2 * zoomLevel,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 8 * zoomLevel,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(dynamic category) {
    if (category == null) return 'N/A';
    return category.toString().split('_').map((e) => e.capitalize()).join(' ');
  }

  String _formatPriority(dynamic priority) {
    if (priority == null) return 'Normal';
    return priority.toString().capitalize();
  }

  String _formatOutcome(dynamic outcome) {
    if (outcome == null) return 'N/A';
    return outcome.toString().split('_').map((e) => e.capitalize()).join(' ');
  }

  Color _getPriorityColor(dynamic priority) {
    switch (priority?.toString().toLowerCase()) {
      case 'emergency':
        return Color(0xFF8B0000);
      case 'critical':
        return Color(0xFFE74C3C);
      case 'high':
        return Color(0xFFF39C12);
      case 'normal':
        return Color(0xFF3498DB);
      case 'low':
        return Color(0xFF95A5A6);
      default:
        return Color(0xFF3498DB);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
