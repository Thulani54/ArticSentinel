import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/Constants.dart';
import '../constants/models/device.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import '../models/device.dart';
import '../models/unit.dart';
import '../services/shared_preferences.dart';
import '../widgets/compact_header.dart';

class DeviceManagementRecords {
  int itemCount;
  String itemName;
  IconData itemIcon;
  Color cardColor;

  DeviceManagementRecords(
      this.itemCount, this.itemName, this.itemIcon, this.cardColor);
}

class DeviceManagement extends StatefulWidget {
  const DeviceManagement({super.key});

  @override
  State<DeviceManagement> createState() => _DeviceManagementState();
}

class _DeviceManagementState extends State<DeviceManagement>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Device> _allDevices = [];
  List<Device> _filteredDevices = [];
  List<Unit> _availableUnits = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  bool _isGridView = false;

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
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterDevices();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        await Future.wait([
          _loadDevices(businessId),
          _loadUnits(businessId),
        ]);
        _animationController.forward();
      } else {
        _allDevices = [];
        _filteredDevices = [];
        _availableUnits = [];
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDevices(int businessId) async {
    _allDevices = await ApiService.fetchDevices(businessId);
    _filteredDevices = List.from(_allDevices);
  }

  Future<void> _loadUnits(int businessId) async {
    _availableUnits = await ApiService.fetchUnits(businessId);
  }

  void _filterDevices() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredDevices = _allDevices.where((device) {
        bool matchesSearch = query.isEmpty ||
            device.name.toLowerCase().contains(query) ||
            device.deviceId.toLowerCase().contains(query) ||
            (device.location?.toLowerCase().contains(query) ?? false) ||
            (device.manufacturer?.toLowerCase().contains(query) ?? false) ||
            (device.connectedUnit?.name.toLowerCase().contains(query) ?? false);

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Active' && device.isActive) ||
            (_selectedFilter == 'Inactive' && !device.isActive) ||
            (_selectedFilter == 'Online' && device.isOnline) ||
            (_selectedFilter == 'Offline' && !device.isOnline) ||
            (_selectedFilter == 'Service Due' && device.isServiceDue) ||
            (_selectedFilter == 'Warranty Expired' &&
                !device.isWarrantyValid) ||
            (_selectedFilter == 'With Unit' && device.connectedUnit != null) ||
            (_selectedFilter == 'Without Unit' && device.connectedUnit == null);

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

  List<DeviceManagementRecords> get deviceRecordList {
    int totalDevices = _allDevices.length;
    int activeDevices = _allDevices.where((d) => d.isActive).length;
    int inactiveDevices = _allDevices.where((d) => !d.isActive).length;
    int onlineDevices = _allDevices.where((d) => d.isOnline).length;
    int serviceDueDevices = _allDevices.where((d) => d.isServiceDue).length;
    int warrantyExpiredDevices =
        _allDevices.where((d) => !d.isWarrantyValid).length;
    int devicesWithUnits =
        _allDevices.where((d) => d.connectedUnit != null).length;
    int devicesWithoutUnits =
        _allDevices.where((d) => d.connectedUnit == null).length;

    return [
      DeviceManagementRecords(
        totalDevices,
        "Total Devices",
        Icons.devices_rounded,
        Constants.ctaColorLight,
      ),
      DeviceManagementRecords(
        activeDevices,
        "Active",
        Icons.check_circle_rounded,
        const Color(0xFF10B981),
      ),
      DeviceManagementRecords(
        inactiveDevices,
        "Inactive",
        Icons.cancel_rounded,
        const Color(0xFFEF4444),
      ),
      DeviceManagementRecords(
        onlineDevices,
        "Online",
        Icons.wifi_rounded,
        const Color(0xFF06B6D4),
      ),
      DeviceManagementRecords(
        serviceDueDevices,
        "Service Due",
        Icons.warning_amber_rounded,
        const Color(0xFFF59E0B),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1000,
      child: SafeArea(
        child: FadeTransition(
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

                      // Devices Display
                      _buildDevicesSection(),
                      const SizedBox(height: 24),
                      FloatingActionButton.extended(
                        onPressed: _addDevice,
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'Add Device',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const CompactHeader(
      title: "Device Management",
      description: "Monitor and manage IoT devices",
      icon: Icons.devices_rounded,
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
              "Device Overview",
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
            itemCount: deviceRecordList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final record = deviceRecordList[index];
              return _buildStatCard(record, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(DeviceManagementRecords record, int index) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 1:
            _selectedFilter = 'Active';
            break;
          case 2:
            _selectedFilter = 'Inactive';
            break;
          case 3:
            _selectedFilter = 'Online';
            break;
          case 4:
            _selectedFilter = 'Service Due';
            break;
          default:
            _selectedFilter = 'All';
            break;
        }
        _filterDevices();
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
                        'Search devices by name, ID, unit, or location...',
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
                          const BorderSide(color: Color(0xFF3B82F6), width: 2),
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
                    _filterDevices();
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

  Widget _buildDevicesSection() {
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
                Icons.device_hub_rounded,
                size: 20,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Devices (${_filteredDevices.length})",
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
            : _filteredDevices.isEmpty
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
      child: const Center(
        child: CircularProgressIndicator(),
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
              Icons.devices_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
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
                  : 'Get started by adding your first device',
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
                  _filterDevices();
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
      itemCount: _filteredDevices.length,
      itemBuilder: (context, index) {
        final device = _filteredDevices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(Device device) {
    return GestureDetector(
      onTap: () => _showDeviceDetails(device),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: device.isActive
                ? (device.isOnline
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3))
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
                    color: device.isActive
                        ? (device.isOnline
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1))
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.devices_rounded,
                    size: 16,
                    color: device.isActive
                        ? (device.isOnline ? Colors.green : Colors.grey)
                        : Colors.red,
                  ),
                ),
                const Spacer(),
                _buildQuickActions(device),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              device.name,
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
              device.deviceId,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: device.isActive
                    ? (device.isOnline ? Colors.green : Colors.grey)
                    : Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                device.statusDisplay,
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
                    'Device Name',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Device ID',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Connected Unit',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Location',
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
            itemCount: _filteredDevices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final device = _filteredDevices[index];
              return _buildDeviceRow(device, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(Device device, int index) {
    return GestureDetector(
      onTap: () => _showDeviceDetails(device),
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

            // Device Name
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (device.deviceType != null)
                    Text(
                      device.deviceTypeDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),

            // Device ID
            Expanded(
              child: Text(
                device.deviceId,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),

            // Connected Unit
            Expanded(
              child: device.connectedUnit != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.connectedUnit!.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'S/N: ${device.connectedUnit!.serialNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (device.connectedUnit!.isMaintenanceDue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Maintenance Due',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No Unit',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),

            // Location
            Expanded(
              child: Text(
                device.location ?? 'N/A',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),

            // Status
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.isActive
                      ? (device.isOnline ? Colors.green : Colors.grey)
                      : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  device.statusDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 6,
            ),

            // Actions
            _buildQuickActions(device),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Device device) {
    return PopupMenuButton<String>(
      color: Colors.white,
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showDeviceDetails(device);
            break;
          case 'edit':
            _editDevice(device);
            break;
          case 'unit':
            _showChangeUnitDialog(device);
            break;
          case 'delete':
            _deleteDevice(device.id!);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility_rounded,
                  size: 16, color: Color(0xFF3B82F6)),
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
                'Edit Device',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'unit',
          child: Row(
            children: [
              const Icon(Icons.link_rounded,
                  size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'Change Unit',
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
                'Delete Device',
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
                      'Filter Devices',
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
                    'Active',
                    'Inactive',
                    'Online',
                    'Offline',
                    'Service Due',
                    'Warranty Expired',
                    'With Unit',
                    'Without Unit'
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
                          _filterDevices();
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

  void _addDevice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddDeviceDialog(availableUnits: _availableUnits),
    ).then((_) => _loadData());
  }

  void _editDevice(Device device) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          EditDeviceDialog(device: device, availableUnits: _availableUnits),
    ).then((_) => _loadData());
  }

  void _showDeviceDetails(Device device) {
    showDialog(
      context: context,
      builder: (context) => DeviceDetailsDialog(
        device: device,
        onEditPressed: () {
          Navigator.of(context).pop();
          _editDevice(device);
        },
        onChangeUnit: () {
          Navigator.of(context).pop();
          _showChangeUnitDialog(device);
        },
      ),
    );
  }

  void _showChangeUnitDialog(Device device) {
    showDialog(
      context: context,
      builder: (context) => ChangeUnitDialog(
        device: device,
        availableUnits: _availableUnits,
        onUnitChanged: _loadData,
      ),
    );
  }

  Future<void> _deleteDevice(int deviceId) async {
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
                      'Are you sure you want to delete this device? This action cannot be undone.',
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
          await ApiService.deleteDevice(businessId, deviceId);
          _loadData();
          _showSuccessSnackBar('Device deleted successfully');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete device: ${e.toString()}');
      }
    }
  }
}

class DeviceDetailsDialog extends StatelessWidget {
  final Device device;
  final VoidCallback? onEditPressed;
  final VoidCallback? onChangeUnit;

  const DeviceDetailsDialog({
    Key? key,
    required this.device,
    this.onEditPressed,
    this.onChangeUnit,
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
                    Constants.ctaColorLight,
                    Constants.ctaColorLight.withOpacity(0.8)
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
                      device.deviceType == 'chiller'
                          ? Icons.ac_unit
                          : Icons.kitchen,
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
                          device.name,
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
                          'Device ID: ${device.deviceId}',
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
                  // Status indicators
                  Row(
                    children: [
                      _buildStatusBadge(
                        device.isActive ? 'Active' : 'Inactive',
                        device.isActive ? Colors.green[400]! : Colors.red[400]!,
                        Icons.power_settings_new,
                      ),
                      SizedBox(width: 8),
                      _buildStatusBadge(
                        device.isOnline ? 'Online' : 'Offline',
                        device.isOnline ? Colors.blue[400]! : Colors.grey[400]!,
                        device.isOnline ? Icons.wifi : Icons.wifi_off,
                      ),
                    ],
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
                              'Type',
                              device.deviceTypeDisplay,
                              Icons.category,
                              Colors.blue[50]!,
                              Colors.blue[600]!,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Phase',
                              device.phaseType ?? 'Not set',
                              Icons.electrical_services,
                              Colors.orange[50]!,
                              Colors.orange[600]!,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Capacity',
                              device.capacity ?? 'Not set',
                              Icons.storage,
                              Colors.purple[50]!,
                              Colors.purple[600]!,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Connected Unit Section with enhanced styling
                      _buildEnhancedSection(
                        'Connected Unit Information',
                        Icons.link,
                        Colors.teal,
                        onChangeUnit != null
                            ? _buildActionButton(
                                device.connectedUnit != null
                                    ? 'Change Unit'
                                    : 'Connect Unit',
                                Icons.swap_horiz,
                                Constants.ctaColorLight,
                                onChangeUnit!,
                              )
                            : null,
                        child: device.connectedUnit != null
                            ? _buildConnectedUnitInfo()
                            : _buildNoUnitConnected(),
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
                            _buildEnhancedInfoRow('Product ID',
                                device.productId ?? 'Not set', Icons.inventory),
                            _buildEnhancedInfoRow(
                                'Manufacturer',
                                device.manufacturer ?? 'Not set',
                                Icons.business),
                            _buildEnhancedInfoRow(
                                'Model',
                                device.model ?? 'Not set',
                                Icons.precision_manufacturing),
                            _buildEnhancedInfoRow(
                                'Serial Number',
                                device.serialNumber ?? 'Not set',
                                Icons.qr_code),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Location Information Section
                      _buildEnhancedSection(
                        'Location Information',
                        Icons.location_on,
                        Colors.red,
                        null,
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow('Location',
                                device.location ?? 'Not set', Icons.place),
                            _buildEnhancedInfoRow('Building',
                                device.building ?? 'Not set', Icons.apartment),
                            _buildEnhancedInfoRow('Floor',
                                device.floor ?? 'Not set', Icons.layers),
                            _buildEnhancedInfoRow('Room',
                                device.room ?? 'Not set', Icons.meeting_room),
                            if (device.fullLocation.isNotEmpty)
                              _buildEnhancedInfoRow('Full Address',
                                  device.fullLocation, Icons.location_city),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Temperature Settings Section
                      _buildEnhancedSection(
                        'Temperature Settings',
                        Icons.thermostat,
                        Colors.orange,
                        null,
                        child: Column(
                          children: [
                            _buildTemperatureCard(),
                            if (device.targetTempMin != null)
                              _buildEnhancedInfoRow(
                                'Minimum Temperature',
                                '${device.targetTempMin!.toStringAsFixed(1)}°C',
                                Icons.ac_unit,
                              ),
                            if (device.targetTempMax != null)
                              _buildEnhancedInfoRow(
                                'Maximum Temperature',
                                '${device.targetTempMax!.toStringAsFixed(1)}°C',
                                Icons.whatshot,
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Status Information Section
                      _buildEnhancedSection(
                        'Status Information',
                        Icons.health_and_safety,
                        Colors.green,
                        null,
                        child: Column(
                          children: [
                            _buildStatusGrid(),
                            if (device.lastPing != null)
                              _buildEnhancedInfoRow(
                                'Last Communication',
                                _formatDateTime(device.lastPing!),
                                Icons.access_time,
                              ),
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
                            if (device.createdAt != null)
                              _buildEnhancedInfoRow(
                                'Created',
                                _formatDateTime(device.createdAt!),
                                Icons.event_available,
                              ),
                            if (device.updatedAt != null)
                              _buildEnhancedInfoRow(
                                'Last Updated',
                                _formatDateTime(device.updatedAt!),
                                Icons.update,
                              ),
                            if (device.companyName != null)
                              _buildEnhancedInfoRow(
                                'Company',
                                device.companyName!,
                                Icons.corporate_fare,
                              ),
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
                      'Edit Device',
                      Icons.edit,
                      Constants.ctaColorLight,
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

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
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

  Widget _buildConnectedUnitInfo() {
    final unit = device.connectedUnit!;
    return Column(
      children: [
        // Unit Overview Card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[50]!, Colors.teal[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.precision_manufacturing,
                      color: Colors.teal[600], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.name,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                            ),
                          ),
                        ),
                        Text(
                          '${unit.modelNumber} • S/N: ${unit.serialNumber}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.teal[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: unit.status.toLowerCase() == 'operational'
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      unit.status,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: unit.status.toLowerCase() == 'operational'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (unit.isMaintenanceDue) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.amber[700], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Maintenance Due',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),

        // Technical Specifications
        _buildUnitSpecsGrid(),
      ],
    );
  }

  Widget _buildUnitSpecsGrid() {
    final unit = device.connectedUnit!;
    return Column(
      children: [
        // Row 1: Refrigerant and Compressor
        Row(
          children: [
            Expanded(
              child: _buildSpecCard(
                'Refrigerant',
                unit.refrigerantType,
                Icons.opacity,
                Colors.blue[600]!,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSpecCard(
                'Compressor',
                unit.compressorType,
                Icons.settings,
                Colors.grey[600]!,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Row 2: Compressor Details
        if (unit.compressorModel.isNotEmpty) ...[
          _buildEnhancedInfoRow('Compressor Model', unit.compressorModel,
              Icons.precision_manufacturing),
        ],
        if (unit.compressorHp != null) ...[
          _buildEnhancedInfoRow(
              'Compressor HP', '${unit.compressorHp} HP', Icons.power),
        ],
        if (unit.compressorAmpRating != null) ...[
          _buildEnhancedInfoRow('Amp Rating', '${unit.compressorAmpRating} A',
              Icons.electrical_services),
        ],

        // Component Details
        _buildEnhancedInfoRow(
            'Orifice Size', unit.orificeSize, Icons.circle_outlined),
        _buildEnhancedInfoRow('Dryer Size', unit.dryerSize, Icons.dry_cleaning),
        _buildEnhancedInfoRow(
            'Oil Separator', unit.oilSeparator, Icons.filter_alt),
        _buildEnhancedInfoRow(
            'Liquid Receiver', unit.liquidReceiver, Icons.storage),
        _buildEnhancedInfoRow('Accumulator', unit.accumulatorCapacity,
            Icons.battery_charging_full),

        // Fan Information
        SizedBox(height: 16),
        Text(
          'Fan Configuration',
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFanCard(
                'Condenser',
                unit.condenserFan,
                Icons.air,
                Colors.red[600]!,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildFanCard(
                'Evaporator',
                unit.evaporatorFan,
                Icons.ac_unit,
                Colors.blue[600]!,
              ),
            ),
          ],
        ),

        // Evaporator Details
        if (unit.evaporatorModel.isNotEmpty) ...[
          SizedBox(height: 12),
          _buildEnhancedInfoRow('Evaporator Model', unit.evaporatorModel,
              Icons.precision_manufacturing),
        ],
        _buildEnhancedInfoRow('Evaporator Dimensions',
            unit.evaporatorDimensions, Icons.straighten),

        if (unit.location?.isNotEmpty == true) ...[
          SizedBox(height: 12),
          _buildEnhancedInfoRow(
              'Unit Location', unit.location!, Icons.location_on),
        ],
      ],
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

  Widget _buildFanCard(String title, FanInfo fan, IconData icon, Color color) {
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
            '${fan.type} (${fan.count}x)',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            fan.power,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUnitConnected() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'No Unit Connected',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This device is not connected to any refrigeration unit. Connect it to a unit to see technical specifications and performance data.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.red[50]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.device_thermostat, size: 32, color: Colors.orange[600]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature Range',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  device.temperatureRange,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
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

  Widget _buildStatusGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Active',
                device.isActive,
                Icons.power_settings_new,
                device.isActive ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Online',
                device.isOnline,
                device.isOnline ? Icons.wifi : Icons.wifi_off,
                device.isOnline ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Repair Mode',
                device.isInRepairMode,
                Icons.build,
                device.isInRepairMode ? Colors.orange : Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Warranty',
                device.isWarrantyValid,
                device.isWarrantyValid
                    ? Icons.verified_user
                    : Icons.error_outline,
                device.isWarrantyValid ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      String title, bool status, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 8),
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
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status ? 'Yes' : 'No',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTimeline() {
    return Column(
      children: [
        if (device.installationDate != null)
          _buildTimelineItem(
            'Installation',
            device.formattedInstallationDate,
            Icons.build_circle,
            Colors.blue[600]!,
            isFirst: true,
          ),
        if (device.lastServiceDate != null)
          _buildTimelineItem(
            'Last Service',
            device.lastServiceDate!,
            Icons.handyman,
            Colors.green[600]!,
          ),
        if (device.nextServiceDate != null)
          _buildTimelineItem(
            'Next Service',
            device.nextServiceDate!,
            device.isServiceDue ? Icons.warning : Icons.schedule,
            device.isServiceDue ? Colors.red[600]! : Colors.orange[600]!,
            isFuture: !device.isServiceDue,
          ),
        if (device.warrantyExpiry != null)
          _buildTimelineItem(
            'Warranty Expires',
            device.warrantyExpiry!,
            device.isWarrantyValid ? Icons.shield : Icons.shield_outlined,
            device.isWarrantyValid ? Colors.green[600]! : Colors.red[600]!,
            isLast: true,
          ),
      ],
    );
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
}

// Change Unit Dialog
class ChangeUnitDialog extends StatefulWidget {
  final Device device;
  final List<Unit> availableUnits;
  final VoidCallback? onUnitChanged;

  const ChangeUnitDialog({
    Key? key,
    required this.device,
    required this.availableUnits,
    this.onUnitChanged,
  }) : super(key: key);

  @override
  State<ChangeUnitDialog> createState() => _ChangeUnitDialogState();
}

class _ChangeUnitDialogState extends State<ChangeUnitDialog> {
  String? _selectedUnitId;
  bool _isLoading = false;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.device.connectedUnit?.id;

    // Find the current unit index
    if (_selectedUnitId != null) {
      _selectedIndex = widget.availableUnits
          .indexWhere((unit) => unit.id == _selectedUnitId);
    }
  }

  Future<void> _changeUnit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
      if (businessId != null) {
        await ApiService.changeDeviceUnit(
            businessId, widget.device.id!, _selectedUnitId);

        if (widget.onUnitChanged != null) {
          widget.onUnitChanged!();
        }

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Unit connection updated successfully'),
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
              Expanded(
                  child: Text(
                      'Failed to update unit connection: ${e.toString()}')),
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
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
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
                    Constants.ctaColorLight,
                    Constants.ctaColorLight.withOpacity(0.8)
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
                        Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Connected Unit',
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
                          '${widget.device.name} (${widget.device.deviceId})',
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

            // Current Unit Information
            if (widget.device.connectedUnit != null) ...[
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: Colors.blue[600], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Currently Connected Unit',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildCurrentUnitCard(widget.device.connectedUnit!),
                  ],
                ),
              ),
            ],

            // Unit Selection Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.list_alt,
                      color: Constants.ctaColorLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Select New Unit:',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${widget.availableUnits.length} units available',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Units List
            Expanded(
              child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Disconnect Option
                    _buildDisconnectOption(),

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(horizontal: 16),
                    ),

                    // Units List
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: widget.availableUnits.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final unit = widget.availableUnits[index];
                          final isCurrentUnit =
                              unit.id == widget.device.connectedUnit?.id;
                          final isSelected = unit.id == _selectedUnitId;

                          return _buildUnitCard(
                              unit, isCurrentUnit, isSelected, index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
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
                    'Cancel',
                    Icons.close,
                    Colors.grey[600]!,
                    _isLoading ? null : () => Navigator.of(context).pop(),
                    isSecondary: true,
                  ),
                  SizedBox(width: 16),
                  _buildActionButton(
                    _isLoading ? 'Updating...' : 'Update Connection',
                    _isLoading ? Icons.hourglass_empty : Icons.check,
                    Constants.ctaColorLight,
                    _isLoading ? null : _changeUnit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUnitCard(ConnectedUnit unit) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.name,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: unit.status.toLowerCase() == 'operational'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unit.status,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: unit.status.toLowerCase() == 'operational'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Model: ${unit.modelNumber} • S/N: ${unit.serialNumber}',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectOption() {
    final isSelected = _selectedUnitId == null;

    return Container(
      margin: EdgeInsets.all(16),
      child: Material(
        color: isSelected ? Colors.red[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedUnitId = null;
              _selectedIndex = -1;
            });
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.red[300]! : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<String?>(
                  value: null,
                  groupValue: _selectedUnitId,
                  onChanged: (value) {
                    setState(() {
                      _selectedUnitId = value;
                      _selectedIndex = -1;
                    });
                  },
                  activeColor: Colors.red[600],
                ),
                SizedBox(width: 12),
                Icon(Icons.link_off, color: Colors.red[600], size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disconnect from Unit',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Remove unit connection from this device',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.red[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(
      Unit unit, bool isCurrentUnit, bool isSelected, int index) {
    return Material(
      color: isSelected
          ? Constants.ctaColorLight.withOpacity(0.1)
          : isCurrentUnit
              ? Colors.blue[50]
              : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedUnitId = unit.id;
            _selectedIndex = index;
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Constants.ctaColorLight
                  : isCurrentUnit
                      ? Colors.blue[300]!
                      : Colors.grey[300]!,
              width: isSelected || isCurrentUnit ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  Radio<String>(
                    value: unit.id,
                    groupValue: _selectedUnitId,
                    onChanged: (value) {
                      setState(() {
                        _selectedUnitId = value;
                        _selectedIndex = index;
                      });
                    },
                    activeColor: Constants.ctaColorLight,
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing,
                      color: Constants.ctaColorLight,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                unit.name,
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUnit
                                        ? Colors.blue[800]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            if (isCurrentUnit)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Current',
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Model: ${unit.modelNumber} • S/N: ${unit.serialNumber}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: unit.isOperational
                          ? Colors.green[100]
                          : unit.isUnderMaintenance
                              ? Colors.orange[100]
                              : Colors.red[100],
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
                          size: 14,
                          color: unit.isOperational
                              ? Colors.green[700]
                              : unit.isUnderMaintenance
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          unit.status,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: unit.isOperational
                                  ? Colors.green[700]
                                  : unit.isUnderMaintenance
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Unit Details Grid
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // First Row - Basic Info
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Year',
                            unit.formattedYear,
                            Icons.calendar_today,
                            Colors.blue[600]!,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailItem(
                            'Refrigerant',
                            unit.refrigerantType,
                            Icons.opacity,
                            Colors.cyan[600]!,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailItem(
                            'Compressor',
                            unit.compressorType,
                            Icons.settings,
                            Colors.orange[600]!,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Second Row - Power & Location
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Power',
                            unit.compressorHp != null
                                ? '${unit.compressorHp}HP'
                                : 'N/A',
                            Icons.power,
                            Colors.red[600]!,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailItem(
                            'Fans',
                            '${unit.totalFanCount} Total',
                            Icons.air,
                            Colors.purple[600]!,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailItem(
                            'Location',
                            unit.location?.isNotEmpty == true
                                ? unit.location!
                                : 'Not set',
                            Icons.location_on,
                            Colors.green[600]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Warnings
              if (unit.isMaintenanceDue) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.amber[700], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Maintenance Due',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isSecondary = false,
  }) {
    return Material(
      color: isSecondary ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSecondary ? Border.all(color: color) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading && !isSecondary) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ] else ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSecondary ? color : Colors.white,
                ),
              ],
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
}

class EditDeviceDialog extends StatefulWidget {
  final Device device;
  final List<Unit> availableUnits;

  const EditDeviceDialog({
    Key? key,
    required this.device,
    required this.availableUnits,
  }) : super(key: key);

  @override
  State<EditDeviceDialog> createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<EditDeviceDialog> {
  final _formKey = GlobalKey<FormState>();

  // Required fields
  late TextEditingController _nameController;
  late TextEditingController _deviceIdController;

  // Optional fields - Basic Info
  late TextEditingController _productIdController;
  late TextEditingController _locationController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _roomController;

  // Optional fields - Technical Info
  late TextEditingController _manufacturerController;
  late TextEditingController _modelController;
  late TextEditingController _serialNumberController;
  late TextEditingController _capacityController;
  late TextEditingController _targetTempMinController;
  late TextEditingController _targetTempMaxController;

  // Optional fields - Service Info
  late TextEditingController _installationDateController;
  late TextEditingController _warrantyExpiryController;
  late TextEditingController _lastServiceDateController;
  late TextEditingController _nextServiceDateController;

  String? _selectedUnitId;
  late String _selectedDeviceType;
  late String _selectedPhaseType;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing device data
    _nameController = TextEditingController(text: widget.device.name);
    _deviceIdController = TextEditingController(text: widget.device.deviceId);

    // Basic info
    _productIdController =
        TextEditingController(text: widget.device.productId ?? '');
    _locationController =
        TextEditingController(text: widget.device.location ?? '');
    _buildingController =
        TextEditingController(text: widget.device.building ?? '');
    _floorController = TextEditingController(text: widget.device.floor ?? '');
    _roomController = TextEditingController(text: widget.device.room ?? '');

    // Technical info
    _manufacturerController =
        TextEditingController(text: widget.device.manufacturer ?? '');
    _modelController = TextEditingController(text: widget.device.model ?? '');
    _serialNumberController =
        TextEditingController(text: widget.device.serialNumber ?? '');
    _capacityController =
        TextEditingController(text: widget.device.capacity ?? '');
    _targetTempMinController = TextEditingController(
        text: widget.device.targetTempMin?.toString() ?? '');
    _targetTempMaxController = TextEditingController(
        text: widget.device.targetTempMax?.toString() ?? '');

    // Service info
    _installationDateController =
        TextEditingController(text: widget.device.installationDate ?? '');
    _warrantyExpiryController =
        TextEditingController(text: widget.device.warrantyExpiry ?? '');
    _lastServiceDateController =
        TextEditingController(text: widget.device.lastServiceDate ?? '');
    _nextServiceDateController =
        TextEditingController(text: widget.device.nextServiceDate ?? '');

    // Dropdowns and checkboxes
    _selectedUnitId = widget.device.connectedUnit?.id;
    _selectedDeviceType = widget.device.deviceType ?? 'chiller';
    _selectedPhaseType = widget.device.phaseType ?? 'single';
    _isActive = widget.device.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Modern Header
              Container(
                width: double.infinity,
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
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Device',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Device ID: ${widget.device.deviceId}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.device.isActive == true
                            ? Colors.white.withOpacity(0.2)
                            : Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.device.isActive == true ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Required Fields Section
                      _buildSectionHeader('Device Information', Icons.star),
                      const SizedBox(height: 20),
                      _buildRequiredFields(),

                      const SizedBox(height: 40),

                      // Optional Basic Info Section
                      _buildSectionHeader(
                          'Basic Information', Icons.info_outline),
                      const SizedBox(height: 20),
                      _buildBasicInfoFields(),

                      const SizedBox(height: 40),

                      // Technical Details Section
                      _buildSectionHeader(
                          'Technical Details', Icons.engineering),
                      const SizedBox(height: 20),
                      _buildTechnicalFields(),

                      const SizedBox(height: 40),

                      // Service Information Section
                      _buildSectionHeader(
                          'Service Information', Icons.build_circle_outlined),
                      const SizedBox(height: 20),
                      _buildServiceFields(),

                      const SizedBox(height: 40),

                      // Unit Connection Section
                      _buildSectionHeader(
                          'Unit Connection & Status', Icons.link),
                      const SizedBox(height: 20),
                      _buildUnitConnectionFields(),
                    ],
                  ),
                ),
              ),

              // Modern Action buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Constants.ctaColorLight,
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Updating...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.update_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Update Device',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _updateDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
      if (businessId != null) {
        Device updatedDevice = Device(
          id: widget.device.id,
          name: _nameController.text,
          deviceId: widget.device.deviceId, // Keep original device ID
          deviceType: _selectedDeviceType,

          // Updated fields from form
          productId: _productIdController.text.isNotEmpty
              ? _productIdController.text
              : null,
          location: _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
          building: _buildingController.text.isNotEmpty
              ? _buildingController.text
              : null,
          floor:
              _floorController.text.isNotEmpty ? _floorController.text : null,
          room: _roomController.text.isNotEmpty ? _roomController.text : null,
          phaseType: _selectedPhaseType,
          manufacturer: _manufacturerController.text.isNotEmpty
              ? _manufacturerController.text
              : null,
          model:
              _modelController.text.isNotEmpty ? _modelController.text : null,
          serialNumber: _serialNumberController.text.isNotEmpty
              ? _serialNumberController.text
              : null,
          capacity: _capacityController.text.isNotEmpty
              ? _capacityController.text
              : null,
          targetTempMin: _targetTempMinController.text.isNotEmpty
              ? double.tryParse(_targetTempMinController.text)
              : null,
          targetTempMax: _targetTempMaxController.text.isNotEmpty
              ? double.tryParse(_targetTempMaxController.text)
              : null,
          installationDate: _installationDateController.text.isNotEmpty
              ? _installationDateController.text
              : null,
          warrantyExpiry: _warrantyExpiryController.text.isNotEmpty
              ? _warrantyExpiryController.text
              : null,
          lastServiceDate: _lastServiceDateController.text.isNotEmpty
              ? _lastServiceDateController.text
              : null,
          nextServiceDate: _nextServiceDateController.text.isNotEmpty
              ? _nextServiceDateController.text
              : null,
          isActive: _isActive,

          // Preserve system fields that shouldn't change
          isOnline: widget.device.isOnline,
          lastPing: widget.device.lastPing,
          isInRepairMode: widget.device.isInRepairMode,
          repairModeStartedAt: widget.device.repairModeStartedAt,
          repairModeReason: widget.device.repairModeReason,
          createdAt: widget.device.createdAt,
          updatedAt: widget.device.updatedAt,
          companyName: widget.device.companyName,
        );

        await ApiService.updateDevice(
            businessId, widget.device.id!, updatedDevice, _selectedUnitId);

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Device updated successfully',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Constants.ctaColorLight,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
                  'Failed to update device: ${e.toString()}',
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to build modern section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.ctaColorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Constants.ctaColorLight.withOpacity(0.2),
          width: 1,
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

  // Modern text form field styling
  InputDecoration _buildInputDecoration(String label, IconData icon,
      {bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon,
          color: enabled ? Constants.ctaColorLight : const Color(0xFF9CA3AF),
          size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(36),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(36),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(36),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(36),
        borderSide: BorderSide(color: Constants.ctaColorLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(36),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      filled: true,
      fillColor: enabled ? const Color(0xFFFAFAFA) : const Color(0xFFF3F4F6),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: enabled ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Required fields section
  Widget _buildRequiredFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration:
                    _buildInputDecoration('Device Name *', Icons.devices),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter device name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _deviceIdController,
                decoration: _buildInputDecoration(
                    'Device ID (Read Only)', Icons.qr_code,
                    enabled: false),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                enabled: false, // Device ID cannot be changed
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDeviceType,
                decoration:
                    _buildInputDecoration('Device Type *', Icons.category),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(value: 'chiller', child: Text('Chiller')),
                  DropdownMenuItem(value: 'freezer', child: Text('Freezer')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceType = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPhaseType,
                decoration: _buildInputDecoration(
                    'Phase Type', Icons.electrical_services),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(
                      value: 'single', child: Text('Single Phase')),
                  DropdownMenuItem(value: 'three', child: Text('Three Phase')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPhaseType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Basic info fields section
  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _productIdController,
                decoration:
                    _buildInputDecoration('Product ID', Icons.inventory),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration:
                    _buildInputDecoration('Location', Icons.location_on),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _buildingController,
                decoration: _buildInputDecoration('Building', Icons.business),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _floorController,
                decoration: _buildInputDecoration('Floor', Icons.layers),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _roomController,
                decoration: _buildInputDecoration('Room', Icons.room),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Technical fields section
  Widget _buildTechnicalFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _manufacturerController,
                decoration:
                    _buildInputDecoration('Manufacturer', Icons.factory),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration:
                    _buildInputDecoration('Model', Icons.model_training),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _serialNumberController,
                decoration:
                    _buildInputDecoration('Serial Number', Icons.numbers),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _capacityController,
                decoration:
                    _buildInputDecoration('Capacity (e.g., 500L)', Icons.scale),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _targetTempMinController,
                decoration: _buildInputDecoration(
                    'Min Temperature (°C)', Icons.thermostat),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _targetTempMaxController,
                decoration: _buildInputDecoration(
                    'Max Temperature (°C)', Icons.thermostat),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Service fields section
  Widget _buildServiceFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _installationDateController,
                decoration: _buildInputDecoration(
                    'Installation Date (YYYY-MM-DD)', Icons.build),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _warrantyExpiryController,
                decoration: _buildInputDecoration(
                    'Warranty Expiry (YYYY-MM-DD)', Icons.verified_user),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lastServiceDateController,
                decoration: _buildInputDecoration(
                    'Last Service Date (YYYY-MM-DD)', Icons.handyman),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _nextServiceDateController,
                decoration: _buildInputDecoration(
                    'Next Service Date (YYYY-MM-DD)', Icons.schedule),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Unit connection fields section
  Widget _buildUnitConnectionFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedUnitId,
                decoration: _buildInputDecoration(
                    'Connected Unit (Optional)', Icons.link),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Unit'),
                  ),
                  ...widget.availableUnits.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit.id,
                      child: Text(unit.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(36),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      color: _isActive
                          ? Constants.ctaColorLight
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Device Active',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value ?? true;
                        });
                      },
                      activeColor: Constants.ctaColorLight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Required fields
    _nameController.dispose();
    _deviceIdController.dispose();

    // Optional fields - Basic Info
    _productIdController.dispose();
    _locationController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _roomController.dispose();

    // Optional fields - Technical Info
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _capacityController.dispose();
    _targetTempMinController.dispose();
    _targetTempMaxController.dispose();

    // Optional fields - Service Info
    _installationDateController.dispose();
    _warrantyExpiryController.dispose();
    _lastServiceDateController.dispose();
    _nextServiceDateController.dispose();

    super.dispose();
  }
}

class ApiService {
  static final String _baseUrl = Constants.articBaseUrl2;

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Fetch all devices for a specific business with unit details
  static Future<List<Device>> fetchDevices(int businessId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/devices/list/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "include_unit_details": true, // Request unit details
      }),
    );
    print("dffggf ${jsonEncode({
          "business_id": businessId,
          "include_unit_details": true, // Request unit details
        })}");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> deviceList = responseData['devices'] ?? responseData;
      List<Device> devices =
          deviceList.map((dynamic item) => Device.fromJson(item)).toList();
      return devices;
    } else {
      throw Exception('Failed to load devices: ${response.body}');
    }
  }

  // Fetch all units for a specific business
  static Future<List<Unit>> fetchUnits(int businessId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/units/list/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> unitList = responseData['units'] ?? responseData;
      List<Unit> units =
          unitList.map((dynamic item) => Unit.fromJson(item)).toList();
      return units;
    } else {
      throw Exception('Failed to load units: ${response.body}');
    }
  }

  // Add a new device with optional unit connection
  static Future<Device> addDevice(int businessId, Device device,
      [String? unitId]) async {
    Map<String, dynamic> deviceData = device.toJson();
    deviceData['business_id'] = businessId;
    if (unitId != null) {
      deviceData['connected_unit_id'] = unitId;
    }

    final response = await http.post(
      Uri.parse('${_baseUrl}api/devices/create/'),
      headers: await _getHeaders(),
      body: jsonEncode(deviceData),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Device.fromJson(responseData['device'] ?? responseData);
    } else {
      throw Exception('Failed to add device: ${response.body}');
    }
  }

  // Update an existing device with optional unit connection
  static Future<Device> updateDevice(
      int businessId, int deviceId, Device device,
      [String? unitId]) async {
    Map<String, dynamic> deviceData = device.toJson();
    deviceData['business_id'] = businessId;
    deviceData['device_id'] = deviceId;
    if (unitId != null) {
      deviceData['connected_unit_id'] = unitId;
    }

    final response = await http.post(
      Uri.parse('${_baseUrl}api/devices/update/'),
      headers: await _getHeaders(),
      body: jsonEncode(deviceData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Device.fromJson(responseData['device'] ?? responseData);
    } else {
      throw Exception('Failed to update device: ${response.body}');
    }
  }

  // Change device unit connection
  static Future<bool> changeDeviceUnit(
      int businessId, int deviceId, String? unitId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/devices/update/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "device_id": deviceId,
        "connected_unit_id": unitId, // Can be null to disconnect
      }),
    );
    print(
        "changeDeviceUnit: businessId=$businessId deviceId=$deviceId unitId=$unitId");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception('Failed to change device unit: ${response.body}');
    }
  }

  // Delete a device
  static Future<bool> deleteDevice(int businessId, int deviceId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/devices/delete/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "device_id": deviceId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception('Failed to delete device: ${response.body}');
    }
  }

  // Get devices by unit
  static Future<List<Device>> getDevicesByUnit(
      int businessId, String unitId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/devices/by-unit/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "unit_id": unitId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> deviceList = responseData['devices'] ?? responseData;
      List<Device> devices =
          deviceList.map((dynamic item) => Device.fromJson(item)).toList();
      return devices;
    } else {
      throw Exception('Failed to get devices by unit: ${response.body}');
    }
  }
}

class AddDeviceDialog extends StatefulWidget {
  final List<Unit> availableUnits;

  const AddDeviceDialog({Key? key, required this.availableUnits})
      : super(key: key);

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  // Required fields
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();

  // Optional fields - Basic Info
  final _productIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _roomController = TextEditingController();

  // Optional fields - Technical Info
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _targetTempMinController = TextEditingController();
  final _targetTempMaxController = TextEditingController();

  // Optional fields - Service Info
  final _installationDateController = TextEditingController();
  final _warrantyExpiryController = TextEditingController();
  final _lastServiceDateController = TextEditingController();
  final _nextServiceDateController = TextEditingController();

  String? _selectedUnitId;
  String _selectedDeviceType = 'chiller';
  String _selectedPhaseType = 'single';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Modern Header with gradient
              Container(
                width: double.infinity,
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
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add New Device',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Required Fields Section
                      _buildSectionHeader('Required Information',
                          const Color(0xFFEF4444), Icons.star),
                      const SizedBox(height: 20),
                      _buildRequiredFields(),

                      const SizedBox(height: 40),

                      // Optional Basic Info Section
                      _buildSectionHeader('Basic Information',
                          const Color(0xFF3B82F6), Icons.info_outline),
                      const SizedBox(height: 20),
                      _buildBasicInfoFields(),

                      const SizedBox(height: 40),

                      // Technical Details Section
                      _buildSectionHeader('Technical Details',
                          const Color(0xFF10B981), Icons.engineering),
                      const SizedBox(height: 20),
                      _buildTechnicalFields(),

                      const SizedBox(height: 40),

                      // Service Information Section
                      _buildSectionHeader('Service Information',
                          const Color(0xFFF59E0B), Icons.build_circle_outlined),
                      const SizedBox(height: 20),
                      _buildServiceFields(),

                      const SizedBox(height: 40),

                      // Unit Connection Section
                      _buildSectionHeader('Unit Connection',
                          const Color(0xFF8B5CF6), Icons.link),
                      const SizedBox(height: 20),
                      _buildUnitConnectionFields(),
                    ],
                  ),
                ),
              ),

              // Modern Action buttons
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _isLoading ? null : _resetForm,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Constants.ctaColorLight,
                            Constants.ctaColorLight.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Constants.ctaColorLight.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Adding...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Device',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int? businessId = await Sharedprefs.getBusinessUidSharedPreference();
      if (businessId != null) {
        Device newDevice = Device(
          name: _nameController.text,
          deviceId: _deviceIdController.text,
          deviceType: _selectedDeviceType,
          productId: _productIdController.text.isNotEmpty
              ? _productIdController.text
              : null,
          location: _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
          building: _buildingController.text.isNotEmpty
              ? _buildingController.text
              : null,
          floor:
              _floorController.text.isNotEmpty ? _floorController.text : null,
          room: _roomController.text.isNotEmpty ? _roomController.text : null,
          manufacturer: _manufacturerController.text.isNotEmpty
              ? _manufacturerController.text
              : null,
          model:
              _modelController.text.isNotEmpty ? _modelController.text : null,
          serialNumber: _serialNumberController.text.isNotEmpty
              ? _serialNumberController.text
              : null,
          capacity: _capacityController.text.isNotEmpty
              ? _capacityController.text
              : null,
          targetTempMin: _targetTempMinController.text.isNotEmpty
              ? double.tryParse(_targetTempMinController.text)
              : null,
          targetTempMax: _targetTempMaxController.text.isNotEmpty
              ? double.tryParse(_targetTempMaxController.text)
              : null,
          phaseType: _selectedPhaseType,
          installationDate: _installationDateController.text.isNotEmpty
              ? _installationDateController.text
              : null,
          warrantyExpiry: _warrantyExpiryController.text.isNotEmpty
              ? _warrantyExpiryController.text
              : null,
          lastServiceDate: _lastServiceDateController.text.isNotEmpty
              ? _lastServiceDateController.text
              : null,
          nextServiceDate: _nextServiceDateController.text.isNotEmpty
              ? _nextServiceDateController.text
              : null,
          isActive: _isActive,
        );

        await ApiService.addDevice(businessId, newDevice, _selectedUnitId);

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Device added successfully',
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
                  'Failed to add device: ${e.toString()}',
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _deviceIdController.clear();
    _productIdController.clear();
    _locationController.clear();
    _buildingController.clear();
    _floorController.clear();
    _roomController.clear();
    _manufacturerController.clear();
    _modelController.clear();
    _serialNumberController.clear();
    _capacityController.clear();
    _targetTempMinController.clear();
    _targetTempMaxController.clear();
    _installationDateController.clear();
    _warrantyExpiryController.clear();
    _lastServiceDateController.clear();
    _nextServiceDateController.clear();
    setState(() {
      _selectedUnitId = null;
      _selectedDeviceType = 'chiller';
      _selectedPhaseType = 'single';
      _isActive = true;
    });
  }

  // Helper method to build modern section headers
  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
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

  // Modern text form field styling
  InputDecoration _buildInputDecoration(
      String label, IconData icon, Color iconColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: iconColor, size: 20),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Required fields section
  Widget _buildRequiredFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                    'Device Name *', Icons.devices, const Color(0xFFEF4444)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter device name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _deviceIdController,
                decoration: _buildInputDecoration(
                    'Device ID *', Icons.qr_code, const Color(0xFFEF4444)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter device ID';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDeviceType,
                decoration: _buildInputDecoration(
                    'Device Type *', Icons.category, const Color(0xFFEF4444)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(value: 'chiller', child: Text('Chiller')),
                  DropdownMenuItem(value: 'freezer', child: Text('Freezer')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a device type';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPhaseType,
                decoration: _buildInputDecoration('Phase Type',
                    Icons.electrical_services, const Color(0xFF3B82F6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(
                      value: 'single', child: Text('Single Phase')),
                  DropdownMenuItem(value: 'three', child: Text('Three Phase')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPhaseType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Basic info fields section
  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _productIdController,
                decoration: _buildInputDecoration(
                    'Product ID', Icons.inventory, const Color(0xFF3B82F6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value)) {
                      return 'Enter a valid product ID (alphanumeric or hyphens)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(
                    'Location', Icons.location_on, const Color(0xFF3B82F6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _buildingController,
                decoration: _buildInputDecoration(
                    'Building', Icons.business, const Color(0xFF3B82F6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _floorController,
                decoration: _buildInputDecoration(
                    'Floor', Icons.layers, const Color(0xFF3B82F6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^-?\d+$').hasMatch(value)) {
                      return 'Enter a valid floor number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _roomController,
                decoration: _buildInputDecoration(
                    'Room', Icons.room, const Color(0xFF3B82F6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Technical fields section
  Widget _buildTechnicalFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _manufacturerController,
                decoration: _buildInputDecoration(
                    'Manufacturer', Icons.factory, const Color(0xFF10B981)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: _buildInputDecoration(
                    'Model', Icons.model_training, const Color(0xFF10B981)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _serialNumberController,
                decoration: _buildInputDecoration(
                    'Serial Number', Icons.numbers, const Color(0xFF10B981)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value)) {
                      return 'Enter a valid serial number (alphanumeric or hyphens)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _capacityController,
                decoration: _buildInputDecoration('Capacity (e.g., 500L)',
                    Icons.scale, const Color(0xFF10B981)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\d+(\.\d+)?[A-Za-z]+$').hasMatch(value)) {
                      return 'Enter a valid capacity (e.g., 500L)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _targetTempMinController,
                decoration: _buildInputDecoration('Min Temperature (°C)',
                    Icons.thermostat, const Color(0xFF10B981)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    if (_targetTempMaxController.text.isNotEmpty) {
                      final minTemp = double.tryParse(value);
                      final maxTemp =
                          double.tryParse(_targetTempMaxController.text);
                      if (minTemp != null &&
                          maxTemp != null &&
                          minTemp > maxTemp) {
                        return 'Min temperature cannot exceed max';
                      }
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _targetTempMaxController,
                decoration: _buildInputDecoration('Max Temperature (°C)',
                    Icons.thermostat, const Color(0xFF10B981)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    if (_targetTempMinController.text.isNotEmpty) {
                      final minTemp =
                          double.tryParse(_targetTempMinController.text);
                      final maxTemp = double.tryParse(value);
                      if (minTemp != null &&
                          maxTemp != null &&
                          maxTemp < minTemp) {
                        return 'Max temperature cannot be less than min';
                      }
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Service fields section
  Widget _buildServiceFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _installationDateController,
                decoration: _buildInputDecoration(
                    'Installation Date', Icons.build, const Color(0xFFF59E0B)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                readOnly: true,
                onTap: () => _selectDate(context, _installationDateController),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _warrantyExpiryController,
                decoration: _buildInputDecoration('Warranty Expiry',
                    Icons.verified_user, const Color(0xFFF59E0B)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                readOnly: true,
                onTap: () => _selectDate(context, _warrantyExpiryController),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                      if (_installationDateController.text.isNotEmpty) {
                        final installDate =
                            DateTime.parse(_installationDateController.text);
                        final expiryDate = DateTime.parse(value);
                        if (expiryDate.isBefore(installDate)) {
                          return 'Warranty expiry cannot be before installation';
                        }
                      }
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lastServiceDateController,
                decoration: _buildInputDecoration('Last Service Date',
                    Icons.handyman, const Color(0xFFF59E0B)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                readOnly: true,
                onTap: () => _selectDate(context, _lastServiceDateController),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _nextServiceDateController,
                decoration: _buildInputDecoration('Next Service Date',
                    Icons.schedule, const Color(0xFFF59E0B)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                readOnly: true,
                onTap: () => _selectDate(context, _nextServiceDateController),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                      if (_lastServiceDateController.text.isNotEmpty) {
                        final lastService =
                            DateTime.parse(_lastServiceDateController.text);
                        final nextService = DateTime.parse(value);
                        if (nextService.isBefore(lastService)) {
                          return 'Next service cannot be before last service';
                        }
                      }
                    } catch (e) {
                      return 'Enter valid date (YYYY-MM-DD)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Unit connection fields section
  Widget _buildUnitConnectionFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedUnitId,
                decoration: _buildInputDecoration('Connected Unit (Optional)',
                    Icons.link, const Color(0xFF8B5CF6)),
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Unit'),
                  ),
                  ...widget.availableUnits.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit.id,
                      child: Text(unit.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      color: _isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Device Active',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: Constants.ctaColorLight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Date picker helper method
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
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
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    _productIdController.dispose();
    _locationController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _roomController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _capacityController.dispose();
    _targetTempMinController.dispose();
    _targetTempMaxController.dispose();
    _installationDateController.dispose();
    _warrantyExpiryController.dispose();
    _lastServiceDateController.dispose();
    _nextServiceDateController.dispose();
    super.dispose();
  }
}
