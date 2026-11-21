import '../widgets/app_tone.dart';
import '../device_journal/bottle_scan_history.dart';
import '../services/offline_read_client.dart';
import '../widgets/offline_snapshot_banner.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_screen.dart';
import '../widgets/mobile_equipment_card.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/device_alert_card.dart';
import '../widgets/mobile_forms.dart';
import '../onboarding/device_setup_wizard.dart';
import 'device_editor.dart';
import '../widgets/unit_link_sheets.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import '../constants/models/device.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import '../models/device.dart';
import '../models/unit.dart';
import '../gasmon/gas_cylinder_details_dialog.dart';
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
  final _offline = OfflineReadClient();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Device> _allDevices = [];
  List<Device> _filteredDevices = [];
  List<Unit> _availableUnits = [];
  bool _isLoading = true;
  bool _loadFailed = false;
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
    _animationController.forward();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _offline.close();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterDevices();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _loadFailed = false; });
    try {
      final businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        final results = await Future.wait([
          ApiService.fetchDevices(businessId, reader: _offline),
          ApiService.fetchUnits(businessId, reader: _offline),
        ]).timeout(const Duration(seconds: 20));
        if (!mounted) return;
        _allDevices = results[0].cast<Device>();
        _availableUnits = results[1].cast<Unit>();
      } else {
        _allDevices = [];
        _availableUnits = [];
      }
      if (!mounted) return;
      _filterDevices();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        Tone.auto(const Color(0xFF10B981)),
      ),
      DeviceManagementRecords(
        inactiveDevices,
        "Inactive",
        Icons.cancel_rounded,
        Tone.auto(const Color(0xFFEF4444)),
      ),
      DeviceManagementRecords(
        onlineDevices,
        "Online",
        Icons.wifi_rounded,
        Tone.auto(const Color(0xFF06B6D4)),
      ),
      DeviceManagementRecords(
        serviceDueDevices,
        "Service Due",
        Icons.warning_amber_rounded,
        Tone.auto(const Color(0xFFF59E0B)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildMobilePage();
    return Container(
      color: isPhoneLayout(context) ? GasPalette.page : null,
      height: isPhoneLayout(context) ? null : 1000,
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
                  padding: EdgeInsets.all(isPhoneLayout(context) ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OfflineSnapshotBanner(client: _offline, onRetry: _loadData),
                      // Statistics Cards
                      if (!_loadFailed && !_isLoading) _buildStatisticsSection(),

                      SizedBox(height: isPhoneLayout(context) ? 24 : 32),

                      // Search and Controls
                      if (!_loadFailed && !_isLoading) _buildSearchAndControls(),

                      const SizedBox(height: 24),

                      // Devices Display
                      _buildDevicesSection(),
                      const SizedBox(height: 24),
                      FloatingActionButton.extended(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        elevation: 0,
                        onPressed: _addDevice,
                        backgroundColor: isPhoneLayout(context)
                            ? GasPalette.primary
                            : Constants.ctaColorLight,
                        foregroundColor: Tone.fg(Colors.white),
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
              title: 'Devices',
              trailing: FilledButton(
                onPressed: _addDevice,
                style: FilledButton.styleFrom(
                  backgroundColor: GasPalette.primary,
                  foregroundColor: Tone.fg(Colors.white),
                  minimumSize: const Size(64, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text('Add Device'),
              ),
            ),
            const SizedBox(height: 12),
            OfflineSnapshotBanner(client: _offline, onRetry: _loadData),
            if (!_loadFailed && !_isLoading) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: deviceRecordList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    _buildStatCard(deviceRecordList[index], index),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: mobileInputDecoration(
                context,
                const InputDecoration(hintText: 'Search name, ID or location'),
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
                      _filterDevices();
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Tooltip(
                    message: '${_filteredDevices.length} devices shown',
                    child: Semantics(
                      label: '${_filteredDevices.length} devices shown',
                      excludeSemantics: true,
                      child: Text(
                        '${_filteredDevices.length}',
                        key: const ValueKey('devices-result-count'),
                        style: gasSmall(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
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
                : _filteredDevices.isEmpty
                ? _buildEmptyState()
                : _buildMobileDeviceList(),
          ],
        ),
      ),
    ),
  );

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
              "Device Overview",
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
                        hintText: isPhoneLayout(context)
                            ? 'Search name, ID or location'
                            : 'Search devices by name, ID, unit, or location...',
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
                              color: Tone.bg(Color(0xFF3B82F6)), width: 2),
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
                color: Tone.bg(const Color(0xFF8B5CF6)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.device_hub_rounded,
                size: 20,
                color: Tone.fg(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              "Devices (${_filteredDevices.length})",
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
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Tone.bg(Colors.white),
        border: isPhoneLayout(context)
            ? Border.all(color: GasPalette.border)
            : null,
        borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadError() => GPanel(child: AppEmptyState(
    kind: AppEmptyStateKind.offline,
    title: 'Devices could not be loaded',
    message: 'Check your internet connection and try again. Your saved devices have not been changed.',
    actionLabel: 'Try again', onAction: _loadData,
  ));

  Widget _buildEmptyState() {
    final filtered = _searchController.text.isNotEmpty || _selectedFilter != 'All';
    return GPanel(child: AppEmptyState(
      kind: filtered ? AppEmptyStateKind.results : AppEmptyStateKind.devices,
      title: filtered ? 'No matching devices' : 'Your first device starts here',
      message: filtered
          ? 'Try another name, ID or location, or clear your filters.'
          : 'Add a gas scale or monitoring device to see its readings and set up your alerts.',
      actionLabel: filtered ? 'Clear filters' : 'Add device',
      onAction: filtered ? () {
        _searchController.clear();
        setState(() => _selectedFilter = 'All');
        _filterDevices();
      } : _addDevice,
    ));
  }

  Widget _buildMobileDeviceCard(Device device) => MobileEquipmentCard(
    device: device,
    onOpen: () => _showDeviceDetails(device),
    actions: _buildQuickActions(device),
  );

  Widget _buildMobileDeviceList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < _filteredDevices.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        _buildMobileDeviceCard(_filteredDevices[index]),
      ],
    ],
  );

  Widget _buildGridView() {
    if (isPhoneLayout(context)) return _buildMobileDeviceList();
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
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 16),
          border: Border.all(
            color: device.isActive
                ? (device.isOnline
                    ? Tone.auto(Colors.green).withOpacity(0.3)
                    : Tone.auto(Colors.grey).withOpacity(0.3))
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
                    color: device.isActive
                        ? (device.isOnline
                            ? Tone.auto(Colors.green).withOpacity(0.1)
                            : Tone.auto(Colors.grey).withOpacity(0.1))
                        : Tone.bg(Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.devices_rounded,
                    size: 16,
                    color: device.isActive
                        ? (device.isOnline ? Tone.auto(Colors.green) : Tone.auto(Colors.grey))
                        : Tone.fg(Colors.red),
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
                color: isPhoneLayout(context)
                    ? GasPalette.ink
                    : Tone.fg(const Color(0xFF1E293B)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              device.deviceId,
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
                color: device.isActive
                    ? (device.isOnline ? Tone.auto(Colors.green) : Tone.auto(Colors.grey))
                    : Tone.bg(Colors.red),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                device.statusDisplay,
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
    if (isPhoneLayout(context)) return _buildMobileDeviceList();
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
                    'Device Name',
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
                    'Device ID',
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
                    'Connected Unit',
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
                    'Location',
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
                      color: isPhoneLayout(context)
                          ? GasPalette.ink
                          : Tone.fg(const Color(0xFF1E293B)),
                    ),
                  ),
                  if (device.deviceType != null)
                    Text(
                      device.deviceTypeDisplay,
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

            // Device ID
            Expanded(
              child: Text(
                device.deviceId,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPhoneLayout(context)
                      ? GasPalette.ink
                      : Tone.fg(const Color(0xFF1E293B)),
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
                            color: isPhoneLayout(context)
                                ? GasPalette.ink
                                : Tone.fg(const Color(0xFF1E293B)),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'S/N: ${device.connectedUnit!.serialNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isPhoneLayout(context)
                                ? GasPalette.ink2
                                : Tone.fg(const Color(0xFF64748B)),
                          ),
                        ),
                        if (device.connectedUnit!.isMaintenanceDue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Tone.bg(Colors.amber),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Maintenance Due',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Tone.fg(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Tone.bg(Colors.grey[200]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No Unit',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Tone.fg(Colors.grey[600]),
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
                  color: isPhoneLayout(context)
                      ? GasPalette.ink
                      : Tone.fg(const Color(0xFF1E293B)),
                ),
              ),
            ),

            // Status
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.isActive
                      ? (device.isOnline ? Tone.auto(Colors.green) : Tone.auto(Colors.grey))
                      : Tone.bg(Colors.red),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  device.statusDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Tone.fg(Colors.white),
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
      color: Tone.bg(Colors.white),
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
              Icon(Icons.visibility_rounded,
                  size: 16, color: Tone.fg(Color(0xFF3B82F6))),
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
              Icon(Icons.link_rounded,
                  size: 16, color: Tone.fg(Color(0xFF8B5CF6))),
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
              Icon(Icons.delete_rounded,
                  size: 16, color: Tone.fg(Color(0xFFEF4444))),
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
                    title: const Text('Filter devices'),
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
                    'Active',
                    'Inactive',
                    'Online',
                    'Offline',
                    'Service Due',
                    'Warranty Expired',
                    'With Unit',
                    'Without Unit'
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
                            _filterDevices();
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
                            'Filter Devices',
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
                                    _filterDevices();
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

  /// The guided setup: identify, fit and set up, connect and link — with a
  /// first-reading check and, for gas scales, Wi-Fi setup over Bluetooth.
  Future<void> _addDevice() async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<Device?>(
      fullscreenDialog: true,
      builder: (_) => const DeviceSetupWizard(fromEquipment: true),
    ));
    if (mounted) _loadData();
  }

  Future<void> _editDevice(Device device) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var openCylinder = false;
    final updated = await navigator.push<Device?>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (editorContext) => DeviceEditorScreen(
        device: device,
        availableUnits: _availableUnits,
        onSave: (changed, unitId) async {
          final businessId = await Sharedprefs.getBusinessUidSharedPreference();
          if (businessId == null) throw StateError('Signed out');
          await ApiService.updateDevice(businessId, device.id!, changed, unitId);
        },
        onOpenCylinderSetup: isGasCylinderType(device.deviceType)
            ? () {
                openCylinder = true;
                Navigator.of(editorContext).pop();
              }
            : null,
      ),
    ));
    if (!mounted) return;
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updated.name} saved')));
    }
    _loadData();
    if (openCylinder) _showDeviceDetails(device);
  }

  void _showDeviceDetails(Device device) {
    // Gas cylinder devices open the gas dashboard instead of the
    // temperature-oriented details dialog.
    if (isGasCylinderType(device.deviceType)) {
      showMobileDialog(
        context: context,
        builder: (context) => GasCylinderDetailsDialog(device: device),
      );
      return;
    }
    showMobileDialog(
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

  Future<void> _showChangeUnitDialog(Device device) async {
    if (await showLinkUnitToDevice(context, device: device) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${device.name} link updated')));
      _loadData();
    }
  }

  Future<void> _deleteDevice(int deviceId) async {
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
                      'Are you sure you want to delete this device? This action cannot be undone.',
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

  Widget _buildPhoneDetails(BuildContext context) {
    final unit = device.connectedUnit;
    Widget section(
      String title,
      Map<String, String?> values, {
      Widget? action,
    }) => GPanel(
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
          if (action != null) action,
        ],
      ),
    );
    return MobileDialog(
      child: Scaffold(
        backgroundColor: GasPalette.page,
        appBar: AppBar(
          title: const Text('Equipment details'),
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
              title: device.name,
              description: '${device.deviceTypeDisplay} · ${device.deviceId}',
              bottom: Text(
                device.statusDisplay,
                style: gasSmall(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            DeviceAlertCard(device: device),
            if (device.deviceType?.toLowerCase() == 'device7' && device.id != null)
              OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BottleScanHistoryPage(deviceId: device.id!, deviceName: device.name))),
                icon: const Icon(Icons.history), label: const Text('Bottle scan history')),

            const SizedBox(height: 12),
            section('Device information', {
              'Product ID': device.productId,
              'Manufacturer': device.manufacturer,
              'Model': device.model,
              'Serial number': device.serialNumber,
              'Phase': device.phaseType,
              'Capacity': device.capacity,
            }),
            const SizedBox(height: 12),
            section(
              'Connected unit',
              unit == null
                  ? {'Connection': 'No unit connected'}
                  : {
                      'Name': unit.name,
                      'Model': unit.modelNumber,
                      'Serial number': unit.serialNumber,
                      'Status': unit.status,
                      'Location': unit.location,
                      'Refrigerant': unit.refrigerantType,
                      'Compressor type': unit.compressorType,
                      'Compressor model': unit.compressorModel,
                      'Compressor power': unit.compressorHp == null
                          ? null
                          : '${unit.compressorHp} HP',
                      'Compressor rating': unit.compressorAmpRating == null
                          ? null
                          : '${unit.compressorAmpRating} A',
                      'Condenser fan':
                          '${unit.condenserFan.count} × ${unit.condenserFan.type} · ${unit.condenserFan.power}',
                      'Evaporator fan':
                          '${unit.evaporatorFan.count} × ${unit.evaporatorFan.type} · ${unit.evaporatorFan.power}',
                      'Evaporator model': unit.evaporatorModel,
                      'Evaporator dimensions': unit.evaporatorDimensions,
                      'Orifice size': unit.orificeSize,
                      'Dryer size': unit.dryerSize,
                      'Oil separator': unit.oilSeparator,
                      'Liquid receiver': unit.liquidReceiver,
                      'Accumulator capacity': unit.accumulatorCapacity,
                      'Maintenance': unit.isMaintenanceDue
                          ? 'Maintenance due'
                          : 'Up to date',
                    },
              action: onChangeUnit == null
                  ? null
                  : OutlinedButton(
                      onPressed: onChangeUnit,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Text(
                        unit == null ? 'Connect unit' : 'Change unit',
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            section('Location', {
              'Location': device.location,
              'Building': device.building,
              'Floor': device.floor,
              'Room': device.room,
              'Full address': device.fullLocation,
            }),
            const SizedBox(height: 12),
            section('Temperature settings', {
              'Target range': device.temperatureRange,
            }),
            const SizedBox(height: 12),
            section('Status', {
              'Activity': device.isActive ? 'Active' : 'Inactive',
              'Connection': device.isOnline ? 'Online' : 'Offline',
              'Repair mode': device.isInRepairMode ? 'In repair' : 'Normal',
              if (device.repairModeReason != null)
                'Repair reason': device.repairModeReason,
              'Last communication': device.lastPing == null
                  ? null
                  : _formatDateTime(device.lastPing!),
            }),
            const SizedBox(height: 12),
            section('Maintenance', {
              'Installed': device.formattedInstallationDate,
              'Warranty expiry': device.warrantyExpiry,
              'Last service': device.lastServiceDate,
              'Next service': device.nextServiceDate,
              'Service status': device.isServiceDue ? 'Service due' : 'Not due',
              'Warranty status': device.isWarrantyValid
                  ? 'Valid'
                  : 'Expired or not set',
            }),
            const SizedBox(height: 12),
            section('System information', {
              'Created': device.createdAt == null
                  ? null
                  : _formatDateTime(device.createdAt!),
              'Last updated': device.updatedAt == null
                  ? null
                  : _formatDateTime(device.updatedAt!),
              'Company': device.companyName,
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
                child: const Text('Edit device'),
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
                      device.deviceType == 'chiller'
                          ? Icons.ac_unit
                          : Icons.kitchen,
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
                          device.name,
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
                          'Device ID: ${device.deviceId}',
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
                  // Status indicators
                  Row(
                    children: [
                      _buildStatusBadge(
                        device.isActive ? 'Active' : 'Inactive',
                        device.isActive ? Tone.auto(Colors.green[400]) : Tone.auto(Colors.red[400]),
                        Icons.power_settings_new,
                      ),
                      SizedBox(width: 8),
                      _buildStatusBadge(
                        device.isOnline ? 'Online' : 'Offline',
                        device.isOnline ? Tone.auto(Colors.blue[400]) : Tone.auto(Colors.grey[400]),
                        device.isOnline ? Icons.wifi : Icons.wifi_off,
                      ),
                    ],
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
                      // Quick Info Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Type',
                              device.deviceTypeDisplay,
                              Icons.category,
                              Tone.auto(Colors.blue[50]),
                              Tone.auto(Colors.blue[600]),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Phase',
                              device.phaseType ?? 'Not set',
                              Icons.electrical_services,
                              Tone.auto(Colors.orange[50]),
                              Tone.auto(Colors.orange[600]),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              'Capacity',
                              device.capacity ?? 'Not set',
                              Icons.storage,
                              Tone.auto(Colors.purple[50]),
                              Tone.auto(Colors.purple[600]),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      DeviceAlertCard(device: device),
                      const SizedBox(height: 24),

                      // Connected Unit Section with enhanced styling
                      _buildEnhancedSection(
                        'Connected Unit Information',
                        Icons.link,
                        Tone.auto(Colors.teal),
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
                            ? _buildConnectedUnitInfo(context)
                            : _buildNoUnitConnected(),
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
                        Tone.auto(Colors.red),
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
                        Tone.auto(Colors.orange),
                        null,
                        child: Column(
                          children: [
                            _buildTemperatureCard(context),
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
                        Tone.auto(Colors.green),
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
                        Tone.auto(Colors.amber),
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
                        Tone.auto(Colors.grey),
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
        color: Tone.bg(Colors.white).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Tone.fg(Colors.white)),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Tone.fg(Colors.white),
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

  Widget _buildConnectedUnitInfo(BuildContext context) {
    final unit = device.connectedUnit!;
    return Column(
      children: [
        // Unit Overview Card
        Container(
          padding: EdgeInsets.all(16),
          decoration: mobileFlatDecoration(
              context,
              BoxDecoration(
                gradient: LinearGradient(
                  colors: [Tone.auto(Colors.teal[50]), Tone.auto(Colors.teal[100])],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Tone.bg(Colors.teal[200])),
              )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.precision_manufacturing,
                      color: Tone.fg(Colors.teal[600]), size: 24),
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
                              color: Tone.fg(Colors.teal[800]),
                            ),
                          ),
                        ),
                        Text(
                          '${unit.modelNumber} • S/N: ${unit.serialNumber}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Tone.fg(Colors.teal[600]),
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
                          ? Tone.bg(Colors.green[100])
                          : Tone.bg(Colors.orange[100]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      unit.status,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: unit.status.toLowerCase() == 'operational'
                              ? Tone.fg(Colors.green[700])
                              : Tone.fg(Colors.orange[700]),
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
                    color: Tone.bg(Colors.amber[100]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Tone.bg(Colors.amber[300])),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Tone.fg(Colors.amber[700]), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Maintenance Due',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Tone.fg(Colors.amber[700]),
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
                Tone.auto(Colors.blue[600]),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSpecCard(
                'Compressor',
                unit.compressorType,
                Icons.settings,
                Tone.auto(Colors.grey[600]),
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
              color: Tone.fg(Colors.grey[700]),
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
                Tone.auto(Colors.red[600]),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildFanCard(
                'Evaporator',
                unit.evaporatorFan,
                Icons.ac_unit,
                Tone.auto(Colors.blue[600]),
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
                color: Tone.fg(Colors.black87),
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
                color: Tone.fg(Colors.black87),
              ),
            ),
          ),
          Text(
            fan.power,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 11,
                color: Tone.fg(Colors.grey[600]),
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
        color: Tone.bg(Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Tone.bg(Colors.grey[200])),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 48, color: Tone.fg(Colors.grey[400])),
          SizedBox(height: 12),
          Text(
            'No Unit Connected',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Tone.fg(Colors.grey[700]),
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
                color: Tone.fg(Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: mobileFlatDecoration(
          context,
          BoxDecoration(
            gradient: LinearGradient(
              colors: [Tone.auto(Colors.orange[50]), Tone.auto(Colors.red[50])],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Tone.bg(Colors.orange[200])),
          )),
      child: Row(
        children: [
          Icon(Icons.device_thermostat, size: 32, color: Tone.fg(Colors.orange[600])),
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
                      color: Tone.fg(Colors.orange[800]),
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
                      color: Tone.fg(Colors.orange[900]),
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
                device.isActive ? Tone.auto(Colors.green) : Tone.auto(Colors.red),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Online',
                device.isOnline,
                device.isOnline ? Icons.wifi : Icons.wifi_off,
                device.isOnline ? Tone.auto(Colors.blue) : Tone.auto(Colors.grey),
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
                device.isInRepairMode ? Tone.auto(Colors.orange) : Tone.auto(Colors.green),
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
                device.isWarrantyValid ? Tone.auto(Colors.green) : Tone.auto(Colors.red),
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
              color: status ? Tone.bg(Colors.green) : Tone.bg(Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status ? 'Yes' : 'No',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Tone.fg(Colors.white),
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
            Tone.auto(Colors.blue[600]),
            isFirst: true,
          ),
        if (device.lastServiceDate != null)
          _buildTimelineItem(
            'Last Service',
            device.lastServiceDate!,
            Icons.handyman,
            Tone.auto(Colors.green[600]),
          ),
        if (device.nextServiceDate != null)
          _buildTimelineItem(
            'Next Service',
            device.nextServiceDate!,
            device.isServiceDue ? Icons.warning : Icons.schedule,
            device.isServiceDue ? Tone.auto(Colors.red[600]) : Tone.auto(Colors.orange[600]),
            isFuture: !device.isServiceDue,
          ),
        if (device.warrantyExpiry != null)
          _buildTimelineItem(
            'Warranty Expires',
            device.warrantyExpiry!,
            device.isWarrantyValid ? Icons.shield : Icons.shield_outlined,
            device.isWarrantyValid ? Tone.auto(Colors.green[600]) : Tone.auto(Colors.red[600]),
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
      // The API sends UTC; show the phone's local time.
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      final now = DateTime.now();
      // Compare calendar days, not 24-hour spans.
      final days = DateTime(now.year, now.month, now.day)
          .difference(DateTime(dateTime.year, dateTime.month, dateTime.day))
          .inDays;

      if (days == 0) {
        return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (days == 1) {
        return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (days > 1 && days < 7) {
        return '$days days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateTimeString;
    }
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
  static Future<List<Device>> fetchDevices(int businessId, {OfflineReadClient? reader}) async {
    final response = await (reader?.post ?? http.post)(
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
  static Future<List<Unit>> fetchUnits(int businessId, {OfflineReadClient? reader}) async {
    final response = await (reader?.post ?? http.post)(
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
    if (device.deviceType == 'gas_cylinder') {
      for (final key in [
        'phase_type',
        'target_temp_min',
        'target_temp_max',
        'capacity'
      ]) {
        deviceData.remove(key);
      }
    }
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
