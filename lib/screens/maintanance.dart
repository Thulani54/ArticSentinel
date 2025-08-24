import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/custom_widgets/customCard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
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

  // Filters
  Map<String, dynamic> _filters = {};
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      Uri.parse('${ApiConfig.baseUrl}/api/maintenance/list/'),
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
    return Container(
      padding: EdgeInsets.all(16),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
      ),
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
                'Active Schedules',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
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
          // Add schedules list here
          _buildEmptyState('No recurring schedules configured'),
        ],
      ),
    );
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
        Uri.parse('${ApiConfig.baseUrl}/api/maintenance/$id/status/'),
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
        Uri.parse('${ApiConfig.baseUrl}/api/maintenance/schedule/generate/'),
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
            '${ApiConfig.baseUrl}/api/maintenance/${widget.maintenanceId}/'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('=== FETCHING OBSERVATIONS ===');
        print(
            'URL: ${ApiConfig.baseUrl}/api/maintenance/${widget.maintenanceId}/');
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
    final bool canEdit = _maintenance['status'] == 'in_progress';

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
              if (canEdit)
                ElevatedButton.icon(
                  onPressed: parts.isEmpty ? null : _savePartsAndMaterials,
                  icon: Icon(Icons.save, size: 16),
                  label: Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
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
              if (canEdit)
                ElevatedButton.icon(
                  onPressed: materials.isEmpty ? null : _savePartsAndMaterials,
                  icon: Icon(Icons.save, size: 16),
                  label: Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
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

  // Files/Media Section (UI scaffold; backend upload pending confirmation)
  Widget _buildInteractiveFilesSection(bool canEdit) {
    final beforePhotos = _maintenance['before_photos'] as List<dynamic>? ?? [];
    final afterPhotos = _maintenance['after_photos'] as List<dynamic>? ?? [];
    final documents = _maintenance['documents'] as List<dynamic>? ?? [];

    return CustomCard(
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Files & Media',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (canEdit)
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showUploadMediaDialog(),
                      icon: Icon(Icons.upload, size: 16),
                      label: Text('Upload Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showUploadDocumentDialog(),
                      icon: Icon(Icons.picture_as_pdf, size: 16),
                      label: Text('Upload Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 12),
          if (beforePhotos.isEmpty && afterPhotos.isEmpty && documents.isEmpty)
            Text(
              'No files uploaded',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            )
          else ...[
            if (beforePhotos.isNotEmpty) ...[
              Text('Before Photos',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              _buildPhotoGrid(beforePhotos),
              SizedBox(height: 12),
            ],
            if (afterPhotos.isNotEmpty) ...[
              Text('After Photos',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              _buildPhotoGrid(afterPhotos),
              SizedBox(height: 12),
            ],
            if (documents.isNotEmpty) ...[
              Text('Documents',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Column(
                children: documents
                    .map((d) => ListTile(
                          leading: Icon(Icons.insert_drive_file,
                              color: Colors.grey[600]),
                          title: Text(d.toString()),
                          trailing: Icon(Icons.open_in_new, size: 18),
                          onTap: () => _showNotImplemented('Open document'),
                        ))
                    .toList(),
              ),
            ],
          ],
        ]),
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

                        return Container(
                          padding: EdgeInsets.all(16),
                          child: Row(
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
                                child: Text(
                                  _formatDateTime(dateAdded.toIso8601String()),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
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
          'URL: ${ApiConfig.baseUrl}/api/maintenance/${widget.maintenanceId}/observations/');
      print('Headers: ${ApiConfig.headers}');
      print('Request Body: ${json.encode(requestBody)}');
      print('==========================');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/maintenance/${widget.maintenanceId}/observations/'),
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
        '${Constants.articBaseUrl2}/maintenance/${widget.maintenanceId}/upload-media');
    final request = http.MultipartRequest('POST', url);

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
        '${Constants.articBaseUrl2}/maintenance/${widget.maintenanceId}/upload-document');
    final request = http.MultipartRequest('POST', url);

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
          '${ApiConfig.baseUrl}/api/maintenance/${widget.maintenanceId}/status/';
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
            '${ApiConfig.baseUrl}/api/maintenance/checklist/${item['id']}/update/'),
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
            '${ApiConfig.baseUrl}/api/maintenance/checklist/$itemId/update/'),
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
            '${ApiConfig.baseUrl}/api/maintenance/checklist/$itemId/delete/'),
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
        Uri.parse('${Constants.articBaseUrl2}api/maintenance/types/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'Bearer ${await Sharedprefs.getAuthTokenPreference()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _maintenanceTypes = (data['maintenance_types'] as List)
            .map((item) => MaintenanceType.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load maintenance types');
      }
    } catch (e) {}
  }

  Future<void> _loadAssignableUsers() async {
    _assignableUsers = [
      {'id': '1', 'name': 'John Doe'},
      {'id': '2', 'name': 'Jane Smith'},
      {'id': '3', 'name': 'Mike Johnson'},
    ];
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

            // Form Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 64, color: const Color(0xFFEF4444)),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
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
                                  items: _maintenanceTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type.id,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(type.name,
                                              style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600)),
                                          Text(type.categoryDisplay,
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color:
                                                      Constants.ctaColorLight)),
                                        ],
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
                              ],
                            ),
                          ),
                        ),
            ),

            // Footer Actions
            if (!_isLoading && _error == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24)),
                  border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _resetForm,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: [
                          Constants.ctaColorLight,
                          Constants.ctaColorLight.withOpacity(0.8)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Constants.ctaColorLight.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Scheduling...',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.build_circle, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Schedule Maintenance',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
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
        Uri.parse('${ApiConfig.baseUrl}/api/maintenance/reports/monthly/'),
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
            '${ApiConfig.baseUrl}/api/maintenance/reports/$year/$month/records/?business_id=${await SharedPrefs.getBusinessId()}'),
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
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/maintenance/reports/$maintenanceId/pdf/?business_id=${await SharedPrefs.getBusinessId()}'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        // Save PDF to device
        await _savePdfToDevice(
          response.bodyBytes,
          'maintenance_report_${maintenanceId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } else {
        throw Exception('Failed to generate PDF report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateMonthlySummaryPDF(int year, int month) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/maintenance/reports/$year/$month/summary-pdf/'),
        headers: ApiConfig.headers,
        body: json.encode({
          'business_id': await SharedPrefs.getBusinessId(),
        }),
      );

      if (response.statusCode == 200) {
        // Save PDF to device or open in PDF viewer
        _showPDFDownloadSuccess(
            'Monthly summary report downloaded successfully');
      } else {
        throw Exception('Failed to generate monthly summary PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate monthly PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

              // Content Area
              Expanded(
                  child: Container(
                      color: Colors.white,
                      child: Column(children: [
                        // Year Selection Bar
                        Container(
                          padding: EdgeInsets.all(24),
                          child: Row(
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Constants.ctaColorLight
                                        .withOpacity(0.3),
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
                                    int year = DateTime.now().year - 2 + index;
                                    return DropdownMenuItem(
                                      value: year,
                                      child: Text(
                                        year.toString(),
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (year) {
                                    if (year != null) {
                                      setState(() {
                                        _selectedYear = year;
                                        _selectedMonth = null;
                                        _selectedMonthRecords.clear();
                                      });
                                      _loadMonthlyReports();
                                    }
                                  },
                                ),
                              ),
                              Spacer(),
                              if (_selectedMonth != null)
                                ElevatedButton.icon(
                                  onPressed: () => _generateMonthlySummaryPDF(
                                    _selectedYear,
                                    _selectedMonth['month'],
                                  ),
                                  icon: Icon(Icons.download, size: 18),
                                  label: Text(
                                      'Download ${_selectedMonth['month_name']} Report'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Constants.ctaColorLight,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Error Display
                        if (_error.isNotEmpty)
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red[600], size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error,
                                    style: GoogleFonts.inter(
                                      color: Colors.red[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Loading or Content
                        if (_isLoading)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Constants.ctaColorLight,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading reports...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Monthly Reports List - Left Panel
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      height: double.infinity,
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_view_month,
                                                color: Constants.ctaColorLight,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Monthly Reports',
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Constants.ctaColorLight
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _selectedYear.toString(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        Constants.ctaColorLight,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: _monthlyReports.length,
                                              itemBuilder: (context, index) {
                                                final month =
                                                    _monthlyReports[index];
                                                final isSelected =
                                                    _selectedMonth == month;

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: CustomCard(
                                                    color: isSelected
                                                        ? Constants
                                                            .ctaColorLight
                                                            .withOpacity(0.3)
                                                        : Colors.white,
                                                    elevation: 6,
                                                    child: ListTile(
                                                      title: Text(
                                                        month['month_name'],
                                                        style:
                                                            GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      subtitle: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Total: ${month['total_maintenance']}',
                                                            style: GoogleFonts
                                                                .inter(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                          Text(
                                                            'Completed: ${month['completed']}',
                                                            style: GoogleFonts
                                                                .inter(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                          Text(
                                                            'Completion Rate: ${month['completion_rate']}%',
                                                            style: GoogleFonts
                                                                .inter(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                        ],
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons
                                                                    .picture_as_pdf,
                                                                color:
                                                                    Colors.red),
                                                            onPressed: () =>
                                                                _generateMonthlySummaryPDF(
                                                                    month[
                                                                        'year'],
                                                                    month[
                                                                        'month']),
                                                            tooltip:
                                                                'Download Monthly PDF',
                                                          ),
                                                        ],
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedMonth =
                                                              month;
                                                        });
                                                        _loadMonthRecords(
                                                            month['year'],
                                                            month['month']);
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 16),

                                  // Maintenance Records for Selected Month
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedMonth != null
                                              ? 'Maintenance Records - ${_selectedMonth['month_name']} ${_selectedMonth['year']}'
                                              : 'Select a month to view records',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Expanded(
                                          child: _selectedMonth == null
                                              ? Center(
                                                  child: Text(
                                                    'Please select a month from the list',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  itemCount:
                                                      _selectedMonthRecords
                                                          .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final record =
                                                        _selectedMonthRecords[
                                                            index];

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .shade300,
                                                              blurRadius: 8,
                                                              offset:
                                                                  Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: ListTile(
                                                          title: Text(
                                                            record['device']
                                                                ['name'],
                                                            style: GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Type: ${record['maintenance_type']['name']}',
                                                                style: GoogleFonts
                                                                    .inter(
                                                                        fontSize:
                                                                            12),
                                                              ),
                                                              Text(
                                                                'Status: ${record['status_display']}',
                                                                style: GoogleFonts
                                                                    .inter(
                                                                        fontSize:
                                                                            12),
                                                              ),
                                                              Text(
                                                                'Date: ${DateTime.parse(record['scheduled_date']).toLocal().toString().split(' ')[0]}',
                                                                style: GoogleFonts
                                                                    .inter(
                                                                        fontSize:
                                                                            12),
                                                              ),
                                                            ],
                                                          ),
                                                          trailing: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                icon: Icon(
                                                                    Icons
                                                                        .picture_as_pdf,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed: () =>
                                                                    _generateDetailedPDF(
                                                                        record[
                                                                            'id']),
                                                                tooltip:
                                                                    'Download Detailed PDF Report',
                                                              ),
                                                              IconButton(
                                                                icon: Icon(
                                                                    Icons
                                                                        .visibility,
                                                                    color: Constants
                                                                        .ctaColorLight),
                                                                onPressed: () {
                                                                  // Navigate to maintenance detail screen
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              MaintenanceDetailScreen(
                                                                        maintenanceId:
                                                                            record['id'],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                tooltip:
                                                                    'View Details',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      ])))
            ])));
  }
}
