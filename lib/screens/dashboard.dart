import 'dart:async';
import 'dart:convert';

import 'package:artic_sentinel/models/dashboard.dart';
import 'package:artic_sentinel/screens/roles.dart';
import 'package:artic_sentinel/screens/settings/settings.dart';
import 'package:artic_sentinel/screens/units.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../constants/Constants.dart';
import '../constants/models/device.dart';
import '../custom_widgets/customCard.dart';
import '../models/animal_breed.dart';
import '../models/average_temperature.dart';
import '../models/daily_summar_records.dart';
import '../models/notification.dart';
import '../services/dashboard_services.dart';
import '../services/myNotifier.dart';
import 'device_perfomance_tracking.dart';
import 'communication.dart';
import 'dashboard_home.dart';
import 'device_management.dart';
import 'geo_fencing.dart';
import 'health_wellness.dart';
import 'help.dart';
import 'alert.dart';
import 'maintanance.dart';

// Models for API responses
class LatestDeviceData {
  final String? deviceId;
  final String? time;
  final double? temperature;
  final double? temperatureAir;
  final double? temperatureCoil;
  final double? temperatureDrain;
  final bool? door;
  final bool? iceBuiltUp;
  final bool? comp;
  final double? compressorLow;
  final double? compressorHigh;
  final double? compAmpPh1;
  final double? compAmpPh2;
  final double? compAmpPh3;

  LatestDeviceData({
    this.deviceId,
    this.time,
    this.temperature,
    this.temperatureAir,
    this.temperatureCoil,
    this.temperatureDrain,
    this.door,
    this.iceBuiltUp,
    this.comp,
    this.compressorLow,
    this.compressorHigh,
    this.compAmpPh1,
    this.compAmpPh2,
    this.compAmpPh3,
  });

  factory LatestDeviceData.fromJson(Map<String, dynamic> json) {
    return LatestDeviceData(
      deviceId: json['device_id'],
      time: json['time'],
      temperature: json['temperature']?.toDouble(),
      temperatureAir: json['temperatureAir']?.toDouble(),
      temperatureCoil: json['temperatureCoil']?.toDouble(),
      temperatureDrain: json['temperatureDrain']?.toDouble(),
      door: json['door'],
      iceBuiltUp: json['iceBuiltUp'],
      comp: json['comp'],
      compressorLow: json['compressorLow']?.toDouble(),
      compressorHigh: json['compressorHigh']?.toDouble(),
      compAmpPh1: json['compAmpPh1']?.toDouble(),
      compAmpPh2: json['compAmpPh2']?.toDouble(),
      compAmpPh3: json['compAmpPh3']?.toDouble(),
    );
  }
}

class HourlyAggregate {
  final String? hourBucket;
  final double? avgTempAir;
  final double? avgTemp;
  final int? compressorOnCount;
  final int? totalReadings;

  HourlyAggregate({
    this.hourBucket,
    this.avgTempAir,
    this.avgTemp,
    this.compressorOnCount,
    this.totalReadings,
  });

  factory HourlyAggregate.fromJson(Map<String, dynamic> json) {
    return HourlyAggregate(
      hourBucket: json['hour_bucket'],
      avgTempAir: json['avg_temp_air']?.toDouble(),
      avgTemp: json['avg_temp']?.toDouble(),
      compressorOnCount: json['compressor_on_count'],
      totalReadings: json['total_readings'],
    );
  }
}

class AlertData {
  final String? id;
  final String? deviceId;
  final String? timestamp;
  final String? alertType;
  final String? message;
  final String? severity;
  final String? status;

  AlertData({
    this.id,
    this.deviceId,
    this.timestamp,
    this.alertType,
    this.message,
    this.severity,
    this.status,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      id: json['id'],
      deviceId: json['device_id'],
      timestamp: json['timestamp'],
      alertType: json['alert_type'],
      message: json['message'],
      severity: json['severity'],
      status: json['status'],
    );
  }
}

class DoorOpens {
  String? deviceId;
  int? doorOpenCount;

  DoorOpens({this.deviceId, this.doorOpenCount});
}

MyNotifier? myNotifier1;
final activityTrackingValue = ValueNotifier<int>(0);
final averageTamWidgetValue = ValueNotifier<int>(0);

