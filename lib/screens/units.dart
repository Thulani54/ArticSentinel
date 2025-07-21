import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../models/unit.dart';
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
    print('Starting auto-refresh timer for Unit Management at ${DateTime.now()}');
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
    print('_loadUnits called for Unit Management with showLoading: $showLoading at ${DateTime.now()}');
    
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        final result = await UnitApiService.fetchUnitsManagement(businessId);
        
        if (mounted) {
          setState(() {
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
          
          print('Unit Management data refreshed successfully at ${lastRefreshTime}');
        }
      } else {
        if (mounted) {
          setState(() {
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
        setState(() => _isLoading = false);
        if (showLoading) {
          _showErrorSnackBar('Failed to load units: ${e.toString()}');
        }
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
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
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
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
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
        const Color(0xFF10B981),
      ),
      UnitManagementRecords(
        _statistics['maintenance_units'] ?? 0,
        "Maintenance",
        Icons.build_rounded,
        const Color(0xFFF59E0B),
      ),
      UnitManagementRecords(
        _statistics['decommissioned_units'] ?? 0,
        "Decommissioned",
        Icons.cancel_rounded,
        const Color(0xFFEF4444),
      ),
      UnitManagementRecords(
        _statistics['maintenance_due_units'] ?? 0,
        "Maintenance Due",
        Icons.warning_amber_rounded,
        const Color(0xFFF97316),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Cards
                          _buildStatisticsSection(),

                          const SizedBox(height: 32),

                          // Search and Controls
                          _buildSearchAndControls(),

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
            if (lastRefreshTime != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Updated ${_formatRefreshTime(lastRefreshTime!)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
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
        onPressed: _addUnit,
        backgroundColor: Constants.ctaColorLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Unit',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

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
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                size: 20,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Unit Overview",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
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
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: record.cardColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    color: const Color(0xFF1E293B),
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
                color: const Color(0xFF64748B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search units by name, serial, model, or location...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF6B7280),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Constants.ctaColorLight, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
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
                      ? const Color(0xFF64748B)
                      : Constants.ctaColorLight,
                  side: BorderSide(
                    color: _selectedFilter == 'All'
                        ? const Color(0xFFE2E8F0)
                        : Constants.ctaColorLight,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
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
                            : const Color(0xFF64748B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isGridView = true),
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: _isGridView
                            ? Constants.ctaColorLight
                            : const Color(0xFF64748B),
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
                    color: const Color(0xFF64748B),
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
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Units (${_filteredUnits.length})",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? _buildLoadingState()
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
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorGreen),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading units...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.precision_manufacturing_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No units found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your search or filters'
                  : 'Get started by adding your first unit',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            if (_searchController.text.isNotEmpty ||
                _selectedFilter != 'All') ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedFilter = 'All');
                  _filterUnits();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unit.isOperational
                ? Colors.green.withOpacity(0.3)
                : unit.isUnderMaintenance
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                        ? Colors.green.withOpacity(0.1)
                        : unit.isUnderMaintenance
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_rounded,
                    size: 16,
                    color: unit.isOperational
                        ? Colors.green
                        : unit.isUnderMaintenance
                            ? Colors.orange
                            : Colors.red,
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
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              unit.modelNumber,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: unit.isOperational
                    ? Colors.green
                    : unit.isUnderMaintenance
                        ? Colors.orange
                        : Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unit.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFFF8FAFC),
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
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Model & Serial',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Specifications',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
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
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (unit.location?.isNotEmpty == true)
                    Text(
                      unit.location!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
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
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'S/N: ${unit.serialNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      unit.refrigerantType,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (unit.isMaintenanceDue) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Due',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
      color: Colors.white,
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
              const Icon(Icons.edit_rounded,
                  size: 16, color: Color(0xFFF59E0B)),
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
              const Icon(Icons.delete_rounded,
                  size: 16, color: Color(0xFFEF4444)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filter Units',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
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
                              : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      ),
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

  void _addUnit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddUnitDialog(),
    ).then((_) {
      // Force refresh with loading indicator after adding unit
      _loadUnits(showLoading: true);
    });
  }

  void _editUnit(Unit unit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditUnitDialog(unit: unit),
    ).then((_) => _loadUnits());
  }

  void _showUnitDetails(Unit unit) {
    showDialog(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
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
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confirm Delete',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
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
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
class AddUnitDialog extends StatefulWidget {
  @override
  State<AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<AddUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  // Form Controllers
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _yearController =
      TextEditingController(text: DateTime.now().year.toString());
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  // Technical Specifications Controllers
  final _orificeSizeController = TextEditingController(text: 'Standard');
  final _dryerSizeController = TextEditingController(text: 'Medium');
  final _oilSeparatorController =
      TextEditingController(text: 'Standard Oil Sep');
  final _liquidReceiverController = TextEditingController(text: '10L Receiver');
  final _accumulatorCapacityController = TextEditingController(text: '5L');

  // Compressor Controllers
  final _compressorModelController =
      TextEditingController(text: 'Standard Compressor');
  final _compressorHpController = TextEditingController(text: '2.0');
  final _compressorAmpRatingController = TextEditingController(text: '8.5');

  // Evaporator Controllers
  final _evaporatorModelController =
      TextEditingController(text: 'Standard Evaporator');
  final _evaporatorLengthController = TextEditingController(text: '1.2');
  final _evaporatorWidthController = TextEditingController(text: '0.8');
  final _evaporatorHeightController = TextEditingController(text: '0.6');

  // Fan Controllers
  final _condenserFanCountController = TextEditingController(text: '1');
  final _condenserFanPowerController = TextEditingController(text: '250W');
  final _evaporatorFanCountController = TextEditingController(text: '1');
  final _evaporatorFanPowerController = TextEditingController(text: '150W');

  // Dropdown Values (with defaults)
  String _selectedStatus = 'operational';
  String _selectedRefrigerantType = 'r404a';
  String _selectedExpansionValveType = 'internal';
  String _selectedControlType = 'electronic';
  String _selectedCompressorType = 'scroll';
  String _selectedDryerType = 'flare';
  String _selectedCondenserFanType = 'axial';
  String _selectedEvaporatorFanType = 'axial';

  // Date Controllers
  DateTime? _lastMaintenanceDate;
  DateTime? _lastRepairedDate;
  DateTime? _nextScheduledMaintenance;

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _serialNumberController.dispose();
    _modelNumberController.dispose();
    _yearController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _orificeSizeController.dispose();
    _dryerSizeController.dispose();
    _oilSeparatorController.dispose();
    _liquidReceiverController.dispose();
    _accumulatorCapacityController.dispose();
    _compressorModelController.dispose();
    _compressorHpController.dispose();
    _compressorAmpRatingController.dispose();
    _evaporatorModelController.dispose();
    _evaporatorLengthController.dispose();
    _evaporatorWidthController.dispose();
    _evaporatorHeightController.dispose();
    _condenserFanCountController.dispose();
    _condenserFanPowerController.dispose();
    _evaporatorFanCountController.dispose();
    _evaporatorFanPowerController.dispose();
    super.dispose();
  }

  Future<void> _addUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
      if (businessId != null) {
        Map<String, dynamic> unitData = {
          'name': _nameController.text,
          'serial_number': _serialNumberController.text,
          'model_number': _modelNumberController.text,
          'year': int.tryParse(_yearController.text) ?? DateTime.now().year,
          'location': _locationController.text,
          'status': _selectedStatus,
          'refrigerant_type': _selectedRefrigerantType,
          'expansion_valve_type': _selectedExpansionValveType,
          'control_type': _selectedControlType,
          'compressor_type': _selectedCompressorType,
          'dryer_type': _selectedDryerType,
          'orifice_size': _orificeSizeController.text,
          'dryer_size': _dryerSizeController.text,
          'oil_separator': _oilSeparatorController.text,
          'liquid_receiver': _liquidReceiverController.text,
          'accumulator_capacity': _accumulatorCapacityController.text,
          'compressor_model': _compressorModelController.text,
          'compressor_hp': double.tryParse(_compressorHpController.text),
          'compressor_amp_rating':
              double.tryParse(_compressorAmpRatingController.text),
          'evaporator_model': _evaporatorModelController.text,
          'evaporator_length':
              double.tryParse(_evaporatorLengthController.text),
          'evaporator_width': double.tryParse(_evaporatorWidthController.text),
          'evaporator_height':
              double.tryParse(_evaporatorHeightController.text),
          'condenser_fan_type': _selectedCondenserFanType,
          'condenser_fan_count':
              int.tryParse(_condenserFanCountController.text) ?? 1,
          'condenser_fan_power': _condenserFanPowerController.text,
          'evaporator_fan_type': _selectedEvaporatorFanType,
          'evaporator_fan_count':
              int.tryParse(_evaporatorFanCountController.text) ?? 1,
          'evaporator_fan_power': _evaporatorFanPowerController.text,
          'last_maintenance_date':
              _lastMaintenanceDate?.toIso8601String().split('T')[0],
          'last_repaired_date':
              _lastRepairedDate?.toIso8601String().split('T')[0],
          'next_scheduled_maintenance':
              _nextScheduledMaintenance?.toIso8601String().split('T')[0],
          'notes': _notesController.text,
        };

        await UnitApiService.createUnit(businessId, unitData);

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Unit created successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to create unit: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
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
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.add_circle, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Unit',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create a new refrigeration unit',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress Indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Step ${_currentStep + 1} of 4',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Welcome Message (only on first step)
            if (_currentStep == 0) ...[
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.cyan[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb,
                        color: Constants.ctaColorLight, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Getting Started',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This wizard will guide you through creating a new refrigeration unit with all technical specifications.',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Constants.ctaColorLight,
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

            // Stepper Content
            Expanded(
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    setState(() {
                      _currentStep = step;
                    });
                  },
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        if (details.stepIndex > 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = details.stepIndex - 1;
                              });
                            },
                            child: Text('Previous'),
                          ),
                        SizedBox(width: 8),
                        if (details.stepIndex < 3)
                          ElevatedButton(
                            onPressed: () {
                              if (details.stepIndex == 0) {
                                // Validate basic info before proceeding
                                if (_nameController.text.isEmpty ||
                                    _serialNumberController.text.isEmpty ||
                                    _modelNumberController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please fill in all required fields'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() {
                                _currentStep = details.stepIndex + 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Next'),
                          ),
                        if (details.stepIndex == 3)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _addUnit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text('Create Unit'),
                          ),
                      ],
                    );
                  },
                  steps: [
                    // Step 1: Basic Information
                    Step(
                      title: Text('Basic Information'),
                      content: _buildBasicInformationStep(),
                      isActive: _currentStep >= 0,
                    ),
                    // Step 2: Technical Specifications
                    Step(
                      title: Text('Technical Specifications'),
                      content: _buildTechnicalSpecificationsStep(),
                      isActive: _currentStep >= 1,
                    ),
                    // Step 3: Components & Dimensions
                    Step(
                      title: Text('Components & Dimensions'),
                      content: _buildComponentsStep(),
                      isActive: _currentStep >= 2,
                    ),
                    // Step 4: Maintenance & Notes
                    Step(
                      title: Text('Maintenance & Review'),
                      content: _buildMaintenanceStep(),
                      isActive: _currentStep >= 3,
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

  Widget _buildBasicInformationStep() {
    return Column(
      children: [
        // Required fields notice
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Constants.ctaColorLight.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Constants.ctaColorLight),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Constants.ctaColorLight, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fields marked with * are required to create a unit',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Constants.ctaColorLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _nameController,
                label: 'Unit Name *',
                icon: Icons.precision_manufacturing,
                hintText: 'e.g., Main Walk-in Chiller',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit name';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _serialNumberController,
                label: 'Serial Number *',
                icon: Icons.qr_code,
                hintText: 'e.g., CHU-2024-001',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter serial number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _modelNumberController,
                label: 'Model Number *',
                icon: Icons.model_training,
                hintText: 'e.g., RC-500L-DUAL',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter model number';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _yearController,
                label: 'Year of Manufacture',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year';
                  }
                  int? year = int.tryParse(value);
                  if (year == null ||
                      year < 1990 ||
                      year > DateTime.now().year) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                hintText: 'e.g., Kitchen 1, Rooftop East',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Initial Status',
                icon: Icons.info,
                value: _selectedStatus,
                items: [
                  {'value': 'operational', 'display': 'Operational'},
                  {'value': 'maintenance', 'display': 'Under Maintenance'},
                  {'value': 'decommissioned', 'display': 'Decommissioned'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicalSpecificationsStep() {
    return Column(
      children: [
        // Help text
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.settings, color: Constants.ctaColorLight, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configure the technical specifications for your refrigeration unit',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Constants.ctaColorLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Refrigeration System
        _buildSectionHeader('Refrigeration System', Icons.opacity),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Refrigerant Type',
                icon: Icons.opacity,
                value: _selectedRefrigerantType,
                items: [
                  {'value': 'r404a', 'display': 'R-404A'},
                  {'value': 'r22', 'display': 'R-22'},
                  {'value': 'r134a', 'display': 'R-134a'},
                  {'value': 'r410a', 'display': 'R-410A'},
                  {'value': 'other', 'display': 'Other'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRefrigerantType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Expansion Valve',
                icon: Icons.tune,
                value: _selectedExpansionValveType,
                items: [
                  {'value': 'internal', 'display': 'Internal'},
                  {'value': 'external', 'display': 'External'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedExpansionValveType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Control & Compressor System
        _buildSectionHeader('Control & Compressor System', Icons.settings),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Control Type',
                icon: Icons.control_camera,
                value: _selectedControlType,
                items: [
                  {'value': 'electronic', 'display': 'Electronic'},
                  {'value': 'mechanical', 'display': 'Thermostat'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedControlType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Compressor Type',
                icon: Icons.settings,
                value: _selectedCompressorType,
                items: [
                  {'value': 'scroll', 'display': 'Scroll'},
                  {'value': 'harmonic', 'display': 'Harmonic'},
                  {'value': 'reciprocating', 'display': 'Reciprocating'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCompressorType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _compressorModelController,
                label: 'Compressor Model',
                icon: Icons.precision_manufacturing,
                hintText: 'e.g., Copeland ZR94KC',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Dryer Type',
                icon: Icons.dry_cleaning,
                value: _selectedDryerType,
                items: [
                  {'value': 'flare', 'display': 'Flare'},
                  {'value': 'swage', 'display': 'Swage'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDryerType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComponentsStep() {
    return Column(
      children: [
        // Power Specifications
        _buildSectionHeader('Power Specifications', Icons.power),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _compressorHpController,
                label: 'Compressor HP',
                icon: Icons.power,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                hintText: 'e.g., 2.0',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _compressorAmpRatingController,
                label: 'Compressor Amp Rating',
                icon: Icons.electrical_services,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                hintText: 'e.g., 8.5',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Component Specifications
        _buildSectionHeader('Component Specifications', Icons.engineering),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _orificeSizeController,
                label: 'Orifice Size',
                icon: Icons.circle_outlined,
                hintText: 'e.g., 0.5mm or Standard',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _dryerSizeController,
                label: 'Dryer Size',
                icon: Icons.dry_cleaning,
                hintText: 'e.g., Small, Medium, Large',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _oilSeparatorController,
                label: 'Oil Separator',
                icon: Icons.filter_alt,
                hintText: 'e.g., Standard Oil Sep',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _liquidReceiverController,
                label: 'Liquid Receiver',
                icon: Icons.storage,
                hintText: 'e.g., 10L Receiver',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _accumulatorCapacityController,
          label: 'Accumulator Capacity',
          icon: Icons.battery_charging_full,
          hintText: 'e.g., 5L',
        ),
        SizedBox(height: 16),

        // Fan Configuration
        _buildSectionHeader('Fan Configuration', Icons.air),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Condenser Fan Type',
                icon: Icons.thermostat,
                value: _selectedCondenserFanType,
                items: [
                  {'value': 'axial', 'display': 'Axial'},
                  {'value': 'centrifugal', 'display': 'Centrifugal'},
                  {'value': 'mixed_flow', 'display': 'Mixed Flow'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCondenserFanType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _condenserFanCountController,
                label: 'Condenser Fan Count',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                hintText: 'e.g., 1',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _condenserFanPowerController,
                label: 'Condenser Fan Power',
                icon: Icons.power,
                hintText: 'e.g., 250W',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Evaporator Fan Type',
                icon: Icons.ac_unit,
                value: _selectedEvaporatorFanType,
                items: [
                  {'value': 'axial', 'display': 'Axial'},
                  {'value': 'centrifugal', 'display': 'Centrifugal'},
                  {'value': 'mixed_flow', 'display': 'Mixed Flow'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEvaporatorFanType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                  controller: _evaporatorFanCountController,
                  label: 'Evaporator Fan Count',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  hintText: 'e.g., 1'),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorFanPowerController,
                label: 'Evaporator Fan Power',
                icon: Icons.power,
                hintText: 'e.g., 150W',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Evaporator Dimensions
        _buildSectionHeader('Evaporator Dimensions', Icons.straighten),
        _buildTextField(
          controller: _evaporatorModelController,
          label: 'Evaporator Model',
          icon: Icons.ac_unit,
          hintText: 'e.g., Standard Evaporator',
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _evaporatorLengthController,
                label: 'Length (m)',
                icon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                hintText: 'e.g., 1.2',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorWidthController,
                label: 'Width (m)',
                icon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                hintText: 'e.g., 0.8',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorHeightController,
                label: 'Height (m)',
                icon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                hintText: 'e.g., 0.6',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaintenanceStep() {
    return Column(
      children: [
        // Summary header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Almost Done!',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add maintenance information and review your unit details before creating.',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Maintenance Information
        _buildSectionHeader('Maintenance Information', Icons.build),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Last Maintenance Date',
                icon: Icons.build_circle,
                selectedDate: _lastMaintenanceDate,
                onDateSelected: (date) {
                  setState(() {
                    _lastMaintenanceDate = date;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Last Repaired Date',
                icon: Icons.handyman,
                selectedDate: _lastRepairedDate,
                onDateSelected: (date) {
                  setState(() {
                    _lastRepairedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildDateField(
          label: 'Next Scheduled Maintenance',
          icon: Icons.schedule,
          selectedDate: _nextScheduledMaintenance,
          onDateSelected: (date) {
            setState(() {
              _nextScheduledMaintenance = date;
            });
          },
        ),
        SizedBox(height: 16),

        // Notes Section
        _buildSectionHeader('Additional Notes', Icons.note),
        _buildTextField(
          controller: _notesController,
          label: 'Notes',
          icon: Icons.note,
          hintText: 'Any additional information about this unit...',
          maxLines: 4,
        ),
        SizedBox(height: 20),

        // Unit Summary
        _buildSectionHeader('Unit Summary', Icons.list),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                  'Unit Name',
                  _nameController.text.isEmpty
                      ? 'Not specified'
                      : _nameController.text),
              _buildSummaryRow(
                  'Serial Number',
                  _serialNumberController.text.isEmpty
                      ? 'Not specified'
                      : _serialNumberController.text),
              _buildSummaryRow(
                  'Model Number',
                  _modelNumberController.text.isEmpty
                      ? 'Not specified'
                      : _modelNumberController.text),
              _buildSummaryRow(
                  'Year',
                  _yearController.text.isEmpty
                      ? 'Not specified'
                      : _yearController.text),
              _buildSummaryRow(
                  'Location',
                  _locationController.text.isEmpty
                      ? 'Not specified'
                      : _locationController.text),
              _buildSummaryRow('Status', _selectedStatus),
              _buildSummaryRow(
                  'Refrigerant Type', _selectedRefrigerantType.toUpperCase()),
              _buildSummaryRow('Compressor Type', _selectedCompressorType),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Constants.ctaColorGreen, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 16),
              height: 1,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Constants.ctaColorGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Constants.ctaColorGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Constants.ctaColorGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Constants.ctaColorGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['display']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required void Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Constants.ctaColorGreen,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Constants.ctaColorGreen),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select date',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: selectedDate != null
                            ? Colors.black87
                            : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditUnitDialog extends StatefulWidget {
  final Unit unit;

  const EditUnitDialog({Key? key, required this.unit}) : super(key: key);

  @override
  State<EditUnitDialog> createState() => _EditUnitDialogState();
}

class _EditUnitDialogState extends State<EditUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _serialNumberController;
  late TextEditingController _modelNumberController;
  late TextEditingController _yearController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  // Technical Specifications Controllers
  late TextEditingController _orificeSizeController;
  late TextEditingController _dryerSizeController;
  late TextEditingController _oilSeparatorController;
  late TextEditingController _liquidReceiverController;
  late TextEditingController _accumulatorCapacityController;

  // Compressor Controllers
  late TextEditingController _compressorModelController;
  late TextEditingController _compressorHpController;
  late TextEditingController _compressorAmpRatingController;

  // Evaporator Controllers
  late TextEditingController _evaporatorModelController;
  late TextEditingController _evaporatorLengthController;
  late TextEditingController _evaporatorWidthController;
  late TextEditingController _evaporatorHeightController;

  // Fan Controllers
  late TextEditingController _condenserFanCountController;
  late TextEditingController _condenserFanPowerController;
  late TextEditingController _evaporatorFanCountController;
  late TextEditingController _evaporatorFanPowerController;

  // Dropdown Values
  String _selectedStatus = 'operational';
  String _selectedRefrigerantType = 'r404a';
  String _selectedExpansionValveType = 'internal';
  String _selectedControlType = 'electronic';
  String _selectedCompressorType = 'scroll';
  String _selectedDryerType = 'flare';
  String _selectedCondenserFanType = 'axial';
  String _selectedEvaporatorFanType = 'axial';

  // Date Controllers
  DateTime? _lastMaintenanceDate;
  DateTime? _lastRepairedDate;
  DateTime? _nextScheduledMaintenance;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Basic Information
    _nameController = TextEditingController(text: widget.unit.name);
    _serialNumberController =
        TextEditingController(text: widget.unit.serialNumber);
    _modelNumberController =
        TextEditingController(text: widget.unit.modelNumber);
    _yearController = TextEditingController(text: widget.unit.year.toString());
    _locationController =
        TextEditingController(text: widget.unit.location ?? '');
    _notesController = TextEditingController(text: widget.unit.notes ?? '');

    // Technical Specifications
    _orificeSizeController =
        TextEditingController(text: widget.unit.orificeSize);
    _dryerSizeController = TextEditingController(text: widget.unit.dryerSize);
    _oilSeparatorController =
        TextEditingController(text: widget.unit.oilSeparator);
    _liquidReceiverController =
        TextEditingController(text: widget.unit.liquidReceiver);
    _accumulatorCapacityController =
        TextEditingController(text: widget.unit.accumulatorCapacity);

    // Compressor
    _compressorModelController =
        TextEditingController(text: widget.unit.compressorModel);
    _compressorHpController =
        TextEditingController(text: widget.unit.compressorHp?.toString() ?? '');
    _compressorAmpRatingController = TextEditingController(
        text: widget.unit.compressorAmpRating?.toString() ?? '');

    // Evaporator
    _evaporatorModelController =
        TextEditingController(text: widget.unit.evaporatorModel);
    _evaporatorLengthController = TextEditingController(
        text: widget.unit.evaporatorLength?.toString() ?? '');
    _evaporatorWidthController = TextEditingController(
        text: widget.unit.evaporatorWidth?.toString() ?? '');
    _evaporatorHeightController = TextEditingController(
        text: widget.unit.evaporatorHeight?.toString() ?? '');

    // Fans
    _condenserFanCountController =
        TextEditingController(text: widget.unit.condenserFanCount.toString());
    _condenserFanPowerController =
        TextEditingController(text: widget.unit.condenserFanPower);
    _evaporatorFanCountController =
        TextEditingController(text: widget.unit.evaporatorFanCount.toString());
    _evaporatorFanPowerController =
        TextEditingController(text: widget.unit.evaporatorFanPower);

    // Dropdown values
    _selectedStatus = widget.unit.statusValue;
    _selectedRefrigerantType = widget.unit.refrigerantTypeValue;
    _selectedExpansionValveType = widget.unit.expansionValveTypeValue;
    _selectedControlType = widget.unit.controlTypeValue;
    _selectedCompressorType = widget.unit.compressorTypeValue;
    _selectedDryerType = widget.unit.dryerTypeValue;
    _selectedCondenserFanType = widget.unit.condenserFanTypeValue;
    _selectedEvaporatorFanType = widget.unit.evaporatorFanTypeValue;

    // Dates
    _lastMaintenanceDate = widget.unit.lastMaintenanceDate != null
        ? DateTime.parse(widget.unit.lastMaintenanceDate!)
        : null;
    _lastRepairedDate = widget.unit.lastRepairedDate != null
        ? DateTime.parse(widget.unit.lastRepairedDate!)
        : null;
    _nextScheduledMaintenance = widget.unit.nextScheduledMaintenance != null
        ? DateTime.parse(widget.unit.nextScheduledMaintenance!)
        : null;
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _serialNumberController.dispose();
    _modelNumberController.dispose();
    _yearController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _orificeSizeController.dispose();
    _dryerSizeController.dispose();
    _oilSeparatorController.dispose();
    _liquidReceiverController.dispose();
    _accumulatorCapacityController.dispose();
    _compressorModelController.dispose();
    _compressorHpController.dispose();
    _compressorAmpRatingController.dispose();
    _evaporatorModelController.dispose();
    _evaporatorLengthController.dispose();
    _evaporatorWidthController.dispose();
    _evaporatorHeightController.dispose();
    _condenserFanCountController.dispose();
    _condenserFanPowerController.dispose();
    _evaporatorFanCountController.dispose();
    _evaporatorFanPowerController.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
      if (businessId != null) {
        Map<String, dynamic> unitData = {
          'name': _nameController.text,
          'serial_number': _serialNumberController.text,
          'model_number': _modelNumberController.text,
          'year': int.tryParse(_yearController.text) ?? widget.unit.year,
          'location': _locationController.text,
          'status': _selectedStatus,
          'refrigerant_type': _selectedRefrigerantType,
          'expansion_valve_type': _selectedExpansionValveType,
          'control_type': _selectedControlType,
          'compressor_type': _selectedCompressorType,
          'dryer_type': _selectedDryerType,
          'orifice_size': _orificeSizeController.text,
          'dryer_size': _dryerSizeController.text,
          'oil_separator': _oilSeparatorController.text,
          'liquid_receiver': _liquidReceiverController.text,
          'accumulator_capacity': _accumulatorCapacityController.text,
          'compressor_model': _compressorModelController.text,
          'compressor_hp': double.tryParse(_compressorHpController.text),
          'compressor_amp_rating':
              double.tryParse(_compressorAmpRatingController.text),
          'evaporator_model': _evaporatorModelController.text,
          'evaporator_length':
              double.tryParse(_evaporatorLengthController.text),
          'evaporator_width': double.tryParse(_evaporatorWidthController.text),
          'evaporator_height':
              double.tryParse(_evaporatorHeightController.text),
          'condenser_fan_type': _selectedCondenserFanType,
          'condenser_fan_count':
              int.tryParse(_condenserFanCountController.text) ?? 1,
          'condenser_fan_power': _condenserFanPowerController.text,
          'evaporator_fan_type': _selectedEvaporatorFanType,
          'evaporator_fan_count':
              int.tryParse(_evaporatorFanCountController.text) ?? 1,
          'evaporator_fan_power': _evaporatorFanPowerController.text,
          'last_maintenance_date':
              _lastMaintenanceDate?.toIso8601String().split('T')[0],
          'last_repaired_date':
              _lastRepairedDate?.toIso8601String().split('T')[0],
          'next_scheduled_maintenance':
              _nextScheduledMaintenance?.toIso8601String().split('T')[0],
          'notes': _notesController.text,
        };

        await UnitApiService.updateUnit(businessId, widget.unit.id, unitData);

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Unit updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to update unit: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
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
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Unit',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${widget.unit.name} (${widget.unit.serialNumber})',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress Indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Step ${_currentStep + 1} of 4',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stepper Content
            Expanded(
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    setState(() {
                      _currentStep = step;
                    });
                  },
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        if (details.stepIndex > 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = details.stepIndex - 1;
                              });
                            },
                            child: Text('Previous'),
                          ),
                        SizedBox(width: 8),
                        if (details.stepIndex < 3)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = details.stepIndex + 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Next'),
                          ),
                        if (details.stepIndex == 3)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveUnit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text('Save Unit'),
                          ),
                      ],
                    );
                  },
                  steps: [
                    // Step 1: Basic Information
                    Step(
                      title: Text('Basic Information'),
                      content: _buildBasicInformationStep(),
                      isActive: _currentStep >= 0,
                    ),
                    // Step 2: Technical Specifications
                    Step(
                      title: Text('Technical Specifications'),
                      content: _buildTechnicalSpecificationsStep(),
                      isActive: _currentStep >= 1,
                    ),
                    // Step 3: Components & Dimensions
                    Step(
                      title: Text('Components & Dimensions'),
                      content: _buildComponentsStep(),
                      isActive: _currentStep >= 2,
                    ),
                    // Step 4: Maintenance & Notes
                    Step(
                      title: Text('Maintenance & Notes'),
                      content: _buildMaintenanceStep(),
                      isActive: _currentStep >= 3,
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

  Widget _buildBasicInformationStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _nameController,
                label: 'Unit Name',
                icon: Icons.precision_manufacturing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit name';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _serialNumberController,
                label: 'Serial Number',
                icon: Icons.qr_code,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter serial number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _modelNumberController,
                label: 'Model Number',
                icon: Icons.model_training,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter model number';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _yearController,
                label: 'Year of Manufacture',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year';
                  }
                  int? year = int.tryParse(value);
                  if (year == null ||
                      year < 1990 ||
                      year > DateTime.now().year) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _locationController,
                label: 'Location (Optional)',
                icon: Icons.location_on,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Status',
                icon: Icons.info,
                value: _selectedStatus,
                items: [
                  {'value': 'operational', 'display': 'Operational'},
                  {'value': 'maintenance', 'display': 'Under Maintenance'},
                  {'value': 'decommissioned', 'display': 'Decommissioned'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicalSpecificationsStep() {
    return Column(
      children: [
        // Refrigeration System
        _buildSectionHeader('Refrigeration System', Icons.opacity),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Refrigerant Type',
                icon: Icons.opacity,
                value: _selectedRefrigerantType,
                items: [
                  {'value': 'r404a', 'display': 'R-404A'},
                  {'value': 'r22', 'display': 'R-22'},
                  {'value': 'r134a', 'display': 'R-134a'},
                  {'value': 'r410a', 'display': 'R-410A'},
                  {'value': 'other', 'display': 'Other'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRefrigerantType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Expansion Valve',
                icon: Icons.tune,
                value: _selectedExpansionValveType,
                items: [
                  {'value': 'internal', 'display': 'Internal'},
                  {'value': 'external', 'display': 'External'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedExpansionValveType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Control & Compressor System
        _buildSectionHeader('Control & Compressor System', Icons.settings),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Control Type',
                icon: Icons.control_camera,
                value: _selectedControlType,
                items: [
                  {'value': 'electronic', 'display': 'Electronic'},
                  {'value': 'mechanical', 'display': 'Thermostat'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedControlType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Compressor Type',
                icon: Icons.settings,
                value: _selectedCompressorType,
                items: [
                  {'value': 'scroll', 'display': 'Scroll'},
                  {'value': 'harmonic', 'display': 'Harmonic'},
                  {'value': 'reciprocating', 'display': 'Reciprocating'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCompressorType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _compressorModelController,
                label: 'Compressor Model',
                icon: Icons.precision_manufacturing,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Dryer Type',
                icon: Icons.dry_cleaning,
                value: _selectedDryerType,
                items: [
                  {'value': 'flare', 'display': 'Flare'},
                  {'value': 'swage', 'display': 'Swage'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDryerType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComponentsStep() {
    return Column(
      children: [
        // Power Specifications
        _buildSectionHeader('Power Specifications', Icons.power),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _compressorHpController,
                label: 'Compressor HP',
                icon: Icons.power,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _compressorAmpRatingController,
                label: 'Compressor Amp Rating',
                icon: Icons.electrical_services,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Component Specifications
        _buildSectionHeader('Component Specifications', Icons.engineering),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _orificeSizeController,
                label: 'Orifice Size',
                icon: Icons.circle_outlined,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _dryerSizeController,
                label: 'Dryer Size',
                icon: Icons.dry_cleaning,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _oilSeparatorController,
                label: 'Oil Separator',
                icon: Icons.filter_alt,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _liquidReceiverController,
                label: 'Liquid Receiver',
                icon: Icons.storage,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _accumulatorCapacityController,
          label: 'Accumulator Capacity',
          icon: Icons.battery_charging_full,
        ),
        SizedBox(height: 16),

        // Fan Configuration
        _buildSectionHeader('Fan Configuration', Icons.air),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Condenser Fan Type',
                icon: Icons.thermostat,
                value: _selectedCondenserFanType,
                items: [
                  {'value': 'axial', 'display': 'Axial'},
                  {'value': 'centrifugal', 'display': 'Centrifugal'},
                  {'value': 'mixed_flow', 'display': 'Mixed Flow'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCondenserFanType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _condenserFanCountController,
                label: 'Condenser Fan Count',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _condenserFanPowerController,
                label: 'Condenser Fan Power',
                icon: Icons.power,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Evaporator Fan Type',
                icon: Icons.ac_unit,
                value: _selectedEvaporatorFanType,
                items: [
                  {'value': 'axial', 'display': 'Axial'},
                  {'value': 'centrifugal', 'display': 'Centrifugal'},
                  {'value': 'mixed_flow', 'display': 'Mixed Flow'},
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEvaporatorFanType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorFanCountController,
                label: 'Evaporator Fan Count',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorFanPowerController,
                label: 'Evaporator Fan Power',
                icon: Icons.power,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Evaporator Dimensions
        _buildSectionHeader('Evaporator Dimensions', Icons.straighten),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _evaporatorModelController,
                label: 'Evaporator Model',
                icon: Icons.model_training,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _evaporatorLengthController,
                label: 'Length (m)',
                icon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorWidthController,
                label: 'Width (m)',
                icon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _evaporatorHeightController,
                label: 'Height (m)',
                icon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaintenanceStep() {
    return Column(
      children: [
        // Maintenance Dates
        _buildSectionHeader('Maintenance Dates', Icons.calendar_today),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Last Maintenance Date',
                icon: Icons.handyman,
                selectedDate: _lastMaintenanceDate,
                onDateSelected: (date) {
                  setState(() {
                    _lastMaintenanceDate = date;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Last Repaired Date',
                icon: Icons.build_circle,
                selectedDate: _lastRepairedDate,
                onDateSelected: (date) {
                  setState(() {
                    _lastRepairedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildDateField(
          label: 'Next Scheduled Maintenance',
          icon: Icons.schedule,
          selectedDate: _nextScheduledMaintenance,
          onDateSelected: (date) {
            setState(() {
              _nextScheduledMaintenance = date;
            });
          },
        ),
        SizedBox(height: 24),

        // Notes Section
        _buildSectionHeader('Notes & Additional Information', Icons.note),
        _buildTextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          icon: Icons.note,
          maxLines: 4,
          hintText:
              'Enter any additional notes or specifications for this unit...',
        ),

        SizedBox(height: 24),

        // Summary Card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Constants.ctaColorGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Constants.ctaColorGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Constants.ctaColorGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Review Summary',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Constants.ctaColorGreen,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Unit: ${_nameController.text}',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                'Model: ${_modelNumberController.text} • S/N: ${_serialNumberController.text}',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Refrigerant: ${_getDisplayValue(_selectedRefrigerantType, 'refrigerant')} • Compressor: ${_getDisplayValue(_selectedCompressorType, 'compressor')}',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (_compressorHpController.text.isNotEmpty)
                Text(
                  'Power: ${_compressorHpController.text}HP • Status: ${_getDisplayValue(_selectedStatus, 'status')}',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Constants.ctaColorGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: Constants.ctaColorGreen),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Constants.ctaColorGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Constants.ctaColorGreen),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Constants.ctaColorGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Constants.ctaColorGreen),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value']!,
          child: Text(item['display']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required void Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(Duration(days: 365 * 5)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: Constants.ctaColorGreen),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select date',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 16,
                        color: selectedDate != null
                            ? Colors.black87
                            : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  String _getDisplayValue(String value, String type) {
    switch (type) {
      case 'refrigerant':
        switch (value) {
          case 'r404a':
            return 'R-404A';
          case 'r22':
            return 'R-22';
          case 'r134a':
            return 'R-134a';
          case 'r410a':
            return 'R-410A';
          case 'other':
            return 'Other';
          default:
            return value;
        }
      case 'compressor':
        switch (value) {
          case 'scroll':
            return 'Scroll';
          case 'harmonic':
            return 'Harmonic';
          case 'reciprocating':
            return 'Reciprocating';
          default:
            return value;
        }
      case 'status':
        switch (value) {
          case 'operational':
            return 'Operational';
          case 'maintenance':
            return 'Under Maintenance';
          case 'decommissioned':
            return 'Decommissioned';
          default:
            return value;
        }
      default:
        return value;
    }
  }
}

class UnitDetailsDialog extends StatelessWidget {
  final Unit unit;
  final VoidCallback? onEditPressed;

  const UnitDetailsDialog({
    Key? key,
    required this.unit,
    this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
              decoration: BoxDecoration(
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
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing,
                      color: Colors.white,
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
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'S/N: ${unit.serialNumber} • Model: ${unit.modelNumber}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
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
                      color: Colors.white.withOpacity(0.2),
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
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          unit.status,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
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
                      // Quick Info Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Year',
                              unit.formattedYear,
                              Icons.calendar_today,
                              Colors.blue[50]!,
                              Constants.ctaColorLight!,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Refrigerant',
                              unit.refrigerantType,
                              Icons.opacity,
                              Colors.cyan[50]!,
                              Colors.cyan[600]!,
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
                              Colors.red[50]!,
                              Colors.red[600]!,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Fans',
                              '${unit.totalFanCount} Total',
                              Icons.air,
                              Colors.purple[50]!,
                              Colors.purple[600]!,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Basic Information Section
                      _buildEnhancedSection(
                        'Basic Information',
                        Icons.info_outline,
                        Colors.blue,
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
                        Colors.orange,
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
                                    Colors.cyan[600]!,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildSpecCard(
                                    'Compressor',
                                    unit.compressorType,
                                    Icons.settings,
                                    Colors.orange[600]!,
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
                                    Colors.green[600]!,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildSpecCard(
                                    'Control Type',
                                    unit.controlType,
                                    Icons.control_camera,
                                    Colors.purple[600]!,
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
                        Colors.red,
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
                            _buildCompressorSpecsCard(),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Fan Configuration Section
                      _buildEnhancedSection(
                        'Fan Configuration',
                        Icons.air,
                        Colors.purple,
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
                                    Colors.red[600]!,
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
                        Colors.green,
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
                        Colors.blue,
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow('Evaporator Model',
                                unit.evaporatorModel, Icons.model_training),
                            _buildEvaporatorDimensionsCard(),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Maintenance Information Section
                      _buildEnhancedSection(
                        'Maintenance Information',
                        Icons.build,
                        Colors.amber,
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
                        Colors.grey,
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
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    'Close',
                    Icons.close,
                    Colors.grey[600]!,
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
                color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
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
                  color: Colors.grey[700],
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
                  color: Colors.black87,
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
                color: Colors.black87,
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
                color: Colors.black87,
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
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                power,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompressorSpecsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.orange[50]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.power, size: 24, color: Colors.red[600]),
              SizedBox(width: 12),
              Text(
                'Compressor Specifications',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
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
                color: Colors.red[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaporatorDimensionsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.cyan[50]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
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
                      color: Colors.blue[900],
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
            : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              unit.isMaintenanceDue ? Colors.amber[300]! : Colors.green[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            unit.isMaintenanceDue ? Icons.warning_amber : Icons.check_circle,
            size: 32,
            color: unit.isMaintenanceDue
                ? Constants.ctaColorLight
                : Colors.green[700],
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
                          : Colors.green[800],
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
                          ? Colors.amber[900]
                          : Colors.green[900],
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
        Colors.green[600]!,
        isFirst: timelineItems.isEmpty,
      ));
    }

    if (unit.lastRepairedDate != null) {
      timelineItems.add(_buildTimelineItem(
        'Last Repair',
        _formatDate(unit.lastRepairedDate!),
        Icons.build_circle,
        Colors.orange[600]!,
        isFirst: timelineItems.isEmpty,
      ));
    }

    if (unit.nextScheduledMaintenance != null) {
      timelineItems.add(_buildTimelineItem(
        'Next Maintenance',
        _formatDate(unit.nextScheduledMaintenance!),
        unit.isMaintenanceDue ? Icons.warning : Icons.schedule,
        unit.isMaintenanceDue ? Colors.red[600]! : Constants.ctaColorLight!,
        isFirst: timelineItems.isEmpty,
        isLast: true,
        isFuture: !unit.isMaintenanceDue,
      ));
    }

    if (timelineItems.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600]),
            SizedBox(width: 12),
            Text(
              'No maintenance records available',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
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
                color: Colors.grey[300],
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
                color: Colors.grey[300],
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
                      color: Colors.grey[700],
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
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
                color: Colors.grey[800],
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
                color: isSecondary ? color : Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSecondary ? color : Colors.white,
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
      List<dynamic> unitList = responseData['units'] ?? [];
      List<Unit> units =
          unitList.map((dynamic item) => Unit.fromJson(item)).toList();

      return {
        'units': units,
        'statistics': responseData['statistics'] ?? {},
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
