import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/custom_widgets/customCard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/pdf_saver.dart';

import '../models/device.dart' hide Device;
import '../models/maintanance.dart';
import '../services/shared_preferences.dart';
import '../widgets/compact_header.dart';

// Main Maintenance Dashboard
class MaintenanceDashboard extends StatefulWidget {
  @override
  _MaintenanceDashboardState createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';

  // Data
  Map<String, dynamic> _dashboardData = {};
  List<dynamic> _maintenanceRecords = [];
  List<dynamic> _maintenanceTypes = [];
  List<dynamic> _upcomingMaintenance = [];
  Map<String, dynamic> _remindersData = {};
  List<dynamic> _schedules = [];

  // Filters
  Map<String, dynamic> _filters = {};
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _loadDashboardData(),
        _loadMaintenanceRecords(),
        _loadMaintenanceTypes(),
        _loadRemindersData(),
        _loadSchedules(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}api/maintenance/dashboard/'),
      headers: ApiConfig.headers,
      body: json.encode({
        'business_id': await SharedPrefs.getBusinessId(),
        'date_from': _dateRange?.start.toIso8601String(),
        'date_to': _dateRange?.end.toIso8601String(),
      }),
    );
    if (kDebugMode) {
      print("hghjh ${response.body}");
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("hghjh ${data['dashboard']['upcoming_maintenance']}");
      setState(() {
        _dashboardData = data['dashboard'];
        _upcomingMaintenance = data['dashboard']['upcoming_maintenance'];
      });
    }
  }

  Future<void> _loadMaintenanceRecords() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}api/maintenance/list/'),
      headers: ApiConfig.headers,
      body: json.encode({
        'business_id': await SharedPrefs.getBusinessId(),
        'filters': _filters,
        'page': 1,
        'per_page': 50,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _maintenanceRecords = data['maintenance_records'];
      });
    }
  }

  Future<void> _loadMaintenanceTypes() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}api/maintenance/types/'),
      headers: ApiConfig.headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _maintenanceTypes = data['maintenance_types'];
      });
    }
  }

  Future<void> _loadRemindersData() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/reminders/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'business_id': await SharedPrefs.getBusinessId(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _remindersData = data['reminders'] ?? {};
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  Future<void> _loadSchedules() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/schedules/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'business_id': await SharedPrefs.getBusinessId(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _schedules = data['schedules'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  Future<void> _sendManualReminder(String maintenanceId, String reminderType) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/$maintenanceId/send-reminder/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'reminder_type': reminderType,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRemindersData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1000,
      child: Column(
        children: [
          // Header Section
          _buildHeader(),

          // Tab Bar
          _buildTabBar(),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error.isNotEmpty
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildMaintenanceListTab(),
                          _buildSchedulingTab(),
                          _buildRemindersTab(),
                          _buildAnalyticsTab(),
                          _buildSettingsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const CompactHeader(
      title: "Maintenance",
      description: "Schedule and track maintenance tasks",
      icon: Icons.build_rounded,
    );
  }

  Widget _buildQuickStats() {
    final summary = _dashboardData['summary'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            '${summary['total_maintenance'] ?? 0}',
            Icons.list_alt,
            Colors.white.withOpacity(0.9),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '${summary['completed_maintenance'] ?? 0}',
            Icons.check_circle,
            Constants.ctaColorLight!,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Overdue',
            '${summary['overdue_maintenance'] ?? 0}',
            Icons.warning,
            Colors.orange[300]!,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rate',
            '${summary['completion_rate']?.toStringAsFixed(1) ?? 0}%',
            Icons.trending_up,
            Colors.blue[300]!,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Constants.ctaColorLight.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Constants.ctaColorLight,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          _buildTabItem(Icons.dashboard_rounded, 'Overview'),
          _buildTabItem(Icons.format_list_bulleted_rounded, 'Records'),
          _buildTabItem(Icons.schedule_rounded, 'Scheduling'),
          _buildTabItem(Icons.notifications_rounded, 'Reminders'),
          _buildTabItem(Icons.analytics_rounded, 'Analytics'),
          _buildTabItem(Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String text) {
    return Tab(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions at the top
          _buildCompactQuickActions(),

          SizedBox(height: 24),

          // Upcoming Maintenance
          _buildSectionHeader('Upcoming Maintenance', Icons.schedule),
          SizedBox(height: 12),
          _buildUpcomingMaintenanceList(),

          SizedBox(height: 24),

          // Recent Activity
          _buildSectionHeader('Recent Activity', Icons.history),
          SizedBox(height: 12),
          _buildRecentActivityList(),
        ],
      ),
    );
  }

  Widget _buildUpcomingMaintenanceList() {
    if (_upcomingMaintenance.isEmpty) {
      return _buildEmptyState('No upcoming maintenance scheduled');
    }

    return Column(
      children: _upcomingMaintenance.take(5).map((maintenance) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: _buildUpCommingMaintenanceCard(maintenance, isCompact: true),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivityList() {
    final recentRecords = _maintenanceRecords.take(5).toList();

    if (recentRecords.isEmpty) {
      return _buildEmptyState('No recent maintenance activity');
    }

    return Column(
      children: recentRecords.map((record) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: _buildMaintenanceCard(record, isCompact: true),
        );
      }).toList(),
    );
  }

  Widget _buildCompactQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Constants.ctaColorLight.withOpacity(0.05),
                Constants.ctaColorLight.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Constants.ctaColorLight.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Constants.ctaColorLight,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              if (isMobile) ...[
                // Mobile layout: 3 buttons in top row, Schedule button at bottom
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactActionButton(
                        'Reports',
                        Icons.assessment_outlined,
                        Color(0xFF1976D2),
                        () => _showReportsDialog(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactActionButton(
                        'Overdue',
                        Icons.warning_amber_outlined,
                        Color(0xFFEF6C00),
                        () => _showOverdueItems(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactActionButton(
                        'Types',
                        Icons.category_outlined,
                        Color(0xFF7B1FA2),
                        () => _showMaintenanceTypes(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Schedule button at bottom, full width on mobile
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Constants.ctaColorLight,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _showCreateMaintenanceDialog(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Schedule Maintenance',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Desktop layout: all 4 buttons in a row
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactActionButton(
                        'Schedule',
                        Icons.add_circle_outline,
                        Constants.ctaColorLight,
                        () => _showCreateMaintenanceDialog(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactActionButton(
                        'Reports',
                        Icons.assessment_outlined,
                        Color(0xFF1976D2),
                        () => _showReportsDialog(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactActionButton(
                        'Overdue',
                        Icons.warning_amber_outlined,
                        Color(0xFFEF6C00),
                        () => _showOverdueItems(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactActionButton(
                        'Types',
                        Icons.category_outlined,
                        Color(0xFF7B1FA2),
                        () => _showMaintenanceTypes(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildQuickActionCard(
          'Schedule Maintenance',
          Icons.add_circle,
          Constants.ctaColorLight,
          () => _showCreateMaintenanceDialog(),
        ),
        _buildQuickActionCard(
          'Generate Reports',
          Icons.assessment,
          Color(0xFF1976D2),
          () => _showReportsDialog(),
        ),
        _buildQuickActionCard(
          'Overdue Items',
          Icons.warning,
          Color(0xFFEF6C00),
          () => _showOverdueItems(),
        ),
        _buildQuickActionCard(
          'Maintenance Types',
          Icons.category,
          Color(0xFF7B1FA2),
          () => _showMaintenanceTypes(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceListTab() {
    return Column(
      children: [
        // Filters
        _buildFiltersSection(),

        // List
        Expanded(
          child: _maintenanceRecords.isEmpty
              ? _buildEmptyState('No maintenance records found')
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _maintenanceRecords.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: _buildMaintenanceCard(_maintenanceRecords[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Constants.ctaColorLight),
              SizedBox(width: 8),
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              if (_filters.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters.clear();
                    });
                    _loadMaintenanceRecords();
                  },
                  child: Text('Clear All'),
                ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Status', 'status', [
                {'value': 'scheduled', 'label': 'Scheduled'},
                {'value': 'in_progress', 'label': 'In Progress'},
                {'value': 'completed', 'label': 'Completed'},
                {'value': 'overdue', 'label': 'Overdue'},
                {'value': 'cancelled', 'label': 'Cancelled'},
              ]),
              _buildFilterChip('Priority', 'priority', [
                {'value': 'low', 'label': 'Low'},
                {'value': 'normal', 'label': 'Normal'},
                {'value': 'high', 'label': 'High'},
                {'value': 'critical', 'label': 'Critical'},
                {'value': 'emergency', 'label': 'Emergency'},
              ]),
              _buildDateRangeFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String key, List<Map<String, String>> options) {
    return PopupMenuButton<String>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _filters.containsKey(key)
              ? Constants.ctaColorLight.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _filters.containsKey(key)
                ? Constants.ctaColorLight
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _filters.containsKey(key)
                    ? Constants.ctaColorLight
                    : Colors.grey[700],
              ),
            ),
            if (_filters.containsKey(key)) ...[
              SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: Constants.ctaColorLight,
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option['value'],
          child: Text(option['label']!),
        );
      }).toList(),
      onSelected: (value) {
        setState(() {
          _filters[key] = value;
        });
        _loadMaintenanceRecords();
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(Duration(days: 365)),
          lastDate: DateTime.now().add(Duration(days: 365)),
          initialDateRange: _dateRange,
        );

        if (picked != null) {
          setState(() {
            _dateRange = picked;
            _filters['date_from'] = picked.start.toIso8601String();
            _filters['date_to'] = picked.end.toIso8601String();
          });
          _loadMaintenanceRecords();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _dateRange != null
              ? Constants.ctaColorLight.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _dateRange != null
                ? Constants.ctaColorLight
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 14,
              color: _dateRange != null
                  ? Constants.ctaColorLight
                  : Colors.grey[600],
            ),
            SizedBox(width: 4),
            Text(
              _dateRange != null
                  ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                  : 'Date Range',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _dateRange != null
                    ? Constants.ctaColorLight
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> maintenance,
      {bool isCompact = false}) {
    return InkWell(
      onTap: () => _showMaintenanceDetails(maintenance),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(maintenance['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    maintenance['status_display'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(maintenance['status']),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(maintenance['priority'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    maintenance['priority_display'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getPriorityColor(maintenance['priority']),
                    ),
                  ),
                ),
                Spacer(),
                if (maintenance['is_overdue'] == true)
                  Icon(Icons.warning, color: Colors.orange, size: 20),
              ],
            ),
            SizedBox(height: 12),

            // Device and Type
            Text(
              '${maintenance['device']["name"] ?? 'Unknown Device'} - ${maintenance['maintenance_type']["name"] ?? 'Unknown Type'}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              maintenance['priority'] ?? 'normal',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 8),

            // Date and Assignee
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  _formatDateTime(maintenance['scheduled_date']),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (maintenance['assigned_to'] != null) ...[
                  SizedBox(width: 16),
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    maintenance['assigned_to']['username'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),

            if (!isCompact) ...[
              SizedBox(height: 8),

              // Work Description
              Text(
                maintenance['work_description'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Action Buttons
              // Action Buttons
              Row(
                children: [
                  if (maintenance['status'] == 'scheduled') ...[
                    _buildActionButton(
                      'Start',
                      Icons.play_arrow,
                      Constants.ctaColorLight,
                      () =>
                          _updateMaintenanceStatus(maintenance['id'], 'start'),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (maintenance['status'] == 'in_progress') ...[
                    _buildActionButton(
                      'Complete',
                      Icons.check,
                      Color(0xFF1976D2),
                      () => _updateMaintenanceStatus(
                          maintenance['id'], 'complete'),
                    ),
                    SizedBox(width: 8),
                  ],
                  _buildActionButton(
                    'Details',
                    Icons.info,
                    Colors.grey[600]!,
                    () => _showMaintenanceDetails(maintenance),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpCommingMaintenanceCard(Map<String, dynamic> maintenance,
      {bool isCompact = false}) {
    return InkWell(
      onTap: () => _showMaintenanceDetails(maintenance),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            //Text(maintenance.toString()),

            // Device and Type
            Text(
              '${maintenance['device_name'] ?? 'Unknown Device'} - ${maintenance['maintenance_type'] ?? 'Unknown Type'} | ${maintenance['priority'] ?? 'normal'}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            SizedBox(height: 8),

            // Date and Assignee
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  _formatDateTime(maintenance['scheduled_date']),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (maintenance['assigned_to'] != null) ...[
                  SizedBox(width: 16),
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    (maintenance['assigned_to'] ?? '').toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),

            if (!isCompact) ...[
              SizedBox(height: 8),

              // Work Description
              Text(
                maintenance['work_description'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Action Buttons
              // Action Buttons
              Row(
                children: [
                  if (maintenance['status'] == 'scheduled') ...[
                    _buildActionButton(
                      'Start',
                      Icons.play_arrow,
                      Constants.ctaColorLight,
                      () =>
                          _updateMaintenanceStatus(maintenance['id'], 'start'),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (maintenance['status'] == 'in_progress') ...[
                    _buildActionButton(
                      'Complete',
                      Icons.check,
                      Color(0xFF1976D2),
                      () => _updateMaintenanceStatus(
                          maintenance['id'], 'complete'),
                    ),
                    SizedBox(width: 8),
                  ],
                  _buildActionButton(
                    'Details',
                    Icons.info,
                    Colors.grey[600]!,
                    () => _showMaintenanceDetails(maintenance),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recurring Schedules', Icons.repeat),
          SizedBox(height: 12),
          // Add scheduling interface here
          _buildSchedulesList(),

          SizedBox(height: 24),

          _buildSectionHeader('Generate Maintenance', Icons.auto_awesome),
          SizedBox(height: 12),
          _buildGenerateMaintenanceSection(),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Constants.ctaColorLight),
              SizedBox(width: 8),
              Text(
                'Active Schedules (${_schedules.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => _loadSchedules(),
                icon: Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showCreateScheduleDialog(),
                icon: Icon(Icons.add, size: 16),
                label: Text('New Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_schedules.isEmpty)
            _buildEmptyState('No recurring schedules configured')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _schedules.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                final isActive = schedule['is_active'] ?? false;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.repeat,
                      color: isActive ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${schedule['device']?['name'] ?? 'Unknown Device'}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${schedule['maintenance_type']?['name'] ?? ''} - ${schedule['frequency_display'] ?? ''}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Next due: ${schedule['next_due'] ?? 'N/A'}',
                        style: GoogleFonts.inter(fontSize: 11, color: Constants.ctaColorLight),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'toggle') {
                            _toggleScheduleStatus(schedule['id'], !isActive);
                          } else if (value == 'delete') {
                            _deleteSchedule(schedule['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(isActive ? Icons.pause : Icons.play_arrow, size: 18),
                                SizedBox(width: 8),
                                Text(isActive ? 'Deactivate' : 'Activate'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _toggleScheduleStatus(String scheduleId, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/schedule/$scheduleId/update/'),
        headers: ApiConfig.headers,
        body: json.encode({'is_active': isActive}),
      );
      if (response.statusCode == 200) {
        _loadSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule ${isActive ? 'activated' : 'deactivated'}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating schedule'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Schedule'),
        content: Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/schedule/$scheduleId/delete/'),
        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        _loadSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting schedule'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildGenerateMaintenanceSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Constants.ctaColorLight),
              SizedBox(width: 8),
              Text(
                'Auto-Generate Maintenance',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Generate maintenance records from active schedules that are due.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _generateScheduledMaintenance(),
            icon: Icon(Icons.play_arrow, size: 16),
            label: Text('Generate Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.ctaColorLight,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cost Analysis
          _buildSectionHeader('Cost Analysis', Icons.monetization_on),
          SizedBox(height: 12),
          _buildCostAnalysisSection(),

          SizedBox(height: 24),

          // Performance Metrics
          _buildSectionHeader('Performance Metrics', Icons.trending_up),
          SizedBox(height: 12),
          _buildPerformanceMetrics(),

          SizedBox(height: 24),

          // Charts and Trends
          _buildSectionHeader('Trends & Breakdown', Icons.pie_chart),
          SizedBox(height: 12),
          _buildChartsSection(),
        ],
      ),
    );
  }

  Widget _buildCostAnalysisSection() {
    final costAnalysis = _dashboardData['cost_analysis'] ?? {};

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Cost',
                  '${costAnalysis['total_cost']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.attach_money,
                  Color(0xFF1976D2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Average Cost',
                  '${costAnalysis['avg_cost']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.bar_chart,
                  Color(0xFF388E3C),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Estimated',
                  '${costAnalysis['total_estimated']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.calculate,
                  Color(0xFF7B1FA2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Variance',
                  '${costAnalysis['cost_variance']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.trending_up,
                  costAnalysis['cost_variance'] != null &&
                          costAnalysis['cost_variance'] > 0
                      ? Color(0xFFD32F2F)
                      : Color(0xFF388E3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final durationAnalysis = _dashboardData['duration_analysis'] ?? {};
    final summary = _dashboardData['summary'] ?? {};

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Hours',
                  '${durationAnalysis['total_hours']?.toStringAsFixed(1) ?? '0.0'}h',
                  Icons.timer,
                  Color(0xFF1976D2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg Duration',
                  '${durationAnalysis['avg_hours']?.toStringAsFixed(1) ?? '0.0'}h',
                  Icons.schedule,
                  Color(0xFF388E3C),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Completion Rate',
                  '${summary['completion_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.check_circle,
                  Color(0xFF388E3C),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'On-Time Rate',
                  '${_calculateOnTimeRate()}%',
                  Icons.access_time,
                  Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    final breakdowns = _dashboardData['breakdowns'] ?? {};

    return Column(
      children: [
        // Status Breakdown
        _buildBreakdownCard('Status Breakdown', breakdowns['by_status']),
        SizedBox(height: 16),
        // Type Breakdown
        _buildBreakdownCard(
            'Maintenance Type Breakdown', breakdowns['by_type']),
        SizedBox(height: 16),
        // Device Breakdown
        _buildBreakdownCard('Top Devices', breakdowns['by_device']),
      ],
    );
  }

  Widget _buildBreakdownCard(String title, List<dynamic>? data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
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
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          if (data != null && data.isNotEmpty)
            ...data.take(5).map((item) => _buildBreakdownItem(item)).toList()
          else
            _buildEmptyState('No data available'),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(Map<String, dynamic> item) {
    final count = item['count'] ?? 0;
    final total = _dashboardData['summary']['total_maintenance'] ?? 1;
    final percentage = (count / total * 100).round();

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item['status'] ??
                  item['name'] ??
                  item['device__name'] ??
                  'Unknown',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$count ($percentage%)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    final summary = _remindersData['summary'] ?? {};
    final upcoming = _remindersData['upcoming'] ?? [];
    final overdue = _remindersData['overdue'] ?? [];
    final sentReminders = _remindersData['sent_reminders'] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reminder Stats
          _buildReminderStats(summary),
          SizedBox(height: 24),

          // Overdue Maintenance
          if (overdue.isNotEmpty) ...[
            _buildSectionHeader('Overdue Maintenance', Icons.warning_rounded),
            SizedBox(height: 12),
            _buildRemindersList(overdue, isOverdue: true),
            SizedBox(height: 24),
          ],

          // Upcoming Reminders
          _buildSectionHeader('Upcoming Maintenance', Icons.schedule),
          SizedBox(height: 12),
          _buildRemindersList(upcoming, isOverdue: false),
          SizedBox(height: 24),

          // Sent Reminders History
          _buildSectionHeader('Recent Reminders Sent', Icons.history),
          SizedBox(height: 12),
          _buildSentRemindersList(sentReminders),
        ],
      ),
    );
  }

  Widget _buildReminderStats(Map<String, dynamic> summary) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Constants.ctaColorLight, Constants.ctaColorLight.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Constants.ctaColorLight.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildReminderStatCard(
              'Upcoming',
              '${summary['upcoming_count'] ?? 0}',
              Icons.schedule,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildReminderStatCard(
              'Overdue',
              '${summary['overdue_count'] ?? 0}',
              Icons.warning_rounded,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildReminderStatCard(
              'Sent Today',
              '${(summary['reminders_sent_today'] ?? 0) + (summary['overdue_reminders_sent_today'] ?? 0)}',
              Icons.send,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersList(List<dynamic> reminders, {required bool isOverdue}) {
    if (reminders.isEmpty) {
      return _buildEmptyState(isOverdue ? 'No overdue maintenance' : 'No upcoming maintenance');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: reminders.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return _buildReminderCard(reminder, isOverdue: isOverdue);
        },
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, {required bool isOverdue}) {
    final priorityColor = _getPriorityColor(reminder['priority'] ?? 'normal');
    final reminderSent = reminder['reminder_sent'] ?? false;
    final overdueReminderSent = reminder['overdue_reminder_sent'] ?? false;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isOverdue ? Icons.warning_rounded : Icons.schedule,
          color: isOverdue ? Colors.red : Colors.blue,
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              reminder['device_name'] ?? 'Unknown Device',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reminder['priority_display'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            reminder['maintenance_type'] ?? '',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: isOverdue ? Colors.red : Colors.grey),
              SizedBox(width: 4),
              Text(
                reminder['time_display'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              SizedBox(width: 12),
              if (reminderSent || overdueReminderSent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 10, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Reminder Sent',
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (reminder['assigned_to'] != null) ...[
            SizedBox(height: 2),
            Text(
              'Assigned: ${reminder['assigned_to']}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        onPressed: () => _sendManualReminder(
          reminder['id'],
          isOverdue ? 'overdue' : 'upcoming',
        ),
        icon: Icon(Icons.send, color: Constants.ctaColorLight, size: 20),
        tooltip: 'Send Reminder',
      ),
    );
  }

  Widget _buildSentRemindersList(List<dynamic> sentReminders) {
    if (sentReminders.isEmpty) {
      return _buildEmptyState('No reminders sent recently');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: sentReminders.length > 10 ? 10 : sentReminders.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final reminder = sentReminders[index];
          return ListTile(
            dense: true,
            leading: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.check, color: Colors.green, size: 16),
            ),
            title: Text(
              reminder['device_name'] ?? 'Unknown Device',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${reminder['maintenance_type'] ?? ''} - Sent: ${_formatReminderDate(reminder['reminder_sent_at'])}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
            ),
          );
        },
      ),
    );
  }

  String _formatReminderDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Maintenance Types', Icons.category),
          SizedBox(height: 12),
          _buildMaintenanceTypesSection(),
          SizedBox(height: 24),
          _buildSectionHeader('System Settings', Icons.settings),
          SizedBox(height: 12),
          _buildSystemSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTypesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.category, color: Constants.ctaColorLight),
                SizedBox(width: 8),
                Text(
                  'Available Maintenance Types',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: _loadMaintenanceTypes,
                  icon: Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          if (_maintenanceTypes.isNotEmpty)
            ..._maintenanceTypes
                .map((type) => _buildMaintenanceTypeItem(type))
                .toList()
          else
            Padding(
              padding: EdgeInsets.all(16),
              child: _buildEmptyState('No maintenance types available'),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTypeItem(Map<String, dynamic> type) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor(type['category']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type['category_display'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getCategoryColor(type['category']),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (type['description'] != null &&
                    type['description'].isNotEmpty)
                  Text(
                    type['description'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (type['estimated_duration_hours'] != null)
            Text(
              '${type['estimated_duration_hours']}h',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'Auto-generate maintenance',
            'Automatically create maintenance records from schedules',
            true,
            (value) {
              // Handle setting change
            },
          ),
          Divider(),
          _buildSettingItem(
            'Overdue notifications',
            'Send notifications for overdue maintenance',
            true,
            (value) {
              // Handle setting change
            },
          ),
          Divider(),
          _buildSettingItem(
            'Cost tracking',
            'Track estimated vs actual costs',
            true,
            (value) {
              // Handle setting change
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
      String title, String description, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Constants.ctaColorLight,
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Constants.ctaColorLight, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Constants.ctaColorLight),
          SizedBox(height: 16),
          Text(
            'Loading maintenance data...',
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            _error,
            style: GoogleFonts.inter(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Color(0xFF388E3C);
      case 'in_progress':
        return Color(0xFF1976D2);
      case 'scheduled':
        return Color(0xFF7B1FA2);
      case 'overdue':
        return Color(0xFFD32F2F);
      case 'cancelled':
        return Color(0xFF616161);
      default:
        return Color(0xFF616161);
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'emergency':
        return Color(0xFFD32F2F);
      case 'critical':
        return Color(0xFFFF5722);
      case 'high':
        return Color(0xFFFF9800);
      case 'normal':
        return Color(0xFF1976D2);
      case 'low':
        return Color(0xFF4CAF50);
      default:
        return Color(0xFF616161);
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'preventive':
        return Color(0xFF4CAF50);
      case 'corrective':
        return Color(0xFFFF9800);
      case 'emergency':
        return Color(0xFFD32F2F);
      case 'inspection':
        return Color(0xFF2196F3);
      case 'calibration':
        return Color(0xFF9C27B0);
      case 'cleaning':
        return Color(0xFF00BCD4);
      case 'replacement':
        return Color(0xFFFF5722);
      default:
        return Color(0xFF616161);
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('MMM d, yyyy HH:mm').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  String _calculateOnTimeRate() {
    // Calculate on-time completion rate
    final completedOnTime = _maintenanceRecords.where((record) {
      return record['status'] == 'completed' &&
          record['actual_end_date'] != null &&
          record['scheduled_date'] != null;
    }).length;

    final totalCompleted = _maintenanceRecords
        .where((record) => record['status'] == 'completed')
        .length;

    if (totalCompleted == 0) return '0.0';
    return ((completedOnTime / totalCompleted) * 100).toStringAsFixed(1);
  }

  // Action Methods
  Future<void> _updateMaintenanceStatus(String id, String action) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/$id/status/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'action': action,
          'user_id': await SharedPrefs.getUserId(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance status updated successfully'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadMaintenanceRecords();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateScheduledMaintenance() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/schedule/generate/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'business_id': await SharedPrefs.getBusinessId(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Generated ${data['generated_count']} maintenance records'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadMaintenanceRecords();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate maintenance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMaintenanceDetails(Map<String, dynamic> maintenance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceDetailScreen(
          maintenanceId: maintenance['id'],
        ),
      ),
    );
  }

  void _showCreateMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateMaintenanceDialog(),
    );
  }

  void _showCreateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateScheduleDialog(),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => MaintenanceReportsDialog(),
    );
  }

  void _showOverdueItems() {
    setState(() {
      _filters['status'] = 'overdue';
    });
    _tabController.animateTo(1); // Go to Records tab
    _loadMaintenanceRecords();
  }

  void _showMaintenanceTypes() {
    _tabController.animateTo(4); // Go to Settings tab
  }

  CreateScheduleDialog() {}
}

// Supporting Classes
class ApiConfig {
  static String baseUrl = Constants.articBaseUrl2;
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };
}

class SharedPrefs {
  static Future<String> getBusinessId() async {
    // Return business ID from shared preferences
    return Constants.myBusiness.businessUid.toString();
  }

  static Future<int> getUserId() async {
    // Return user ID from shared preferences
    return 1; // Placeholder - should be replaced with actual SharedPreferences logic
  }
}

// Maintenance Detail Screen
class MaintenanceDetailScreen extends StatefulWidget {
  final String maintenanceId;

  const MaintenanceDetailScreen({Key? key, required this.maintenanceId})
      : super(key: key);

  @override
  _MaintenanceDetailScreenState createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _maintenance = {};
  List<dynamic> _checklistItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMaintenanceDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceDetail() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('=== FETCHING OBSERVATIONS ===');
        print(
            'URL: ${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/');
        print('Response Status: ${response.statusCode}');
        print('Full Response Data: ${json.encode(data)}');
        print('Maintenance Data: ${json.encode(data['maintenance'])}');
        print('Observations Raw Data: ${data['maintenance']['observations']}');
        print(
            'Observations Type: ${data['maintenance']['observations'].runtimeType}');
        if (data['maintenance']['observations'] is List) {
          print(
              'Observations List Length: ${data['maintenance']['observations'].length}');
          for (int i = 0; i < data['maintenance']['observations'].length; i++) {
            print('Observation $i: ${data['maintenance']['observations'][i]}');
          }
        }
        print('=============================');

        setState(() {
          _maintenance = data['maintenance'];
          _checklistItems = data['maintenance']['checklist_items'] ?? [];
        });
      } else {
        throw Exception('Failed to load maintenance details');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load maintenance details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Maintenance Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Constants.ctaColorLight,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Constants.ctaColorLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          if (!_isLoading && _maintenance.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              icon: Icon(
                Icons.more_vert,
                color: Constants.ctaColorLight,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                PopupMenuItem(value: 'export', child: Text('Export')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Constants.ctaColorLight,
                labelColor: Constants.ctaColorLight,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Checklist'),
                  Tab(text: 'Findings'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'Documentation'),
                ],
              ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Constants.ctaColorLight))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(_error),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMaintenanceDetail,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildChecklistTab(),
                    _buildObservationsTab(),
                    _buildTimelineTab(),
                    _buildDocumentationTab(),
                  ],
                ),
      floatingActionButton:
          !_isLoading && _maintenance.isNotEmpty ? _buildActionButton() : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(),
          SizedBox(height: 16),

          // Basic Information
          _buildInfoSection('Basic Information', [
            _buildInfoRow('Device', _maintenance['device']['name']),
            _buildInfoRow('Type', _maintenance['maintenance_type']['name']),
            _buildInfoRow('Category',
                _maintenance['maintenance_type']['category_display']),
            _buildInfoRow('Priority', _maintenance['priority_display']),
            _buildInfoRow(
                'Scheduled', _formatDateTime(_maintenance['scheduled_date'])),
          ]),

          SizedBox(height: 16),

          // Personnel Information
          _buildInfoSection('Personnel', [
            _buildInfoRow('Assigned To',
                _maintenance['assigned_to']?['username'] ?? 'Unassigned'),
            _buildInfoRow('Performed By',
                _maintenance['performed_by']?['username'] ?? 'Not started'),
            _buildInfoRow('Supervised By',
                _maintenance['supervised_by']?['username'] ?? 'None'),
          ]),

          SizedBox(height: 16),

          // Work Details
          _buildInfoSection('Work Details', [
            _buildInfoText('Description', _maintenance['work_description']),
            if (_maintenance['work_performed']?.isNotEmpty == true)
              _buildInfoText('Work Performed', _maintenance['work_performed']),
            if (_maintenance['issues_found']?.isNotEmpty == true)
              _buildInfoText('Issues Found', _maintenance['issues_found']),
            if (_maintenance['resolution_notes']?.isNotEmpty == true)
              _buildInfoText('Resolution', _maintenance['resolution_notes']),
          ]),

          SizedBox(height: 16),

          // Cost & Duration
          _buildCostDurationSection(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(_maintenance['status']),
                  color: Colors.black,
                  size: 32,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _maintenance['status_display'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Maintenance Status',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_maintenance['is_overdue'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (_maintenance['actual_start_date'] != null ||
                _maintenance['actual_end_date'] != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  if (_maintenance['actual_start_date'] != null) ...[
                    Icon(Icons.play_arrow,
                        color: Colors.white.withOpacity(0.9), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Started: ${_formatDateTime(_maintenance['actual_start_date'])}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                  if (_maintenance['actual_end_date'] != null) ...[
                    if (_maintenance['actual_start_date'] != null)
                      SizedBox(width: 16),
                    Icon(Icons.check,
                        color: Colors.white.withOpacity(0.9), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Completed: ${_formatDateTime(_maintenance['actual_end_date'])}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Constants.ctaColorLight.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Constants.ctaColorLight,
                ),
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Constants.ctaColorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Constants.ctaColorLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostDurationSection() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Constants.ctaColorLight.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Cost & Duration Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Constants.ctaColorLight,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Estimated Cost',
                      '${_maintenance['estimated_cost']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.attach_money,
                      Color(0xFF1976D2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Actual Cost',
                      '${_maintenance['actual_cost']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.receipt,
                      Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Est. Duration',
                      '${_maintenance['estimated_duration_hours']?.toStringAsFixed(1) ?? '0.0'}h',
                      Icons.schedule,
                      Color(0xFF7B1FA2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Actual Duration',
                      '${_maintenance['actual_duration_hours']?.toStringAsFixed(1) ?? '0.0'}h',
                      Icons.timer,
                      Color(0xFFEF6C00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistTab() {
    final canModifyChecklist = _maintenance['status'] == 'in_progress';

    return Column(
      children: [
        // Progress Header
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.checklist, color: Constants.ctaColorLight),
                  SizedBox(width: 8),
                  Text(
                    'Maintenance Checklist',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  if (canModifyChecklist)
                    IconButton(
                      onPressed: _showAddChecklistItemDialog,
                      icon: Icon(Icons.add_circle,
                          color: Constants.ctaColorLight),
                      tooltip: 'Add Checklist Item',
                    ),
                  Text(
                    '${_getCompletedCount()}/${_checklistItems.length}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Constants.ctaColorLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: _getCompletionPercentage(),
                backgroundColor: Colors.grey[200],
                valueColor:
                    AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
              ),
            ],
          ),
        ),

        // Add New Item Input (when in progress)
        if (canModifyChecklist)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: _buildQuickAddChecklistItem(),
          ),

        // Checklist Items
        Expanded(
          child: _checklistItems.isEmpty
              ? _buildEmptyChecklistState(canModifyChecklist)
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _checklistItems.length,
                  itemBuilder: (context, index) {
                    return _buildChecklistItem(
                        _checklistItems[index], canModifyChecklist);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(
      Map<String, dynamic> item, bool canModifyChecklist) {
    final isCompleted = item['is_completed'] ?? false;
    final isCritical = item['is_critical'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isCritical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: canModifyChecklist
                    ? () => _toggleChecklistItem(item)
                    : null,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Constants.ctaColorLight
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? Constants.ctaColorLight
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.grey[600] : Colors.grey[800],
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isCritical)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CRITICAL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              if (canModifyChecklist)
                IconButton(
                  onPressed: () => _showChecklistItemOptions(item),
                  icon:
                      Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                  tooltip: 'Item Options',
                ),
            ],
          ),
          if (item['notes']?.isNotEmpty == true) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['notes'],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          if (isCompleted && item['completed_by'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  '${item['completed_by']} • ${_formatDateTime(item['completed_at'])}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChecklistState(bool canModifyChecklist) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No checklist items yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          if (canModifyChecklist) ...[
            SizedBox(height: 8),
            Text(
              'Add items to create a maintenance checklist',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddChecklistItemDialog,
              icon: Icon(Icons.add, size: 18),
              label: Text('Add First Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddChecklistItem() {
    return Row(
      children: [
        Icon(Icons.add_task, color: Constants.ctaColorLight, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: TextEditingController(),
            decoration: InputDecoration(
              hintText: 'Type to quickly add a checklist item...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Constants.ctaColorLight),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: IconButton(
                onPressed: () => _showAddChecklistItemDialog(),
                icon: Icon(Icons.add_circle, color: Constants.ctaColorLight),
                tooltip: 'Add Item',
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addChecklistItemQuick(value.trim());
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildObservationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildObservationsSection(
              true), // Always allow editing in this dedicated tab
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance Timeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          _buildTimelineItem(
            'Scheduled',
            _formatDateTime(_maintenance['scheduled_date']),
            Icons.schedule,
            Color(0xFF1976D2),
            isCompleted: true,
          ),
          if (_maintenance['actual_start_date'] != null)
            _buildTimelineItem(
              'Started',
              _formatDateTime(_maintenance['actual_start_date']),
              Icons.play_arrow,
              Color(0xFF388E3C),
              isCompleted: true,
            ),
          if (_maintenance['actual_end_date'] != null)
            _buildTimelineItem(
              'Completed',
              _formatDateTime(_maintenance['actual_end_date']),
              Icons.check_circle,
              Constants.ctaColorLight,
              isCompleted: true,
            ),
          if (_maintenance['next_maintenance_date'] != null)
            _buildTimelineItem(
              'Next Maintenance',
              _formatDate(_maintenance['next_maintenance_date']),
              Icons.event,
              Color(0xFF7B1FA2),
              isCompleted: false,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String? date, IconData icon, Color color,
      {required bool isCompleted}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : color,
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
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.grey[800] : Colors.grey[600],
                  ),
                ),
                if (date != null)
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationTab() {
    // Allow uploads for in_progress, scheduled, and completed maintenance
    final status = _maintenance['status'] ?? '';
    final bool canEdit = status == 'in_progress' || status == 'scheduled' || status == 'completed' || status == 'pending';

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parts Management
          _buildInteractivePartsSection(canEdit),
          SizedBox(height: 16),

          // Materials Management
          _buildInteractiveMaterialsSection(canEdit),
          SizedBox(height: 16),

          // External Services
          if (_maintenance['external_contractor']?.isNotEmpty == true) ...[
            _buildModernExternalContractorSection(),
            SizedBox(height: 16),
          ],

          // Safety & Compliance
          if (_maintenance['safety_precautions']?.isNotEmpty == true ||
              _maintenance['compliance_notes']?.isNotEmpty == true) ...[
            _buildModernSafetySection(),
            SizedBox(height: 16),
          ],

          // Files and Media Management
          _buildInteractiveFilesSection(canEdit),
        ],
      ),
    );
  }

  // Interactive Parts Section
  Widget _buildInteractivePartsSection(bool canEdit) {
    final rawParts = _maintenance['parts_used'] ?? [];
    final parts = <String>[...rawParts.map((part) => part.toString())];
    final controller = TextEditingController();

    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.build,
                  color: Constants.ctaColorLight,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parts Used',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    Text(
                      '${parts.length} part${parts.length != 1 ? 's' : ''} recorded',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                ElevatedButton.icon(
                  onPressed: () => _uploadSectionImage('parts'),
                  icon: Icon(Icons.add_photo_alternate, size: 16),
                  label: Text('Add Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: parts.isEmpty ? null : _savePartsAndMaterials,
                  icon: Icon(Icons.save, size: 16),
                  label: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ],
          ),
          // Parts Images Gallery
          _buildSectionImageGallery('parts', _maintenance['parts_images'] ?? [], canEdit),
          SizedBox(height: 20),
          if (parts.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.build_circle,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    canEdit ? 'No parts recorded yet' : 'No parts recorded',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (canEdit) ...[
                    SizedBox(height: 4),
                    Text(
                      'Use the field below to add parts',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parts.map((p) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Constants.ctaColorLight.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 16,
                                  color: Constants.ctaColorLight,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  p,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canEdit)
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    final updated = <String>[...parts];
                                    updated.remove(p);
                                    _maintenance['parts_used'] = updated;
                                  });
                                },
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (canEdit) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Constants.ctaColorLight.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: Constants.ctaColorLight,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add New Part',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText:
                                'Enter part name or code (e.g., Air Filter #AF-100)',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Constants.ctaColorLight, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            prefixIcon: Icon(
                              Icons.settings,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;
                            setState(() {
                              final updated = <String>[...parts];
                              updated.add(value.trim());
                              _maintenance['parts_used'] = updated;
                            });
                            controller.clear();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (controller.text.trim().isEmpty) return;
                          setState(() {
                            final updated = <String>[...parts];
                            updated.add(controller.text.trim());
                            _maintenance['parts_used'] = updated;
                          });
                          controller.clear();
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add Part'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // Interactive Materials Section
  Widget _buildInteractiveMaterialsSection(bool canEdit) {
    final rawMaterials = _maintenance['materials_used'] ?? [];
    final materials = <String>[
      ...rawMaterials.map((material) => material.toString())
    ];
    final controller = TextEditingController();

    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory,
                  color: Constants.ctaColorLight,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materials Used',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    Text(
                      '${materials.length} material${materials.length != 1 ? 's' : ''} recorded',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                ElevatedButton.icon(
                  onPressed: () => _uploadSectionImage('materials'),
                  icon: Icon(Icons.add_photo_alternate, size: 16),
                  label: Text('Add Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: materials.isEmpty ? null : _savePartsAndMaterials,
                  icon: Icon(Icons.save, size: 16),
                  label: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ],
          ),
          // Materials Images Gallery
          _buildSectionImageGallery('materials', _maintenance['materials_images'] ?? [], canEdit),
          SizedBox(height: 20),
          if (materials.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    canEdit
                        ? 'No materials recorded yet'
                        : 'No materials recorded',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (canEdit) ...[
                    SizedBox(height: 4),
                    Text(
                      'Use the field below to add materials',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: materials.map((m) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Constants.ctaColorLight.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.science,
                                  size: 16,
                                  color: Constants.ctaColorLight,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  m,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canEdit)
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    final updated = <String>[...materials];
                                    updated.remove(m);
                                    _maintenance['materials_used'] = updated;
                                  });
                                },
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (canEdit) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Constants.ctaColorLight.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: Constants.ctaColorLight,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add New Material',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText:
                                'Enter material name or type (e.g., Lubricant Oil 1L)',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Constants.ctaColorLight, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            prefixIcon: Icon(
                              Icons.science,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;
                            setState(() {
                              final updated = <String>[...materials];
                              updated.add(value.trim());
                              _maintenance['materials_used'] = updated;
                            });
                            controller.clear();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (controller.text.trim().isEmpty) return;
                          setState(() {
                            final updated = <String>[...materials];
                            updated.add(controller.text.trim());
                            _maintenance['materials_used'] = updated;
                          });
                          controller.clear();
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add Material'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // Files/Media Section - Enhanced with categories
  Widget _buildInteractiveFilesSection(bool canEdit) {
    final beforePhotos = _maintenance['before_photos'] as List<dynamic>? ?? [];
    final afterPhotos = _maintenance['after_photos'] as List<dynamic>? ?? [];
    final documents = _maintenance['documents'] as List<dynamic>? ?? [];
    final partsImages = _maintenance['parts_images'] as List<dynamic>? ?? [];
    final materialsImages = _maintenance['materials_images'] as List<dynamic>? ?? [];

    final totalFiles = beforePhotos.length + afterPhotos.length + documents.length + partsImages.length + materialsImages.length;

    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header with stats and upload buttons
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_open,
                  color: Constants.ctaColorLight,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files & Media',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    Text(
                      '$totalFiles file${totalFiles != 1 ? 's' : ''} uploaded',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                ElevatedButton.icon(
                  onPressed: () => _showUploadMediaDialog(),
                  icon: Icon(Icons.add_photo_alternate, size: 16),
                  label: Text('Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showUploadDocumentDialog(),
                  icon: Icon(Icons.upload_file, size: 16),
                  label: Text('Documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 20),

          if (totalFiles == 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'No files uploaded yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (canEdit) ...[
                    SizedBox(height: 4),
                    Text(
                      'Use the buttons above to add photos and documents',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            // Before Photos Section
            if (beforePhotos.isNotEmpty)
              _buildMediaCategory(
                'Before Photos',
                Icons.photo_camera,
                Colors.blue,
                beforePhotos,
                canEdit,
              ),

            // After Photos Section
            if (afterPhotos.isNotEmpty)
              _buildMediaCategory(
                'After Photos',
                Icons.photo_camera,
                Colors.green,
                afterPhotos,
                canEdit,
              ),

            // Parts Images Section
            if (partsImages.isNotEmpty)
              _buildMediaCategory(
                'Parts Images',
                Icons.build,
                Colors.orange,
                partsImages,
                canEdit,
                section: 'parts',
              ),

            // Materials Images Section
            if (materialsImages.isNotEmpty)
              _buildMediaCategory(
                'Materials Images',
                Icons.inventory,
                Colors.purple,
                materialsImages,
                canEdit,
                section: 'materials',
              ),

            // Documents Section
            if (documents.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Documents (${documents.length})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...documents.map((doc) {
                      final docData = doc is Map ? doc : {'filename': doc.toString()};
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.teal, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    docData['filename'] ?? docData.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (docData['description'] != null && docData['description'].toString().isNotEmpty)
                                    Text(
                                      docData['description'],
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (docData['url'] != null)
                              IconButton(
                                onPressed: () {
                                  final url = docData['url'].startsWith('http')
                                      ? docData['url']
                                      : '${Constants.articBaseUrl2}${docData['url']}';
                                  // Open document
                                },
                                icon: Icon(Icons.open_in_new, size: 20),
                                color: Colors.grey[600],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }

  // Build a media category with expandable gallery
  Widget _buildMediaCategory(String title, IconData icon, Color color, List<dynamic> images, bool canEdit, {String? section}) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 8),
              Text(
                '$title (${images.length})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                final imageUrl = img is Map ? (img['url'] ?? '') : img.toString();
                final filename = img is Map ? (img['filename'] ?? 'Image') : 'Image';
                final imageId = img is Map ? (img['id'] ?? '') : '';

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showImagePreview(imageUrl, filename),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl.startsWith('http')
                                  ? imageUrl
                                  : '${Constants.articBaseUrl2}$imageUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: color,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (canEdit && section != null && imageId.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _deleteSectionImage(section, imageId),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Modern External Contractor Section
  Widget _buildModernExternalContractorSection() {
    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Constants.ctaColorLight,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'External Contractor',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Constants.ctaColorLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Company:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _maintenance['external_contractor'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Contact:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _maintenance['contractor_contact'] ?? 'Not provided',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Safety & Compliance Section
  Widget _buildModernSafetySection() {
    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.security,
                    color: Constants.ctaColorLight,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Safety & Compliance',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Constants.ctaColorLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_maintenance['safety_precautions']?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange[600],
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Safety Precautions',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _maintenance['safety_precautions'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
            if (_maintenance['compliance_notes']?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Compliance Notes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _maintenance['compliance_notes'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
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

  // Modern Observations List Section
  Widget _buildObservationsSection(bool canEdit) {
    // Access observations from _maintenance data with proper type handling
    final observationsData = _maintenance['observations'];
    List<Map<String, dynamic>> observationsList = [];

    print('=== BUILDING FINDINGS UI ===');
    print('Raw observations data: $observationsData');
    print('Data type: ${observationsData.runtimeType}');

    if (observationsData is List) {
      print('Processing as List with ${observationsData.length} items');
      observationsList = observationsData.cast<Map<String, dynamic>>();
      print('Processed observations list: $observationsList');
    } else if (observationsData is Map) {
      print('Processing as single Map');
      observationsList = [observationsData.cast<String, dynamic>()];
      print('Converted to list: $observationsList');
    } else if (observationsData is String && observationsData.isNotEmpty) {
      print('Processing as legacy String: "$observationsData"');
      // Convert legacy string format to structured data
      observationsList = [
        {
          'text': observationsData,
          'created_by': 'Legacy Entry',
          'created_at': DateTime.now().toIso8601String(),
          'is_critical': false,
          'category': 'general',
        }
      ];
      print('Converted legacy string to: $observationsList');
    } else {
      print('No observations data or unsupported format');
    }

    print('Final findings list count: ${observationsList.length}');
    print('================================');

    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header with Add Button
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: Constants.ctaColorLight,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance Findings',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                      Text(
                        '${observationsList.length} finding${observationsList.length != 1 ? 's' : ''} recorded',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  ElevatedButton.icon(
                    onPressed: () => _showAddObservationDialog(),
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Add Finding'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
              ],
            ),

            SizedBox(height: 20),

            // Observations List
            if (observationsList.isEmpty)
              Container(
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No findings recorded',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add findings to track maintenance discoveries and recommendations',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Finding',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Recorded By',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Date Added',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: observationsList.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final observation = observationsList[index];
                        final dateAdded = observation['created_at'] != null
                            ? DateTime.tryParse(observation['created_at']) ??
                                DateTime.now()
                            : DateTime.now();

                        final observationImages = observation['images'] as List<dynamic>? ?? [];
                        final observationId = observation['id']?.toString() ?? '';

                        return Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          observation['text'] ??
                                              'No observation text',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            height: 1.4,
                                          ),
                                        ),
                                        if (observation['is_critical'] == true) ...[
                                          SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'CRITICAL',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Constants.ctaColorLight
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        observation['created_by'] ?? 'Unknown',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Constants.ctaColorLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(dateAdded.toIso8601String()),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        if (canEdit && observationId.isNotEmpty)
                                          IconButton(
                                            onPressed: () => _uploadObservationImage(observationId),
                                            icon: Icon(Icons.add_photo_alternate, size: 20),
                                            color: Colors.green[600],
                                            tooltip: 'Add Photo',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Show observation images if any
                              if (observationImages.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Container(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: observationImages.length,
                                    itemBuilder: (context, imgIndex) {
                                      final img = observationImages[imgIndex];
                                      final imageUrl = img['url'] ?? '';
                                      return Container(
                                        margin: EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showImagePreview(imageUrl, img['filename'] ?? 'Image'),
                                              child: Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey[300]!),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      imageUrl.startsWith('http')
                                                        ? imageUrl
                                                        : '${Constants.articBaseUrl2}$imageUrl'
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Save observations to backend
  Future<void> _saveObservations(String observations) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/update/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'observations': observations,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Observations saved successfully'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        // Reload maintenance data to get the latest state
        _loadMaintenanceDetail();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save observations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Simple Add Observation Dialog
  void _showAddObservationDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Add Finding',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Constants.ctaColorLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter your finding...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Constants.ctaColorLight),
                ),
              ),
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _addObservation(controller.text.trim());
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error adding finding: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.ctaColorLight,
              foregroundColor: Colors.white,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add new observation to maintenance record
  Future<void> _addObservation(String observationText) async {
    try {
      final requestBody = {
        'text': observationText,
        'maintenance_id': widget.maintenanceId,
        'user_id': await SharedPrefs.getUserId(),
        'business_id': await SharedPrefs.getBusinessId(),
        'category': 'general',
        'is_critical': false,
      };

      print('=== ADDING FINDING ===');
      print(
          'URL: ${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/observations/');
      print('Headers: ${ApiConfig.headers}');
      print('Request Body: ${json.encode(requestBody)}');
      print('==========================');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/observations/'),
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      );

      print('=== FINDING RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('============================');

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Finding added successfully'),
            backgroundColor: Constants.ctaColorLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload maintenance data to refresh observations
        _loadMaintenanceDetail();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add finding: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      rethrow;
    }
  }

  // Upload Media Dialog and Functionality
  void _showUploadMediaDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.upload,
                        color: Constants.ctaColorLight,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload Media',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Select images or videos to upload for this maintenance task.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUploadMedia('image'),
                        icon: Icon(Icons.image, size: 20),
                        label: Text('Select Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUploadMedia('video'),
                        icon: Icon(Icons.videocam, size: 20),
                        label: Text('Select Videos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  // Upload Document Dialog and Functionality
  void _showUploadDocumentDialog() {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Constants.ctaColorLight,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload Document',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Upload a document with description for this maintenance task.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter document description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Constants.ctaColorLight),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _pickAndUploadDocument(descriptionController.text),
                    icon: Icon(Icons.upload_file, size: 20),
                    label: Text('Select & Upload Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Pick and Upload Media Files
  Future<void> _pickAndUploadMedia(String type) async {
    try {
      FilePickerResult? result;

      if (type == 'image') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
      } else if (type == 'video') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: true,
        );
      }

      if (result != null) {
        Navigator.of(context).pop(); // Close dialog

        for (PlatformFile file in result.files) {
          await _uploadMediaFile(file, type);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${result.files.length} file(s) uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh maintenance data to show new files
        _loadMaintenanceDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload media: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Pick and Upload Document File
  Future<void> _pickAndUploadDocument(String description) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: null, // Allow all file types
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        Navigator.of(context).pop(); // Close dialog

        await _uploadDocumentFile(result.files.single, description);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh maintenance data to show new document
        _loadMaintenanceDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload document: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Upload Media File to Backend
  Future<void> _uploadMediaFile(PlatformFile file, String type) async {
    final url = Uri.parse(
        '${Constants.articBaseUrl2}api/maintenance/${widget.maintenanceId}/upload-media/');
    final request = http.MultipartRequest('POST', url);

    // Add authorization header
    final token = await Sharedprefs.getAuthTokenPreference();
    request.headers['Authorization'] = 'Bearer $token';

    // Add file
    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ));
    }

    // Add metadata
    request.fields['type'] = type;
    request.fields['maintenance_id'] = widget.maintenanceId.toString();
    request.fields['business_id'] =
        (await SharedPrefs.getBusinessId()).toString();
    request.fields['user_id'] = (await SharedPrefs.getUserId()).toString();

    print('=== UPLOADING MEDIA FILE ===');
    print('File: ${file.name}');
    print('Type: $type');
    print('Size: ${file.size}');
    print('URL: $url');
    print('Fields: ${request.fields}');

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    print('Upload response: ${response.statusCode}');
    print('Upload response body: $responseData');

    if (response.statusCode != 200) {
      throw Exception('Failed to upload media: ${response.statusCode}');
    }
  }

  // Upload Document File to Backend
  Future<void> _uploadDocumentFile(
      PlatformFile file, String description) async {
    final url = Uri.parse(
        '${Constants.articBaseUrl2}api/maintenance/${widget.maintenanceId}/upload-document/');
    final request = http.MultipartRequest('POST', url);

    // Add authorization header
    final token = await Sharedprefs.getAuthTokenPreference();
    request.headers['Authorization'] = 'Bearer $token';

    // Add file
    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ));
    }

    // Add metadata
    request.fields['description'] = description;
    request.fields['maintenance_id'] = widget.maintenanceId.toString();
    request.fields['business_id'] =
        (await SharedPrefs.getBusinessId()).toString();
    request.fields['user_id'] = (await SharedPrefs.getUserId()).toString();

    print('=== UPLOADING DOCUMENT FILE ===');
    print('File: ${file.name}');
    print('Description: $description');
    print('Size: ${file.size}');
    print('URL: $url');
    print('Fields: ${request.fields}');

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    print('Upload response: ${response.statusCode}');
    print('Upload response body: $responseData');

    if (response.statusCode != 200) {
      throw Exception('Failed to upload document: ${response.statusCode}');
    }
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature not implemented yet'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Upload image for parts section
  Future<void> _uploadSectionImage(String section, {String? itemName}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          final url = Uri.parse(
              '${Constants.articBaseUrl2}api/maintenance/${widget.maintenanceId}/upload-${section}-image/');
          final request = http.MultipartRequest('POST', url);

          // Add authorization header
          final token = await Sharedprefs.getAuthTokenPreference();
          request.headers['Authorization'] = 'Bearer $token';

          // Add file
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'file',
              file.bytes!,
              filename: file.name,
            ));
          }

          // Add metadata
          if (section == 'parts') {
            request.fields['part_name'] = itemName ?? '';
          } else if (section == 'materials') {
            request.fields['material_name'] = itemName ?? '';
          }
          request.fields['caption'] = '';

          final response = await request.send();
          if (response.statusCode != 200) {
            throw Exception('Failed to upload image');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image(s) uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh maintenance data
        _loadMaintenanceDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Upload image for observation/finding
  Future<void> _uploadObservationImage(String observationId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          final url = Uri.parse(
              '${Constants.articBaseUrl2}api/maintenance/observation/$observationId/upload-image/');
          final request = http.MultipartRequest('POST', url);

          // Add authorization header
          final token = await Sharedprefs.getAuthTokenPreference();
          request.headers['Authorization'] = 'Bearer $token';

          // Add file
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'file',
              file.bytes!,
              filename: file.name,
            ));
          }

          request.fields['caption'] = '';

          final response = await request.send();
          if (response.statusCode != 200) {
            throw Exception('Failed to upload image');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image(s) uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh maintenance data
        _loadMaintenanceDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Delete section image
  Future<void> _deleteSectionImage(String section, String imageId) async {
    try {
      final token = await Sharedprefs.getAuthTokenPreference();
      final response = await http.delete(
        Uri.parse(
            '${Constants.articBaseUrl2}api/maintenance/${widget.maintenanceId}/$section/$imageId/delete/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image deleted'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadMaintenanceDetail();
      } else {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Build image gallery for a section
  Widget _buildSectionImageGallery(String section, List<dynamic> images, bool canEdit) {
    if (images.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.photo_library, size: 18, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              'Images (${images.length})',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final img = images[index];
              final imageUrl = img['url'] ?? '';
              return Container(
                margin: EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showImagePreview(imageUrl, img['filename'] ?? 'Image'),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          image: DecorationImage(
                            image: NetworkImage(
                              imageUrl.startsWith('http')
                                ? imageUrl
                                : '${Constants.articBaseUrl2}$imageUrl'
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (canEdit)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _deleteSectionImage(section, img['id']),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Show image preview dialog
  void _showImagePreview(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
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
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Image.network(
                  imageUrl.startsWith('http')
                    ? imageUrl
                    : '${Constants.articBaseUrl2}$imageUrl',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Failed to load image'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePartsAndMaterials() async {
    try {
      final rawParts = _maintenance['parts_used'] ?? [];
      final parts = <String>[...rawParts.map((part) => part.toString())];
      final rawMaterials = _maintenance['materials_used'] ?? [];
      final materials = <String>[
        ...rawMaterials.map((material) => material.toString())
      ];
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/update/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'parts_used': parts,
          'materials_used': materials,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parts and materials saved'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadMaintenanceDetail();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDocumentationSection(String title, List<dynamic>? items) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
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
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          if (items != null && items.isNotEmpty)
            ...items
                .map((item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.fiber_manual_record,
                              size: 8, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList()
          else
            Text(
              'No items recorded',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    final beforePhotos = _maintenance['before_photos'] as List<dynamic>? ?? [];
    final afterPhotos = _maintenance['after_photos'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos & Documentation',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          if (beforePhotos.isNotEmpty) ...[
            Text(
              'Before Photos',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            _buildPhotoGrid(beforePhotos),
            SizedBox(height: 16),
          ],
          if (afterPhotos.isNotEmpty) ...[
            Text(
              'After Photos',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            _buildPhotoGrid(afterPhotos),
          ],
          if (beforePhotos.isEmpty && afterPhotos.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.photo_library, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'No photos available',
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<dynamic> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.image,
            color: Colors.grey[500],
            size: 32,
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    final status = _maintenance['status'];

    if (status == 'scheduled') {
      return FloatingActionButton.extended(
        onPressed: () => _updateStatus('start'),
        backgroundColor: Constants.ctaColorLight,
        icon: Icon(Icons.play_arrow, color: Colors.white),
        label: Text(
          'Start Maintenance',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    } else if (status == 'in_progress') {
      return FloatingActionButton.extended(
        onPressed: () => _updateStatus('complete'),
        backgroundColor: Color(0xFF1976D2),
        icon: Icon(Icons.check, color: Colors.white),
        label: Text(
          'Complete',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container();
  }

  // Helper Methods
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.settings;
      case 'scheduled':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Color(0xFF388E3C);
      case 'in_progress':
        return Color(0xFF1976D2);
      case 'scheduled':
        return Color(0xFF7B1FA2);
      case 'overdue':
        return Color(0xFFD32F2F);
      case 'cancelled':
        return Color(0xFF616161);
      default:
        return Color(0xFF616161);
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('MMM d, yyyy HH:mm').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  int _getCompletedCount() {
    return _checklistItems.where((item) => item['is_completed'] == true).length;
  }

  double _getCompletionPercentage() {
    if (_checklistItems.isEmpty) return 0.0;
    return _getCompletedCount() / _checklistItems.length;
  }

  // Action Methods
  Future<void> _updateStatus(String action) async {
    try {
      final url =
          '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/status/';
      print(
          '🔄 Updating status: $action for maintenance ID: ${widget.maintenanceId}');
      print('🌐 API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.headers,
        body: json.encode({
          'action': action,
          'user_id': await SharedPrefs.getUserId(),
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated successfully'),
              backgroundColor: Constants.ctaColorLight,
            ),
          );
          _loadMaintenanceDetail();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to update status: ${responseData['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Server error: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleChecklistItem(Map<String, dynamic> item) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/checklist/${item['id']}/update/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'mark_completed': !item['is_completed'],
          'user_id': await SharedPrefs.getUserId(),
        }),
      );

      if (response.statusCode == 200) {
        _loadMaintenanceDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update checklist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddChecklistItemDialog() {
    final _descriptionController = TextEditingController();
    final _notesController = TextEditingController();
    bool _isCritical = false;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_task,
                        color: Constants.ctaColorLight,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Checklist Item',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Constants.ctaColorLight,
                            ),
                          ),
                          Text(
                            'Create a new maintenance check item',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Form Fields
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Description *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Check compressor oil levels',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Constants.ctaColorLight, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 2,
                      ),

                      SizedBox(height: 20),

                      Text(
                        'Notes (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Additional details or instructions',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Constants.ctaColorLight, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 3,
                      ),

                      SizedBox(height: 20),

                      // Critical Item Toggle
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCritical
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCritical
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isCritical,
                              onChanged: (value) {
                                setState(() {
                                  _isCritical = value ?? false;
                                });
                              },
                              activeColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mark as Critical Item',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _isCritical
                                          ? Colors.orange[800]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    'Critical items require mandatory completion',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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

                SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_descriptionController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Please enter a description'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isSubmitting = true);

                                try {
                                  await _addChecklistItem(
                                    _descriptionController.text.trim(),
                                    notes:
                                        _notesController.text.trim().isNotEmpty
                                            ? _notesController.text.trim()
                                            : null,
                                    isCritical: _isCritical,
                                  );
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  setState(() => _isSubmitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Adding...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Add Item',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
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
        ),
      ),
    );
  }

  Future<void> _addChecklistItem(
    String description, {
    String? notes,
    bool isCritical = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/checklist/add/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'description': description,
          if (notes != null) 'notes': notes,
          'is_critical': isCritical,
          'user_id': await SharedPrefs.getUserId(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist item added successfully'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadMaintenanceDetail();
      } else {
        throw Exception('Failed to add checklist item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add checklist item: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  Future<void> _addChecklistItemQuick(String description) async {
    try {
      await _addChecklistItem(description);
    } catch (e) {
      // Error already handled in _addChecklistItem
    }
  }

  void _showChecklistItemOptions(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Checklist Item Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                item['is_completed'] == true ? Icons.undo : Icons.check,
                color: Constants.ctaColorLight,
              ),
              title: Text(
                item['is_completed'] == true
                    ? 'Mark Incomplete'
                    : 'Mark Complete',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _toggleChecklistItem(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit Item'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditChecklistItemDialog(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Item'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteChecklistItemDialog(item);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditChecklistItemDialog(Map<String, dynamic> item) {
    final _descriptionController =
        TextEditingController(text: item['description']);
    final _notesController = TextEditingController(text: item['notes'] ?? '');
    bool _isCritical = item['is_critical'] ?? false;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Checklist Item'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Item Description *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Constants.ctaColorLight),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Constants.ctaColorLight),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isCritical,
                      onChanged: (value) {
                        setState(() {
                          _isCritical = value ?? false;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                    Expanded(
                      child: Text(
                        'Mark as Critical Item',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a description'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      try {
                        await _updateChecklistItem(
                          item['id'],
                          _descriptionController.text.trim(),
                          notes: _notesController.text.trim().isNotEmpty
                              ? _notesController.text.trim()
                              : null,
                          isCritical: _isCritical,
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        setState(() => _isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Update Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateChecklistItem(
    String itemId,
    String description, {
    String? notes,
    bool isCritical = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/checklist/$itemId/update/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'description': description,
          if (notes != null) 'notes': notes,
          'is_critical': isCritical,
          'user_id': await SharedPrefs.getUserId(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist item updated successfully'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadMaintenanceDetail();
      } else {
        throw Exception('Failed to update checklist item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update checklist item: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  void _showDeleteChecklistItemDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Checklist Item'),
        content: Text(
          'Are you sure you want to delete this checklist item?\n\n"${item['description']}"',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteChecklistItem(item['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChecklistItem(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/checklist/$itemId/delete/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'user_id': await SharedPrefs.getUserId(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist item deleted successfully'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadMaintenanceDetail();
      } else {
        throw Exception('Failed to delete checklist item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete checklist item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'duplicate':
        // Show duplicate dialog
        break;
      case 'export':
        // Export maintenance record
        break;
      case 'delete':
        // Show delete confirmation
        break;
    }
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      categoryDisplay: json['category_display'] ?? '',
    );
  }
}

// Checklist item model for maintenance
class ChecklistItem {
  String description;
  bool isCritical;
  bool isCompleted;

  ChecklistItem({
    required this.description,
    this.isCritical = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'is_critical': isCritical,
    };
  }
}

class CreateMaintenanceDialog extends StatefulWidget {
  const CreateMaintenanceDialog({Key? key}) : super(key: key);

  @override
  _CreateMaintenanceDialogState createState() =>
      _CreateMaintenanceDialogState();
}

class _CreateMaintenanceDialogState extends State<CreateMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  // Required fields
  final _workDescriptionController = TextEditingController();
  int? _selectedDeviceId;
  String? _selectedMaintenanceTypeId;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  // Optional fields
  String _selectedStatus = 'scheduled';
  String _selectedPriority = 'normal';
  String? _selectedAssignedToId;
  final _estimatedCostController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _partsUsedController = TextEditingController();
  final _materialsUsedController = TextEditingController();
  final _externalContractorController = TextEditingController();
  final _safetyPrecautionsController = TextEditingController();
  // Checklist items
  List<ChecklistItem> _checklistItems = [];
  final _newChecklistController = TextEditingController();
  // Data lists
  List<Device> _devices = [];
  List<MaintenanceType> _maintenanceTypes = [];
  List<Map<String, dynamic>> _assignableUsers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _workDescriptionController.dispose();
    _estimatedCostController.dispose();
    _estimatedDurationController.dispose();
    _partsUsedController.dispose();
    _materialsUsedController.dispose();
    _externalContractorController.dispose();
    _safetyPrecautionsController.dispose();
    _newChecklistController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadDevices(),
        _loadMaintenanceTypes(),
        _loadAssignableUsers(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load required data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDevices() async {
    try {
      int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
      if (businessId == null) throw Exception('Business ID not found');

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await Sharedprefs.getAuthTokenPreference()}',
      };

      var request = http.Request(
          'POST', Uri.parse('${Constants.articBaseUrl2}api/devices/list/'));
      request.body = json.encode({
        'business_id': businessId,
        'include_unit_details': true,
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        if (data['devices'] != null) {
          _devices = (data['devices'] as List)
              .map((deviceData) => Device.fromJson(deviceData))
              .toList();
        }
      } else {
        throw Exception('Failed to load devices: ${response.reasonPhrase}');
      }
    } catch (e) {
      _devices = [
        Device(id: 1, name: 'Main Production Server', deviceId: 'dev-01'),
        Device(id: 2, name: 'Backup NAS Storage', deviceId: 'dev-02'),
        Device(id: 3, name: 'Office HVAC Unit', deviceId: 'dev-03'),
      ];
    }
  }

  Future<void> _loadMaintenanceTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/types/'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _maintenanceTypes = (data['maintenance_types'] as List)
            .map((item) => MaintenanceType.fromJson(item))
            .toList();
      } else {
        print('Failed to load maintenance types: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading maintenance types: $e');
    }
  }

  Future<void> _loadAssignableUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/assignable-users/'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _assignableUsers = (data['users'] as List)
            .map((user) => {
                  'id': user['id'].toString(),
                  'name': user['full_name'] ?? user['username'] ?? 'Unknown',
                })
            .toList();
      } else {
        // Fallback to empty list if API fails
        _assignableUsers = [];
      }
    } catch (e) {
      print('Error loading assignable users: $e');
      _assignableUsers = [];
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      final payload = {
        'device_id': _selectedDeviceId!,
        'maintenance_type_id': _selectedMaintenanceTypeId!,
        'scheduled_date': scheduledDateTime.toIso8601String(),
        'work_description': _workDescriptionController.text,
        'status': _selectedStatus,
        'priority': _selectedPriority,
        if (_selectedAssignedToId != null)
          'assigned_to_id': int.parse(_selectedAssignedToId!),
        if (_estimatedCostController.text.isNotEmpty)
          'estimated_cost': double.parse(_estimatedCostController.text),
        if (_estimatedDurationController.text.isNotEmpty)
          'estimated_duration_hours':
              double.parse(_estimatedDurationController.text),
        if (_partsUsedController.text.isNotEmpty)
          'parts_used': _partsUsedController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
        if (_materialsUsedController.text.isNotEmpty)
          'materials_used': _materialsUsedController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
        if (_externalContractorController.text.isNotEmpty)
          'external_contractor': _externalContractorController.text,
        if (_safetyPrecautionsController.text.isNotEmpty)
          'safety_precautions': _safetyPrecautionsController.text,
        if (_checklistItems.isNotEmpty)
          'checklist_items':
              _checklistItems.map((item) => item.toJson()).toList(),
      };
      print(payload);

      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/maintenance/create/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'Bearer ${await Sharedprefs.getAuthTokenPreference()}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  responseData['message'] ??
                      'Maintenance scheduled successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Failed to create maintenance: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: ${e.toString()}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _workDescriptionController.clear();
    _estimatedCostController.clear();
    _estimatedDurationController.clear();
    _partsUsedController.clear();
    _materialsUsedController.clear();
    _externalContractorController.clear();
    _safetyPrecautionsController.clear();
    _newChecklistController.clear();
    setState(() {
      _selectedDeviceId = null;
      _selectedMaintenanceTypeId = null;
      _scheduledDate = DateTime.now();
      _scheduledTime = TimeOfDay.now();
      _selectedStatus = 'scheduled';
      _selectedPriority = 'normal';
      _selectedAssignedToId = null;
      _checklistItems.clear();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Constants.ctaColorLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Constants.ctaColorLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _scheduledTime) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  void _addChecklistItem() {
    if (_newChecklistController.text.isNotEmpty) {
      setState(() {
        _checklistItems
            .add(ChecklistItem(description: _newChecklistController.text));
        _newChecklistController.clear();
      });
    }
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label,
      {String? hint, IconData? icon, Color? iconColor}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: iconColor ?? const Color(0xFF6B7280), size: 20)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Constants.ctaColorLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
      hintStyle:
          GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Use full screen scaffold for mobile, dialog for desktop
    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Constants.ctaColorLight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.build_circle, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Schedule Maintenance',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: _buildFormContent(),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.build_circle,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Schedule Maintenance',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.9), size: 20),
                  ),
                ],
              ),
            ),
            // Form Content for desktop
            Expanded(child: _buildFormContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: const Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Constants.ctaColorLight,
                      Constants.ctaColorLight.withOpacity(0.8)
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main form content
    return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Required Fields Section
                                _buildSectionHeader('Required Information',
                                    const Color(0xFFEF4444), Icons.star),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<int>(
                                  value: _selectedDeviceId,
                                  decoration: _buildInputDecoration('Device *',
                                      icon: Icons.devices,
                                      iconColor: const Color(0xFFEF4444)),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  items: _devices.map((device) {
                                    return DropdownMenuItem(
                                      value: device.id,
                                      child: Text(device.name,
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedDeviceId = value),
                                  validator: (value) => value == null
                                      ? 'Please select a device'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: _selectedMaintenanceTypeId,
                                  decoration: _buildInputDecoration(
                                      'Maintenance Type *',
                                      icon: Icons.build,
                                      iconColor: const Color(0xFFEF4444)),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  isExpanded: true,
                                  itemHeight: 60,
                                  items: _maintenanceTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type.id,
                                      child: Text(
                                        '${type.name} (${type.categoryDisplay})',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(
                                      () => _selectedMaintenanceTypeId = value),
                                  validator: (value) => value == null
                                      ? 'Please select a maintenance type'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _workDescriptionController,
                                  decoration: _buildInputDecoration(
                                    'Work Description *',
                                    hint:
                                        'e.g., Monthly compressor inspection and cleaning',
                                    icon: Icons.description,
                                    iconColor: const Color(0xFFEF4444),
                                  ),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 3,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter work description'
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAFAFA),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                              width: 1.5),
                                        ),
                                        child: InkWell(
                                          onTap: () => _selectDate(context),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  color:
                                                      const Color(0xFFEF4444),
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Date *',
                                                        style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: const Color(
                                                                0xFF6B7280))),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      DateFormat.yMMMd().format(
                                                          _scheduledDate),
                                                      style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                              0xFF1F2937)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAFAFA),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                              width: 1.5),
                                        ),
                                        child: InkWell(
                                          onTap: () => _selectTime(context),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time,
                                                  color:
                                                      const Color(0xFFEF4444),
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Time *',
                                                        style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: const Color(
                                                                0xFF6B7280))),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _scheduledTime
                                                          .format(context),
                                                      style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                              0xFF1F2937)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                // Optional Fields Section
                                _buildSectionHeader('Optional Information',
                                    const Color(0xFF3B82F6), Icons.tune),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedStatus,
                                        decoration: _buildInputDecoration(
                                            'Status',
                                            icon: Icons.flag,
                                            iconColor: const Color(0xFF3B82F6)),
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'scheduled',
                                              child: Text('Scheduled')),
                                          DropdownMenuItem(
                                              value: 'in_progress',
                                              child: Text('In Progress')),
                                          DropdownMenuItem(
                                              value: 'completed',
                                              child: Text('Completed')),
                                          DropdownMenuItem(
                                              value: 'cancelled',
                                              child: Text('Cancelled')),
                                          DropdownMenuItem(
                                              value: 'overdue',
                                              child: Text('Overdue')),
                                        ],
                                        onChanged: (value) => setState(
                                            () => _selectedStatus = value!),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedPriority,
                                        decoration: _buildInputDecoration(
                                            'Priority',
                                            icon: Icons.priority_high,
                                            iconColor: const Color(0xFF3B82F6)),
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'low', child: Text('Low')),
                                          DropdownMenuItem(
                                              value: 'normal',
                                              child: Text('Normal')),
                                          DropdownMenuItem(
                                              value: 'high',
                                              child: Text('High')),
                                          DropdownMenuItem(
                                              value: 'critical',
                                              child: Text('Critical')),
                                        ],
                                        onChanged: (value) => setState(
                                            () => _selectedPriority = value!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: _selectedAssignedToId,
                                  decoration: _buildInputDecoration(
                                      'Assigned To',
                                      icon: Icons.person,
                                      iconColor: const Color(0xFF3B82F6)),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null, child: Text('Unassigned')),
                                    ..._assignableUsers.map((user) {
                                      return DropdownMenuItem(
                                        value: user['id'].toString(),
                                        child: Text(user['name'],
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) => setState(
                                      () => _selectedAssignedToId = value),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _estimatedCostController,
                                        decoration: _buildInputDecoration(
                                            'Estimated Cost',
                                            hint: '150.00',
                                            icon: Icons.attach_money,
                                            iconColor: const Color(0xFF3B82F6)),
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            if (double.tryParse(value) ==
                                                    null ||
                                                double.parse(value) < 0) {
                                              return 'Enter a valid positive number';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: TextFormField(
                                        controller:
                                            _estimatedDurationController,
                                        decoration: _buildInputDecoration(
                                            'Duration (Hours)',
                                            hint: '3.5',
                                            icon: Icons.timer,
                                            iconColor: const Color(0xFF3B82F6)),
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            if (double.tryParse(value) ==
                                                    null ||
                                                double.parse(value) <= 0) {
                                              return 'Enter a valid positive number';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _partsUsedController,
                                  decoration: _buildInputDecoration(
                                    'Parts Used',
                                    hint:
                                        'Air Filter, Lubricant Oil (comma separated)',
                                    icon: Icons.build_circle,
                                    iconColor: const Color(0xFF3B82F6),
                                  ),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^[\w\s,.-]+$')
                                          .hasMatch(value)) {
                                        return 'Enter valid parts (comma separated)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _materialsUsedController,
                                  decoration: _buildInputDecoration(
                                    'Materials Used',
                                    hint:
                                        'Cleaning Solution, Replacement Gaskets (comma separated)',
                                    icon: Icons.handyman,
                                    iconColor: const Color(0xFF3B82F6),
                                  ),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^[\w\s,.-]+$')
                                          .hasMatch(value)) {
                                        return 'Enter valid materials (comma separated)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _externalContractorController,
                                  decoration: _buildInputDecoration(
                                      'External Contractor',
                                      hint: 'Contractor information',
                                      icon: Icons.business,
                                      iconColor: const Color(0xFF3B82F6)),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _safetyPrecautionsController,
                                  decoration: _buildInputDecoration(
                                    'Safety Precautions',
                                    hint:
                                        'Turn off main power, wear safety goggles',
                                    icon: Icons.security,
                                    iconColor: const Color(0xFF3B82F6),
                                  ),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 40),
                                // Checklist Section
                                _buildSectionHeader('Maintenance Checklist',
                                    const Color(0xFFF59E0B), Icons.checklist),
                                const SizedBox(height: 20),
                                if (_checklistItems.isNotEmpty) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFFE5E7EB)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: _checklistItems
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        ChecklistItem item = entry.value;
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: index <
                                                    _checklistItems.length - 1
                                                ? const Border(
                                                    bottom: BorderSide(
                                                        color:
                                                            Color(0xFFE5E7EB)))
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: item.isCritical,
                                                onChanged: (value) {
                                                  setState(() {
                                                    item.isCritical =
                                                        value ?? false;
                                                  });
                                                },
                                                activeColor:
                                                    Constants.ctaColorLight,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.description,
                                                      style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: const Color(
                                                              0xFF1F2937)),
                                                    ),
                                                    if (item.isCritical)
                                                      Text(
                                                        'Critical',
                                                        style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                                0xFFEF4444)),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Color(0xFFEF4444)),
                                                onPressed: () =>
                                                    _removeChecklistItem(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _newChecklistController,
                                        decoration: _buildInputDecoration(
                                          'Add Checklist Item',
                                          hint: 'Check compressor oil levels',
                                          icon: Icons.add_task,
                                          iconColor: const Color(0xFFF59E0B),
                                        ),
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        // onSubmitted: (_) => _addChecklistItem(),
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            if (!RegExp(r'^[\w\s.-]+$')
                                                .hasMatch(value)) {
                                              return 'Enter a valid checklist item';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Constants.ctaColorLight),
                                      child: IconButton(
                                        onPressed: _addChecklistItem,
                                        icon: const Icon(Icons.add_rounded,
                                            color: Colors.white),
                                        tooltip: 'Add Item',
                                      ),
                                    ),
                                  ],
                                ),

                                // Footer Actions
                                const SizedBox(height: 40),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: _isSubmitting ? null : _resetForm,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                                          ),
                                        ),
                                        child: Text('Reset', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
                                      ),
                                      TextButton(
                                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                                          ),
                                        ),
                                        child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
                                      ),
                                      ElevatedButton(
                                        onPressed: _isSubmitting ? null : _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Constants.ctaColorLight,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: _isSubmitting
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                                  const SizedBox(width: 8),
                                                  Text('Scheduling...', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.build_circle, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('Schedule Maintenance', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
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
}

// Maintenance Reports Dialog
class MaintenanceReportsDialog extends StatefulWidget {
  @override
  _MaintenanceReportsDialogState createState() =>
      _MaintenanceReportsDialogState();
}

class _MaintenanceReportsDialogState extends State<MaintenanceReportsDialog> {
  bool _isLoading = false;
  String _error = '';
  List<dynamic> _monthlyReports = [];
  List<dynamic> _selectedMonthRecords = [];
  int _selectedYear = DateTime.now().year;
  dynamic _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadMonthlyReports();
  }

  Future<void> _loadMonthlyReports() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/reports/monthly/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'business_id': await SharedPrefs.getBusinessId(),
          'year': _selectedYear,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _monthlyReports = data['reports'];
        });
      } else {
        throw Exception('Failed to load monthly reports');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthRecords(int year, int month) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/reports/$year/$month/records/?business_id=${await SharedPrefs.getBusinessId()}'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedMonthRecords = data['maintenance_records'];
        });
      } else {
        throw Exception('Failed to load month records');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load month records: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateDetailedPDF(String maintenanceId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                ),
                SizedBox(height: 16),
                Text(
                  'Generating Professional Report...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch comprehensive maintenance data
      final detailResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}api/maintenance/$maintenanceId/'),
        headers: ApiConfig.headers,
      );

      if (detailResponse.statusCode != 200) {
        throw Exception('Failed to fetch maintenance details');
      }

      final maintenanceData = json.decode(detailResponse.body);

      // Fetch observations
      final observationsResponse = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/$maintenanceId/observations/'),
        headers: ApiConfig.headers,
      );

      List<dynamic> observations = [];
      if (observationsResponse.statusCode == 200) {
        final obsData = json.decode(observationsResponse.body);
        observations = obsData['observations'] ?? [];
      }

      // Generate professional PDF
      Uint8List pdfBytes;
      try {
        pdfBytes = await _buildProfessionalMaintenancePDF(
          maintenanceData,
          observations,
        );
      } catch (pdfError, pdfStack) {
        print('Error building PDF: $pdfError');
        print('PDF Stack: $pdfStack');
        throw Exception('PDF Generation Error: $pdfError');
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Save PDF to device
      await _savePdfToDevice(
        pdfBytes,
        'maintenance_report_${maintenanceId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stackTrace) {
      print('Error in _generateDetailedPDF: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        try {
          Navigator.pop(context); // Close loading dialog if open
        } catch (_) {
          // Dialog might not be open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateSampleDetailedPDF() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                ),
                SizedBox(height: 16),
                Text(
                  'Generating Sample Report...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Create comprehensive sample maintenance data
      final sampleData = {
        'id': 'SAMPLE-${DateTime.now().millisecondsSinceEpoch}',
        'device': {
          'name': 'Refrigeration Unit #5',
          'device_id': 'REFR-005',
          'device_type': 'Commercial Refrigerator',
          'location': 'Building A - Cold Storage Room 3',
        },
        'maintenance_type': {
          'name': 'Preventive Maintenance',
          'category': 'preventive',
        },
        'priority': 'high',
        'status': 'completed',
        'status_display': 'Completed',
        'scheduled_date':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'actual_start_date': DateTime.now()
            .subtract(Duration(days: 2, hours: 1))
            .toIso8601String(),
        'actual_end_date':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'actual_duration_hours': 2.5,
        'assigned_to': {
          'name': 'John Smith',
        },
        'performed_by': {
          'name': 'John Smith',
        },
        'supervised_by': {
          'name': 'Sarah Johnson',
        },
        'description':
            'Scheduled quarterly preventive maintenance for refrigeration unit to ensure optimal performance and prevent equipment failure.',
        'work_performed':
            'Conducted comprehensive inspection of refrigeration system including:\n- Cleaned condenser and evaporator coils\n- Checked and adjusted refrigerant levels\n- Inspected and lubricated motor bearings\n- Tested temperature control accuracy\n- Verified door seals and gaskets\n- Cleaned drain lines and condensate pans\n- Calibrated temperature sensors',
        'parts_used':
            '- Replacement air filter (Model AF-2500)\n- Compressor oil (1 quart)\n- Door gasket sealant\n- Cleaning solution (2 bottles)',
        'estimated_cost': 450.00,
        'actual_cost': 425.50,
        'outcome': 'successful',
        'notes':
            'Unit is operating within normal parameters. Temperature stability improved after calibration. Recommend monitoring for the next 48 hours to ensure sustained performance.',
        'recommendations':
            'Schedule next preventive maintenance in 3 months. Consider installing smart temperature monitoring sensor for real-time alerts. Minor wear detected on compressor belt - plan replacement during next maintenance cycle.',
        'next_scheduled_date':
            DateTime.now().add(Duration(days: 90)).toIso8601String(),
        'checklist_items': [
          {
            'description': 'Visual inspection of unit exterior',
            'is_completed': true,
            'notes': 'No visible damage or corrosion',
          },
          {
            'description': 'Check temperature readings',
            'is_completed': true,
            'notes': 'All within spec: -5°C to 0°C',
          },
          {
            'description': 'Clean condenser coils',
            'is_completed': true,
            'notes': 'Moderate dust buildup removed',
          },
          {
            'description': 'Inspect door seals',
            'is_completed': true,
            'notes': 'Good condition, no leaks detected',
          },
          {
            'description': 'Test temperature controls',
            'is_completed': true,
            'notes': 'Calibrated and functioning correctly',
          },
          {
            'description': 'Lubricate moving parts',
            'is_completed': true,
            'notes': 'All bearings and hinges lubricated',
          },
          {
            'description': 'Check electrical connections',
            'is_completed': true,
            'notes': 'All connections secure, no overheating',
          },
          {
            'description': 'Document all findings',
            'is_completed': true,
            'notes': 'Complete maintenance log updated',
          },
        ],
      };

      final sampleObservations = [
        {
          'category': {'name': 'Mechanical'},
          'description':
              'Minor wear observed on compressor drive belt. No immediate action required but should be monitored.',
          'severity': 'low',
        },
        {
          'category': {'name': 'Electrical'},
          'description':
              'All electrical connections secure. Power consumption within normal range.',
          'severity': 'normal',
        },
        {
          'category': {'name': 'Performance'},
          'description':
              'Temperature recovery time improved by 15% after coil cleaning and calibration.',
          'severity': 'normal',
        },
        {
          'category': {'name': 'Safety'},
          'description':
              'All safety systems operational. Emergency shut-off tested successfully.',
          'severity': 'normal',
        },
      ];

      // Generate professional PDF
      Uint8List pdfBytes;
      try {
        pdfBytes = await _buildProfessionalMaintenancePDF(
          sampleData,
          sampleObservations,
        );
      } catch (pdfError, pdfStack) {
        print('Error building sample PDF: $pdfError');
        print('PDF Stack: $pdfStack');
        throw Exception('PDF Generation Error: $pdfError');
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Save PDF to device
      await _savePdfToDevice(
        pdfBytes,
        'sample_maintenance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stackTrace) {
      print('Error in _generateSampleDetailedPDF: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        try {
          Navigator.pop(context); // Close loading dialog if open
        } catch (_) {
          // Dialog might not be open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate sample PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateMonthlySummaryPDF(int year, int month) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                ),
                SizedBox(height: 16),
                Text(
                  'Generating Monthly Summary Report...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch monthly records data
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}api/maintenance/reports/$year/$month/records/?business_id=${await SharedPrefs.getBusinessId()}'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch monthly records');
      }

      final data = json.decode(response.body);
      final monthlyRecords = data['maintenance_records'] ?? [];

      // Get month statistics from the selected month data
      final monthStats = _selectedMonth;

      // Generate professional monthly PDF
      final pdfBytes = await _buildProfessionalMonthlySummaryPDF(
        year,
        month,
        monthlyRecords,
        monthStats,
      );

      Navigator.pop(context); // Close loading dialog

      // Save PDF to device
      await _savePdfToDevice(
        pdfBytes,
        'monthly_maintenance_${year}_${month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate monthly PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build a professional, comprehensive maintenance report PDF
  Future<Uint8List> _buildProfessionalMaintenancePDF(
    Map<String, dynamic> maintenanceData,
    List<dynamic> observations,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          // Header with Company Branding
          _buildPDFHeader('MAINTENANCE ACTIVITY REPORT'),
          pw.SizedBox(height: 30),

          // Report Metadata
          _buildPDFSection('Report Information', [
            _buildPDFInfoRow('Report Generated',
                DateFormat('MMMM dd, yyyy - HH:mm').format(now)),
            _buildPDFInfoRow(
                'Maintenance ID', maintenanceData['id']?.toString() ?? 'N/A'),
            _buildPDFInfoRow('Report Type', 'Detailed Maintenance Activity'),
          ]),
          pw.SizedBox(height: 20),

          // Device Information
          _buildPDFSection('Equipment Details', [
            _buildPDFInfoRow('Device Name',
                maintenanceData['device']?['name']?.toString() ?? 'N/A'),
            _buildPDFInfoRow('Device ID',
                maintenanceData['device']?['device_id']?.toString() ?? 'N/A'),
            _buildPDFInfoRow('Device Type',
                maintenanceData['device']?['device_type']?.toString() ?? 'N/A'),
            _buildPDFInfoRow('Location',
                maintenanceData['device']?['location']?.toString() ?? 'N/A'),
          ]),
          pw.SizedBox(height: 20),

          // Maintenance Details
          _buildPDFSection('Maintenance Activity Details', [
            _buildPDFInfoRow(
                'Maintenance Type',
                maintenanceData['maintenance_type']?['name']?.toString() ??
                    'N/A'),
            _buildPDFInfoRow(
                'Category',
                _capitalizeText(maintenanceData['maintenance_type']?['category']
                        ?.toString() ??
                    'N/A')),
            _buildPDFInfoRow(
                'Priority',
                _capitalizeText(
                    maintenanceData['priority']?.toString() ?? 'N/A')),
            _buildPDFInfoRow(
                'Status',
                _capitalizeText(maintenanceData['status_display']?.toString() ??
                    maintenanceData['status']?.toString() ??
                    'N/A')),
          ]),
          pw.SizedBox(height: 20),

          // Schedule and Timeline
          _buildPDFSection('Schedule & Timeline', [
            _buildPDFInfoRow('Scheduled Date',
                _formatPDFDateTime(maintenanceData['scheduled_date'])),
            _buildPDFInfoRow('Actual Start',
                _formatPDFDateTime(maintenanceData['actual_start_date'])),
            _buildPDFInfoRow('Actual End',
                _formatPDFDateTime(maintenanceData['actual_end_date'])),
            _buildPDFInfoRow(
                'Duration',
                maintenanceData['actual_duration_hours'] != null
                    ? '${maintenanceData['actual_duration_hours']} hours'
                    : 'N/A'),
            pw.SizedBox(height: 12),
            _buildTimelineProgressBar(maintenanceData),
          ]),
          pw.SizedBox(height: 20),

          // Personnel Information
          _buildPDFSection('Personnel', [
            _buildPDFInfoRow(
                'Assigned To',
                maintenanceData['assigned_to']?['full_name']?.toString() ??
                    'Unassigned'),
            _buildPDFInfoRow('Performed By',
                maintenanceData['performed_by']?['full_name']?.toString() ?? 'N/A'),
            if (maintenanceData['supervised_by'] != null)
              _buildPDFInfoRow(
                  'Supervised By',
                  maintenanceData['supervised_by']?['full_name']?.toString() ??
                      'N/A'),
          ]),
          pw.SizedBox(height: 20),

          // Work Performed
          if (maintenanceData['description'] != null &&
              maintenanceData['description'].toString().isNotEmpty)
            _buildPDFSection('Work Description', [
              pw.Text(
                maintenanceData['description']?.toString() ?? '',
                style: pw.TextStyle(fontSize: 10),
              ),
            ]),
          if (maintenanceData['description'] != null &&
              maintenanceData['description'].toString().isNotEmpty)
            pw.SizedBox(height: 20),

          if (maintenanceData['work_performed'] != null &&
              maintenanceData['work_performed'].toString().isNotEmpty)
            _buildPDFSection('Work Performed', [
              pw.Text(
                maintenanceData['work_performed']?.toString() ?? '',
                style: pw.TextStyle(fontSize: 10),
              ),
            ]),
          if (maintenanceData['work_performed'] != null &&
              maintenanceData['work_performed'].toString().isNotEmpty)
            pw.SizedBox(height: 20),

          // Checklist if available
          if (maintenanceData['checklist_items'] != null &&
              (maintenanceData['checklist_items'] as List).isNotEmpty)
            _buildPDFSection('Maintenance Checklist', [
              _buildMaintenanceStatusPieChart(maintenanceData),
              pw.SizedBox(height: 12),
              _buildChecklistTable(maintenanceData['checklist_items']),
            ]),
          if (maintenanceData['checklist_items'] != null &&
              (maintenanceData['checklist_items'] as List).isNotEmpty)
            pw.SizedBox(height: 20),

          // Observations
          if (observations.isNotEmpty)
            _buildPDFSection('Observations & Findings', [
              _buildObservationsSeverityChart(observations),
              pw.SizedBox(height: 12),
              _buildObservationsTable(observations),
            ]),
          if (observations.isNotEmpty) pw.SizedBox(height: 20),

          // Parts and Materials
          if (maintenanceData['parts_used'] != null &&
              maintenanceData['parts_used'].toString().isNotEmpty)
            _buildPDFSection('Parts & Materials Used', [
              _buildPartsUsedTable(
                  maintenanceData['parts_used']?.toString() ?? ''),
            ]),
          if (maintenanceData['parts_used'] != null &&
              maintenanceData['parts_used'].toString().isNotEmpty)
            pw.SizedBox(height: 20),

          // Cost Information
          _buildPDFSection('Cost Analysis', [
            _buildPDFInfoRow(
                'Estimated Cost',
                maintenanceData['estimated_cost'] != null
                    ? '\$${maintenanceData['estimated_cost']}'
                    : 'N/A'),
            _buildPDFInfoRow(
                'Actual Cost',
                maintenanceData['actual_cost'] != null
                    ? '\$${maintenanceData['actual_cost']}'
                    : 'N/A'),
            if (maintenanceData['estimated_cost'] != null &&
                maintenanceData['actual_cost'] != null)
              _buildPDFInfoRow(
                  'Variance',
                  _calculateCostVariance(maintenanceData['estimated_cost'],
                      maintenanceData['actual_cost'])),
            pw.SizedBox(height: 12),
            _buildCostComparisonChart(maintenanceData),
          ]),
          pw.SizedBox(height: 20),

          // Outcome and Follow-up
          if (maintenanceData['outcome'] != null ||
              maintenanceData['notes'] != null ||
              maintenanceData['recommendations'] != null)
            _buildPDFSection('Outcome & Recommendations', [
              if (maintenanceData['outcome'] != null)
                _buildPDFInfoRow(
                    'Outcome',
                    _capitalizeText(
                        maintenanceData['outcome']?.toString() ?? 'N/A')),
              if (maintenanceData['notes'] != null &&
                  maintenanceData['notes'].toString().isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Notes:',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(maintenanceData['notes']?.toString() ?? '',
                        style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                  ],
                ),
              if (maintenanceData['recommendations'] != null &&
                  maintenanceData['recommendations'].toString().isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Recommendations:',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        maintenanceData['recommendations']?.toString() ?? '',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
            ]),
          if (maintenanceData['outcome'] != null ||
              maintenanceData['notes'] != null ||
              maintenanceData['recommendations'] != null)
            pw.SizedBox(height: 20),

          // Next Scheduled Maintenance
          if (maintenanceData['next_scheduled_date'] != null)
            _buildPDFSection('Follow-up', [
              _buildPDFInfoRow('Next Scheduled Maintenance',
                  _formatPDFDateTime(maintenanceData['next_scheduled_date'])),
            ]),

          // Footer
          pw.SizedBox(height: 40),
          _buildPDFFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build a professional monthly summary PDF
  Future<Uint8List> _buildProfessionalMonthlySummaryPDF(
    int year,
    int month,
    List<dynamic> monthlyRecords,
    dynamic monthStats,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildPDFHeader('MONTHLY MAINTENANCE SUMMARY REPORT'),
          pw.SizedBox(height: 30),

          // Report Information
          _buildPDFSection('Report Information', [
            _buildPDFInfoRow('Report Period', '$monthName $year'),
            _buildPDFInfoRow('Generated On',
                DateFormat('MMMM dd, yyyy - HH:mm').format(now)),
            _buildPDFInfoRow('Total Activities',
                monthStats?['total_maintenance']?.toString() ?? '0'),
          ]),
          pw.SizedBox(height: 20),

          // Executive Summary
          _buildPDFSection('Executive Summary', [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                _buildPDFTableRow('Total Maintenance Activities',
                    monthStats?['total_maintenance']?.toString() ?? '0', true),
                _buildPDFTableRow('Completed',
                    monthStats?['completed']?.toString() ?? '0', false),
                _buildPDFTableRow('In Progress',
                    monthStats?['in_progress']?.toString() ?? '0', false),
                _buildPDFTableRow('Overdue',
                    monthStats?['overdue']?.toString() ?? '0', false),
                _buildPDFTableRow(
                    'Completion Rate',
                    '${monthStats?['completion_rate']?.toString() ?? '0'}%',
                    false),
                _buildPDFTableRow('Total Cost',
                    '\$${_formatCost(monthStats?['total_cost'])}', false),
                _buildPDFTableRow(
                    'Average Duration',
                    '${_formatDuration(monthStats?['avg_duration_hours'])} hours',
                    false),
              ],
            ),
          ]),
          pw.SizedBox(height: 30),

          // Detailed Activities List
          _buildPDFSection('Detailed Activity Log', [
            pw.Text(
              'This section contains a comprehensive list of all maintenance activities performed during $monthName $year.',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 10),
            _buildMonthlyActivitiesTable(monthlyRecords),
          ]),

          // Footer
          pw.SizedBox(height: 40),
          _buildPDFFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  // PDF Helper Methods
  pw.Widget _buildPDFHeader(String title) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ArticSentinel',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'IoT Device Management System',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'OFFICIAL REPORT',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildPDFTableRow(String label, String value, bool isHeader) {
    return pw.TableRow(
      decoration: isHeader ? pw.BoxDecoration(color: PdfColors.blue50) : null,
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildChecklistTable(List<dynamic> checklistItems) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Item',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Status',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Notes',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...checklistItems.map((item) {
          final itemMap = item as Map<String, dynamic>;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  itemMap['description']?.toString() ?? '',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  itemMap['is_completed'] == true ? '✓ Completed' : '○ Pending',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  itemMap['notes']?.toString() ?? '-',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildObservationsTable(List<dynamic> observations) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Category',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Observation',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Severity',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...observations.map((obs) {
          final obsMap = obs as Map<String, dynamic>;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  obsMap['category']?['name']?.toString() ?? 'N/A',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  obsMap['description']?.toString() ?? '',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  _capitalizeText(obsMap['severity']?.toString() ?? 'normal'),
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildMonthlyActivitiesTable(List<dynamic> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: pw.FixedColumnWidth(80),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1),
        4: pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Date',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Device',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Type',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Personnel',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('Status',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...records
            .map((record) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _formatPDFDate(record['scheduled_date']),
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        record['device']?['name']?.toString() ?? 'N/A',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        record['maintenance_type']?['name']?.toString() ??
                            'N/A',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        record['performed_by']?['full_name']?.toString() ??
                            record['assigned_to']?['full_name']?.toString() ??
                            'N/A',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _capitalizeText(record['status_display']?.toString() ??
                            record['status']?.toString() ??
                            'N/A'),
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildPDFFooter() {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'This is an automated report generated by ArticSentinel IoT Management System',
            style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'For questions or concerns, please contact your system administrator',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '© ${DateTime.now().year} ArticSentinel. All rights reserved.',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // Chart builders for PDF
  pw.Widget _buildMaintenanceStatusPieChart(Map<String, dynamic> data) {
    final completed = (data['checklist_items'] as List?)
            ?.where((item) => item['is_completed'] == true)
            .length ??
        0;
    final total = (data['checklist_items'] as List?)?.length ?? 1;
    final pending = total - completed;
    final completedPercent = (completed / total) * 100;

    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 120,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: PdfColors.green300,
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          '${completedPercent.toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Complete',
                          style: pw.TextStyle(
                              fontSize: 11, color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '$completed of $total tasks',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                    'Completed', PdfColors.green, '$completed items'),
                pw.SizedBox(height: 8),
                _buildLegendItem('Pending', PdfColors.orange, '$pending items'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildLegendItem(String label, PdfColor color, String value) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(value,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCostComparisonChart(Map<String, dynamic> data) {
    final estimated =
        double.tryParse(data['estimated_cost']?.toString() ?? '0') ?? 0;
    final actual = double.tryParse(data['actual_cost']?.toString() ?? '0') ?? 0;
    final maxValue = [estimated, actual].reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 180,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Cost Analysis (USD)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          _buildBarChartRow(
              'Estimated', estimated, maxValue, PdfColors.blue300),
          pw.SizedBox(height: 12),
          _buildBarChartRow('Actual', actual, maxValue, PdfColors.green300),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color:
                  actual <= estimated ? PdfColors.green50 : PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Variance:',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '\$${(actual - estimated).toStringAsFixed(2)} (${((actual - estimated) / estimated * 100).toStringAsFixed(1)}%)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: actual <= estimated
                        ? PdfColors.green800
                        : PdfColors.orange800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBarChartRow(
      String label, double value, double maxValue, PdfColor color) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0;

    return pw.Row(
      children: [
        pw.Container(
          width: 80,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10)),
        ),
        pw.Expanded(
          child: pw.Stack(
            children: [
              pw.Container(
                height: 24,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Container(
                width: percentage * 300,
                height: 24,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: pw.Center(
                  child: pw.Text(
                    '\$${value.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildObservationsSeverityChart(List<dynamic> observations) {
    final severityCounts = <String, int>{
      'low': 0,
      'normal': 0,
      'high': 0,
      'critical': 0,
    };

    for (var obs in observations) {
      final severity = (obs['severity']?.toString() ?? 'normal').toLowerCase();
      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
    }

    final total = observations.length;

    return pw.Container(
      height: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Observations by Severity',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildVerticalBar('Critical', severityCounts['critical'] ?? 0,
                    total, PdfColors.red),
                _buildVerticalBar('High', severityCounts['high'] ?? 0, total,
                    PdfColors.orange),
                _buildVerticalBar('Normal', severityCounts['normal'] ?? 0,
                    total, PdfColors.blue),
                _buildVerticalBar(
                    'Low', severityCounts['low'] ?? 0, total, PdfColors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVerticalBar(
      String label, int value, int total, PdfColor color) {
    final maxHeight = 120.0;
    final height = total > 0 ? (value / total) * maxHeight : 0.0;

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        if (value > 0)
          pw.Container(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text(
              value.toString(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        pw.Container(
          width: 50,
          height: height.clamp(20, maxHeight),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  pw.Widget _buildTimelineProgressBar(Map<String, dynamic> data) {
    try {
      final scheduled = DateTime.parse(data['scheduled_date']?.toString() ??
          DateTime.now().toIso8601String());
      final actualStart = data['actual_start_date'] != null
          ? DateTime.parse(data['actual_start_date'].toString())
          : scheduled;
      final actualEnd = data['actual_end_date'] != null
          ? DateTime.parse(data['actual_end_date'].toString())
          : DateTime.now();

      final duration = data['actual_duration_hours'] ?? 0;

      return pw.Container(
        padding: pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Maintenance Timeline',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                _buildTimelineStep(
                    'Scheduled', _formatPDFDate(data['scheduled_date']), true),
                pw.Expanded(
                    child: pw.Container(height: 2, color: PdfColors.blue300)),
                _buildTimelineStep(
                    'Started',
                    _formatPDFDate(data['actual_start_date']),
                    data['actual_start_date'] != null),
                pw.Expanded(
                    child: pw.Container(height: 2, color: PdfColors.blue300)),
                _buildTimelineStep(
                    'Completed',
                    _formatPDFDate(data['actual_end_date']),
                    data['actual_end_date'] != null),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Icon(pw.IconData(0xe192),
                      size: 16, color: PdfColors.blue600),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Total Duration: $duration hours',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return pw.Container();
    }
  }

  pw.Widget _buildTimelineStep(String label, String date, bool completed) {
    return pw.Column(
      children: [
        pw.Container(
          width: 40,
          height: 40,
          decoration: pw.BoxDecoration(
            color: completed ? PdfColors.green : PdfColors.grey300,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Icon(
              completed ? pw.IconData(0xe5ca) : pw.IconData(0xe5d5),
              color: PdfColors.white,
              size: 20,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: completed ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          date,
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildPartsUsedTable(String partsText) {
    final parts =
        partsText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('#',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Part / Material',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...parts.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final part = entry.value.replaceAll(RegExp(r'^[-•]\s*'), '');
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child:
                    pw.Text(index.toString(), style: pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text(part, style: pw.TextStyle(fontSize: 9)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Utility methods for PDF formatting
  String _formatPDFDateTime(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, yyyy HH:mm').format(date.toLocal());
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatPDFDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, yyyy').format(date.toLocal());
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _capitalizeText(String text) {
    if (text.isEmpty) return text;
    return text
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _calculateCostVariance(dynamic estimated, dynamic actual) {
    try {
      final est = double.parse(estimated.toString());
      final act = double.parse(actual.toString());
      final variance = act - est;
      final percentVariance = ((variance / est) * 100).toStringAsFixed(1);
      return '\$${variance.toStringAsFixed(2)} (${variance >= 0 ? '+' : ''}$percentVariance%)';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatCost(dynamic value) {
    if (value == null) return '0.00';
    try {
      final cost = double.parse(value.toString());
      return cost.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  String _formatDuration(dynamic value) {
    if (value == null) return '0.0';
    try {
      final duration = double.parse(value.toString());
      return duration.toStringAsFixed(1);
    } catch (e) {
      return '0.0';
    }
  }

  Future<void> _savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      // Request storage permission for mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Save PDF using platform-specific implementation
      await PdfSaver.savePdf(pdfBytes, fileName);

      // Show success message
      if (mounted) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('PDF downloaded to your browser\'s download folder'),
              backgroundColor: Constants.ctaColorLight,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          // For non-web platforms, show dialog with option to open
          final String downloadPath = Platform.isAndroid
              ? 'Downloads folder'
              : Platform.isIOS
                  ? 'Files app'
                  : 'Downloads folder';

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'PDF Saved Successfully',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'The PDF has been saved to your $downloadPath',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
                if (!Platform.isIOS) // iOS doesn't support direct file opening
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        // Construct the file path based on platform
                        String filePath;
                        if (Platform.isAndroid) {
                          filePath = '/storage/emulated/0/Download/$fileName';
                        } else {
                          // For desktop, we'd need to get the downloads directory
                          // This is a simplified approach
                          filePath = fileName;
                        }

                        final result = await OpenFile.open(filePath);
                        if (result.type != ResultType.done) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Could not open PDF: ${result.message}'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not open PDF: $e'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                    ),
                    child: Text('Open PDF'),
                  ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPDFDownloadSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Constants.ctaColorLight,
      ),
    );
  }

  Widget _buildStatBadge(String text, dynamic value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value != null ? '$text: $value' : text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProfessionalStatBadge(String text, dynamic value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Constants.ctaColorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value != null ? '$text: $value' : text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Constants.ctaColorLight,
        ),
      ),
    );
  }

  // Helper methods for status colors and icons
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Color(0xFF388E3C);
      case 'in_progress':
        return Color(0xFF1976D2);
      case 'scheduled':
        return Color(0xFF7B1FA2);
      case 'overdue':
        return Color(0xFFD32F2F);
      case 'cancelled':
        return Color(0xFF616161);
      default:
        return Color(0xFF616161);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.settings;
      case 'scheduled':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Use full screen scaffold for mobile
    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Constants.ctaColorLight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.assessment_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Maintenance Reports',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _generateSampleDetailedPDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              tooltip: 'Generate Sample Report',
            ),
          ],
        ),
        body: _buildReportsContent(isMobile: true),
      );
    }

    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            constraints: BoxConstraints(maxWidth: 1200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(children: [
              // Clean Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assessment_outlined,
                        color: Constants.ctaColorLight,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maintenance Reports',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Generate and download comprehensive maintenance reports',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: _generateSampleDetailedPDF,
                      icon: Icon(Icons.picture_as_pdf, size: 18),
                      label: Text('Generate Sample Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Desktop content
              Expanded(child: _buildReportsContent(isMobile: false)),
            ])));
  }

  Widget _buildReportsContent({required bool isMobile}) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        // Year Selection Bar
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Year:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Constants.ctaColorLight.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Constants.ctaColorLight,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Constants.ctaColorLight,
                      ),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                            _selectedMonth = null;
                            _selectedMonthRecords = [];
                          });
                          _loadMonthlyReports();
                        }
                      },
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Text(
                    'Report Year:',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Constants.ctaColorLight.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      underline: SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Constants.ctaColorLight,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Constants.ctaColorLight,
                      ),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                            _selectedMonth = null;
                            _selectedMonthRecords = [];
                          });
                          _loadMonthlyReports();
                        }
                      },
                    ),
                  ),
                ],
              ),
        ),
        // Main content area
        Expanded(
          child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Constants.ctaColorLight))
            : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(_error, style: GoogleFonts.inter(color: Colors.grey[600])),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMonthlyReports,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildMonthsGrid(isMobile),
        ),
      ]),
    );
  }

  Widget _buildMonthsGrid(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Reports',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: isMobile ? 8 : 16,
              mainAxisSpacing: isMobile ? 8 : 16,
              childAspectRatio: isMobile ? 1.2 : 1.5,
            ),
            itemCount: _monthlyReports.length,
            itemBuilder: (context, index) {
              final report = _monthlyReports[index];
              return _buildMonthCard(report, isMobile);
            },
          ),
          if (_selectedMonth != null) ...[
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedMonth['month_name']} Records',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateMonthlySummaryPDF(
                    _selectedYear,
                    _selectedMonth['month'],
                  ),
                  icon: Icon(Icons.download, size: 16),
                  label: Text(isMobile ? 'Download' : 'Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_selectedMonthRecords.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No records for this month',
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _selectedMonthRecords.length,
                itemBuilder: (context, index) {
                  final record = _selectedMonthRecords[index];
                  return _buildRecordCard(record, isMobile);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthCard(dynamic report, bool isMobile) {
    final isSelected = _selectedMonth != null &&
        _selectedMonth['month'] == report['month'];
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMonth = report;
        });
        _loadMonthRecords(_selectedYear, report['month']);
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? Constants.ctaColorLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Constants.ctaColorLight : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              report['month_name'] ?? 'Month',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Constants.ctaColorLight : Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${report['total_records'] ?? 0} records',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(dynamic record, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(record['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(record['status']),
              color: _getStatusColor(record['status']),
              size: isMobile ? 18 : 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['device']?['name'] ?? 'Unknown Device',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  record['maintenance_type']?['name'] ?? 'Maintenance',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Constants.ctaColorLight),
            onPressed: () => _generateDetailedPDF(record['id']),
            tooltip: 'Download PDF',
          ),
        ],
      ),
    );
  }
}
