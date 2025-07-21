import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../models/unit.dart';
import '../widgets/compact_header.dart';

class EnhancedGeoFencing extends StatefulWidget {
  const EnhancedGeoFencing({super.key});

  @override
  State<EnhancedGeoFencing> createState() => _EnhancedGeoFencingState();
}

class _EnhancedGeoFencingState extends State<EnhancedGeoFencing>
    with SingleTickerProviderStateMixin {
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  late TabController _tabController;

  // Data
  List<Unit> unitList = [];
  List<dynamic> suppliers = [];
  Unit? selectedUnit;

  // Map settings
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(-25.974365171190335, 28.095606369504797),
    zoom: 10,
  );

  // Loading states
  bool isLoadingUnits = false;
  bool isLoadingSuppliers = false;
  String error = '';
  
  // Auto-refresh functionality
  Timer? _refreshTimer;
  DateTime? lastRefreshTime;
  
  // Map type
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        error = '';
      });

      await Future.wait([
        _loadUnits(),
        _loadSuppliers(),
      ]);

      setState(() {
        lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load location data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadUnits() async {
    setState(() {
      isLoadingUnits = true;
      error = '';
    });

    try {
      int? businessId = await Constants.myBusiness.businessUid;
      if (businessId == null) {
        throw Exception('Business ID not found');
      }

      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
        'POST',
        Uri.parse('${Constants.articBaseUrl2}/api/units/list/'),
      );
      request.body = json.encode({"business_id": businessId});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> data = json.decode(responseBody);

        if (data['success']) {
          List<dynamic> unitsJson = data['units'];
          unitList = unitsJson.map((json) => Unit.fromJson(json)).toList();
          _updateMapMarkers();
        } else {
          throw Exception(data['error'] ?? 'Failed to load units');
        }
      } else {
        throw Exception('Failed to load units: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load units: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoadingUnits = false;
      });
    }
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      isLoadingSuppliers = true;
    });

    try {
      int? businessId = await Constants.myBusiness.businessUid;
      if (businessId == null) {
        throw Exception('Business ID not found');
      }

      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
        'POST',
        Uri.parse('${Constants.articBaseUrl2}/api/suppliers/local/'),
      );
      request.body = json.encode({
        "business_id": businessId,
        "location": "Johannesburg" // You can make this dynamic
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> data = json.decode(responseBody);

        if (data['success']) {
          suppliers = data['suppliers'];
        }
      }
    } catch (e) {
      print('Failed to load suppliers: $e');
    } finally {
      setState(() {
        isLoadingSuppliers = false;
      });
    }
  }

  void _updateMapMarkers() {
    markers.clear();

    for (int i = 0; i < unitList.length; i++) {
      Unit unit = unitList[i];

      if (unit.latitude != null && unit.longitude != null) {
        final MarkerId markerId = MarkerId(unit.id);
        final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(unit.latitude!, unit.longitude!),
          infoWindow: InfoWindow(
            title: unit.name,
            snippet: '${unit.statusDisplay} • ${unit.modelNumber}',
          ),
          icon: _getMarkerIcon(unit.statusValue),
          onTap: () => _onMarkerTapped(unit),
        );
        markers[markerId] = marker;
      }
    }
    setState(() {});
  }

  BitmapDescriptor _getMarkerIcon(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'maintenance':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'decommissioned':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMarkerTapped(Unit unit) {
    setState(() {
      selectedUnit = unit;
    });
    _animateToUnit(unit);
  }

  void _onUnitSelected(Unit unit) {
    setState(() {
      selectedUnit = unit;
    });
    if (unit.latitude != null && unit.longitude != null) {
      _animateToUnit(unit);
    }
  }

  Future<void> _animateToUnit(Unit unit) async {
    if (unit.latitude != null && unit.longitude != null) {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(unit.latitude!, unit.longitude!),
            zoom: 15,
          ),
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
          const CompactHeader(
            title: "Geo Fencing",
            description: "Define and monitor location boundaries",
            icon: Icons.location_on_rounded,
          ),
          // Modern TabBar Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: TabBar(
              controller: _tabController,
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
                Tab(
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Map View'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Units'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Suppliers'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error Display
          if (error.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
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
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.error, color: Colors.red[700], size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error',
                          style: GoogleFonts.inter(
                            color: Colors.red[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          error,
                          style: GoogleFonts.inter(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _loadData,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.red[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Tab Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: error.isNotEmpty ? 16 : 0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  Container(height: 500, child: _buildMapView()),
                  _buildUnitsListView(),
                  _buildSuppliersView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Map Controls Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.map_rounded, color: Constants.ctaColorLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location Overview',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                _buildMapTypeButton(),
                const SizedBox(width: 8),
                _buildRefreshButton(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Map Container
          Expanded(
            flex: selectedUnit != null ? 3 : 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: _currentMapType,
                      initialCameraPosition: _defaultLocation,
                      markers: markers.values.toSet(),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController.complete(controller);
                      },
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    // Units Counter Overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            Icon(Icons.location_on, color: Constants.ctaColorLight, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${unitList.length} Units',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
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
          ),

          // Selected Unit Details Panel
          if (selectedUnit != null) ...[
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: _buildModernUnitDetailsCard(selectedUnit!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitsListView() {
    if (isLoadingUnits) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Constants.ctaColorLight),
            const SizedBox(height: 16),
            Text(
              'Loading units...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (unitList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
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
              'Units will appear here once they are configured with location data',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Units Header with Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: Constants.ctaColorLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Units Overview',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              _buildStatusChip(_getOperationalUnitsCount(), 'Operational', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildStatusChip(_getMaintenanceUnitsCount(), 'Maintenance', const Color(0xFFF59E0B)),
            ],
          ),
        ),

        // Units List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUnits,
            color: Constants.ctaColorLight,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: unitList.length,
              itemBuilder: (context, index) {
                Unit unit = unitList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildModernUnitListCard(unit),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuppliersView() {
    if (isLoadingSuppliers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Constants.ctaColorLight),
            const SizedBox(height: 16),
            Text(
              'Loading suppliers...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_center_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No suppliers found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Local suppliers will be displayed here based on your location',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSuppliers,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Suppliers Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.business_rounded, color: Constants.ctaColorLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Local Suppliers',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suppliers.length} Found',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Constants.ctaColorLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Suppliers List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSuppliers,
            color: Constants.ctaColorLight,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                var supplier = suppliers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildModernSupplierCard(supplier),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitListCard(Unit unit) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onUnitSelected(unit),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(unit.statusValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      unit.statusDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(unit.statusValue),
                      ),
                    ),
                  ),
                  Spacer(),
                  if (unit.hasCoordinates)
                    Icon(Icons.location_on,
                        color: Constants.ctaColorGreen, size: 16),
                  if (unit.isMaintenanceDue)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Maintenance Due',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                unit.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${unit.modelNumber} • S/N: ${unit.serialNumber}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (unit.location?.isNotEmpty == true) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        unit.location!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Connected Devices Count
              if (unit.connectedDevicesCount > 0) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.devices,
                        size: 14, color: Constants.ctaColorGreen),
                    SizedBox(width: 4),
                    Text(
                      '${unit.connectedDevicesCount} connected device${unit.connectedDevicesCount > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Constants.ctaColorGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDetailsCard(Unit unit) {
    return CustomCard(
      elevation: 5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    unit.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(unit.statusValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    unit.statusDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(unit.statusValue),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Unit Info
            _buildDetailRow('Model', unit.modelNumber),
            _buildDetailRow('Serial Number', unit.serialNumber),
            _buildDetailRow('Year', unit.formattedYear),
            if (unit.location?.isNotEmpty == true)
              _buildDetailRow('Location', unit.location!),

            // Maintenance Info
            if (unit.lastMaintenanceDate != null ||
                unit.lastRepairedDate != null) ...[
              SizedBox(height: 16),
              Text(
                'Maintenance History',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              if (unit.lastMaintenanceDate != null)
                _buildDetailRow(
                    'Last Maintenance', _formatDate(unit.lastMaintenanceDate!)),
              if (unit.lastRepairedDate != null)
                _buildDetailRow(
                    'Last Repair', _formatDate(unit.lastRepairedDate!)),
              if (unit.nextScheduledMaintenance != null)
                _buildDetailRow('Next Maintenance',
                    _formatDate(unit.nextScheduledMaintenance!)),
            ],

            // Connected Devices
            if (unit.connectedDevices.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Connected Devices (${unit.connectedDevices.length})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              ...unit.connectedDevices
                  .map((device) => _buildDeviceRow(device))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow(Map<String, dynamic> device) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: device['is_online'] ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  device['name'] ?? 'Unknown Device',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (device['is_in_repair_mode'])
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Repair Mode',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '${device['device_type']} • ID: ${device['device_id']}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (device['target_temp_min'] != null &&
              device['target_temp_max'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Target: ${device['target_temp_min']}°C - ${device['target_temp_max']}°C',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (device['last_service_date'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Last Service: ${_formatDate(device['last_service_date'])}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getSupplierTypeColor(supplier['supplier_type_value'])
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    supplier['supplier_type'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getSupplierTypeColor(
                          supplier['supplier_type_value']),
                    ),
                  ),
                ),
                Spacer(),
                if (supplier['is_preferred'])
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.amber[700]),
                        SizedBox(width: 4),
                        Text(
                          'Preferred',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              supplier['name'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (supplier['contact_person']?.isNotEmpty == true) ...[
              SizedBox(height: 4),
              Text(
                'Contact: ${supplier['contact_person']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  supplier['phone_primary'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.location_city, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${supplier['city']}, ${supplier['province_state']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (supplier['rating'] != null && supplier['rating'] > 0) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < supplier['rating'].floor()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                  SizedBox(width: 8),
                  Text(
                    '${supplier['rating'].toStringAsFixed(1)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (supplier['delivery_area']?.isNotEmpty == true) ...[
              SizedBox(height: 8),
              Text(
                'Delivery Area: ${supplier['delivery_area']}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Lead Time: ${supplier['lead_time_days']} days',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Spacer(),
                if (supplier['after_hours_available'])
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '24/7',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            if (supplier['specializations']?.isNotEmpty == true) ...[
              SizedBox(height: 8),
              Text(
                'Specializations: ${supplier['specializations']}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'decommissioned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSupplierTypeColor(String? type) {
    switch (type) {
      case 'manufacturer':
        return Colors.blue;
      case 'distributor':
        return Colors.green;
      case 'wholesaler':
        return Colors.purple;
      case 'retailer':
        return Colors.orange;
      case 'service':
        return Colors.teal;
      case 'online':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Helper Methods for Map View
  Widget _buildMapTypeButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _toggleMapType,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Icon(
                _getMapTypeIcon(),
                color: Constants.ctaColorLight,
                size: 20,
              ),
              // Badge showing current map type
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    _getMapTypeBadgeText(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.hybrid;
          break;
        case MapType.hybrid:
          _currentMapType = MapType.normal;
          break;
        default:
          _currentMapType = MapType.normal;
      }
    });
  }

  IconData _getMapTypeIcon() {
    switch (_currentMapType) {
      case MapType.normal:
        return Icons.layers_rounded;
      case MapType.satellite:
        return Icons.satellite_rounded;
      case MapType.hybrid:
        return Icons.terrain_rounded;
      default:
        return Icons.layers_rounded;
    }
  }

  String _getMapTypeBadgeText() {
    switch (_currentMapType) {
      case MapType.normal:
        return 'N';
      case MapType.satellite:
        return 'S';
      case MapType.hybrid:
        return 'H';
      default:
        return 'N';
    }
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _loadData,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.refresh_rounded,
            color: Constants.ctaColorLight,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModernUnitDetailsCard(Unit unit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Constants.ctaColorLight.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Constants.ctaColorLight.withOpacity(0.1),
                  Constants.ctaColorLight.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_rounded,
                    color: Constants.ctaColorLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unit.modelNumber} • S/N: ${unit.serialNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(unit.statusValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(unit.statusValue).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    unit.statusDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(unit.statusValue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  Text(
                    'Unit Information',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIconDetailRow('Model', unit.modelNumber, Icons.settings),
                  _buildIconDetailRow('Year', unit.formattedYear, Icons.calendar_today),
                  if (unit.location?.isNotEmpty == true)
                    _buildIconDetailRow('Location', unit.location!, Icons.place),
                  
                  // Coordinates if available
                  if (unit.hasCoordinates) ...[
                    const SizedBox(height: 4),
                    _buildIconDetailRow(
                      'Coordinates',
                      '${unit.latitude!.toStringAsFixed(6)}, ${unit.longitude!.toStringAsFixed(6)}',
                      Icons.my_location,
                    ),
                  ],

                  // Maintenance Information
                  if (unit.lastMaintenanceDate != null ||
                      unit.lastRepairedDate != null ||
                      unit.nextScheduledMaintenance != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Maintenance History',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (unit.lastMaintenanceDate != null)
                      _buildIconDetailRow(
                        'Last Maintenance',
                        _formatDate(unit.lastMaintenanceDate!),
                        Icons.build,
                      ),
                    if (unit.lastRepairedDate != null)
                      _buildIconDetailRow(
                        'Last Repair',
                        _formatDate(unit.lastRepairedDate!),
                        Icons.handyman,
                      ),
                    if (unit.nextScheduledMaintenance != null)
                      _buildIconDetailRow(
                        'Next Maintenance',
                        _formatDate(unit.nextScheduledMaintenance!),
                        Icons.schedule,
                      ),
                  ],

                  // Connected Devices
                  if (unit.connectedDevices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Connected Devices (${unit.connectedDevices.length})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...unit.connectedDevices
                        .map((device) => _buildDeviceRow(device))
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Constants.ctaColorLight,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showUnitDetails(unit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Full Details',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _centerOnUnit(unit),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.center_focus_strong_rounded,
                        color: Constants.ctaColorLight,
                        size: 18,
                      ),
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

  Widget _buildIconDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: Constants.ctaColorLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUnitDetails(Unit unit) {
    // Placeholder method for showing detailed unit information
    // This could open a modal, navigate to a details page, or show a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Unit Details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildUnitDetailsCard(unit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _centerOnUnit(Unit unit) async {
    if (unit.latitude != null && unit.longitude != null) {
      final GoogleMapController controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(unit.latitude!, unit.longitude!),
            zoom: 16,
            tilt: 45,
          ),
        ),
      );
      
      // Update selected unit to show details panel
      setState(() {
        selectedUnit = unit;
      });
    }
  }

  // Missing Helper Methods

  Widget _buildStatusChip(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _getOperationalUnitsCount() {
    return unitList.where((unit) => unit.statusValue.toLowerCase() == 'operational').length;
  }

  int _getMaintenanceUnitsCount() {
    return unitList.where((unit) => unit.statusValue.toLowerCase() == 'maintenance').length;
  }

  Widget _buildModernUnitListCard(Unit unit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Constants.ctaColorLight.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onUnitSelected(unit),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Status and Location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(unit.statusValue).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(unit.statusValue).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(unit.statusValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            unit.statusDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(unit.statusValue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (unit.hasCoordinates)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: const Color(0xFF10B981),
                          size: 14,
                        ),
                      ),
                    if (unit.isMaintenanceDue)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              size: 12,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Unit Name
                Text(
                  unit.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Model and Serial
                Text(
                  '${unit.modelNumber} • S/N: ${unit.serialNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                
                if (unit.location?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Constants.ctaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.place_rounded,
                          size: 12,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unit.location!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Connected Devices Count
                if (unit.connectedDevicesCount > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.devices_rounded,
                          size: 14,
                          color: Constants.ctaColorLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${unit.connectedDevicesCount} device${unit.connectedDevicesCount > 1 ? 's' : ''} connected',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Constants.ctaColorLight,
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
      ),
    );
  }

  Widget _buildModernSupplierCard(dynamic supplier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Constants.ctaColorLight.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Type and Preferred Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSupplierTypeColor(supplier['supplier_type_value']).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getSupplierTypeColor(supplier['supplier_type_value']).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getSupplierTypeColor(supplier['supplier_type_value']),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        supplier['supplier_type'] ?? 'Supplier',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getSupplierTypeColor(supplier['supplier_type_value']),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (supplier['is_preferred'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Preferred',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Supplier Name
            Text(
              supplier['name'] ?? 'Unknown Supplier',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            
            if (supplier['contact_person']?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'Contact: ${supplier['contact_person']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Contact Information
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    size: 12,
                    color: Constants.ctaColorLight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  supplier['phone_primary'] ?? 'No phone',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 12,
                    color: Constants.ctaColorLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${supplier['city'] ?? 'Unknown'}, ${supplier['province_state'] ?? 'Unknown'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            
            // Rating
            if (supplier['rating'] != null && supplier['rating'] > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < (supplier['rating']?.floor() ?? 0)
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color: const Color(0xFFF59E0B),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${supplier['rating']?.toStringAsFixed(1) ?? '0.0'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 10),
            
            // Additional Information Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lead: ${supplier['lead_time_days'] ?? '0'} days',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const Spacer(),
                if (supplier['after_hours_available'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '24/7',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Specializations
            if (supplier['specializations']?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Specializations: ${supplier['specializations']}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
