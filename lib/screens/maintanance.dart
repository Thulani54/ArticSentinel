import '../widgets/app_tone.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/mobile_screen.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_forms.dart';
import 'schedule_maintenance.dart';
import 'maintenance_ui.dart';
import '../widgets/device_illustration.dart';
import '../onboarding/setup_flow_frame.dart';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/custom_widgets/customCard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/pdf_saver.dart';

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
  int _recordPage = 1, _recordGeneration = 0;
  bool _hasMoreRecords = false, _loadingMoreRecords = false;
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
        MaintenanceEquipment.refresh(force: true),
        _loadDashboardData(),
        _loadMaintenanceRecords(),
        _loadMaintenanceTypes(),
        _loadRemindersData(),
        _loadSchedules(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Check your connection and try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _guardMaintenanceLoad(Future<void> Function() load) async {
    try {
      await load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Check your connection and try again.');
    }
  }

  Future<void> _loadDashboardData() => _guardMaintenanceLoad(() async {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}api/maintenance/dashboard/'),
              headers: await ApiConfig.authHeaders(),
              body: json.encode({
                'business_id': await SharedPrefs.getBusinessId(),
                'date_from': _dateRange?.start.toIso8601String(),
                'date_to': _dateRange?.end.toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 20));
        if (kDebugMode) {}

        if (response.statusCode != 200) {
          throw StateError('Maintenance request failed');
        }
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (!mounted) return;
          setState(() {
            _dashboardData = data['dashboard'];
            _upcomingMaintenance = data['dashboard']['upcoming_maintenance'];
          });
        }
      });

  Future<void> _loadMaintenanceRecords({bool append = false}) async {
    if (append && _loadingMoreRecords) return;
    final generation = append ? _recordGeneration : ++_recordGeneration;
    final page = append ? _recordPage + 1 : 1;
    final filters = Map<String, dynamic>.from(_filters);
    if (append) setState(() => _loadingMoreRecords = true);
    try {
      final response = await http
          .post(Uri.parse('${ApiConfig.baseUrl}api/maintenance/list/'),
              headers: await ApiConfig.authHeaders(),
              body: jsonEncode({
                'business_id': await SharedPrefs.getBusinessId(),
                'filters': filters,
                'page': page,
                'per_page': 50,
              }))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Unavailable');
      final data = jsonDecode(response.body);
      if (!mounted || generation != _recordGeneration) return;
      setState(() {
        final records = List<dynamic>.from(data['maintenance_records']);
        _maintenanceRecords =
            append ? [..._maintenanceRecords, ...records] : records;
        _recordPage = page;
        _hasMoreRecords = data['pagination']?['has_next'] == true;
      });
    } catch (_) {
      if (!mounted || generation != _recordGeneration) return;
      if (append) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to load more records. Please retry.')));
      } else {
        setState(() => _error = 'Check your connection and try again.');
      }
    } finally {
      if (mounted && generation == _recordGeneration)
        setState(() => _loadingMoreRecords = false);
    }
  }

  Future<void> _loadMaintenanceTypes() => _guardMaintenanceLoad(() async {
        final response = await http
            .get(
              Uri.parse('${ApiConfig.baseUrl}api/maintenance/types/'),
              headers: await ApiConfig.authHeaders(),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          throw StateError('Maintenance request failed');
        }
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!mounted) return;
          setState(() {
            _maintenanceTypes = data['maintenance_types'];
          });
        }
      });

  Future<void> _loadRemindersData() => _guardMaintenanceLoad(() async {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}api/maintenance/reminders/'),
              headers: await ApiConfig.authHeaders(),
              body: json.encode({
                'business_id': await SharedPrefs.getBusinessId(),
              }),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          throw StateError('Maintenance request failed');
        }
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _remindersData = data['reminders'] ?? {};
        });
      });

  Future<void> _loadSchedules() => _guardMaintenanceLoad(() async {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}api/maintenance/schedules/'),
              headers: await ApiConfig.authHeaders(),
              body: json.encode({
                'business_id': await SharedPrefs.getBusinessId(),
              }),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          throw StateError('Maintenance request failed');
        }
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _schedules = data['schedules'] ?? [];
        });
      });

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildPhoneMaintenance(context);
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

  Widget _buildPhoneMaintenance(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height - 100,
        child: ColoredBox(
            color: GasPalette.page,
            child: Column(children: [
              const MobileScreenHeader(
                title: 'Maintenance',
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                      color: Tone.bg(const Color(0xFFE9EDF4)),
                      borderRadius: BorderRadius.circular(32)),
                  labelColor: GasPalette.primary,
                  unselectedLabelColor: GasPalette.ink2,
                  labelStyle: gasBody(context)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(height: 36, text: 'Overview'),
                    Tab(height: 36, text: 'Records'),
                    Tab(height: 36, text: 'Scheduling'),
                    Tab(height: 36, text: 'Reminders'),
                    Tab(height: 36, text: 'Analytics'),
                    Tab(height: 36, text: 'Settings')
                  ],
                ),
              ),
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
                                _buildSettingsTab()
                              ],
                            )),
            ])),
      );
    });
  }

  Widget _buildHeader() {
    return const CompactHeader(
      title: "Maintenance",
      description: "Schedule and track maintenance tasks",
      icon: Icons.build_rounded,
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Tone.bg(const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tone.bg(const Color(0xFFE2E8F0)), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Tone.bg(Colors.black).withOpacity(0.08),
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
        unselectedLabelColor: Tone.fg(const Color(0xFF64748B)),
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
    final summary = _dashboardData['summary'] is Map
        ? _dashboardData['summary'] as Map
        : const {};
    final records =
        _maintenanceRecords.whereType<Map<String, dynamic>>().toList();
    final late = records.where(maintenanceIsLate).toList();
    final weekEnd = DateTime.now().add(const Duration(days: 7));
    final upcoming = _upcomingMaintenance
        .whereType<Map<String, dynamic>>()
        .where((r) => !maintenanceIsLate(r))
        .toList();
    final thisWeek = upcoming.where((r) {
      final at = DateTime.tryParse('${r['scheduled_date']}');
      return at != null && at.isBefore(weekEnd);
    }).length;
    final completed =
        records.where((r) => r['status'] == 'completed').take(3).toList();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    Widget list(List<Map<String, dynamic>> items, String empty) => items.isEmpty
        ? Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Tone.bg(Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GasPalette.border)),
            child: Text(empty,
                style:
                    GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
          )
        : Column(children: [
            for (final r in items) _buildMaintenanceCard(r, isCompact: true)
          ]);

    final attention = [
      MaintenanceSectionHeader(
          title: 'Needs attention',
          subtitle: late.isEmpty
              ? 'Nothing overdue'
              : '${late.length} overdue job${late.length == 1 ? '' : 's'}'),
      list(late.take(4).toList(), 'All caught up — no overdue maintenance.'),
    ];
    final comingUp = [
      MaintenanceSectionHeader(
          title: 'Coming up',
          subtitle: thisWeek == 0
              ? 'Nothing due this week'
              : '$thisWeek due in the next 7 days',
          action: TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('All records'))),
      if (upcoming.isEmpty)
        _buildEmptyState('No upcoming maintenance scheduled')
      else
        list(upcoming.take(5).toList(), ''),
    ];
    final recent = [
      const MaintenanceSectionHeader(title: 'Recently completed'),
      list(completed, 'Completed jobs will appear here.'),
    ];

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            MaintenanceStatTile(
                value:
                    '${late.isNotEmpty ? late.length : summary['overdue_maintenance'] ?? 0}',
                label: 'Overdue',
                icon: Iconsax.danger,
                tone: late.isNotEmpty ? GasPalette.critInk : null,
                onTap: _showOverdueItems),
            const SizedBox(width: 10),
            MaintenanceStatTile(
                value: '$thisWeek',
                label: 'Due this week',
                icon: Iconsax.calendar_1),
            const SizedBox(width: 10),
            MaintenanceStatTile(
                value: '${summary['completed_maintenance'] ?? 0}',
                label: 'Completed',
                icon: Iconsax.tick_circle,
                tone: GasPalette.goodInk),
            if (wide) ...[
              const SizedBox(width: 10),
              MaintenanceStatTile(
                  value: '${summary['total_maintenance'] ?? 0}',
                  label: 'Last 30 days',
                  icon: Iconsax.chart_2),
            ],
          ]),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _showCreateMaintenanceDialog,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Schedule maintenance'),
            style: FilledButton.styleFrom(
                backgroundColor: GasPalette.primary,
                foregroundColor: Tone.fg(Colors.white),
                minimumSize: const Size.fromHeight(50),
                shape: const StadiumBorder()),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(
                avatar: const Icon(Iconsax.repeat, size: 17),
                label: const Text('Recurring schedule'),
                onPressed: _showCreateScheduleDialog),
            ActionChip(
                avatar: const Icon(Iconsax.document_text, size: 17),
                label: const Text('Reports'),
                onPressed: _showReportsDialog),
            ActionChip(
                avatar: const Icon(Iconsax.danger, size: 17),
                label: const Text('Overdue'),
                onPressed: _showOverdueItems),
            ActionChip(
                avatar: const Icon(Iconsax.category, size: 17),
                label: const Text('Types'),
                onPressed: _showMaintenanceTypes),
          ]),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: comingUp)),
              const SizedBox(width: 20),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [...attention, ...recent])),
            ])
          else ...[
            if (late.isNotEmpty) ...attention,
            ...comingUp,
            ...recent,
          ],
        ]),
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
              ? SingleChildScrollView(
                  child: _buildEmptyState('No maintenance records found'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount:
                      _maintenanceRecords.length + (_hasMoreRecords ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _maintenanceRecords.length)
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: OutlinedButton(
                              onPressed: _loadingMoreRecords
                                  ? null
                                  : () => _loadMaintenanceRecords(append: true),
                              child: Text(_loadingMoreRecords
                                  ? 'Loading…'
                                  : 'Load more records')));
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: isPhoneLayout(context) ? GasPalette.page : Tone.bg(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_maintenanceRecords.length}${_hasMoreRecords ? '+' : ''} job${_maintenanceRecords.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: GasPalette.ink),
              ),
              const Spacer(),
              if (_filters.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters.clear();
                      _dateRange = null;
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
              : Tone.bg(Colors.grey[100]),
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 32 : 20),
          border: Border.all(
            color: _filters.containsKey(key)
                ? Constants.ctaColorLight
                : Tone.bg(Colors.grey[300]),
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
                    : Tone.fg(Colors.grey[700]),
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
              : Tone.bg(Colors.grey[100]),
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 32 : 20),
          border: Border.all(
            color: _dateRange != null
                ? Constants.ctaColorLight
                : Tone.bg(Colors.grey[300]),
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
                  : Tone.fg(Colors.grey[600]),
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
                    : Tone.fg(Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Records, upcoming jobs and reminders all use the shared job card.
  Widget _buildMaintenanceCard(Map<String, dynamic> maintenance,
      {bool isCompact = false}) {
    final status = maintenance['status'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MaintenanceJobCard(
        record: maintenance,
        compact: isCompact,
        onOpen: () => _showMaintenanceDetails(maintenance),
        onStart: status == 'scheduled' || status == 'overdue'
            ? () => _updateMaintenanceStatus('${maintenance['id']}', 'start')
            : null,
        onComplete: status == 'in_progress'
            ? () => _updateMaintenanceStatus('${maintenance['id']}', 'complete')
            : null,
      ),
    );
  }

  Widget _buildSchedulingTab() {
    final active =
        _schedules.where((x) => x is Map && x['is_active'] == true).length;
    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MaintenanceSectionHeader(
            title: 'Recurring schedules',
            subtitle: _schedules.isEmpty
                ? 'Repeat routine jobs automatically'
                : '$active active of ${_schedules.length}',
            action: FilledButton.icon(
              onPressed: _showCreateScheduleDialog,
              style: FilledButton.styleFrom(
                  backgroundColor: GasPalette.primary,
                  foregroundColor: Tone.fg(Colors.white),
                  shape: const StadiumBorder()),
              icon: const Icon(Iconsax.repeat, size: 18),
              label: const Text('New schedule'),
            ),
          ),
          const SetupNote(
            icon: Iconsax.magicpen,
            title: 'Jobs create themselves',
            text:
                'Each schedule adds its next job 3 days before it’s due, at 09:00, and the usual reminders follow. '
                'Use “Create due jobs now” if you don’t want to wait.',
          ),
          const SizedBox(height: 12),
          if (_schedules.isEmpty)
            _buildEmptyState('No recurring schedules yet')
          else
            for (final schedule in _schedules.whereType<Map>())
              _scheduleCard(Map<String, dynamic>.from(schedule)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _generateScheduledMaintenance,
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              icon: const Icon(Iconsax.flash_1, size: 18),
              label: const Text('Create due jobs now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic> schedule) {
    final isActive = schedule['is_active'] == true;
    final device = MaintenanceEquipment.of(schedule['device']);
    final deviceName =
        '${schedule['device'] is Map ? schedule['device']['name'] : 'Equipment'}';
    final unit = device?.connectedUnit?.name;
    final type =
        '${schedule['maintenance_type'] is Map ? schedule['maintenance_type']['name'] : 'Maintenance'}';
    final frequency = schedule['frequency'] == 'custom'
        ? 'Every ${schedule['custom_frequency_days']} days'
        : '${schedule['frequency_display'] ?? schedule['frequency']}';
    final next = DateTime.tryParse('${schedule['next_due']}');
    final assignee = schedule['auto_assign_to'] is Map
        ? '${schedule['auto_assign_to']['name'] ?? schedule['auto_assign_to']['full_name'] ?? ''}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Tone.bg(Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GasPalette.border)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Opacity(
              opacity: isActive ? 1 : .45,
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: GasPalette.panelAlt,
                    borderRadius: BorderRadius.circular(12)),
                child: DeviceIllustration(type: device?.deviceType, size: 40),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type,
                        style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: GasPalette.ink)),
                    Text(unit == null ? deviceName : '$unit · $deviceName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: GasPalette.ink2)),
                  ]),
            ),
            PopupMenuButton<String>(
              tooltip: 'Schedule options',
              onSelected: (value) {
                if (value == 'toggle')
                  _toggleScheduleStatus('${schedule['id']}', !isActive);
                if (value == 'delete') _deleteSchedule('${schedule['id']}');
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'toggle',
                    child:
                        Text(isActive ? 'Pause schedule' : 'Resume schedule')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete schedule',
                        style: TextStyle(color: GasPalette.critInk))),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            MaintenancePill(
                text: frequency,
                bg: GasPalette.seriesSoft,
                fg: GasPalette.series,
                icon: Iconsax.repeat),
            isActive
                ? MaintenancePill(
                    text: next == null
                        ? 'Next job: not set'
                        : 'Next job ${DateFormat('EEE d MMM').format(next)}',
                    bg: GasPalette.panelAlt,
                    fg: GasPalette.ink,
                    icon: Iconsax.calendar_1)
                : MaintenancePill(
                    text: 'Paused',
                    bg: GasPalette.warnSoft,
                    fg: GasPalette.warnInk,
                    icon: Iconsax.pause_circle),
            if (assignee.trim().isNotEmpty)
              MaintenancePill(
                  text: assignee,
                  bg: GasPalette.panelAlt,
                  fg: GasPalette.ink2,
                  icon: Iconsax.user),
          ]),
        ]),
      ),
    );
  }

  Future<void> _toggleScheduleStatus(String scheduleId, bool isActive) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/schedule/$scheduleId/update/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({'is_active': isActive}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Request failed');
      if (!mounted) return;
      if (response.statusCode == 200) {
        _loadSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Schedule ${isActive ? 'activated' : 'deactivated'}'),
              backgroundColor: Tone.bg(Colors.green)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating schedule'),
            backgroundColor: Tone.bg(Colors.red)),
      );
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final confirm = await showMobileDialog<bool>(
      context: context,
      builder: (context) => MobileAlertDialog(
        title: Text('Delete Schedule'),
        content: Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Tone.fg(Colors.red))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await http
          .delete(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/schedule/$scheduleId/delete/'),
            headers: await ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Request failed');
      if (!mounted) return;
      if (response.statusCode == 200) {
        _loadSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Schedule deleted'), backgroundColor: Tone.bg(Colors.green)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting schedule'),
            backgroundColor: Tone.bg(Colors.red)),
      );
    }
  }

  Widget _buildAnalyticsTab() {
    final cost = _dashboardData['cost_analysis'] is Map
        ? _dashboardData['cost_analysis'] as Map
        : const {};
    final duration = _dashboardData['duration_analysis'] is Map
        ? _dashboardData['duration_analysis'] as Map
        : const {};
    final summary = _dashboardData['summary'] is Map
        ? _dashboardData['summary'] as Map
        : const {};
    final breakdowns = _dashboardData['breakdowns'] is Map
        ? _dashboardData['breakdowns'] as Map
        : const {};
    final money = NumberFormat.currency(symbol: 'R ', decimalDigits: 0);
    double n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final variance = n(cost['cost_variance']);
    final period = _dashboardData['period'];
    final from =
        period is Map ? DateTime.tryParse('${period['date_from']}') : null;
    final to = period is Map ? DateTime.tryParse('${period['date_to']}') : null;

    Widget pair(Widget a, Widget b) =>
        Row(children: [a, const SizedBox(width: 10), b]);

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
              from != null && to != null
                  ? 'Last 30 days · ${DateFormat('d MMM').format(from)} – ${DateFormat('d MMM').format(to)}'
                  : 'Last 30 days',
              style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
          const MaintenanceSectionHeader(
              title: 'Costs',
              subtitle: 'Actual against estimated, for jobs in this period'),
          pair(
            MaintenanceStatTile(
                value: money.format(n(cost['total_cost'])),
                label: 'Spent',
                icon: Iconsax.wallet_2),
            MaintenanceStatTile(
                value: money.format(n(cost['total_estimated'])),
                label: 'Estimated',
                icon: Iconsax.receipt_2),
          ),
          const SizedBox(height: 10),
          pair(
            MaintenanceStatTile(
                value: money.format(n(cost['avg_cost'])),
                label: 'Average per job',
                icon: Iconsax.calculator),
            MaintenanceStatTile(
                value: '${variance > 0 ? '+' : ''}${money.format(variance)}',
                label: variance > 0 ? 'Over estimate' : 'Under or on estimate',
                icon: Iconsax.chart_1,
                tone: variance > 0 ? GasPalette.critInk : GasPalette.goodInk),
          ),
          const MaintenanceSectionHeader(title: 'Time and completion'),
          pair(
            MaintenanceStatTile(
                value: '${n(duration['total_hours']).toStringAsFixed(1)} h',
                label: 'Hours worked',
                icon: Iconsax.clock),
            MaintenanceStatTile(
                value: '${n(duration['avg_hours']).toStringAsFixed(1)} h',
                label: 'Average job',
                icon: Iconsax.timer_1),
          ),
          const SizedBox(height: 10),
          pair(
            MaintenanceStatTile(
                value: '${n(summary['completion_rate']).toStringAsFixed(0)}%',
                label: 'Completed',
                icon: Iconsax.tick_circle,
                tone: GasPalette.goodInk),
            MaintenanceStatTile(
                value: '${n(summary['on_time_rate']).toStringAsFixed(0)}%',
                label: 'On time',
                icon: Iconsax.calendar_tick),
          ),
          _breakdown('By status', breakdowns['by_status']),
          _breakdown('By type', breakdowns['by_type']),
          _breakdown('By equipment', breakdowns['by_device']),
        ],
      ),
    );
  }

  Widget _breakdown(String title, dynamic raw) {
    final rows = (raw is List ? raw : const []).whereType<Map>().toList();
    String label(Map item) {
      final v = item['status_display'] ??
          item['status'] ??
          item['name'] ??
          item['maintenance_type__name'] ??
          item['device__name'] ??
          'Other';
      final text = '$v'.replaceAll('_', ' ');
      return text.isEmpty
          ? 'Other'
          : '${text[0].toUpperCase()}${text.substring(1)}';
    }

    final max = rows.fold<num>(
        1,
        (m, r) =>
            (r['count'] is num && r['count'] > m) ? r['count'] as num : m);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MaintenanceSectionHeader(title: title),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Tone.bg(Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GasPalette.border)),
        child: rows.isEmpty
            ? Text('No jobs in this period yet.',
                style:
                    GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2))
            : Column(children: [
                for (final r in rows.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      SizedBox(
                        width: 120,
                        child: Text(label(r),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: GasPalette.ink)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: ((r['count'] as num?) ?? 0) / max,
                            minHeight: 10,
                            backgroundColor: GasPalette.panelAlt,
                            color: GasPalette.series,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 28,
                        child: Text('${r['count'] ?? 0}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: GasPalette.ink)),
                      ),
                    ]),
                  ),
              ]),
      ),
    ]);
  }

  /// Reminder rows are flat; shape them like records for the job card.
  Map<String, dynamic> _reminderAsRecord(Map r) => {
        'id': r['id'],
        'device': {'device_id': r['device_id'], 'name': r['device_name']},
        'maintenance_type': {'name': r['maintenance_type']},
        'scheduled_date': r['scheduled_date'],
        'status': r['status'],
        'status_display': r['status_display'],
        'priority': r['priority'],
        'priority_display': r['priority_display'],
        'assigned_to': r['assigned_to'] is String
            ? {'full_name': r['assigned_to']}
            : r['assigned_to'],
        'work_description': r['work_description'],
      };

  String _nextReminder(dynamic scheduled) {
    final at = DateTime.tryParse('$scheduled')?.toLocal();
    if (at == null) return '';
    final h = at.difference(DateTime.now()).inMinutes / 60;
    if (h <= 0) return 'Daily overdue reminders';
    if (h <= 3) return '3-hour reminder sent or due now';
    if (h <= 24) return 'Next: day-before reminder';
    if (h <= 48) return 'Next: 2-day reminder';
    if (h <= 72) return 'Next: 3-day reminder';
    return 'First reminder ${DateFormat('EEE d MMM').format(at.subtract(const Duration(days: 3)))}';
  }

  Widget _buildRemindersTab() {
    final summary = _remindersData['summary'] is Map
        ? Map<String, dynamic>.from(_remindersData['summary'])
        : <String, dynamic>{};
    final upcoming = (_remindersData['upcoming'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final overdue = (_remindersData['overdue'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final sent = (_remindersData['sent_reminders'] as List? ?? const [])
        .whereType<Map>()
        .toList();

    Widget step(String when, String label, {bool late = false}) =>
        Column(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: late ? GasPalette.critSoft : GasPalette.seriesSoft,
                shape: BoxShape.circle),
            child: Icon(late ? Iconsax.danger : Iconsax.notification,
                size: 17, color: late ? GasPalette.critInk : GasPalette.series),
          ),
          const SizedBox(height: 4),
          Text(when,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GasPalette.ink)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: GasPalette.ink2)),
        ]);

    Widget job(Map r, {bool late = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MaintenanceJobCard(
                record: _reminderAsRecord(r),
                compact: true,
                onOpen: () => _showMaintenanceDetails(_reminderAsRecord(r))),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(_nextReminder(r['scheduled_date']),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: late ? GasPalette.critInk : GasPalette.ink2)),
            ),
          ]),
        );

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            MaintenanceStatTile(
                value: '${summary['upcoming_count'] ?? upcoming.length}',
                label: 'Upcoming',
                icon: Iconsax.calendar_1),
            const SizedBox(width: 10),
            MaintenanceStatTile(
                value: '${summary['overdue_count'] ?? overdue.length}',
                label: 'Overdue',
                icon: Iconsax.danger,
                tone: overdue.isNotEmpty ? GasPalette.critInk : null),
            const SizedBox(width: 10),
            MaintenanceStatTile(
                value:
                    '${summary['reminders_sent_today'] ?? summary['sent_today'] ?? 0}',
                label: 'Sent today',
                icon: Iconsax.sms),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Tone.bg(Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GasPalette.border)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('How reminders work',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GasPalette.ink)),
                  const SizedBox(height: 4),
                  Text(
                      'Emails go to the person assigned, the account owner, administrators and managers.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: GasPalette.ink2)),
                  const SizedBox(height: 14),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        step('3 days', 'before'),
                        step('2 days', 'before'),
                        step('1 day', 'before'),
                        step('3 hours', 'before'),
                        step('Late', 'daily ×3', late: true),
                      ]),
                ]),
          ),
          if (overdue.isNotEmpty) ...[
            MaintenanceSectionHeader(
                title: 'Overdue', subtitle: 'Reminded daily for 3 days'),
            for (final r in overdue) job(r, late: true),
          ],
          const MaintenanceSectionHeader(title: 'Upcoming'),
          if (upcoming.isEmpty)
            _buildEmptyState('No upcoming maintenance')
          else
            for (final r in upcoming) job(r),
          const MaintenanceSectionHeader(title: 'Recently sent'),
          if (sent.isEmpty)
            _buildEmptyState('No reminders sent recently')
          else
            for (final r in sent.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    backgroundColor: GasPalette.goodSoft,
                    child: Icon(Iconsax.sms_tracking,
                        color: GasPalette.goodInk, size: 18)),
                title: Text(
                    '${r['maintenance_type'] ?? 'Maintenance'} · ${r['device_name'] ?? ''}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GasPalette.ink)),
                subtitle: Text(
                    'Sent ${_formatReminderDate(r['reminder_sent_at'])}',
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: GasPalette.ink2)),
              ),
        ],
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
    final types = _maintenanceTypes.whereType<Map>().toList();
    final byCategory = <String, List<Map>>{};
    for (final t in types) {
      byCategory
          .putIfAbsent(
              '${t['category_display'] ?? t['category'] ?? 'Other'}', () => [])
          .add(t);
    }
    Widget tool(IconData icon, String title, String text, int tab) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundColor: GasPalette.seriesSoft,
              child: Icon(icon, color: GasPalette.series, size: 20)),
          title: Text(title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: GasPalette.ink)),
          subtitle: Text(text,
              style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _tabController.animateTo(tab),
        );
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MaintenanceSectionHeader(
            title: 'Maintenance types',
            subtitle: '${types.length} available to schedule',
            action: IconButton(
                tooltip: 'Refresh types',
                onPressed: _loadMaintenanceTypes,
                icon: const Icon(Iconsax.refresh)),
          ),
          if (types.isEmpty)
            _buildEmptyState('No maintenance types are set up yet')
          else
            for (final entry in byCategory.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(entry.key,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GasPalette.ink2)),
              ),
              Material(
                color: Tone.bg(Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: GasPalette.border)),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final t in entry.value)
                    ListTile(
                      title: Text('${t['name'] ?? ''}',
                          style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: GasPalette.ink)),
                      subtitle: '${t['description'] ?? ''}'.isEmpty
                          ? null
                          : Text('${t['description']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12.5, color: GasPalette.ink2)),
                      trailing: t['estimated_duration_hours'] == null
                          ? null
                          : MaintenancePill(
                              text: '≈ ${t['estimated_duration_hours']} h',
                              bg: GasPalette.panelAlt,
                              fg: GasPalette.ink2,
                              icon: Iconsax.clock),
                    ),
                ]),
              ),
            ],
          const MaintenanceSectionHeader(title: 'Tools'),
          Material(
              color: Tone.bg(Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: GasPalette.border)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(children: [
                  tool(Iconsax.repeat, 'Recurring schedules',
                      'Repeat routine jobs automatically', 2),
                  tool(Iconsax.notification, 'Reminders',
                      'Who is reminded, and when', 3),
                  tool(Iconsax.chart_2, 'Analytics',
                      'Costs, hours and completion', 4),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    if (isPhoneLayout(context)) {
      return AppEmptyState(
        kind: AppEmptyStateKind.records,
        icon: Icons.event_available_outlined,
        title: message,
        message: 'Maintenance activity will appear here when available.',
        compact: true,
      );
    }
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Tone.fg(Colors.grey[400]),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Tone.fg(Colors.grey[600]),
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
            style: GoogleFonts.inter(color: Tone.fg(Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    if (isPhoneLayout(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppEmptyState(
          kind: AppEmptyStateKind.offline,
          title: 'Unable to load maintenance',
          message: _error,
          actionLabel: 'Retry',
          onAction: _loadInitialData,
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Tone.fg(Colors.red)),
          SizedBox(height: 16),
          Text(
            _error,
            style: GoogleFonts.inter(color: Tone.fg(Colors.red)),
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

  // Action Methods
  Future<void> _updateMaintenanceStatus(String id, String action) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}api/maintenance/$id/status/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'action': action,
              'user_id': await SharedPrefs.getUserId(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) throw StateError('Request failed');
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance status updated successfully'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadInitialData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Unable to update status. Check your connection and retry.'),
          backgroundColor: Tone.bg(Colors.red),
        ),
      );
    }
  }

  Future<void> _generateScheduledMaintenance() async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}api/maintenance/schedule/generate/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'business_id': await SharedPrefs.getBusinessId(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) throw StateError('Request failed');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Generated ${data['generated_count']} maintenance records'),
            backgroundColor: Constants.ctaColorLight,
          ),
        );
        _loadInitialData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Unable to generate maintenance. Check your connection and retry.'),
          backgroundColor: Tone.bg(Colors.red),
        ),
      );
    }
  }

  Future<void> _showMaintenanceDetails(Map<String, dynamic> maintenance) async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) => MaintenanceDetailScreen(
            maintenanceId: maintenance['id'].toString())));
    if (mounted) await _loadInitialData();
  }

  /// The guided scheduling flow (schedule_maintenance.dart): unit or
  /// device, what and when, then review.
  Future<void> _showCreateMaintenanceDialog() async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const ScheduleMaintenanceScreen()));
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Maintenance scheduled')));
      await _loadInitialData();
    }
  }

  Future<void> _showCreateScheduleDialog() async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const ScheduleMaintenanceScreen(recurring: true)));
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring schedule created')));
      await _loadInitialData();
    }
  }

  void _showReportsDialog() {
    showMobileDialog(
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
    _tabController.animateTo(5); // Go to Settings tab
  }
}

