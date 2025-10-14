import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';

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
  const Reports({Key? key}) : super(key: key);

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

  final List<String> periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
    'Custom Range',
  ];

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

  final List<DownloadedReport> downloadedReports = [
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
  ];

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

  void _showDevicePerformanceDialog() {
    String selectedDevice = 'all';
    String selectedMetric = 'all';
    bool includeCharts = true;
    bool includeRawData = false;

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
                            value: 'all',
                            child: Text('All Devices'),
                          ),
                          DropdownMenuItem(
                            value: 'device_001',
                            child: Text('Device 001 - Chiller A'),
                          ),
                          DropdownMenuItem(
                            value: 'device_002',
                            child: Text('Device 002 - Freezer B'),
                          ),
                          DropdownMenuItem(
                            value: 'device_003',
                            child: Text('Device 003 - Chiller C'),
                          ),
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
                            backgroundColor:
                                Colors.grey.withValues(alpha: 0.1),
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              isGenerating = true;
                              selectedReportType = 'device_performance';
                            });
                            Future.delayed(Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  isGenerating = false;
                                });
                                _showSuccessDialog('Device Performance Report');
                              }
                            });
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

  void _showTemperatureAnalyticsDialog() {
    String selectedDevice = 'all';
    String temperatureRange = 'all';
    bool includeAnomalies = true;

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
                          DropdownMenuItem(value: 'all', child: Text('All Devices')),
                          DropdownMenuItem(value: 'device_001', child: Text('Device 001 - Chiller A')),
                          DropdownMenuItem(value: 'device_002', child: Text('Device 002 - Freezer B')),
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
                          DropdownMenuItem(value: 'all', child: Text('All Temperatures')),
                          DropdownMenuItem(value: 'normal', child: Text('Normal Range Only')),
                          DropdownMenuItem(value: 'high', child: Text('Above Threshold')),
                          DropdownMenuItem(value: 'low', child: Text('Below Threshold')),
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              isGenerating = true;
                              selectedReportType = 'temperature_analytics';
                            });
                            Future.delayed(Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  isGenerating = false;
                                });
                                _showSuccessDialog('Temperature Analytics Report');
                              }
                            });
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
        {'label': 'Alert Severity', 'options': ['All Severities', 'Critical Only', 'High Priority', 'Medium & Low']},
        {'label': 'Alert Type', 'options': ['All Types', 'Temperature Alerts', 'System Alerts', 'Door Alerts']},
      ],
    );
  }

  void _showMaintenanceHistoryDialog() {
    _showGenericReportDialog(
      'Maintenance History Report',
      'Configure maintenance records',
      FontAwesomeIcons.screwdriverWrench,
      Color(0xFF7B68EE),
      'maintenance_history',
      [
        {'label': 'Maintenance Type', 'options': ['All Types', 'Preventive', 'Corrective', 'Emergency']},
        {'label': 'Status', 'options': ['All Status', 'Completed', 'Pending', 'Scheduled']},
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
        {'label': 'Measurement', 'options': ['All Measurements', 'Power Usage', 'Energy Cost', 'Efficiency Rating']},
        {'label': 'Comparison', 'options': ['No Comparison', 'Month over Month', 'Year over Year', 'Device vs Device']},
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
        {'label': 'Compliance Standard', 'options': ['All Standards', 'FDA', 'ISO 9001', 'HACCP', 'Custom']},
        {'label': 'Report Level', 'options': ['Summary', 'Detailed', 'Audit Trail', 'Executive Summary']},
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
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              isGenerating = true;
                              selectedReportType = reportId;
                            });
                            Future.delayed(Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  isGenerating = false;
                                });
                                _showSuccessDialog(title);
                              }
                            });
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
          List<DownloadedReport> currentPageReports =
              downloadedReports.sublist(startIndex, endIndex);

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
                                    Text(
                                      report.name,
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
                                          report.downloadedBy,
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
                                          report.downloadDate,
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
                                          '${report.format} • ${report.fileSize}',
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
                                                  padding: EdgeInsets.only(right: 4),
                                                  child: SizedBox(
                                                    width: 10,
                                                    height: 10,
                                                    child: CircularProgressIndicator(
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
                                      color: isProcessing ? Colors.grey : Colors.blue,
                                    ),
                                    onPressed: isProcessing ? null : () {},
                                    tooltip: 'View',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.cloud_download,
                                      size: 18,
                                      color: isProcessing ? Colors.grey : Colors.green,
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
                        _showDownloadDialog(reportName);
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

  void _showPDFPreviewDialog(String reportName) {
    int currentPage = 1;
    int totalPages = 8;
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
                                        color: Colors.grey.withValues(alpha: 0.3)),
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
                                    SizedBox(height: 20 * zoomLevel),
                                    // Sample Content
                                    Text(
                                      'Executive Summary',
                                      style: GoogleFonts.inter(
                                        fontSize: 14 * zoomLevel,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 8 * zoomLevel),
                                    Text(
                                      'This report provides comprehensive analysis of device performance metrics, temperature analytics, and operational statistics for the selected time period.',
                                      style: GoogleFonts.inter(
                                        fontSize: 10 * zoomLevel,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 16 * zoomLevel),
                                    // Sample Data Table
                                    Container(
                                      padding: EdgeInsets.all(12 * zoomLevel),
                                      decoration: BoxDecoration(
                                        color: Colors.grey
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Key Metrics',
                                            style: GoogleFonts.inter(
                                              fontSize: 12 * zoomLevel,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8 * zoomLevel),
                                          _buildMetricRow(
                                              'Total Devices', '24', zoomLevel),
                                          _buildMetricRow(
                                              'Active Devices', '21', zoomLevel),
                                          _buildMetricRow('Avg Temperature',
                                              '-18°C', zoomLevel),
                                          _buildMetricRow(
                                              'Uptime', '99.8%', zoomLevel),
                                        ],
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
                              _showDownloadDialog(reportName);
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

  void _showDownloadDialog(String reportName) {
    double progress = 0.0;
    String status = 'Preparing download...';
    bool isCompleted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (progress == 0.0) {
            // Simulate download progress
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
                              : Constants.ctaColorLight
                                  .withValues(alpha: 0.1),
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
                            onPressed: () {
                              // Open file location
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
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            SizedBox(height: 4),
            Divider(thickness: 0.5, color: Colors.grey),
            SizedBox(height: 32),

            // Quick Stats Section
            Row(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: Colors.purple.withValues(alpha: 0.1),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
            SizedBox(height: 32),

            // Report Types Section
            Text(
              "Report Types",
              style: GoogleFonts.inter(
                fontSize: 18,
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
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: reportTypes.length,
              itemBuilder: (context, index) {
                final reportType = reportTypes[index];
                final isGeneratingThis = isGenerating &&
                    selectedReportType == reportType.id;

                return CustomCard(
                  elevation: 2,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: isGenerating
                        ? null
                        : () => _generateReport(reportType),
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
                                  color: reportType.color.withValues(alpha: 0.1),
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
                fontSize: 18,
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
                child: Column(
                  children: [
                    _buildRecentReportItem(
                      'Device Performance Report',
                      'Generated on Dec 10, 2024',
                      FontAwesomeIcons.chartLine,
                      Color(0xFF4A90E2),
                    ),
                    Divider(height: 24, thickness: 0.5),
                    _buildRecentReportItem(
                      'Temperature Analytics',
                      'Generated on Dec 08, 2024',
                      FontAwesomeIcons.temperatureHalf,
                      Color(0xFFE94B3C),
                    ),
                    Divider(height: 24, thickness: 0.5),
                    _buildRecentReportItem(
                      'Alerts Summary',
                      'Generated on Dec 05, 2024',
                      FontAwesomeIcons.bellConcierge,
                      Color(0xFFF5A623),
                    ),
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
}