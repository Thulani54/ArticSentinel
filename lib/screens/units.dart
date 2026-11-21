import '../widgets/app_tone.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_screen.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/mobile_forms.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import '../models/unit.dart';
import 'unit_flow.dart';
import '../widgets/unit_link_sheets.dart';
import '../services/shared_preferences.dart';
import '../widgets/compact_header.dart';

class UnitManagementRecords {
  int itemCount;
  String itemName;
  IconData itemIcon;
  Color cardColor;

  UnitManagementRecords(
      this.itemCount, this.itemName, this.itemIcon, this.cardColor);
}

class UnitManagement extends StatefulWidget {
  const UnitManagement({super.key});

  @override
  State<UnitManagement> createState() => _UnitManagementState();
}

class _UnitManagementState extends State<UnitManagement>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Unit> _allUnits = [];
  List<Unit> _filteredUnits = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _loadFailed = false;
  String _selectedFilter = 'All';
  bool _isGridView = false;

  // Auto-refresh timer
  Timer? _refreshTimer;
  DateTime? lastRefreshTime;
  bool isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start animation immediately to avoid blank screen
    _animationController.forward();

    _loadUnits();
    _searchController.addListener(_onSearchChanged);

    // Start auto-refresh timer with a delay to avoid immediate refresh
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterUnits();
  }

  void _startAutoRefresh() {
    print(
        'Starting auto-refresh timer for Unit Management at ${DateTime.now()}');
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('Auto-refresh triggered for Unit Management at ${DateTime.now()}');
      if (mounted) {
        _loadUnits(showLoading: false);
      } else {
        print('Widget not mounted, cancelling timer');
        timer.cancel();
      }
    });
  }

  Future<void> _loadUnits({bool showLoading = true}) async {
    print(
        '_loadUnits called for Unit Management with showLoading: $showLoading at ${DateTime.now()}');

    if (showLoading && mounted) setState(() => _loadFailed = false);
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        final result = await UnitApiService.fetchUnitsManagement(businessId).timeout(const Duration(seconds: 20));

        if (mounted) {
          setState(() {
            _loadFailed = false;
            _allUnits = result['units'];
            _statistics = result['statistics'];
            _filteredUnits = List.from(_allUnits);
            lastRefreshTime = DateTime.now();
            _isLoading = false;
          });

          // Mark initial load as complete
          isInitialLoad = false;

          // Apply current filters after loading
          _filterUnits();

          print(
              'Unit Management data refreshed successfully at ${lastRefreshTime}');
        }
      } else {
        if (mounted) {
          setState(() {
            _loadFailed = false;
            _allUnits = [];
            _filteredUnits = [];
            _statistics = {};
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading Unit Management data: $e');
      if (mounted) {
        setState(() { _isLoading = false; _loadFailed = true; });
      }
    }
  }

  void _filterUnits() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredUnits = _allUnits.where((unit) {
        bool matchesSearch = query.isEmpty ||
            unit.name.toLowerCase().contains(query) ||
            unit.serialNumber.toLowerCase().contains(query) ||
            unit.modelNumber.toLowerCase().contains(query) ||
            (unit.location?.toLowerCase().contains(query) ?? false);

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Operational' && unit.isOperational) ||
            (_selectedFilter == 'Maintenance' && unit.isUnderMaintenance) ||
            (_selectedFilter == 'Decommissioned' && unit.isDecommissioned) ||
            (_selectedFilter == 'Maintenance Due' && unit.isMaintenanceDue);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Tone.fg(Colors.white)),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Tone.bg(Colors.red),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Tone.fg(Colors.white)),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Tone.bg(Colors.green),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  List<UnitManagementRecords> get unitRecordList {
    return [
      UnitManagementRecords(
        _statistics['total_units'] ?? 0,
        "Total Units",
        Icons.precision_manufacturing_rounded,
        Constants.ctaColorLight,
      ),
      UnitManagementRecords(
        _statistics['operational_units'] ?? 0,
        "Operational",
        Icons.check_circle_rounded,
        Tone.auto(const Color(0xFF10B981)),
      ),
      UnitManagementRecords(
        _statistics['maintenance_units'] ?? 0,
        "Maintenance",
        Icons.build_rounded,
        Tone.auto(const Color(0xFFF59E0B)),
      ),
      UnitManagementRecords(
        _statistics['decommissioned_units'] ?? 0,
        "Decommissioned",
        Icons.cancel_rounded,
        Tone.auto(const Color(0xFFEF4444)),
      ),
      UnitManagementRecords(
        _statistics['maintenance_due_units'] ?? 0,
        "Maintenance Due",
        Icons.warning_amber_rounded,
        Tone.auto(const Color(0xFFF97316)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildMobilePage();
    return Scaffold(
      backgroundColor:
          isPhoneLayout(context) ? GasPalette.page : Tone.bg(const Color(0xFFF8FAFC)),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          isPhoneLayout(context) ? 16 : 20,
                          20,
                          isPhoneLayout(context) ? 16 : 20,
                          96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Cards
                          if (!_loadFailed && !_isLoading) _buildStatisticsSection(),

                          SizedBox(height: isPhoneLayout(context) ? 24 : 32),

                          // Search and Controls
                          if (!_loadFailed && !_isLoading) _buildSearchAndControls(),

                          const SizedBox(height: 24),

                          // Units Display
                          _buildUnitsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Refresh indicator
            if (lastRefreshTime != null && !isPhoneLayout(context))
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Tone.bg(Colors.black87),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Tone.bg(Colors.black).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Tone.fg(Colors.white),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Updated ${_formatRefreshTime(lastRefreshTime!)}',
                        style: GoogleFonts.inter(
                          color: Tone.fg(Colors.white),
                          fontSize: 12,
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
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 0,
        onPressed: _addUnit,
        backgroundColor: isPhoneLayout(context)
            ? GasPalette.primary
            : Constants.ctaColorLight,
        foregroundColor: Tone.fg(Colors.white),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Unit',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMobilePage() => ColoredBox(
    color: GasPalette.page,
    child: SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            MobileScreenHeader(
              padding: EdgeInsets.zero,
              title: 'Units',
              trailing: FilledButton(
                onPressed: _addUnit,
                style: FilledButton.styleFrom(
                  backgroundColor: GasPalette.primary,
                  foregroundColor: Tone.fg(Colors.white),
                  minimumSize: const Size(64, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text('Add Unit'),
              ),
            ),
            const SizedBox(height: 12),
            if (!_loadFailed && !_isLoading) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unitRecordList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    _buildStatCard(unitRecordList[index], index),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: mobileInputDecoration(
                context,
                const InputDecoration(
                  hintText: 'Search name, serial or location',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        _selectedFilter == 'All'
                            ? 'Filter'
                            : _selectedFilter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GasPalette.ink,
                        side: BorderSide(color: GasPalette.border),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_selectedFilter != 'All')
                  IconButton(
                    tooltip: 'Clear filters',
                    onPressed: () {
                      setState(() => _selectedFilter = 'All');
                      _filterUnits();
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Tooltip(
                    message: '${_filteredUnits.length} units shown',
                    child: Semantics(
                      label: '${_filteredUnits.length} units shown',
                      excludeSemantics: true,
                      child: Text(
                        '${_filteredUnits.length}',
                        key: const ValueKey('units-result-count'),
                        style: gasSmall(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'List view',
                  onPressed: () => setState(() => _isGridView = false),
                  icon: Icon(
                    Icons.view_list_rounded,
                    color: !_isGridView ? GasPalette.primary : GasPalette.ink2,
                  ),
                ),
                IconButton(
                  tooltip: 'Grid view',
                  onPressed: () => setState(() => _isGridView = true),
                  icon: Icon(
                    Icons.grid_view_rounded,
                    color: _isGridView ? GasPalette.primary : GasPalette.ink2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ],
            _isLoading
                ? _buildLoadingState()
                : _loadFailed
                ? _buildLoadError()
                : _filteredUnits.isEmpty
                ? _buildEmptyState()
                : _buildMobileUnitList(),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader() {
    return CompactHeader(
      title: "Unit Management",
      description: "Monitor and manage refrigeration units",
      icon: Icons.inventory_2_rounded,
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Tone.bg(const Color(0xFF10B981)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.analytics_rounded,
                size: 20,
                color: Tone.fg(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              "Unit Overview",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isPhoneLayout(context)
                    ? GasPalette.ink
                    : Tone.fg(const Color(0xFF1E293B)),
              ),
            )),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isPhoneLayout(context) ? 132 : 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: unitRecordList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final record = unitRecordList[index];
              return _buildStatCard(record, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(UnitManagementRecords record, int index) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 1:
            _selectedFilter = 'Operational';
            break;
          case 2:
            _selectedFilter = 'Maintenance';
            break;
          case 3:
            _selectedFilter = 'Decommissioned';
            break;
          case 4:
            _selectedFilter = 'Maintenance Due';
            break;
          default:
            _selectedFilter = 'All';
            break;
        }
        _filterUnits();
      },
      child: Container(
        width: isPhoneLayout(context) ? null : 160,
        padding: isPhoneLayout(context)
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isPhoneLayout(context) &&
                  _selectedFilter == (index == 0 ? 'All' : record.itemName)
              ? GasPalette.primary
              : Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 32 : 16),
          border: Border.all(
            color: isPhoneLayout(context)
                ? GasPalette.border
                : record.cardColor.withOpacity(0.2),
          ),
          boxShadow: isPhoneLayout(context)
              ? const []
              : [
                  BoxShadow(
                    color: Tone.bg(Colors.black).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isPhoneLayout(context)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    index == 0 ? 'All' : record.itemName,
                    style: gasSmall(context).copyWith(
                      color:
                          _selectedFilter ==
                              (index == 0 ? 'All' : record.itemName)
                          ? Tone.auto(Colors.white)
                          : GasPalette.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.itemCount.toString(),
                    style: gasBody(context).copyWith(
                      color:
                          _selectedFilter ==
                              (index == 0 ? 'All' : record.itemName)
                          ? Tone.auto(Colors.white)
                          : GasPalette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: record.cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          record.itemIcon,
                          color: record.cardColor,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        record.itemCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isPhoneLayout(context)
                              ? GasPalette.ink
                              : Tone.fg(const Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    record.itemName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink2
                          : Tone.fg(const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchAndControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Tone.bg(Colors.white),
        border: isPhoneLayout(context)
            ? Border.all(color: GasPalette.border)
            : null,
        borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Tone.bg(Colors.black).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          MobileFormRow(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: mobileInputDecoration(
                      context,
                      InputDecoration(
                        hintText:
                            'Search units by name, serial, model, or location...',
                        hintStyle: GoogleFonts.inter(
                          color: Tone.fg(const Color(0xFF9CA3AF)),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Tone.fg(Color(0xFF6B7280)),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Tone.bg(Color(0xFFE5E7EB))),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Tone.bg(Color(0xFFE5E7EB))),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Constants.ctaColorLight, width: 2),
                        ),
                        filled: true,
                        fillColor: Tone.bg(const Color(0xFFF9FAFB)),
                      )),
                ),
              ),
              const SizedBox(width: 12),

              // Filter Button
              OutlinedButton.icon(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label:
                    Text(_selectedFilter == 'All' ? 'Filter' : _selectedFilter),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedFilter == 'All'
                      ? Tone.fg(const Color(0xFF64748B))
                      : Constants.ctaColorLight,
                  side: BorderSide(
                    color: _selectedFilter == 'All'
                        ? Tone.bg(const Color(0xFFE2E8F0))
                        : Constants.ctaColorLight,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(isPhoneLayout(context) ? 32 : 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: Tone.bg(const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isGridView = false),
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: !_isGridView
                            ? Constants.ctaColorLight
                            : Tone.fg(const Color(0xFF64748B)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isGridView = true),
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: _isGridView
                            ? Constants.ctaColorLight
                            : Tone.fg(const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedFilter != 'All') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Active filter: ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isPhoneLayout(context)
                        ? GasPalette.ink2
                        : Tone.fg(const Color(0xFF64748B)),
                  ),
                ),
                Chip(
                  label: Text(_selectedFilter),
                  onDeleted: () {
                    setState(() => _selectedFilter = 'All');
                    _filterUnits();
                  },
                  backgroundColor: Constants.ctaColorLight.withOpacity(0.1),
                  labelStyle: GoogleFonts.inter(
                    color: Constants.ctaColorLight,
                    fontWeight: FontWeight.w600,
                  ),
                  deleteIconColor: Constants.ctaColorLight,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Tone.bg(const Color(0xFF8B5CF6)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: Tone.fg(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              "Units (${_filteredUnits.length})",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isPhoneLayout(context)
                    ? GasPalette.ink
                    : Tone.fg(const Color(0xFF1E293B)),
              ),
            )),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? _buildLoadingState()
            : _loadFailed
                ? _buildLoadError()
                : _filteredUnits.isEmpty
                ? _buildEmptyState()
                : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Tone.bg(Colors.white),
        border: isPhoneLayout(context)
            ? Border.all(color: GasPalette.border)
            : null,
        borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Constants.ctaColorGreen),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading units...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Tone.fg(Colors.black54),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() => GPanel(child: AppEmptyState(
    kind: AppEmptyStateKind.offline, title: 'Units could not be loaded',
    message: 'Check your internet connection and try again.',
    actionLabel: 'Try again', onAction: _loadUnits,
  ));

  Widget _buildEmptyState() {
    final filtered = _searchController.text.isNotEmpty || _selectedFilter != 'All';
    return GPanel(child: AppEmptyState(
      kind: filtered ? AppEmptyStateKind.results : AppEmptyStateKind.devices,
      title: filtered ? 'No matching units' : 'No units yet',
      message: filtered ? 'Try another search or clear your filters.' : 'Add a unit to organise your equipment and its maintenance.',
      actionLabel: filtered ? 'Clear filters' : 'Add unit',
      onAction: filtered ? () {
        _searchController.clear();
        setState(() => _selectedFilter = 'All');
        _filterUnits();
      } : _addUnit,
    ));
  }

  Widget _buildMobileUnitCard(Unit unit) {
    final statusColor = unit.isOperational
        ? GasPalette.good
        : (unit.isUnderMaintenance ? GasPalette.warnInk : GasPalette.critInk);
    return Semantics(
      button: true,
      label: 'View ${unit.name}',
      child: InkWell(
        onTap: () => _showUnitDetails(unit),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      unit.name,
                      style: gasTitle(context)
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildQuickActions(unit),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${unit.modelNumber} · ${unit.serialNumber}',
                style: gasSmall(context),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(unit.location ?? '', style: gasSmall(context)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit.status,
                    style: gasSmall(
                      context,
                    ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUnitList() => GPanel(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < _filteredUnits.length; index++) ...[
          if (index > 0)
            Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: GasPalette.border,
            ),
          _buildMobileUnitCard(_filteredUnits[index]),
        ],
      ],
    ),
  );

  Widget _buildGridView() {
    if (isPhoneLayout(context)) return _buildMobileUnitList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredUnits.length,
      itemBuilder: (context, index) {
        final unit = _filteredUnits[index];
        return _buildUnitCard(unit);
      },
    );
  }

  Widget _buildUnitCard(Unit unit) {
    return GestureDetector(
      onTap: () => _showUnitDetails(unit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
          border: Border.all(
            color: unit.isOperational
                ? Tone.bg(Colors.green).withOpacity(0.3)
                : unit.isUnderMaintenance
                    ? Tone.bg(Colors.orange).withOpacity(0.3)
                    : Tone.bg(Colors.red).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Tone.bg(Colors.black).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: unit.isOperational
                        ? Tone.bg(Colors.green).withOpacity(0.1)
                        : unit.isUnderMaintenance
                            ? Tone.bg(Colors.orange).withOpacity(0.1)
                            : Tone.bg(Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_rounded,
                    size: 16,
                    color: unit.isOperational
                        ? Tone.fg(Colors.green)
                        : unit.isUnderMaintenance
                            ? Tone.fg(Colors.orange)
                            : Tone.fg(Colors.red),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 6,
                ),
                _buildQuickActions(unit),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              unit.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPhoneLayout(context)
                    ? GasPalette.ink
                    : Tone.fg(const Color(0xFF1E293B)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              unit.modelNumber,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isPhoneLayout(context)
                    ? GasPalette.ink2
                    : Tone.fg(const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: unit.isOperational
                    ? Tone.bg(Colors.green)
                    : unit.isUnderMaintenance
                        ? Tone.bg(Colors.orange)
                        : Tone.bg(Colors.red),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unit.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Tone.fg(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (isPhoneLayout(context)) return _buildMobileUnitList();
    return Container(
      decoration: BoxDecoration(
        color: Tone.bg(Colors.white),
        border: isPhoneLayout(context)
            ? Border.all(color: GasPalette.border)
            : null,
        borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Tone.bg(Colors.black).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Tone.bg(const Color(0xFFF8FAFC)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Unit Name',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink2
                          : Tone.fg(const Color(0xFF64748B)),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Model & Serial',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink2
                          : Tone.fg(const Color(0xFF64748B)),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Specifications',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink2
                          : Tone.fg(const Color(0xFF64748B)),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink2
                          : Tone.fg(const Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 100, child: Text('Actions')),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredUnits.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final unit = _filteredUnits[index];
              return _buildUnitRow(unit, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitRow(Unit unit, int index) {
    return GestureDetector(
      onTap: () => _showUnitDetails(unit),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Index
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Tone.bg(const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPhoneLayout(context)
                        ? GasPalette.ink2
                        : Tone.fg(const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Unit Name
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink
                          : Tone.fg(const Color(0xFF1E293B)),
                    ),
                  ),
                  if (unit.location?.isNotEmpty == true)
                    Text(
                      unit.location!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isPhoneLayout(context)
                            ? GasPalette.ink2
                            : Tone.fg(const Color(0xFF64748B)),
                      ),
                    ),
                ],
              ),
            ),

            // Model & Serial
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.modelNumber,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink
                          : Tone.fg(const Color(0xFF1E293B)),
                    ),
                  ),
                  Text(
                    'S/N: ${unit.serialNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isPhoneLayout(context)
                          ? GasPalette.ink2
                          : Tone.fg(const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),

            // Specifications
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Tone.bg(Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      unit.refrigerantType,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Tone.fg(Colors.white),
                      ),
                    ),
                  ),
                  if (unit.isMaintenanceDue) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Tone.bg(Colors.amber),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Due',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Tone.fg(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            _buildQuickActions(unit),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Unit unit) {
    return PopupMenuButton<String>(
      color: Tone.bg(Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showUnitDetails(unit);
            break;
          case 'edit':
            _editUnit(unit);
            break;
          case 'delete':
            _deleteUnit(unit.id);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_rounded,
                  size: 16, color: Constants.ctaColorLight),
              const SizedBox(width: 8),
              Text(
                'View Details',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 16, color: Tone.fg(Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Text(
                'Edit Unit',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded,
                  size: 16, color: Tone.fg(Color(0xFFEF4444))),
              const SizedBox(width: 8),
              Text(
                'Delete Unit',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Tone.fg(Color(0xFF64748B)),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showMobileDialog(
      context: context,
      builder: (context) => isPhoneLayout(context)
          ? MobileDialog(
              child: Scaffold(
                backgroundColor: GasPalette.page,
                appBar: AppBar(
                    title: const Text('Filter units'),
                    backgroundColor: GasPalette.panel,
                    foregroundColor: GasPalette.ink,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded))
                    ]),
                body: ListView(padding: const EdgeInsets.all(16), children: [
                  for (final filter in [
                    'All',
                    'Operational',
                    'Maintenance',
                    'Decommissioned',
                    'Maintenance Due'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: GasPalette.panel,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                                color: _selectedFilter == filter
                                    ? GasPalette.primary
                                    : GasPalette.border)),
                        child: ListTile(
                          title: Text(filter,
                              style: gasBody(context)
                                  .copyWith(color: GasPalette.ink)),
                          trailing: _selectedFilter == filter
                              ? Icon(Icons.check_rounded,
                                  color: GasPalette.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedFilter = filter);
                            Navigator.pop(context);
                            _filterUnits();
                          },
                        ),
                      ),
                    ),
                ]),
              ),
            )
          : MobileDialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Tone.bg(Colors.white),
                  borderRadius:
                      BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Constants.ctaColorLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.filter_list_rounded,
                              color: Tone.fg(Colors.white),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter Units',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isPhoneLayout(context)
                                  ? GasPalette.ink
                                  : Tone.fg(const Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filter Options
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          'All',
                          'Operational',
                          'Maintenance',
                          'Decommissioned',
                          'Maintenance Due'
                        ].map((filter) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedFilter == filter
                                    ? Constants.ctaColorLight
                                    : Tone.bg(const Color(0xFFE2E8F0)),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                                type: MaterialType.transparency,
                                child: RadioListTile<String>(
                                  title: Text(
                                    filter,
                                    style: GoogleFonts.inter(
                                      fontWeight: _selectedFilter == filter
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  value: filter,
                                  groupValue: _selectedFilter,
                                  activeColor: Constants.ctaColorLight,
                                  onChanged: (value) {
                                    setState(() => _selectedFilter = value!);
                                    Navigator.pop(context);
                                    _filterUnits();
                                  },
                                )),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Add and edit share the guided unit flow (unit_flow.dart).
  Future<void> _openUnitFlow({Unit? unit}) async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => UnitFlowScreen(
        unit: unit,
        onSave: (data) async {
          final businessId = await Sharedprefs.getBusinessUidSharedPreference();
          if (businessId == null) throw 'Sign in again to save this unit.';
          try {
            if (unit == null) {
              await UnitApiService.createUnit(businessId, data);
            } else {
              await UnitApiService.updateUnit(businessId, unit.id, data);
            }
          } on Exception catch (e) {
            // The API helpers wrap the server body; show its message if short.
            final match = RegExp(r'"error"\s*:\s*"([^"]{1,160})"').firstMatch('$e');
            if (match != null) throw match.group(1)!;
            rethrow;
          }
        },
      ),
    ));
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(unit == null ? 'Unit added' : '${unit.name} saved')));
    }
    _loadUnits(showLoading: unit == null);
  }

  void _addUnit() => _openUnitFlow();

  void _editUnit(Unit unit) => _openUnitFlow(unit: unit);

  void _showUnitDetails(Unit unit) {
    showMobileDialog(
      context: context,
      builder: (context) => UnitDetailsDialog(
        unit: unit,
        onEditPressed: () {
          Navigator.of(context).pop();
          _editUnit(unit);
        },
      ),
    );
  }

  Future<void> _deleteUnit(String unitId) async {
    final confirmed = await showMobileDialog<bool>(
      context: context,
      builder: (context) => MobileDialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Tone.bg(Colors.white),
            borderRadius:
                BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Tone.bg(Colors.red).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Tone.bg(Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Tone.fg(Colors.white),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confirm Delete',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isPhoneLayout(context)
                            ? GasPalette.ink
                            : Tone.fg(const Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Are you sure you want to delete this unit? This action cannot be undone.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isPhoneLayout(context)
                            ? GasPalette.ink2
                            : Tone.fg(const Color(0xFF64748B)),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    MobileFormRow(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    isPhoneLayout(context) ? 32 : 8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Tone.bg(Colors.red),
                              foregroundColor: Tone.fg(Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    isPhoneLayout(context) ? 32 : 8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Delete'),
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
      ),
    );

    if (confirmed == true) {
      try {
        int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
        if (businessId != null) {
          await UnitApiService.deleteUnit(businessId, unitId);
          _loadUnits();
          _showSuccessSnackBar('Unit deleted successfully');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete unit: ${e.toString()}');
      }
    }
  }
}

// Placeholder dialogs (to be implemented)
class UnitDetailsDialog extends StatelessWidget {
  final Unit unit;
  final VoidCallback? onEditPressed;

  const UnitDetailsDialog({
    Key? key,
    required this.unit,
    this.onEditPressed,
  }) : super(key: key);

  Widget _buildPhoneDetails(BuildContext context) {
    Widget section(String title, Map<String, String?> values) => GPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: gasTitle(context)),
          const SizedBox(height: 12),
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(entry.key, style: gasSmall(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Text(
                      (entry.value ?? '').isEmpty ? 'Not set' : entry.value!,
                      style: gasBody(context).copyWith(color: GasPalette.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    return MobileDialog(
      child: Scaffold(
        backgroundColor: GasPalette.page,
        appBar: AppBar(
          title: const Text('Unit details'),
          backgroundColor: GasPalette.panel,
          foregroundColor: GasPalette.ink,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MobileScreenHeader(
              padding: EdgeInsets.zero,
              title: unit.name,
              description: 'S/N ${unit.serialNumber}',
              bottom: Text(
                unit.status,
                style: gasSmall(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            UnitDevicesPanel(unitId: unit.id, unitName: unit.name),
            const SizedBox(height: 12),
            section('Unit information', {
              'Model': unit.modelNumber,
              'Year': unit.formattedYear,
              'Location': unit.location,
              'Company': unit.companyName,
            }),
            const SizedBox(height: 12),
            section('Technical specifications', {
              'Refrigerant': unit.refrigerantType,
              'Expansion valve': unit.expansionValveType,
              'Control': unit.controlType,
              'Compressor type': unit.compressorType,
              'Compressor model': unit.compressorModel,
              'Compressor specifications': unit.compressorSpecs,
              'Compressor power': unit.compressorHp == null
                  ? null
                  : '${unit.compressorHp} HP',
              'Compressor rating': unit.compressorAmpRating == null
                  ? null
                  : '${unit.compressorAmpRating} A',
              'Dryer type': unit.dryerType,
            }),
            const SizedBox(height: 12),
            section('Fans and evaporator', {
              'Condenser fan':
                  '${unit.condenserFanCount} × ${unit.condenserFanType} · ${unit.condenserFanPower}',
              'Evaporator fan':
                  '${unit.evaporatorFanCount} × ${unit.evaporatorFanType} · ${unit.evaporatorFanPower}',
              'Total fans': '${unit.totalFanCount}',
              'Evaporator model': unit.evaporatorModel,
              'Evaporator dimensions': unit.evaporatorDimensionsDisplay,
            }),
            const SizedBox(height: 12),
            section('Components', {
              'Orifice size': unit.orificeSize,
              'Dryer size': unit.dryerSize,
              'Oil separator': unit.oilSeparator,
              'Liquid receiver': unit.liquidReceiver,
              'Accumulator capacity': unit.accumulatorCapacity,
            }),
            const SizedBox(height: 12),
            section('Maintenance', {
              'Status': unit.maintenanceStatus,
              'Last maintenance': unit.lastMaintenanceDate == null
                  ? null
                  : _formatDate(unit.lastMaintenanceDate!),
              'Last repair': unit.lastRepairedDate == null
                  ? null
                  : _formatDate(unit.lastRepairedDate!),
              'Next scheduled maintenance':
                  unit.nextScheduledMaintenance == null
                  ? null
                  : _formatDate(unit.nextScheduledMaintenance!),
            }),
            const SizedBox(height: 12),
            section('Notes', {'Notes': unit.notes}),
            const SizedBox(height: 12),
            section('System information', {
              'Created': _formatDateTime(unit.dateCreated),
              'Last updated': _formatDateTime(unit.dateUpdated),
            }),
            if (onEditPressed != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onEditPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: GasPalette.primary,
                  foregroundColor: Tone.fg(Colors.white),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text('Edit unit'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildPhoneDetails(context);
    return MobileDialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Tone.bg(Colors.black).withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Header with gradient background
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: mobileFlatDecoration(
                  context,
                  BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Constants.ctaColorGreen,
                        Constants.ctaColorGreen.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  )),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Tone.bg(Colors.white).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing,
                      color: Tone.fg(Colors.white),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.name,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Tone.fg(Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'S/N: ${unit.serialNumber} • Model: ${unit.modelNumber}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Tone.fg(Colors.white).withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Tone.bg(Colors.white).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          unit.isOperational
                              ? Icons.check_circle
                              : unit.isUnderMaintenance
                                  ? Icons.build
                                  : Icons.error,
                          size: 16,
                          color: Tone.fg(Colors.white),
                        ),
                        SizedBox(width: 4),
                        Text(
                          unit.status,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Tone.fg(Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Material(
                    color: Tone.bg(Colors.white).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, color: Tone.fg(Colors.white), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Content Area
            Expanded(
              child: Container(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnitDevicesPanel(unitId: unit.id, unitName: unit.name),
                      const SizedBox(height: 20),
                      // Quick Info Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Year',
                              unit.formattedYear,
                              Icons.calendar_today,
                              Tone.auto(Colors.blue[50]),
                              Constants.ctaColorLight!,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Refrigerant',
                              unit.refrigerantType,
                              Icons.opacity,
                              Tone.auto(Colors.cyan[50]),
                              Tone.auto(Colors.cyan[600]),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Power',
                              unit.compressorHp != null
                                  ? '${unit.compressorHp}HP'
                                  : 'N/A',
                              Icons.power,
                              Tone.auto(Colors.red[50]),
                              Tone.auto(Colors.red[600]),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Fans',
                              '${unit.totalFanCount} Total',
                              Icons.air,
                              Tone.auto(Colors.purple[50]),
                              Tone.auto(Colors.purple[600]),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Basic Information Section
                      _buildEnhancedSection(
                        'Basic Information',
                        Icons.info_outline,
                        Tone.auto(Colors.blue),
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow('Unit Name', unit.name,
                                Icons.precision_manufacturing),
                            _buildEnhancedInfoRow('Model Number',
                                unit.modelNumber, Icons.model_training),
                            _buildEnhancedInfoRow('Serial Number',
                                unit.serialNumber, Icons.qr_code),
                            _buildEnhancedInfoRow('Year of Manufacture',
                                unit.formattedYear, Icons.calendar_today),
                            if (unit.location?.isNotEmpty == true)
                              _buildEnhancedInfoRow('Location', unit.location!,
                                  Icons.location_on),
                            _buildEnhancedInfoRow(
                                'Company', unit.companyName, Icons.business),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Technical Specifications Section
                      _buildEnhancedSection(
                        'Technical Specifications',
                        Icons.settings,
                        Tone.auto(Colors.orange),
                        null,
                        child: Column(
                          children: [
                            // Primary Systems Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSpecCard(
                                    'Refrigerant',
                                    unit.refrigerantType,
                                    Icons.opacity,
                                    Tone.auto(Colors.cyan[600]),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildSpecCard(
                                    'Compressor',
                                    unit.compressorType,
                                    Icons.settings,
                                    Tone.auto(Colors.orange[600]),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Secondary Systems Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSpecCard(
                                    'Expansion Valve',
                                    unit.expansionValveType,
                                    Icons.tune,
                                    Tone.auto(Colors.green[600]),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildSpecCard(
                                    'Control Type',
                                    unit.controlType,
                                    Icons.control_camera,
                                    Tone.auto(Colors.purple[600]),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Other specifications
                            _buildEnhancedInfoRow('Dryer Type', unit.dryerType,
                                Icons.dry_cleaning),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Compressor Details Section
                      _buildEnhancedSection(
                        'Compressor Details',
                        Icons.precision_manufacturing,
                        Tone.auto(Colors.red),
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow('Compressor Model',
                                unit.compressorModel, Icons.model_training),
                            if (unit.compressorHp != null)
                              _buildEnhancedInfoRow('Horsepower',
                                  '${unit.compressorHp} HP', Icons.power),
                            if (unit.compressorAmpRating != null)
                              _buildEnhancedInfoRow(
                                  'Amp Rating',
                                  '${unit.compressorAmpRating} A',
                                  Icons.electrical_services),
                            _buildCompressorSpecsCard(context),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Fan Configuration Section
                      _buildEnhancedSection(
                        'Fan Configuration',
                        Icons.air,
                        Tone.auto(Colors.purple),
                        null,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFanCard(
                                    'Condenser Fan',
                                    unit.condenserFanType,
                                    unit.condenserFanCount,
                                    unit.condenserFanPower,
                                    Icons.thermostat,
                                    Tone.auto(Colors.red[600]),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildFanCard(
                                    'Evaporator Fan',
                                    unit.evaporatorFanType,
                                    unit.evaporatorFanCount,
                                    unit.evaporatorFanPower,
                                    Icons.ac_unit,
                                    Constants.ctaColorLight!,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildEnhancedInfoRow('Total Fan Count',
                                '${unit.totalFanCount} fans', Icons.air),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Component Details Section
                      _buildEnhancedSection(
                        'Component Specifications',
                        Icons.engineering,
                        Tone.auto(Colors.green),
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow('Orifice Size',
                                unit.orificeSize, Icons.circle_outlined),
                            _buildEnhancedInfoRow('Dryer Size', unit.dryerSize,
                                Icons.dry_cleaning),
                            _buildEnhancedInfoRow('Oil Separator',
                                unit.oilSeparator, Icons.filter_alt),
                            _buildEnhancedInfoRow('Liquid Receiver',
                                unit.liquidReceiver, Icons.storage),
                            _buildEnhancedInfoRow(
                                'Accumulator Capacity',
                                unit.accumulatorCapacity,
                                Icons.battery_charging_full),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Evaporator Details Section
                      _buildEnhancedSection(
                        'Evaporator Details',
                        Icons.ac_unit,
                        Tone.auto(Colors.blue),
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow('Evaporator Model',
                                unit.evaporatorModel, Icons.model_training),
                            _buildEvaporatorDimensionsCard(context),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Maintenance Information Section
                      _buildEnhancedSection(
                        'Maintenance Information',
                        Icons.build,
                        Tone.auto(Colors.amber),
                        null,
                        child: Column(
                          children: [
                            _buildMaintenanceStatusCard(),
                            SizedBox(height: 16),
                            _buildMaintenanceTimeline(),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // System Information Section
                      _buildEnhancedSection(
                        'System Information',
                        Icons.computer,
                        Tone.auto(Colors.grey),
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow(
                              'Created',
                              _formatDateTime(unit.dateCreated),
                              Icons.event_available,
                            ),
                            _buildEnhancedInfoRow(
                              'Last Updated',
                              _formatDateTime(unit.dateUpdated),
                              Icons.update,
                            ),
                            if (unit.notes?.isNotEmpty == true)
                              _buildNotesCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Enhanced Action Buttons
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Tone.bg(Colors.grey[50]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Tone.bg(Colors.grey[200]), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    'Close',
                    Icons.close,
                    Tone.auto(Colors.grey[600]),
                    () => Navigator.of(context).pop(),
                    isSecondary: true,
                  ),
                  SizedBox(width: 16),
                  if (onEditPressed != null)
                    _buildActionButton(
                      'Edit Unit',
                      Icons.edit,
                      Constants.ctaColorGreen,
                      onEditPressed!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard(String title, String value, IconData icon,
      Color bgColor, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Tone.fg(Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSection(
      String title, IconData icon, Color color, Widget? action,
      {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Tone.bg(Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tone.bg(Colors.grey[200])),
        boxShadow: [
          BoxShadow(
            color: Tone.bg(Colors.black).withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Tone.bg(Colors.grey[100]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Tone.fg(Colors.grey[600])),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Tone.fg(Colors.grey[700]),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Tone.fg(Colors.black87),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Tone.fg(Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanCard(String title, String type, int count, String power,
      IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            type,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Tone.fg(Colors.black87),
              ),
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${count}x',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Tone.fg(Colors.grey[600]),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                power,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 11,
                    color: Tone.fg(Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompressorSpecsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: mobileFlatDecoration(
          context,
          BoxDecoration(
            gradient: LinearGradient(
              colors: [Tone.auto(Colors.red[50]), Tone.auto(Colors.orange[50])],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Tone.bg(Colors.red[200])),
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.power, size: 24, color: Tone.fg(Colors.red[600])),
              SizedBox(width: 12),
              Text(
                'Compressor Specifications',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Tone.fg(Colors.red[800]),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            unit.compressorSpecs,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Tone.fg(Colors.red[900]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaporatorDimensionsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: mobileFlatDecoration(
          context,
          BoxDecoration(
            gradient: LinearGradient(
              colors: [Tone.auto(Colors.blue[50]), Tone.auto(Colors.cyan[50])],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Tone.bg(Colors.blue[200])),
          )),
      child: Row(
        children: [
          Icon(Icons.straighten, size: 32, color: Constants.ctaColorLight),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaporator Dimensions',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Constants.ctaColorLight,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  unit.evaporatorDimensionsDisplay,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Tone.fg(Colors.blue[900]),
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

  Widget _buildMaintenanceStatusCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unit.isMaintenanceDue
            ? Constants.ctaColorLight.withOpacity(0.08)
            : Tone.bg(Colors.green[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              unit.isMaintenanceDue ? Tone.bg(Colors.amber[300]) : Tone.bg(Colors.green[300]),
        ),
      ),
      child: Row(
        children: [
          Icon(
            unit.isMaintenanceDue ? Icons.warning_amber : Icons.check_circle,
            size: 32,
            color: unit.isMaintenanceDue
                ? Constants.ctaColorLight
                : Tone.fg(Colors.green[700]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance Status',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: unit.isMaintenanceDue
                          ? Constants.ctaColorLight
                          : Tone.fg(Colors.green[800]),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  unit.maintenanceStatus,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: unit.isMaintenanceDue
                          ? Tone.fg(Colors.amber[900])
                          : Tone.fg(Colors.green[900]),
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

  Widget _buildMaintenanceTimeline() {
    List<Widget> timelineItems = [];

    if (unit.lastMaintenanceDate != null) {
      timelineItems.add(_buildTimelineItem(
        'Last Maintenance',
        _formatDate(unit.lastMaintenanceDate!),
        Icons.handyman,
        Tone.auto(Colors.green[600]),
        isFirst: timelineItems.isEmpty,
      ));
    }

    if (unit.lastRepairedDate != null) {
      timelineItems.add(_buildTimelineItem(
        'Last Repair',
        _formatDate(unit.lastRepairedDate!),
        Icons.build_circle,
        Tone.auto(Colors.orange[600]),
        isFirst: timelineItems.isEmpty,
      ));
    }

    if (unit.nextScheduledMaintenance != null) {
      timelineItems.add(_buildTimelineItem(
        'Next Maintenance',
        _formatDate(unit.nextScheduledMaintenance!),
        unit.isMaintenanceDue ? Icons.warning : Icons.schedule,
        unit.isMaintenanceDue ? Tone.auto(Colors.red[600]) : Constants.ctaColorLight!,
        isFirst: timelineItems.isEmpty,
        isLast: true,
        isFuture: !unit.isMaintenanceDue,
      ));
    }

    if (timelineItems.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Tone.bg(Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Tone.fg(Colors.grey[600])),
            SizedBox(width: 12),
            Text(
              'No maintenance records available',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Tone.fg(Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: timelineItems);
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
    bool isFuture = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: Tone.bg(Colors.grey[300]),
              ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: Tone.bg(Colors.grey[300]),
              ),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 13,
                      color: Tone.fg(Colors.grey[700]),
                      fontStyle: isFuture ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Tone.bg(Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Tone.bg(Colors.grey[300])),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Tone.fg(Colors.grey[600]), size: 20),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Tone.fg(Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            unit.notes!,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: Tone.fg(Colors.grey[800]),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isSecondary = false,
  }) {
    return Material(
      color: isSecondary ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSecondary ? Border.all(color: color) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSecondary ? color : Tone.fg(Colors.white),
              ),
              SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSecondary ? color : Tone.fg(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// API Service for Unit Management
class UnitApiService {
  static final String _baseUrl = Constants.articBaseUrl2;

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  static Future<Map<String, dynamic>> fetchUnitsManagement(
      int businessId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/units/management/list/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == false) throw Exception('Units unavailable');
      List<dynamic> unitList = responseData['units'] ?? [];
      List<Unit> units =
          unitList.map((dynamic item) => Unit.fromJson(item)).toList();

      return {
        'units': units,
        'statistics': Map<String, dynamic>.from(responseData['statistics'] as Map? ?? {}),
      };
    } else {
      throw Exception('Failed to load units: ${response.body}');
    }
  }

  static Future<Unit> createUnit(
      int businessId, Map<String, dynamic> unitData) async {
    unitData['business_id'] = businessId;

    final response = await http.post(
      Uri.parse('${_baseUrl}api/units/management/create/'),
      headers: await _getHeaders(),
      body: jsonEncode(unitData),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Unit.fromJson(responseData['unit']);
    } else {
      throw Exception('Failed to create unit: ${response.body}');
    }
  }

  static Future<Unit> updateUnit(
      int businessId, String unitId, Map<String, dynamic> unitData) async {
    unitData['business_id'] = businessId;
    unitData['unit_id'] = unitId;

    final response = await http.post(
      Uri.parse('${_baseUrl}api/units/management/update/'),
      headers: await _getHeaders(),
      body: jsonEncode(unitData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Unit.fromJson(responseData['unit']);
    } else {
      throw Exception('Failed to update unit: ${response.body}');
    }
  }

  static Future<bool> deleteUnit(int businessId, String unitId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/units/management/delete/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "unit_id": unitId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete unit: ${response.body}');
    }
  }

  static Future<Unit> getUnitDetail(int businessId, String unitId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/units/management/detail/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "unit_id": unitId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Unit.fromJson(responseData['unit']);
    } else {
      throw Exception('Failed to get unit details: ${response.body}');
    }
  }
}