class TopNavbar {
  int id;
  String string_id;
  String name;

  TopNavbar(this.id, this.string_id, this.name);
}

class SideBarItems {
  int id;
  String item_id;
  String itemName;
  IconData itemIcon;

  SideBarItems(this.id, this.item_id, this.itemName, this.itemIcon);
}

class ArticDashboard extends StatefulWidget {
  const ArticDashboard({super.key});

  @override
  State<ArticDashboard> createState() => _ArticDashboardState();
}

List<DeviceModel3> totalDetached = [];
List<DeviceModel3> totalActive = [];
List<DeviceModel3> totalInactive = [];
List<DeviceModel3> totalNew = [];
List<DeviceModel3> totalFaulty = [];
List<DeviceModel3> totalDevice = [];

class _ArticDashboardState extends State<ArticDashboard> {
  // API Data
  List<LatestDeviceData> latestDeviceDataList = [];
  List<DailyAggregate> dailyAggregatesList = [];
  List<HourlyAggregate> hourlyAggregatesList = [];
  List<AlertData> alertsList = [];
  bool isLoading = true;
  bool isInitialLoad = true;

  // Device Selection
  String? selectedDeviceId;
  List<DeviceModel3> availableDevices = [];

  // Auto-refresh timer
  Timer? _refreshTimer;
  DateTime? lastRefreshTime;

  List<TopNavbar> navBarList = [
    TopNavbar(1, "home", "HOME"),
    TopNavbar(3, "about_us", "About Us"),
    TopNavbar(4, "contact", "Contact"),
    TopNavbar(5, "services", "Services"),
    TopNavbar(6, "resources", "Resources")
  ];

  List<SideBarItems> sideBarList = [
    SideBarItems(1, "dashboard", "Dashboard", CupertinoIcons.home),
    SideBarItems(2, "device_perfomance", "Device Performance",
        CupertinoIcons.chart_bar_alt_fill),
    SideBarItems(
        2, "units", "Unit Management", CupertinoIcons.rectangle_grid_2x2),
    SideBarItems(
        2, "communication", "Communications", CupertinoIcons.chat_bubble_2),
    SideBarItems(
        3, "geo_fencing", "Location Management", CupertinoIcons.location_solid),
    SideBarItems(5, "device_management", "Device Management",
        CupertinoIcons.device_laptop),
    SideBarItems(8, "notification", "Notifications", CupertinoIcons.bell),
    SideBarItems(8, "maintenance", "Maintenance", CupertinoIcons.wrench_fill),
    SideBarItems(8, "access", "Access Management", CupertinoIcons.person_2),
    SideBarItems(9, "settings", "Settings", CupertinoIcons.gear_alt),
    SideBarItems(10, "help", "Help & Support", CupertinoIcons.question_circle),
  ];

  List<DailySummaryRecords> dailySummaryList = [];
  List<DailySummaryRecords2> dailySummaryList2 = [];
  List<NotificationModel> recentNotificationList = [];
  List<AverageTemperature> aveTemperatureList = [];
  List<AnimalBreed> animalBreedList = [
    AnimalBreed(01, "Chiller", 78, 21),
    AnimalBreed(02, "Freezer", 31, 45),
  ];

  Map<String, dynamic> distance = {
    "distance_travelled": 43,
    "distance_expected": 60
  };
  Map<String, dynamic> battery = {
    "average_battery": 69,
    "actual_percentage": 100
  };