// Supporting Classes
class ApiConfig {
  static String baseUrl = Constants.articBaseUrl2;
  static Future<Map<String, String>> authHeaders() async {
    final token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Token $token'
    };
  }
}

class SharedPrefs {
  static Future<String> getBusinessId() async {
    // Return business ID from shared preferences
    return Constants.myBusiness.businessUid.toString();
  }

  static Future<int> getUserId() async {
    // Return user ID from shared preferences
    final userId = await Sharedprefs.getUserUidSharedPreference();
    if (userId == null) throw StateError('Sign in again to continue.');
    return userId;
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
  bool _updatingStatus = false;
  String _error = '';
  Map<String, dynamic> _maintenance = {};
  List<dynamic> _checklistItems = [];
  // Kept across rebuilds so typed text isn't lost.
  final _quickChecklist = TextEditingController();
  final _newPart = TextEditingController();
  final _newMaterial = TextEditingController();
  bool _docsDirty = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMaintenanceDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickChecklist.dispose();
    _newPart.dispose();
    _newMaterial.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceDetail() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      unawaited(MaintenanceEquipment.refresh().then((_) {
        if (mounted) setState(() {});
      }));
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/'),
            headers: await ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!mounted) return;
        setState(() {
          _maintenance = data['maintenance'];
          _checklistItems = data['maintenance']['checklist_items'] ?? [];
        });
      } else {
        throw Exception('Failed to load maintenance details');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Check your connection and try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tone.bg(Colors.white),
      appBar: AppBar(
        title: Text(
          'Maintenance Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Constants.ctaColorLight,
          ),
        ),
        backgroundColor: Tone.bg(Colors.white),
        surfaceTintColor: Tone.bg(Colors.white),
        foregroundColor: Constants.ctaColorLight,
        elevation: 2,
        shadowColor: Tone.bg(Colors.black).withOpacity(0.1),
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
                if (['scheduled', 'cancelled'].contains(_maintenance['status']))
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Constants.ctaColorLight,
                labelColor: Constants.ctaColorLight,
                unselectedLabelColor: Tone.fg(Colors.grey),
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
              ? isPhoneLayout(context)
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AppEmptyState(
                        kind: AppEmptyStateKind.offline,
                        title: 'Unable to load maintenance details',
                        message: _error,
                        actionLabel: 'Retry',
                        onAction: _loadMaintenanceDetail,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Tone.fg(Colors.red), size: 48),
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

  String _person(dynamic p, String fallback) {
    if (p is! Map) return fallback;
    final name = '${p['full_name'] ?? ''}'.trim();
    return name.isNotEmpty ? name : '${p['username'] ?? fallback}';
  }

  Widget _buildOverviewTab() {
    final m = _maintenance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildInfoSection('People', [
            _buildInfoRow('Assigned to', _person(m['assigned_to'], 'Unassigned')),
            _buildInfoRow('Performed by', _person(m['performed_by'], 'Not started')),
            _buildInfoRow('Supervised by', _person(m['supervised_by'], 'None')),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Work', [
            _buildInfoText('Description', '${m['work_description'] ?? ''}'),
            if ('${m['work_performed'] ?? ''}'.isNotEmpty) _buildInfoText('Work performed', '${m['work_performed']}'),
            if ('${m['issues_found'] ?? ''}'.isNotEmpty) _buildInfoText('Issues found', '${m['issues_found']}'),
            if ('${m['resolution_notes'] ?? ''}'.isNotEmpty) _buildInfoText('Resolution', '${m['resolution_notes']}'),
          ]),
          const SizedBox(height: 16),
          _buildCostDurationSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// The job at a glance: what, which equipment, when, state and who.
  Widget _buildStatusCard() {
    final m = _maintenance;
    final device = MaintenanceEquipment.of(m['device']);
    final unit = device?.connectedUnit?.name;
    final status = '${m['status'] ?? 'scheduled'}';
    final late = maintenanceIsLate(m);
    final st = maintenanceStatusStyle(late ? 'overdue' : status);
    final pr = maintenancePriorityStyle('${m['priority']}');
    final category = m['maintenance_type'] is Map ? '${m['maintenance_type']['category_display'] ?? ''}' : '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: late ? GasPalette.critLine : GasPalette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: GasPalette.panelAlt, borderRadius: BorderRadius.circular(16)),
            child: DeviceIllustration(type: device?.deviceType, size: 52),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m['maintenance_type']?['name'] ?? 'Maintenance'}',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: GasPalette.ink)),
              Text(unit == null ? '${m['device']?['name'] ?? ''}' : '$unit · ${m['device']?['name'] ?? ''}',
                  style: GoogleFonts.inter(fontSize: 14, color: GasPalette.ink2)),
              if (category.isNotEmpty) Text(category, style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(late ? Iconsax.danger : Iconsax.calendar_1, size: 17, color: late ? GasPalette.critInk : GasPalette.ink2),
          const SizedBox(width: 8),
          Text(maintenanceWhen(m['scheduled_date'], done: status == 'completed' || status == 'cancelled'),
              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: late ? GasPalette.critInk : GasPalette.ink)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          MaintenancePill(text: late ? 'Overdue' : '${m['status_display'] ?? status}', bg: st.bg, fg: st.fg, icon: st.icon),
          MaintenancePill(text: '${m['priority_display'] ?? m['priority']} priority', bg: pr.bg, fg: pr.fg),
        ]),
      ]),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
          color: Tone.bg(Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: GasPalette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: GasPalette.ink)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 120,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
        ),
        Expanded(
          child: Text(value.isEmpty ? '—' : value,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: GasPalette.ink)),
        ),
      ]),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
        const SizedBox(height: 4),
        Text(value.trim().isEmpty ? '—' : value,
            style: GoogleFonts.inter(fontSize: 14.5, height: 1.45, color: GasPalette.ink)),
      ]),
    );
  }

  Widget _buildCostDurationSection() {
    final m = _maintenance;
    final money = NumberFormat.currency(symbol: 'R ', decimalDigits: 0);
    double? n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    String rand(dynamic v) => n(v) == null ? '—' : money.format(n(v));
    String hours(dynamic v) => n(v) == null ? '—' : '${n(v)!.toStringAsFixed(1)} h';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Cost and time', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: GasPalette.ink)),
      const SizedBox(height: 10),
      Row(children: [
        MaintenanceStatTile(value: rand(m['estimated_cost']), label: 'Estimated cost', icon: Iconsax.receipt_2),
        const SizedBox(width: 10),
        MaintenanceStatTile(value: rand(m['actual_cost']), label: 'Actual cost', icon: Iconsax.wallet_2),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        MaintenanceStatTile(value: hours(m['estimated_duration_hours']), label: 'Estimated time', icon: Iconsax.timer_1),
        const SizedBox(width: 10),
        MaintenanceStatTile(value: hours(m['actual_duration_hours']), label: 'Actual time', icon: Iconsax.clock),
      ]),
    ]);
  }

  Widget _buildChecklistTab() {
    final canModify = _maintenance['status'] == 'in_progress';
    final items = _checklistItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final done = items.where((i) => i['is_completed'] == true).length;
    final criticalLeft = items.where((i) => i['is_critical'] == true && i['is_completed'] != true).length;
    final complete = items.isNotEmpty && done == items.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Tone.bg(Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: GasPalette.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text('Checklist', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: GasPalette.ink)),
              ),
              Text(items.isEmpty ? 'No items' : '$done of ${items.length} done',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: complete ? GasPalette.goodInk : GasPalette.ink)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _getCompletionPercentage(),
                minHeight: 8,
                backgroundColor: GasPalette.panelAlt,
                color: complete ? GasPalette.good : GasPalette.series,
              ),
            ),
            if (criticalLeft > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Iconsax.danger, size: 16, color: GasPalette.critInk),
                const SizedBox(width: 6),
                Expanded(child: Text('$criticalLeft critical item${criticalLeft == 1 ? '' : 's'} left before the job can be completed',
                    style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.critInk))),
              ]),
            ],
            if (!canModify) ...[
              const SizedBox(height: 10),
              Text(
                  _maintenance['status'] == 'completed'
                      ? 'This job is complete; the checklist is read-only.'
                      : 'Start the job to tick items off or add new ones.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
            ],
          ]),
        ),
        if (canModify) ...[
          const SizedBox(height: 12),
          _buildQuickAddChecklistItem(),
        ],
        const SizedBox(height: 12),
        if (items.isEmpty)
          _buildEmptyChecklistState(canModify)
        else
          for (final item in items) _buildChecklistItem(item, canModify),
      ],
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, bool canModifyChecklist) {
    final isCompleted = item['is_completed'] == true;
    final isCritical = item['is_critical'] == true;
    final notes = '${item['notes'] ?? ''}'.trim();
    final by = item['completed_by'] is Map
        ? '${item['completed_by']['full_name'] ?? item['completed_by']['username'] ?? ''}'
        : '${item['completed_by'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isCompleted ? GasPalette.panelAlt : Tone.bg(Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isCritical && !isCompleted ? GasPalette.critLine : GasPalette.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canModifyChecklist ? () => _toggleChecklistItem(item) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                key: ValueKey('checklist-${item['id']}'),
                value: isCompleted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                activeColor: GasPalette.good,
                onChanged: canModifyChecklist ? (_) => _toggleChecklistItem(item) : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${item['description'] ?? item['item_description'] ?? ''}',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? GasPalette.ink2 : GasPalette.ink,
                            decoration: isCompleted ? TextDecoration.lineThrough : null)),
                    if (isCritical) ...[
                      const SizedBox(height: 6),
                      MaintenancePill(text: 'Critical', bg: GasPalette.critSoft, fg: GasPalette.critInk, icon: Iconsax.danger),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(notes, style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
                    ],
                    if (isCompleted && by.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Iconsax.tick_circle, size: 14, color: GasPalette.goodInk),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              'Done by $by${item['completed_at'] == null ? '' : ' · ${maintenanceWhen(item['completed_at'], done: true)}'}',
                              style: GoogleFonts.inter(fontSize: 12, color: GasPalette.goodInk)),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),
              if (canModifyChecklist)
                IconButton(
                  tooltip: 'Item options',
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: GasPalette.ink2),
                  onPressed: () => _showChecklistItemOptions(item),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChecklistState(bool canModifyChecklist) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(Iconsax.task_square, size: 40, color: GasPalette.series),
        const SizedBox(height: 10),
        Text('No checklist items', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: GasPalette.ink)),
        const SizedBox(height: 4),
        Text(
            canModifyChecklist
                ? 'Add the steps the technician should tick off.'
                : 'Checklist steps added to this job appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
      ]),
    );
  }

  Widget _buildQuickAddChecklistItem() {
    void add() {
      final text = _quickChecklist.text.trim();
      if (text.isEmpty) return;
      _addChecklistItemQuick(text);
      _quickChecklist.clear();
    }

    return Row(children: [
      Expanded(
        child: TextField(
          controller: _quickChecklist,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => add(),
          decoration: InputDecoration(
            hintText: 'Add a checklist step',
            prefixIcon: const Icon(Iconsax.add_square, size: 20),
            filled: true,
            fillColor: Tone.bg(Colors.white),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide(color: GasPalette.border)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide(color: GasPalette.border)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        tooltip: 'Add step',
        style: IconButton.styleFrom(backgroundColor: GasPalette.primary, foregroundColor: Tone.fg(Colors.white)),
        onPressed: add,
        icon: const Icon(Icons.add),
      ),
      IconButton(
        tooltip: 'Add with options (critical, notes)',
        onPressed: _showAddChecklistItemDialog,
        icon: const Icon(Iconsax.setting_4),
      ),
    ]);
  }

  Widget _buildObservationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      child: Column(
        children: [
          _buildObservationsSection(
              true), // Always allow editing in this dedicated tab
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    final m = _maintenance;
    DateTime? t(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
    String who(dynamic v) => v is Map ? '${v['full_name'] ?? v['username'] ?? ''}' : '${v ?? ''}';
    final events = <({DateTime? at, String title, String detail, IconData icon, Color color, bool pending})>[];
    void add(DateTime? at, String title, String detail, IconData icon, Color color, {bool pending = false}) =>
        events.add((at: at, title: title, detail: detail, icon: icon, color: color, pending: pending));

    add(t(m['created_at']), 'Job created', '', Iconsax.add_circle, GasPalette.ink2);
    final scheduled = t(m['scheduled_date']);
    add(scheduled, 'Scheduled', who(m['assigned_to']).isEmpty ? 'Unassigned' : 'Assigned to ${who(m['assigned_to'])}',
        Iconsax.calendar_1, GasPalette.series,
        pending: scheduled != null && scheduled.isAfter(DateTime.now()) && m['actual_start_date'] == null);
    if (m['actual_start_date'] != null) {
      add(t(m['actual_start_date']), 'Started', who(m['performed_by']), Iconsax.play_circle, GasPalette.series);
    }
    for (final item in _checklistItems.whereType<Map>()) {
      if (item['is_completed'] == true && item['completed_at'] != null) {
        add(t(item['completed_at']), 'Checked: ${item['description'] ?? item['item_description'] ?? ''}',
            who(item['completed_by']), Iconsax.tick_square, GasPalette.goodInk);
      }
    }
    final findings = _maintenance['observations'];
    if (findings is List) {
      for (final f in findings.whereType<Map>()) {
        add(t(f['created_at']), f['is_critical'] == true ? 'Critical finding recorded' : 'Finding recorded',
            '${f['text'] ?? ''}', f['is_critical'] == true ? Iconsax.danger : Iconsax.note_2,
            f['is_critical'] == true ? GasPalette.critInk : GasPalette.ink2);
      }
    }
    if (m['actual_end_date'] != null) {
      add(t(m['actual_end_date']), 'Completed', '', Iconsax.tick_circle, GasPalette.goodInk);
    }
    events.sort((x, y) => (x.at ?? DateTime(2100)).compareTo(y.at ?? DateTime(2100)));
    // What's still to come, in order.
    if (m['actual_start_date'] == null && m['status'] != 'cancelled') {
      add(null, 'Start the job', '', Iconsax.play_circle, GasPalette.ink2, pending: true);
    }
    if (m['actual_end_date'] == null && m['status'] != 'cancelled') {
      add(null, 'Complete the job', '', Iconsax.tick_circle, GasPalette.ink2, pending: true);
    }
    if (m['next_maintenance_date'] != null) {
      add(t(m['next_maintenance_date']), 'Next maintenance', '', Iconsax.repeat, GasPalette.series, pending: true);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        final last = i == events.length - 1;
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 36,
              child: Column(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: e.pending ? Tone.bg(Colors.white) : e.color.withValues(alpha: .12),
                      shape: BoxShape.circle,
                      border: Border.all(color: e.pending ? GasPalette.border : Colors.transparent, width: 1.5)),
                  child: Icon(e.icon, size: 16, color: e.pending ? GasPalette.ink2 : e.color),
                ),
                if (!last) Expanded(child: Container(width: 2, color: GasPalette.border)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title,
                      style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: e.pending ? GasPalette.ink2 : GasPalette.ink)),
                  if (e.at != null)
                    Text(DateFormat('EEE d MMM yyyy, HH:mm').format(e.at!),
                        style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
                  if (e.detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(e.detail, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
                    ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildDocumentationTab() {
    final status = '${_maintenance['status'] ?? ''}';
    final canEdit = const {'in_progress', 'scheduled', 'completed', 'pending'}.contains(status);
    final contractor = '${_maintenance['external_contractor'] ?? ''}'.trim();
    final safety = '${_maintenance['safety_precautions'] ?? ''}'.trim();
    final compliance = '${_maintenance['compliance_notes'] ?? ''}'.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        if (safety.isNotEmpty || compliance.isNotEmpty) _buildModernSafetySection(),
        _itemsSection(
          key: 'parts_used',
          section: 'parts',
          title: 'Parts used',
          icon: Iconsax.setting_2,
          hint: 'Add a part, e.g. Contactor 32A',
          controller: _newPart,
          canEdit: canEdit,
        ),
        _itemsSection(
          key: 'materials_used',
          section: 'materials',
          title: 'Materials used',
          icon: Iconsax.box_1,
          hint: 'Add a material, e.g. Contact cleaner',
          controller: _newMaterial,
          canEdit: canEdit,
        ),
        if (_docsDirty && canEdit) ...[
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () async {
              await _savePartsAndMaterials();
              if (mounted) setState(() => _docsDirty = false);
            },
            style: FilledButton.styleFrom(
                backgroundColor: GasPalette.primary, minimumSize: const Size.fromHeight(48), shape: const StadiumBorder()),
            icon: const Icon(Iconsax.tick_circle, size: 18),
            label: const Text('Save parts and materials'),
          ),
        ],
        if (contractor.isNotEmpty) _buildModernExternalContractorSection(),
        _buildInteractiveFilesSection(canEdit),
      ],
    );
  }

  /// Parts or materials: removable chips, an inline add field and photos.
  Widget _itemsSection({
    required String key,
    required String section,
    required String title,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required bool canEdit,
  }) {
    final items = <String>[...((_maintenance[key] as List?) ?? const []).map((e) => '$e')];
    final images = (_maintenance['${section}_images'] as List?) ?? const [];
    void add() {
      final text = controller.text.trim();
      if (text.isEmpty) return;
      setState(() {
        _maintenance[key] = [...items, text];
        _docsDirty = true;
      });
      controller.clear();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MaintenanceSectionHeader(
        title: title,
        subtitle: items.isEmpty ? 'None recorded' : '${items.length} recorded',
        action: canEdit
            ? IconButton(
                tooltip: 'Add a photo of the $section',
                onPressed: () => _uploadSectionImage(section),
                icon: const Icon(Iconsax.camera),
              )
            : null,
      ),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Tone.bg(Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: GasPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (items.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in items)
                InputChip(
                  avatar: Icon(icon, size: 16, color: GasPalette.series),
                  label: Text(item, overflow: TextOverflow.ellipsis),
                  onDeleted: canEdit
                      ? () => setState(() {
                            _maintenance[key] = [...items]..remove(item);
                            _docsDirty = true;
                          })
                      : null,
                  deleteButtonTooltipMessage: 'Remove $item',
                ),
            ])
          else
            Text(canEdit ? 'Nothing added yet.' : 'None recorded for this job.',
                style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
          if (canEdit) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => add(),
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    filled: true,
                    fillColor: GasPalette.panelAlt,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add',
                style: IconButton.styleFrom(backgroundColor: GasPalette.primary, foregroundColor: Tone.fg(Colors.white)),
                onPressed: add,
                icon: const Icon(Icons.add),
              ),
            ]),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSectionImageGallery(section, images, canEdit),
          ],
        ]),
      ),
    ]);
  }

  Widget _buildInteractiveFilesSection(bool canEdit) {
    List<dynamic> list(String k) => (_maintenance[k] as List?) ?? const [];
    final before = list('before_photos'), after = list('after_photos'), documents = list('documents');
    final total = before.length + after.length + documents.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MaintenanceSectionHeader(
        title: 'Photos and documents',
        subtitle: total == 0 ? 'Before and after photos, reports, certificates' : '$total file${total == 1 ? '' : 's'}',
      ),
      if (canEdit)
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showUploadMediaDialog,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: const StadiumBorder()),
              icon: const Icon(Iconsax.camera, size: 18),
              label: const Text('Add photos'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showUploadDocumentDialog,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: const StadiumBorder()),
              icon: const Icon(Iconsax.document_upload, size: 18),
              label: const Text('Add document'),
            ),
          ),
        ]),
      if (total == 0)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
              canEdit ? 'Take before and after photos so the work is easy to verify later.' : 'No files for this job.',
              style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
        ),
      if (before.isNotEmpty) _buildMediaCategory('Before', Iconsax.gallery, GasPalette.series, before, canEdit),
      if (after.isNotEmpty) _buildMediaCategory('After', Iconsax.gallery_tick, GasPalette.goodInk, after, canEdit),
      if (documents.isNotEmpty) ...[
        const SizedBox(height: 12),
        Material(
          color: Tone.bg(Colors.white),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), side: BorderSide(color: GasPalette.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final doc in documents)
              Builder(builder: (context) {
                final d = doc is Map ? doc : {'filename': '$doc'};
                final url = '${d['url'] ?? ''}';
                final full = url.isEmpty ? '' : (url.startsWith('http') ? url : '${Constants.articBaseUrl2}$url');
                final description = '${d['description'] ?? ''}';
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: GasPalette.seriesSoft,
                      child: Icon(Iconsax.document_text, color: GasPalette.series, size: 20)),
                  title: Text('${d['filename'] ?? 'Document'}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: GasPalette.ink)),
                  subtitle: description.isEmpty
                      ? null
                      : Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
                  trailing: full.isEmpty ? null : const Icon(Iconsax.export_3, size: 20),
                  onTap: full.isEmpty
                      ? null
                      : () async {
                          final ok = await launchUrl(Uri.parse(full), mode: LaunchMode.externalApplication);
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(const SnackBar(content: Text('The document could not be opened.')));
                          }
                        },
                );
              }),
          ]),
        ),
      ],
    ]);
  }

  // Build a media category with expandable gallery
  Widget _buildMediaCategory(String title, IconData icon, Color color,
      List<dynamic> images, bool canEdit,
      {String? section}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tone.bg(Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                '$title · ${images.length} photo${images.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: GasPalette.ink),
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
                final imageUrl =
                    img is Map ? (img['url'] ?? '') : img.toString();
                final filename =
                    img is Map ? (img['filename'] ?? 'Image') : 'Image';
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
                            color: Tone.bg(Colors.grey[200]),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl.startsWith('http')
                                  ? imageUrl
                                  : '${Constants.articBaseUrl2}$imageUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.broken_image,
                                color: Tone.fg(Colors.grey[400]),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
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
                                color: Tone.bg(Colors.red[400]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.close,
                                  size: 14, color: Tone.fg(Colors.white)),
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
    final name = '${_maintenance['external_contractor'] ?? ''}'.trim();
    final contact = '${_maintenance['contractor_contact'] ?? ''}'.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const MaintenanceSectionHeader(title: 'Contractor'),
      Material(
        color: Tone.bg(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: GasPalette.border)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: GasPalette.flameSoft, child: Icon(Iconsax.truck, color: GasPalette.flame, size: 20)),
          title: Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: GasPalette.ink)),
          subtitle: contact.isEmpty ? null : Text(contact, style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
          trailing: contact.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Copy contact',
                  icon: const Icon(Iconsax.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: contact));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact copied')));
                  },
                ),
        ),
      ),
    ]);
  }

  Widget _buildModernSafetySection() {
    final safety = '${_maintenance['safety_precautions'] ?? ''}'.trim();
    final compliance = '${_maintenance['compliance_notes'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: GasPalette.warnSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: GasPalette.warnLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Iconsax.shield_tick, size: 20, color: GasPalette.warnInk),
            const SizedBox(width: 8),
            Text('Safety', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: GasPalette.warnInk)),
          ]),
          if (safety.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(safety, style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: GasPalette.ink)),
          ],
          if (compliance.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Compliance notes', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: GasPalette.warnInk)),
            const SizedBox(height: 2),
            Text(compliance, style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink)),
          ],
        ]),
      ),
    );
  }

  Widget _buildObservationsSection(bool canEdit) {
    final data = _maintenance['observations'];
    final findings = <Map<String, dynamic>>[
      if (data is List) ...data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      if (data is Map) Map<String, dynamic>.from(data),
      if (data is String && data.isNotEmpty)
        {'text': data, 'created_by': 'Earlier note', 'is_critical': false, 'category': 'general'},
    ];
    String author(dynamic v) => v is Map ? '${v['full_name'] ?? v['username'] ?? 'Someone'}' : '${v ?? 'Someone'}';
    String imageUrl(String raw) => raw.startsWith('http') ? raw : '${Constants.articBaseUrl2}$raw';
    final critical = findings.where((f) => f['is_critical'] == true).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MaintenanceSectionHeader(
        title: 'Findings',
        subtitle: findings.isEmpty
            ? 'What the technician noticed'
            : '${findings.length} recorded${critical == 0 ? '' : ' · $critical critical'}',
        action: canEdit
            ? FilledButton.icon(
                onPressed: _showAddObservationDialog,
                style: FilledButton.styleFrom(
                    backgroundColor: GasPalette.primary, foregroundColor: Tone.fg(Colors.white), shape: const StadiumBorder()),
                icon: const Icon(Iconsax.add, size: 18),
                label: const Text('Add finding'),
              )
            : null,
      ),
      if (findings.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Tone.bg(Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: GasPalette.border)),
          child: Column(children: [
            Icon(Iconsax.note_2, size: 36, color: GasPalette.series),
            const SizedBox(height: 8),
            Text('No findings yet', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: GasPalette.ink)),
            const SizedBox(height: 4),
            Text(
                canEdit
                    ? 'Record issues, readings and recommendations as you work. Add photos to each one.'
                    : 'Findings recorded during this job appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
          ]),
        )
      else
        for (final f in findings) _findingCard(f, canEdit, author, imageUrl),
    ]);
  }

  Widget _findingCard(Map<String, dynamic> f, bool canEdit, String Function(dynamic) author,
      String Function(String) imageUrl) {
    final critical = f['is_critical'] == true;
    final id = '${f['id'] ?? ''}';
    final images = (f['images'] as List? ?? const []).whereType<Map>().toList();
    final category = '${f['category_display'] ?? f['category'] ?? ''}'.replaceAll('_', ' ');
    final (bg, fg, icon) = switch ('${f['category']}') {
      'issue' || 'problem' || 'defect' => (GasPalette.critSoft, GasPalette.critInk, Iconsax.danger),
      'recommendation' => (GasPalette.seriesSoft, GasPalette.series, Iconsax.lamp_charge),
      'measurement' || 'reading' => (GasPalette.panelAlt, GasPalette.ink, Iconsax.chart_2),
      _ => (GasPalette.panelAlt, GasPalette.ink2, Iconsax.note_2),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Tone.bg(Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: critical ? GasPalette.critLine : GasPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (category.isNotEmpty)
              MaintenancePill(text: '${category[0].toUpperCase()}${category.substring(1)}', bg: bg, fg: fg, icon: icon),
            if (critical) MaintenancePill(text: 'Critical', bg: GasPalette.critSoft, fg: GasPalette.critInk, icon: Iconsax.danger),
          ]),
          const SizedBox(height: 8),
          Text('${f['text'] ?? ''}', style: GoogleFonts.inter(fontSize: 14.5, height: 1.45, color: GasPalette.ink)),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = '${images[i]['url'] ?? ''}';
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showImagePreview(url, '${images[i]['filename'] ?? 'Photo'}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl(url), width: 72, height: 72, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 72, height: 72, color: GasPalette.panelAlt,
                              child: Icon(Iconsax.gallery_slash, color: GasPalette.ink2))),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Icon(Iconsax.user, size: 14, color: GasPalette.ink2),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                  '${author(f['created_by'])}${f['created_at'] == null ? '' : ' · ${maintenanceWhen(f['created_at'], done: true)}'}',
                  style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
            ),
            if (canEdit && id.isNotEmpty)
              TextButton.icon(
                onPressed: () => _uploadObservationImage(id),
                icon: const Icon(Iconsax.camera, size: 16),
                label: const Text('Add photo'),
              ),
          ]),
        ]),
      ),
    );
  }

  // Simple Add Observation Dialog
  void _showAddObservationDialog() {
    final TextEditingController controller = TextEditingController();

    showMobileDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MobileAlertDialog(
        backgroundColor: Tone.bg(Colors.white),
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
              decoration: mobileInputDecoration(
                  context,
                  InputDecoration(
                    hintText: 'Enter your finding...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Constants.ctaColorLight),
                    ),
                  )),
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
                } catch (e) {}
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPhoneLayout(context)
                  ? GasPalette.primary
                  : Constants.ctaColorLight,
              foregroundColor: Tone.fg(Colors.white),
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

      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/observations/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 20));

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
          backgroundColor: Tone.bg(Colors.red),
          behavior: SnackBarBehavior.floating,
        ),
      );
      rethrow;
    }
  }

  // Upload Media Dialog and Functionality
  void _showUploadMediaDialog() {
    showMobileDialog(
      context: context,
      builder: (BuildContext context) {
        return MobileDialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Tone.bg(Colors.black).withOpacity(0.1),
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
                          color: Tone.fg(Colors.grey[800]),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Tone.fg(Colors.grey[600])),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Select images or videos to upload for this maintenance task.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Tone.fg(Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 24),
                MobileFormRow(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUploadMedia('image'),
                        icon: Icon(Icons.image, size: 20),
                        label: Text('Select Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPhoneLayout(context)
                              ? GasPalette.primary
                              : Constants.ctaColorLight,
                          foregroundColor: Tone.fg(Colors.white),
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
                          backgroundColor: isPhoneLayout(context)
                              ? GasPalette.primary
                              : Constants.ctaColorLight,
                          foregroundColor: Tone.fg(Colors.white),
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

    showMobileDialog(
      context: context,
      builder: (BuildContext context) {
        return MobileDialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Tone.bg(Colors.black).withOpacity(0.1),
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
                          color: Tone.fg(Colors.grey[800]),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Tone.fg(Colors.grey[600])),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Upload a document with description for this maintenance task.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Tone.fg(Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Tone.fg(Colors.grey[800]),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: mobileInputDecoration(
                      context,
                      InputDecoration(
                        hintText: 'Enter document description...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Tone.bg(Colors.grey[300])),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Constants.ctaColorLight),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      )),
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
                      backgroundColor: isPhoneLayout(context)
                          ? GasPalette.primary
                          : Constants.ctaColorLight,
                      foregroundColor: Tone.fg(Colors.white),
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
            backgroundColor: Tone.bg(Colors.green),
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
          backgroundColor: Tone.bg(Colors.red),
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
            backgroundColor: Tone.bg(Colors.green),
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
          backgroundColor: Tone.bg(Colors.red),
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
    request.headers['Authorization'] = 'Token $token';

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

    final response = await request.send().timeout(const Duration(seconds: 30));
    await response.stream.drain<void>().timeout(const Duration(seconds: 30));

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
    request.headers['Authorization'] = 'Token $token';

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

    final response = await request.send().timeout(const Duration(seconds: 30));
    await response.stream.drain<void>().timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to upload document: ${response.statusCode}');
    }
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
          request.headers['Authorization'] = 'Token $token';

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

          final response =
              await request.send().timeout(const Duration(seconds: 30));
          if (response.statusCode != 200) {
            throw Exception('Failed to upload image');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image(s) uploaded successfully'),
            backgroundColor: Tone.bg(Colors.green),
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
          backgroundColor: Tone.bg(Colors.red),
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
          request.headers['Authorization'] = 'Token $token';

          // Add file
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'file',
              file.bytes!,
              filename: file.name,
            ));
          }

          request.fields['caption'] = '';

          final response =
              await request.send().timeout(const Duration(seconds: 30));
          if (response.statusCode != 200) {
            throw Exception('Failed to upload image');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image(s) uploaded successfully'),
            backgroundColor: Tone.bg(Colors.green),
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
          backgroundColor: Tone.bg(Colors.red),
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
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image deleted'),
            backgroundColor: Tone.bg(Colors.green),
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
          backgroundColor: Tone.bg(Colors.red),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Build image gallery for a section
  Widget _buildSectionImageGallery(
      String section, List<dynamic> images, bool canEdit) {
    if (images.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.photo_library, size: 18, color: Tone.fg(Colors.grey[600])),
            SizedBox(width: 8),
            Text(
              'Images (${images.length})',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Tone.fg(Colors.grey[700]),
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
                      onTap: () => _showImagePreview(
                          imageUrl, img['filename'] ?? 'Image'),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Tone.bg(Colors.grey[300])),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl.startsWith('http')
                                ? imageUrl
                                : '${Constants.articBaseUrl2}$imageUrl'),
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
                              color: Tone.bg(Colors.red[400]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Tone.fg(Colors.white),
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
    showMobileDialog(
      context: context,
      builder: (context) => MobileDialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
          decoration: BoxDecoration(
            color: Tone.bg(Colors.white),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Tone.bg(Colors.grey[200]))),
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
                        Icon(Icons.broken_image, size: 48, color: Tone.fg(Colors.grey)),
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
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/update/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'parts_used': parts,
              'materials_used': materials,
            }),
          )
          .timeout(const Duration(seconds: 20));
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
          backgroundColor: Tone.bg(Colors.red),
        ),
      );
    }
  }

  Widget _buildActionButton() {
    final status = _maintenance['status'];
    final start = status == 'scheduled' || status == 'overdue';
    if (!start && status != 'in_progress') return const SizedBox.shrink();
    return FloatingActionButton.extended(
      heroTag: 'maintenance-action',
      elevation: 2,
      shape: const StadiumBorder(),
      backgroundColor: start ? GasPalette.primary : GasPalette.good,
      foregroundColor: Tone.fg(Colors.white),
      onPressed: _updatingStatus ? null : () => _updateStatus(start ? 'start' : 'complete'),
      icon: _updatingStatus
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Tone.fg(Colors.white)))
          : Icon(start ? Iconsax.play : Iconsax.tick_circle),
      label: Text(start ? 'Start job' : 'Mark complete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
    );
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
    if (_updatingStatus) return;
    if (action == 'complete' &&
        _checklistItems.any((item) =>
            item['is_critical'] == true && item['is_completed'] != true)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Complete all critical checklist items before closing this maintenance.')));
      _tabController.animateTo(1);
      return;
    }
    setState(() => _updatingStatus = true);
    try {
      final response = await http
          .post(
              Uri.parse(
                  '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/status/'),
              headers: await ApiConfig.authHeaders(),
              body: jsonEncode(
                  {'action': action, 'user_id': await SharedPrefs.getUserId()}))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 ||
          jsonDecode(response.body)['success'] != true)
        throw StateError('Not saved');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance status updated')));
      await _loadMaintenanceDetail();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Unable to update status. Check your connection and retry.')));
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _toggleChecklistItem(Map<String, dynamic> item) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/checklist/${item['id']}/update/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'mark_completed': !item['is_completed'],
              'user_id': await SharedPrefs.getUserId(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) throw StateError('Not saved');
      if (!mounted) return;
      if (response.statusCode == 200) {
        _loadMaintenanceDetail();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update checklist. Please retry.'),
          backgroundColor: Tone.bg(Colors.red),
        ),
      );
    }
  }

  void _showAddChecklistItemDialog() {
    final _descriptionController = TextEditingController();
    final _notesController = TextEditingController();
    bool _isCritical = false;
    bool _isSubmitting = false;

    showMobileDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => MobileDialog(
          backgroundColor: Tone.bg(Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
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
                              color: Tone.fg(Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Tone.fg(Colors.grey[600])),
                      style: IconButton.styleFrom(
                        backgroundColor: Tone.bg(Colors.grey[100]),
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
                    color: Tone.bg(Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Tone.bg(Colors.grey[200]), width: 1),
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
                        decoration: mobileInputDecoration(
                            context,
                            InputDecoration(
                              hintText: 'e.g., Check compressor oil levels',
                              hintStyle: GoogleFonts.inter(
                                color: Tone.fg(Colors.grey[500]),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Tone.bg(Colors.grey[300])),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Tone.bg(Colors.grey[300])),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Constants.ctaColorLight, width: 2),
                              ),
                              filled: true,
                              fillColor: Tone.bg(Colors.white),
                              contentPadding: EdgeInsets.all(16),
                            )),
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
                        decoration: mobileInputDecoration(
                            context,
                            InputDecoration(
                              hintText: 'Additional details or instructions',
                              hintStyle: GoogleFonts.inter(
                                color: Tone.fg(Colors.grey[500]),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Tone.bg(Colors.grey[300])),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Tone.bg(Colors.grey[300])),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Constants.ctaColorLight, width: 2),
                              ),
                              filled: true,
                              fillColor: Tone.bg(Colors.white),
                              contentPadding: EdgeInsets.all(16),
                            )),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 3,
                      ),

                      SizedBox(height: 20),

                      // Critical Item Toggle
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCritical
                              ? Tone.bg(Colors.orange).withOpacity(0.1)
                              : Tone.bg(Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCritical
                                ? Tone.bg(Colors.orange).withOpacity(0.3)
                                : Tone.bg(Colors.grey[300]),
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
                              activeColor: Tone.auto(Colors.orange),
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
                                          ? Tone.fg(Colors.orange[800])
                                          : Tone.fg(Colors.grey[800]),
                                    ),
                                  ),
                                  Text(
                                    'Critical items require mandatory completion',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Tone.fg(Colors.grey[600]),
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
                MobileFormRow(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                isPhoneLayout(context) ? 32 : 8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Tone.fg(Colors.grey[600]),
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
                                      backgroundColor: Tone.bg(Colors.red),
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
                          backgroundColor: isPhoneLayout(context)
                              ? GasPalette.primary
                              : Constants.ctaColorLight,
                          foregroundColor: Tone.fg(Colors.white),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                isPhoneLayout(context) ? 32 : 8),
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
                                          Tone.fg(Colors.white)),
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
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/checklist/add/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'description': description,
              if (notes != null) 'notes': notes,
              'is_critical': isCritical,
              'user_id': await SharedPrefs.getUserId(),
            }),
          )
          .timeout(const Duration(seconds: 20));

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
          backgroundColor: Tone.bg(Colors.red),
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
    showMobileDialog(
      context: context,
      builder: (context) => MobileAlertDialog(
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
              leading: Icon(Icons.edit, color: Tone.fg(Colors.blue)),
              title: Text('Edit Item'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditChecklistItemDialog(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Tone.fg(Colors.red)),
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

    showMobileDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => MobileAlertDialog(
          title: Text('Edit Checklist Item'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: mobileInputDecoration(
                      context,
                      InputDecoration(
                        labelText: 'Item Description *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Constants.ctaColorLight),
                        ),
                      )),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: mobileInputDecoration(
                      context,
                      InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Constants.ctaColorLight),
                        ),
                      )),
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
                      activeColor: Tone.auto(Colors.orange),
                    ),
                    Expanded(
                      child: Text(
                        'Mark as Critical Item',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Tone.fg(Colors.grey[700]),
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
                            backgroundColor: Tone.bg(Colors.red),
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
                backgroundColor: isPhoneLayout(context)
                    ? GasPalette.primary
                    : Constants.ctaColorLight,
                foregroundColor: Tone.fg(Colors.white),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Tone.fg(Colors.white)),
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
      final response = await http
          .put(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/checklist/$itemId/update/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'description': description,
              if (notes != null) 'notes': notes,
              'is_critical': isCritical,
              'user_id': await SharedPrefs.getUserId(),
            }),
          )
          .timeout(const Duration(seconds: 20));

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
          backgroundColor: Tone.bg(Colors.red),
        ),
      );
      rethrow;
    }
  }

  void _showDeleteChecklistItemDialog(Map<String, dynamic> item) {
    showMobileDialog(
      context: context,
      builder: (context) => MobileAlertDialog(
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
              backgroundColor:
                  isPhoneLayout(context) ? GasPalette.primary : Tone.bg(Colors.red),
              foregroundColor: Tone.fg(Colors.white),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChecklistItem(String itemId) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/checklist/$itemId/delete/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'user_id': await SharedPrefs.getUserId(),
            }),
          )
          .timeout(const Duration(seconds: 20));

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
          backgroundColor: Tone.bg(Colors.red),
        ),
      );
    }
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'edit' || action == 'duplicate') {
      final saved = await showMobileDialog<bool>(
          context: context,
          builder: (_) => MaintenanceEditorDialog(
              record: _maintenance, duplicate: action == 'duplicate'));
      if (saved == true && mounted) await _loadMaintenanceDetail();
    } else if (action == 'export') {
      await showMobileDialog(
          context: context,
          builder: (_) => MaintenanceReportsDialog(
              initialMaintenanceId: widget.maintenanceId));
    } else if (action == 'delete') {
      final confirmed = await showMobileDialog<bool>(
          context: context,
          builder: (dialogContext) => MobileAlertDialog(
                  title: const Text('Delete maintenance?'),
                  content: const Text(
                      'This removes this service record permanently.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Keep record')),
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Delete'))
                  ]));
      if (confirmed != true || !mounted) return;
      try {
        final response = await http
            .delete(
                Uri.parse(
                    '${ApiConfig.baseUrl}api/maintenance/${widget.maintenanceId}/delete/'),
                headers: await ApiConfig.authHeaders())
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) throw StateError('Not deleted');
        if (mounted) Navigator.pop(context, true);
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Unable to delete this maintenance record. Please retry.')));
      }
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
      id: json['id']?.toString() ?? '',
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

class MaintenanceReportsDialog extends StatefulWidget {
  const MaintenanceReportsDialog(
      {super.key, this.initialMaintenanceId, this.pdfSaver});
  final String? initialMaintenanceId;
  final Future<void> Function(Uint8List bytes, String filename)? pdfSaver;
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
    if (widget.initialMaintenanceId != null)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generateDetailedPDF(widget.initialMaintenanceId!);
      });
  }

  Future<void> _loadMonthlyReports() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}api/maintenance/reports/monthly/'),
            headers: await ApiConfig.authHeaders(),
            body: json.encode({
              'business_id': await SharedPrefs.getBusinessId(),
              'year': _selectedYear,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _monthlyReports = data['reports'];
        });
      } else {
        throw Exception('Failed to load monthly reports');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load reports. Check your connection and retry.';
      });
    } finally {
      if (mounted)
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
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/reports/$year/$month/records/?business_id=${await SharedPrefs.getBusinessId()}'),
            headers: await ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _selectedMonthRecords = data['maintenance_records'];
        });
      } else {
        throw Exception('Failed to load month records');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load records. Check your connection and retry.';
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _generateDetailedPDF(String maintenanceId) async {
    bool loadingDialogOpen = true;
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
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
      final detailResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}api/maintenance/$maintenanceId/'),
            headers: await ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 20));

      if (detailResponse.statusCode != 200) {
        throw Exception('Failed to fetch maintenance details');
      }

      final detailEnvelope = json.decode(detailResponse.body);
      final maintenanceData =
          Map<String, dynamic>.from(detailEnvelope['maintenance']);

      // Fetch observations
      final observationsResponse = await http
          .get(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/$maintenanceId/observations/'),
            headers: await ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 20));

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
      } catch (pdfError) {
        throw Exception('PDF Generation Error: $pdfError');
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      loadingDialogOpen = false;

      // Save PDF to device
      await _savePdfToDevice(
        pdfBytes,
        'maintenance_report_${maintenanceId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        try {
          if (loadingDialogOpen)
            Navigator.pop(context); // Close only the loading dialog
        } catch (_) {
          // Dialog might not be open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to generate the report. Check your connection and retry.'),
            backgroundColor: Tone.bg(Colors.red),
          ),
        );
      }
    }
  }

  Future<void> _generateMonthlySummaryPDF(int year, int month) async {
    bool loadingDialogOpen = true;
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
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
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.baseUrl}api/maintenance/reports/$year/$month/records/?business_id=${await SharedPrefs.getBusinessId()}'),
            headers: await ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 20));

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

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      loadingDialogOpen = false;

      // Save PDF to device
      await _savePdfToDevice(
        pdfBytes,
        'monthly_maintenance_${year}_${month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        if (loadingDialogOpen) Navigator.pop(context); // Close only the loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to generate the monthly report. Check your connection and retry.'),
            backgroundColor: Tone.bg(Colors.red),
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
            _buildPDFInfoRow(
                'Performed By',
                maintenanceData['performed_by']?['full_name']?.toString() ??
                    'N/A'),
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
                  itemMap['is_completed'] == true ? 'Completed' : 'Pending',
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
                  pw.Text('Time',
                      style:
                          pw.TextStyle(fontSize: 9, color: PdfColors.blue600)),
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
            child: pw.Text(completed ? 'Done' : 'Due',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
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
    if (widget.pdfSaver != null) {
      await widget.pdfSaver!(pdfBytes, fileName);
      return;
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // The native chooser supports Save to Files / Downloads without broad
      // storage permission or assumptions about a platform's filesystem path.
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      return;
    }
    await PdfSaver.savePdf(pdfBytes, fileName);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Report downloaded.')));
  }

  // Helper methods for status colors and icons
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Tone.auto(Color(0xFF388E3C));
      case 'in_progress':
        return Tone.auto(Color(0xFF1976D2));
      case 'scheduled':
        return Tone.auto(Color(0xFF7B1FA2));
      case 'overdue':
        return Tone.auto(Color(0xFFD32F2F));
      case 'cancelled':
        return Tone.auto(Color(0xFF616161));
      default:
        return Tone.auto(Color(0xFF616161));
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
        backgroundColor: Tone.bg(Colors.white),
        appBar: AppBar(
          backgroundColor: Constants.ctaColorLight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Tone.fg(Colors.white)),
          ),
          title: Text('Maintenance reports',
              style: TextStyle(fontSize: 18, color: Tone.fg(Colors.white))),
        ),
        body: _buildReportsContent(isMobile: true),
      );
    }

    return MobileDialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            constraints: BoxConstraints(maxWidth: 1200),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Tone.bg(Colors.black).withOpacity(0.1),
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
                  color: Tone.bg(Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Tone.bg(Colors.grey[200]),
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
                              color: Tone.fg(Colors.grey[900]),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Generate and download comprehensive maintenance reports',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Tone.fg(Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Tone.fg(Colors.grey[600]),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Tone.bg(Colors.grey[100]),
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
      color: Tone.bg(Colors.white),
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
                        color: Tone.fg(Colors.grey[800]),
                      ),
                    ),
                    SizedBox(height: 8),
                    _MaintenanceFormSurface(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Constants.ctaColorLight.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        isDense: isPhoneLayout(context),
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
                        color: Tone.fg(Colors.grey[800]),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ? Center(
                  child:
                      CircularProgressIndicator(color: Constants.ctaColorLight))
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Tone.fg(Colors.red), size: 48),
                          SizedBox(height: 16),
                          Text(_error,
                              style:
                                  GoogleFonts.inter(color: Tone.fg(Colors.grey[600]))),
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
    if (_monthlyReports.isEmpty ||
        _monthlyReports.every((month) => (month['total_records'] ?? 0) == 0)) {
      return const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: AppEmptyState(
              kind: AppEmptyStateKind.records,
              title: 'No maintenance reports yet',
              message:
                  'Schedule and complete maintenance to build your service history. Reports use your saved records only.'));
    }
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
              color: Tone.fg(Colors.grey[800]),
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 4,
              crossAxisSpacing: isMobile ? 8 : 16,
              mainAxisSpacing: isMobile ? 8 : 16,
              childAspectRatio: isMobile ? 3.2 : 1.5,
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
                    color: Tone.fg(Colors.grey[800]),
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
                    backgroundColor: isPhoneLayout(context)
                        ? GasPalette.primary
                        : Constants.ctaColorLight,
                    foregroundColor: Tone.fg(Colors.white),
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
                    style: GoogleFonts.inter(color: Tone.fg(Colors.grey[500])),
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
    final isSelected =
        _selectedMonth != null && _selectedMonth['month'] == report['month'];
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
          color: isSelected
              ? Constants.ctaColorLight.withOpacity(0.1)
              : Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Constants.ctaColorLight : Tone.bg(Colors.grey[300]),
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
                color: isSelected ? Constants.ctaColorLight : Tone.fg(Colors.grey[800]),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${report['total_records'] ?? 0} records',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                color: Tone.fg(Colors.grey[600]),
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
        color: Tone.bg(Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Tone.bg(Colors.grey[200])),
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
                    color: Tone.fg(Colors.grey[800]),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  record['maintenance_type']?['name'] ?? 'Maintenance',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    color: Tone.fg(Colors.grey[600]),
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