  int sideColorIndex = 0;
  String itemIdIndex = "dashboard";

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  final Completer<GoogleMapController> _map_controller =
      Completer<GoogleMapController>();
  bool _isInfoWindowVisible = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-25.974365171190335, 28.095606369504797),
    zoom: 10,
  );
  MapType mapType = MapType.normal;
  List<String> bottomTitles = [];
  int marker_id = 1;
  late CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(-25.974365171190335, 28.095606369504797),
    zoom: 10,
  );

  // API Methods
  Future<void> fetchLatestDeviceData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.articBaseUrl2}latest-device-data/${Constants.myBusiness.businessUid}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          latestDeviceDataList =
              data.map((item) => LatestDeviceData.fromJson(item)).toList();
        });
        _updateDailySummaryFromLatestData();
      } else {
        print('Failed to fetch latest device data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest device data: $e');
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      String url =
          '${Constants.articBaseUrl2}dashboard-data/?business_uid=${Constants.myBusiness.businessUid}';
      print("gfhghg $url");

      // Add device filter if specific device is selected
      if (selectedDeviceId != null && selectedDeviceId!.isNotEmpty) {
        url += '&device_id=$selectedDeviceId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          dailyAggregatesList = (data['daily_aggregates'] as List)
              .map((item) => DailyAggregate.fromJson(item))
              .toList();
          hourlyAggregatesList = (data['hourly_aggregates'] as List)
              .map((item) => HourlyAggregate.fromJson(item))
              .toList();
        });
        _processDailyAggregates();
      } else {
        print('Failed to fetch dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  Future<void> fetchAlerts() async {
    try {
      String url =
          '${Constants.articBaseUrl2}alerts/?business_id=${Constants.myBusiness.businessUid}';

      // Add device filter if specific device is selected
      if (selectedDeviceId != null && selectedDeviceId!.isNotEmpty) {
        url += '&device_id=$selectedDeviceId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          alertsList = (data['alerts'] as List)
              .map((item) => AlertData.fromJson(item))
              .toList();
        });
        _updateNotificationList();
      } else {
        print('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching alerts: $e');
    }
  }

  Future<void> getDeviceByClient(int business_uid) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.articBaseUrl2}get_devices_by_client/$business_uid/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var responsedata = jsonDecode(response.body);
        List<DeviceModel3> devices = [];

        for (var device in responsedata) {
          DeviceModel3 deviceModel = DeviceModel3.fromJson(device);
          devices.add(deviceModel);
        }

        // Update global variables
        totalActive = devices
            .where((device) => device.currentStatus == "Active")
            .toList();
        totalInactive = devices
            .where((device) => device.currentStatus == "Inactive")
            .toList();
        totalFaulty = devices
            .where((device) => device.currentStatus == "Faulty")
            .toList();
        totalNew =
            devices.where((device) => device.currentStatus == "New").toList();
        totalDetached = devices
            .where((device) => device.currentStatus == "Detached")
            .toList();
        totalDevice = devices;

        // Update Constants and available devices
        Constants.allDeviceData = devices;
        availableDevices = devices;

        // Set default selected device to first device if none selected
        if (selectedDeviceId == null && devices.isNotEmpty) {
          selectedDeviceId = devices.first.deviceId;
        }

        setState(() {});
        _initializeMarkers();
      } else {
        print('Failed to fetch devices: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching devices: $e");
    }
  }

  void _updateDailySummaryFromLatestData() {
    if (latestDeviceDataList.isNotEmpty) {
      // Find data for selected device or use first device
      LatestDeviceData deviceData;
      if (selectedDeviceId != null) {
        deviceData = latestDeviceDataList.firstWhere(
          (data) => data.deviceId == selectedDeviceId,
          orElse: () => latestDeviceDataList.first,
        );
      } else {
        deviceData = latestDeviceDataList.first;
      }

      dailySummaryList = [
        DailySummaryRecords(
          deviceData.temperatureAir?.toInt() ?? 0,
          0,
          "Freezer Room Temperature",
          FontAwesomeIcons.snowflake,
          const Color(0XFFF4F4F4),
        ),
        DailySummaryRecords(
          deviceData.compressorLow?.toInt() ?? 0,
          0,
          "Pressure [Low Side]",
          FontAwesomeIcons.gauge,
          const Color(0Xcc3C514933),
        ),
        DailySummaryRecords(
          deviceData.compressorHigh?.toInt() ?? 0,
          0,
          "Pressure [High Side]",
          FontAwesomeIcons.gaugeHigh,
          const Color(0XccF4F4F4),
        ),
        DailySummaryRecords(
          deviceData.temperatureCoil?.toInt() ?? 0,
          0,
          "Heater Coil Temperature",
          FontAwesomeIcons.fire,
          const Color(0Xcc3C514914),
        ),
        DailySummaryRecords(
          deviceData.temperatureDrain?.toInt() ?? 0,
          0,
          "Heater Drain Temperature",
          FontAwesomeIcons.tint,
          const Color(0Xcc3C514980),
        ),
      ];

      dailySummaryList2 = [
        DailySummaryRecords2(
          "Door Open",
          FontAwesomeIcons.doorOpen,
          const Color(0XFFF4F4F4),
          deviceData.door ?? false,
        ),
        DailySummaryRecords2(
          "Compressor On",
          FontAwesomeIcons.fan,
          const Color(0XFFF4F4F4),
          deviceData.comp ?? false,
        ),
        DailySummaryRecords2(
          "Ice Build-Up",
          FontAwesomeIcons.icicles,
          const Color(0XFFF4F4F4),
          deviceData.iceBuiltUp ?? false,
        ),
      ];
    }
  }

  void _processDailyAggregates() {
    aveTemperatureList.clear();

    for (var aggregate in dailyAggregatesList) {
      if (aggregate.avgTempAir != null && aggregate.dayBucket != null) {
        aveTemperatureList.add(
          AverageTemperature(
            DateFormat('dd MMM').format(DateTime.parse(aggregate.dayBucket!)),
            aggregate.avgTempAir!.toInt(),
            aggregate.avgTempCoil?.toInt() ?? 0,
          ),
        );
      }
    }

    // Update the chart data
    Constants.hourlyData = hourlyAggregatesList
        .map((hourly) => DailyAggregate(
              dayBucket: hourly.hourBucket,
              avgTempAir: hourly.avgTempAir,
              avgTempCoil: 0,
              doorOpenCount: hourly.compressorOnCount,
              totalReadings: hourly.totalReadings,
            ))
        .toList();

    averageTamWidgetValue.value++;
  }

  void _updateNotificationList() {
    recentNotificationList = alertsList
        .map((alert) => NotificationModel(
              id: 0,
              message: alert.message ?? '',
              alertType: alert.alertType ?? '',
              timestamp: alert.timestamp ?? '',
              deviceId: "",
              alertCategory: '',
              isResolved: false,
              isSystemAlert: true,
              paramCode: '',
            ))
        .toList();
  }

  // Method to refresh data when device selection changes
  Future<void> _refreshDataForSelectedDevice() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        fetchLatestDeviceData(),
        fetchDashboardData(),
        fetchAlerts(),
      ]);
    } catch (e) {
      print('Error refreshing data for selected device: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeMarkers() {
    if (Constants.allDeviceData.isNotEmpty) {
      // Clear existing markers
      markers.clear();

      for (var device in Constants.allDeviceData) {
        if (device.latitude != null && device.longitude != null) {
          final markerId = MarkerId(device.deviceId);
          final marker = Marker(
            markerId: markerId,
            position: LatLng(
              double.parse(device.latitude!),
              double.parse(device.longitude!),
            ),
            infoWindow: InfoWindow(
              title: 'Device: ${device.deviceId}',
              snippet: 'Status: ${device.currentStatus}',
            ),
          );
          markers[markerId] = marker;
        }
      }

      // Set initial camera position to first device
      if (markers.isNotEmpty) {
        final firstMarker = markers.values.first;
        initialCameraPosition = CameraPosition(
          target: firstMarker.position,
          zoom: 10,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    print('Dashboard initState called');
    _loadAllData();
    // Start auto-refresh after a slight delay to ensure initial load completes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    print('Starting auto-refresh timer...');
    // Cancel any existing timer first
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('Auto-refresh triggered at ${DateTime.now()}');
      if (mounted && context.mounted) {
        print('Widget is mounted, refreshing data...');
        _loadAllData(
            showLoading: false); // Background refresh without loading indicator
      } else {
        print('Widget not mounted, cancelling timer');
        timer.cancel();
      }
    });
    print('Auto-refresh timer started successfully');
  }

  Future<void> _loadAllData({bool showLoading = true}) async {
    print(
        '_loadAllData called with showLoading: $showLoading at ${DateTime.now()}');

    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      print('Starting data fetch operations...');
      // Load data in parallel
      await Future.wait([
        getDeviceByClient(Constants.myBusiness.businessUid),
        fetchLatestDeviceData(),
        fetchDashboardData(),
        fetchAlerts(),
      ]);

      print('Data fetch completed successfully');
      if (mounted) {
        setState(() {
          isLoading = false;
          isInitialLoad = false;
          lastRefreshTime = DateTime.now();
        });
        print('Dashboard state updated');
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (showLoading && mounted) {
        setState(() {
          isLoading = false;
        });
      }
      // For background updates, silently fail to avoid disrupting UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading && isInitialLoad
        ? Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Constants.ctaColorLight,
                    strokeWidth: 3.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard data...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                child: ArticDashboardTab(),
              ),
              // Show refresh status indicator
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading && !isInitialLoad) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Constants.ctaColorLight,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Updating...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ] else if (lastRefreshTime != null) ...[
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Last updated: ${DateFormat('HH:mm:ss').format(lastRefreshTime!)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: RichText(
            text: TextSpan(
              text: 'Welcome ',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500),
              ),
              children: <TextSpan>[
                TextSpan(
                  text: Constants.myDisplayname,
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        letterSpacing: 0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                TextSpan(
                  text: ' to ${Constants.business_name} Dashboard',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Divider(thickness: 0.5, color: Colors.grey),
        ),
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Text(
            "Dashboard Analytics",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 32),
          child: Row(
            children: [
              Text(
                "Device Analytics",
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                      fontSize: 14,
                      color: Constants.ctaTextColor,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal),
                ),
              ),
              SizedBox(width: 24),
              // Device Dropdown
              Container(
                height: 32,
                width: 200,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: Container(
                    height: 32,
                    width: 200,
                    child: DropdownButton<String>(
                      value: selectedDeviceId,
                      hint: Text(
                        "Select Device",
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: Constants.ctaColorLight, size: 20),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.normal),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            "All Devices",
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal),
                            ),
                          ),
                        ),
                        ...availableDevices.map((device) {
                          return DropdownMenuItem<String>(
                            value: device.deviceId,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColor(
                                        device.currentStatus ?? ''),
                                  ),
                                ),
                                Container(
                                  child: Text(
                                    "${device.deviceId} - ${device.currentStatus ?? 'Unknown'}",
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.normal),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDeviceId = newValue;
                        });
                        _refreshDataForSelectedDevice();
                      },
                    ),
                  ),
                ),
              ),
              // Spacer(),
              if (latestDeviceDataList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Text(
                      "Last Fetched : ${DateFormat('EEE, dd MMM - HH:mm').format(DateTime.parse(latestDeviceDataList.first.time!).add(Duration(hours: 2)))}"),
                ),
            ],
          ),
        ),
        SizedBox(height: 24),
        // Device Analytics Cards
        if (dailySummaryList.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: CustomCard(
              elevation: 3,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 205,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(16),
                child: ListView.builder(
                    itemCount: dailySummaryList.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    physics: ScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            right:
                                index < dailySummaryList.length - 1 ? 24 : 0),
                        child: Container(
                          width: 180,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: dailySummaryList[index].cardColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CustomCard(
                                    color: Constants.ctaColorLight,
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Icon(
                                        dailySummaryList[index].itemIcon,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    dailySummaryList[index]
                                            .itemCount
                                            .toString() +
                                        ((index == 0 ||
                                                index == 3 ||
                                                index == 4)
                                            ? "°c"
                                            : " psi"),
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          letterSpacing: 0,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                dailySummaryList[index].itemName,
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Constants.ctaTextColor,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.normal),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "+${dailySummaryList[index].itemRecordPercentage}% from yesterday",
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.normal),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: CustomCard(
              elevation: 3,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 110,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(16),
                child: ListView.builder(
                    itemCount: dailySummaryList2.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    physics: ScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            right:
                                index < dailySummaryList2.length - 1 ? 24 : 0),
                        child: Container(
                          width: 250,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: dailySummaryList2[index].cardColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CustomCard(
                                    color: Constants.ctaColorLight,
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Icon(
                                        dailySummaryList2[index].itemIcon,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          dailySummaryList2[index].itemName,
                                          style: GoogleFonts.inter(
                                            textStyle: TextStyle(
                                                fontSize: 14,
                                                color: Constants.ctaTextColor,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                        Text(
                                          dailySummaryList2[index]
                                              .condtion
                                              .toString(),
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ),
          ),
        ],
        SizedBox(height: 16),
        // Bar Chart
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: CustomCard(
            elevation: 3,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              height: 300,
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [BarChartSample2()],
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        // Average Temperature Section
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Text(
            "Average Temperature (Air Vs Coil)",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ),
        SizedBox(height: 24),
        if (aveTemperatureList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: CustomCard(
              elevation: 3,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 132,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(16),
                child: ListView.builder(
                    itemCount: aveTemperatureList.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    physics: ScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            right:
                                index < aveTemperatureList.length - 1 ? 24 : 0),
                        child: Container(
                          width: 80,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Color(0XFFD9D9D9),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                aveTemperatureList[index].day,
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Constants.ctaTextColor,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "${aveTemperatureList[index].highTemperature}/${aveTemperatureList[index].lowTemperature}",
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                height: 5,
                                width: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0XFF2F4852),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ),
          ),
        SizedBox(height: 24),
        // Recent Alerts Section
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Text(
            "Recent Alerts",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: CustomCard(
            elevation: 3,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: recentNotificationList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No recent alerts",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentNotificationList.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var notification = recentNotificationList[index];
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: index < recentNotificationList.length - 1
                                  ? 16
                                  : 0),
                          child: InkWell(
                            hoverColor: Colors.white,
                            splashColor: Colors.white,
                            focusColor: Colors.white,
                            child: Container(
                              height: 60,
                              padding: EdgeInsets.all(8),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: Color(0XFFF4F4F4)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Card(
                                    elevation: 10,
                                    color: Colors.white,
                                    shadowColor: Colors.black,
                                    surfaceTintColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3)),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Center(
                                        child: Icon(
                                          CupertinoIcons.chat_bubble_text,
                                          size: 28,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification.message,
                                                style: GoogleFonts.inter(
                                                  textStyle: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      letterSpacing: 0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: Container(
                                                height: 15,
                                                width: 15,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Constants
                                                        .ctaColorLight),
                                              ),
                                            )
                                          ],
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              notification.alertType,
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: Text(
                                                timeAgo.format(DateTime.parse(
                                                    notification.timestamp)),
                                                style: GoogleFonts.inter(
                                                  textStyle: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black,
                                                      letterSpacing: 0,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            onTap: () {
                              _showAlertDialog(notification);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        SizedBox(height: 32),
        // Device Locations Section
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Text(
            "Device Locations",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: CustomCard(
            elevation: 3,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 500,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: initialCameraPosition,
                  markers: markers.values.toSet(),
                  onTap: (LatLng location) {
                    setState(() {
                      _isInfoWindowVisible = false;
                    });
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _map_controller.complete(controller);
                  },
                ),
              )),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  void _showAlertDialog(NotificationModel notification) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => Dialog(
                  insetAnimationDuration: Duration(milliseconds: 800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(64),
                  ),
                  elevation: 0.0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      constraints:
                          BoxConstraints(maxWidth: 800, maxHeight: 350),
                      padding: const EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: Offset(0.0, 10.0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Color(0XFFF4F4F4),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.message,
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 10,
                                          width: 10,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Constants.ctaColorLight),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          timeAgo.format(DateTime.parse(
                                              notification.timestamp)),
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  notification.alertType,
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Device: ${notification.deviceId}",
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                    backgroundColor: Constants.ctaColorLight,
                                    minimumSize: Size(140, 45)),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Close",
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      )),
                )));
  }

  // Helper method to navigate to route based on item_id
  void _navigateToRoute(String itemId) {
    switch (itemId) {
      case "dashboard":
        context.go('/dashboard-home');
        break;
      case "notification":
        context.go('/alerts');
        break;
      case "device_management":
        context.go('/device-management');
        break;
      case "device_perfomance":
        // Note: This route was removed because it requires parameters
        break;
      case "units":
        context.go('/units');
        break;
      case "communication":
        context.go('/communication');
        break;
      case "geo_fencing":
        context.go('/geo-fencing');
        break;
      case "maintenance":
        context.go('/maintenance');
        break;
      case "access":
        context.go('/roles');
        break;
      case "settings":
        context.go('/settings');
        break;
      case "help":
        context.go('/help');
        break;
    }
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'faulty':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      case 'detached':
        return Colors.red.shade300;
      case 'new':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class BarChartSample2 extends StatefulWidget {
  BarChartSample2({super.key});
  final Color leftBarColor = Color(0XFF2F4852);
  final Color rightBarColor = Color(0XFFB1EBC0);
  final Color avgColor = Color(0XFFB1EBC0);
  @override
  State<StatefulWidget> createState() => BarChartSample2State();
}

class BarChartSample2State extends State<BarChartSample2> {
  final double width = 15;
  double maxYvalue = 0;
  late List<BarChartGroupData> showingBarGroups = [];
  int touchedGroupIndex = -1;

  @override
  void initState() {
    super.initState();
    myNotifier1 = MyNotifier(averageTamWidgetValue, context);
    averageTamWidgetValue.addListener(() {
      showingBarGroups.clear();
      maxYvalue = 0;

      Constants.hourlyData.forEach((group) {
        showingBarGroups.add(
          BarChartGroupData(
            x: Constants.hourlyData
                .indexWhere((map) => map.dayBucket == group.dayBucket),
            barRods: [
              BarChartRodData(
                toY: group.avgTempAir ?? 0,
                width: 16,
                color: Constants.ctaColorLight,
              ),
            ],
          ),
        );
      });

      showingBarGroups.forEach((group) {
        group.barRods.forEach((barRod) {
          if (barRod.toY > maxYvalue) {
            maxYvalue = barRod.toY;
          }
        });
      });

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Hourly Average Temperature",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: showingBarGroups.isEmpty
                ? Center(
                    child: Text(
                      "No hourly data available",
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxYvalue > 0 ? maxYvalue : 50,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: ((group) {
                            return Colors.grey;
                          }),
                          getTooltipItem: (a, b, c, d) => null,
                        ),
                        touchCallback: (FlTouchEvent event, response) {
                          if (response == null || response.spot == null) {
                            setState(() {
                              touchedGroupIndex = -1;
                            });
                            return;
                          }
                          touchedGroupIndex =
                              response.spot!.touchedBarGroupIndex;
                          setState(() {
                            if (!event.isInterestedForInteractions) {
                              touchedGroupIndex = -1;
                              return;
                            }
                            if (touchedGroupIndex != -1) {
                              var sum = 0.0;
                              for (final rod
                                  in showingBarGroups[touchedGroupIndex]
                                      .barRods) {
                                sum += rod.toY;
                              }
                              final avg = sum /
                                  showingBarGroups[touchedGroupIndex]
                                      .barRods
                                      .length;
                              showingBarGroups[touchedGroupIndex] =
                                  showingBarGroups[touchedGroupIndex].copyWith(
                                barRods: showingBarGroups[touchedGroupIndex]
                                    .barRods
                                    .map((rod) {
                                  return rod.copyWith(
                                      toY: avg, color: widget.avgColor);
                                }).toList(),
                              );
                            }
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: bottomTitles,
                            reservedSize: 42,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: leftTitles,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: showingBarGroups,
                      gridData: const FlGridData(show: false),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xffAAAAAA),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    double divisionFactor;
    if (maxYvalue <= 50) {
      divisionFactor = 3;
    } else if (maxYvalue <= 100) {
      divisionFactor = 5;
    } else if (maxYvalue <= 150) {
      divisionFactor = 10;
    } else if (maxYvalue <= 200) {
      divisionFactor = 20;
    } else {
      divisionFactor = 25;
    }

    if (value % divisionFactor == 0) {
      String text = value.toInt().toString();
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 0,
        child: Text(text, style: style),
      );
    } else {
      return Container();
    }
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xffAAAAAA),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    if (value.toInt() < 0 || value.toInt() >= Constants.hourlyData.length) {
      return Container();
    }

    final hourBucket = Constants.hourlyData[value.toInt()].dayBucket;
    final formattedHour = hourBucket != null
        ? DateFormat('HH:mm').format(DateTime.parse(hourBucket))
        : '';

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(formattedHour, style: style),
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: widget.leftBarColor,
          width: width,
        ),
        BarChartRodData(
          toY: y2,
          color: widget.rightBarColor,
          width: width,
        ),
      ],
    );
  }

  Widget makeTransactionsIcon() {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(width: space),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(width: space),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withOpacity(1),
        ),
        const SizedBox(width: space),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(width: space),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
      ],
    );
  }
}