class _MaintenanceFormSurface extends StatelessWidget {
  const _MaintenanceFormSurface(
      {required this.child, this.width, this.padding, this.decoration});
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    if (!isPhoneLayout(context)) {
      return Container(
          width: width, padding: padding, decoration: decoration, child: child);
    }
    return InputDecorator(
      decoration:
          mobileInputDecoration(context, const InputDecoration(isDense: true)),
      child: child,
    );
  }
}

/// One service schedule form for phones and larger displays.
class MaintenanceEditorDialog extends StatefulWidget {
  const MaintenanceEditorDialog(
      {super.key, required this.record, this.duplicate = false});
  final Map<String, dynamic> record;
  final bool duplicate;
  @override
  State<MaintenanceEditorDialog> createState() =>
      _MaintenanceEditorDialogState();
}

class _MaintenanceEditorDialogState extends State<MaintenanceEditorDialog> {
  final _requestIdentity = _MaintenanceRequestIdentity();
  final _form = GlobalKey<FormState>();
  late final TextEditingController _description, _cost, _duration;
  late DateTime _scheduled;
  late String _priority;
  String? _assigned;
  List<dynamic> _users = [];
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _description =
        TextEditingController(text: widget.record['work_description'] ?? '');
    _cost = TextEditingController(
        text: widget.record['estimated_cost']?.toString() ?? '');
    _duration = TextEditingController(
        text: widget.record['estimated_duration_hours']?.toString() ?? '');
    _scheduled = widget.duplicate
        ? DateTime.now()
        : DateTime.parse(widget.record['scheduled_date']).toLocal();
    _priority = widget.record['priority'] ?? 'normal';
    _assigned = widget.record['assigned_to']?['id']?.toString();
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(
              Uri.parse(
                  '${ApiConfig.baseUrl}api/maintenance/assignable-users/?business_id=${await SharedPrefs.getBusinessId()}'),
              headers: await ApiConfig.authHeaders())
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          _users = jsonDecode(response.body)['users'];
          if (_assigned != null &&
              !_users.any((u) => u['id'].toString() == _assigned))
            _assigned = null;
        });
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Unable to load your team. Retry before saving.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _number(String? value, {bool positive = false}) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    return n == null || !n.isFinite || n < 0 || (positive && n == 0)
        ? 'Enter a valid ${positive ? 'positive ' : ''}number'
        : null;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await http
          .post(
              Uri.parse(
                  '${ApiConfig.baseUrl}api/maintenance/${widget.duplicate ? 'create' : "${widget.record['id']}/update"}/'),
              headers: await ApiConfig.authHeaders(),
              body: jsonEncode(_requestIdentity.apply({
                'work_description': _description.text.trim(),
                'priority': _priority,
                'assigned_to_id':
                    _assigned == null ? null : int.parse(_assigned!),
                'scheduled_date': _scheduled.toUtc().toIso8601String(),
                'estimated_cost': double.tryParse(_cost.text),
                'estimated_duration_hours': double.tryParse(_duration.text),
                if (widget.duplicate) ...{
                  'device_id': widget.record['device']['id'],
                  'maintenance_type_id': widget.record['maintenance_type']
                      ['id'],
                  'status': 'scheduled'
                }
              })))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != (widget.duplicate ? 201 : 200))
        throw StateError('Not saved');
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Unable to save changes. Your entries are kept; please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MaintenanceEditorSurface(
      title: widget.duplicate ? 'Duplicate maintenance' : 'Edit maintenance',
      busy: _saving,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty && _error != null
              ? AppEmptyState(
                  title: 'Unable to load your team',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: _load)
              : Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.record['device']?['name'] ?? 'Equipment',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        TextFormField(
                            key: const ValueKey('maintenance-description'),
                            controller: _description,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Work description'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Describe the work'
                                : null),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration:
                                const InputDecoration(labelText: 'Priority'),
                            items: [
                              'low',
                              'normal',
                              'high',
                              'critical',
                              'emergency'
                            ]
                                .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                        v[0].toUpperCase() + v.substring(1))))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => _priority = v!)),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                            initialValue: _assigned,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Assigned to'),
                            items: [
                              const DropdownMenuItem<String>(
                                  value: null, child: Text('Unassigned')),
                              ..._users.map((u) => DropdownMenuItem(
                                  value: u['id'].toString(),
                                  child: Text(u['full_name'] ?? u['username'],
                                      overflow: TextOverflow.ellipsis)))
                            ],
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => _assigned = v)),
                        const SizedBox(height: 20),
                        TextFormField(
                            controller: _cost,
                            decoration: const InputDecoration(
                                labelText: 'Estimated cost'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: _number),
                        const SizedBox(height: 20),
                        TextFormField(
                            controller: _duration,
                            decoration: const InputDecoration(
                                labelText: 'Estimated hours'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) => _number(v, positive: true)),
                        const SizedBox(height: 20),
                        OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    final date = await showDatePicker(
                                        context: context,
                                        initialDate: _scheduled,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100));
                                    if (date == null || !mounted) return;
                                    final time = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            TimeOfDay.fromDateTime(_scheduled));
                                    if (time != null && mounted)
                                      setState(() => _scheduled = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                          time.hour,
                                          time.minute));
                                  },
                            child: Text(
                                'Scheduled: ${DateFormat.yMMMd().add_Hm().format(_scheduled)}')),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(_error!,
                                  style: TextStyle(color: Tone.fg(Colors.red)))),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving
                                ? 'Saving…'
                                : widget.duplicate
                                    ? 'Create copy'
                                    : 'Save changes')),
                      ])));
}

class _MaintenanceEditorSurface extends StatelessWidget {
  const _MaintenanceEditorSurface(
      {required this.title, required this.child, this.busy = false});
  final String title;
  final Widget child;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24), child: child));
    return PopScope(
        canPop: !busy,
        child: isPhoneLayout(context)
            ? Scaffold(
                appBar: AppBar(
                    title: Text(title), automaticallyImplyLeading: !busy),
                body: body)
            : Dialog(
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 560, maxHeight: 720),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                          child: Row(children: [
                            Expanded(
                                child: Text(title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)),
                            IconButton(
                                onPressed:
                                    busy ? null : () => Navigator.pop(context),
                                icon: const Icon(Icons.close))
                          ])),
                      Flexible(child: body)
                    ]))));
  }
}

/// Retrying an unchanged form identifies the original operation after a lost response.
class _MaintenanceRequestIdentity {
  String? _fingerprint;
  String? _requestId;
  Map<String, dynamic> apply(Map<String, dynamic> payload) {
    final fingerprint = jsonEncode(payload);
    if (fingerprint != _fingerprint) {
      _fingerprint = fingerprint;
      _requestId = const Uuid().v4();
    }
    return {...payload, 'client_request_id': _requestId};
  }
}
