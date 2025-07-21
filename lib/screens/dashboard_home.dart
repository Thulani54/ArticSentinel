import 'dart:async';
import 'dart:convert';

import 'package:artic_sentinel/models/dashboard.dart';
import 'package:artic_sentinel/screens/settings/settings.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'device_management.dart';
import 'geo_fencing.dart';
import 'health_wellness.dart';
import 'help.dart';
import 'alert.dart';

class TopNavbar {
  int id;
  String string_id;
  String name;

  TopNavbar(this.id, this.string_id, this.name);
}

Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
final Completer<GoogleMapController> _map_controller =
    Completer<GoogleMapController>();
bool _isInfoWindowVisible = false;

class SideBarItems {
  int id;
  String item_id;
  String itemName;
  IconData itemIcon;

  SideBarItems(this.id, this.item_id, this.itemName, this.itemIcon);
}

List<String> bottomTitles = [];
int marker_id = 1;
late CameraPosition initialCameraPosition = CameraPosition(
  target: LatLng(-25.974365171190335, 28.095606369504797),
  zoom: 10,
);

List<LatestDeviceData> latestDeviceDataList = [];
List<DailyAggregate> dailyAggregatesList = [];
List<HourlyAggregate> hourlyAggregatesList = [];
List<AlertData> alertsList = [];
bool isLoading = true;

// Device Selection
String? selectedDeviceId;
List<DeviceModel> availableDevices = [];

// Tab Controller for metrics
late TabController _metricsTabController;
late TabController _chartTabController;

DashboardData? dashboardData;
List<DeviceAlert> activeAlerts = [];
// Performance metrics
PerformanceMetrics? currentPerformanceMetrics;
List<TemperatureRange> temperatureRanges = [];

// Enhanced summary cards
List<EnhancedSummaryCard> enhancedSummaryCards = [];
Widget _buildPressureMetricRow(String title, double? current, double? min,
    double? avg, double? max, String unit) {
  return Container(
    padding: EdgeInsets.all(Constants.spacingMd),
    decoration: BoxDecoration(
      color: Constants.ctaColorLight.withOpacity(Constants.opacityLight),
      borderRadius: BorderRadius.circular(Constants.spacingSm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        SizedBox(height: Constants.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricValue(
                "Current",
                "${current?.toStringAsFixed(0) ?? '--'} $unit",
                Constants.ctaColorLight),
            _buildMetricValue("Min", "${min?.toStringAsFixed(0) ?? '--'} $unit",
                Constants.ctaColorLight.withOpacity(Constants.opacityMedium)),
            _buildMetricValue("Avg", "${avg?.toStringAsFixed(0) ?? '--'} $unit",
                Constants.ctaColorGrey),
            _buildMetricValue("Max", "${max?.toStringAsFixed(0) ?? '--'} $unit",
                Constants.criticalColor),
          ],
        ),
      ],
    ),
  );
}

Widget _buildCompressorMetricCard(String title, String value, IconData icon) {
  return Container(
    padding: EdgeInsets.all(Constants.spacingMd),
    decoration: BoxDecoration(
      color: Constants.ctaColorLight.withOpacity(Constants.opacityLight),
      borderRadius: BorderRadius.circular(Constants.spacingSm),
    ),
    child: Column(
      children: [
        Icon(icon, color: Constants.compressorOnColor, size: 20),
        SizedBox(height: Constants.spacingSm),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Constants.ctaColorLight)),
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 11, color: Constants.ctaTextColor)),
      ],
    ),
  );
}

Widget _buildEfficiencyCard(
    String title, String value, String subtitle, IconData icon, Color color) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 12),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        Text(subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

Widget _buildMetricValue(String label, String value, Color color) {
  return Column(
    children: [
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      Text(label,
          style: GoogleFonts.inter(fontSize: 9, color: Constants.ctaTextColor)),
    ],
  );
}

Color _getTemperatureStatusColor(String? status) {
  switch (status) {
    case 'normal':
      return Constants.ctaColorLight;
    case 'warning':
      return Constants.ctaColorLight.withOpacity(Constants.opacityMedium);
    case 'critical':
      return Constants.criticalColor;
    default:
      return Colors.grey;
  }
}

Color _getPressureStatusColor(String? status) {
  switch (status) {
    case 'normal':
      return Constants.ctaColorLight;
    case 'warning':
      return Constants.ctaColorLight;
    case 'critical':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

IconData _getPressureStatusIcon(String? status) {
  switch (status) {
    case 'normal':
      return Icons.check_circle;
    case 'warning':
      return Icons.warning;
    case 'critical':
      return Icons.error;
    default:
      return Icons.help;
  }
}

Widget _buildChartsTabView() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Analytics Charts",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
      SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: Column(
          children: [
            TabBar(
              controller: _chartTabController,
              tabs: [
                Tab(text: "Hourly Trends"),
                Tab(text: "Daily Summary"),
                Tab(text: "Performance"),
              ],
              labelColor: Constants.ctaColorLight,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Constants.ctaColorLight,
            ),
            Container(
              height: 350,
              child: TabBarView(
                controller: _chartTabController,
                children: [
                  _buildHourlyTrendsChart(),
                  _buildDailySummaryChart(),
                  _buildPerformanceChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildHourlyTrendsChart() {
  if (hourlyAggregatesList.isEmpty) {
    return Center(
        child: Text("No hourly data available",
            style: GoogleFonts.inter(color: Colors.grey)));
  }

  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Temperature & Pressure Trends (Today)",
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < hourlyAggregatesList.length) {
                        final hour = DateTime.parse(
                            hourlyAggregatesList[index].hourBucket!);
                        return Text(DateFormat('HH:mm').format(hour),
                            style: GoogleFonts.inter(fontSize: 10));
                      }
                      return Text('');
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: hourlyAggregatesList.asMap().entries.map((entry) {
                    return FlSpot(
                        entry.key.toDouble(), entry.value.avgTempAir ?? 0);
                  }).toList(),
                  isCurved: true,
                  color: Constants.ctaColorLight,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: hourlyAggregatesList.asMap().entries.map((entry) {
                    return FlSpot(
                        entry.key.toDouble(),
                        (entry.value.avgLowSidePressure ?? 0) /
                            10); // Scale for visibility
                  }).toList(),
                  isCurved: true,
                  color: Constants.ctaColorLight,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem("Temperature (°C)", Colors.blue),
            SizedBox(width: 20),
            _buildLegendItem("Pressure/10 (psi)", Constants.ctaColorLight),
          ],
        ),
      ],
    ),
  );
}

Widget _buildDailySummaryChart() {
  if (dailyAggregatesList.isEmpty) {
    return Center(
        child: Text("No daily data available",
            style: GoogleFonts.inter(color: Colors.grey)));
  }

  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("7-Day Temperature Range",
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: dailyAggregatesList
                      .map((e) => e.maxTempAir ?? 0)
                      .reduce((a, b) => a > b ? a : b) +
                  5,
              minY: dailyAggregatesList
                      .map((e) => e.minTempAir ?? 0)
                      .reduce((a, b) => a < b ? a : b) -
                  5,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < dailyAggregatesList.length) {
                        final date = DateTime.parse(
                            dailyAggregatesList[index].dayBucket!);
                        return Text(DateFormat('MM/dd').format(date),
                            style: GoogleFonts.inter(fontSize: 10));
                      }
                      return Text('');
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: dailyAggregatesList.asMap().entries.map((entry) {
                final data = entry.value;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: data.maxTempAir ?? 0,
                      fromY: data.minTempAir ?? 0,
                      color: Constants.ctaColorLight.withOpacity(0.7),
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPerformanceChart() {
  if (dailyAggregatesList.isEmpty) {
    return Center(
        child: Text("No performance data available",
            style: GoogleFonts.inter(color: Colors.grey)));
  }

  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Compressor Runtime & Efficiency",
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: dailyAggregatesList
                                .first.compressorRuntimePercentage ??
                            0,
                        color: Constants.ctaColorLight,
                        title:
                            '${(dailyAggregatesList.first.compressorRuntimePercentage ?? 0).toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: 100 -
                            (dailyAggregatesList
                                    .first.compressorRuntimePercentage ??
                                0),
                        color: Colors.grey.shade300,
                        title: 'Idle',
                        radius: 50,
                        titleStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600),
                      ),
                    ],
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceMetricRow("Runtime Today",
                        "${dailyAggregatesList.first.compressorRuntimePercentage?.toStringAsFixed(1) ?? '--'}%"),
                    _buildPerformanceMetricRow("Cycles",
                        "${dailyAggregatesList.first.compressorOnCount ?? '--'}"),
                    _buildPerformanceMetricRow("Door Opens",
                        "${dailyAggregatesList.first.doorOpenCount ?? '--'}"),
                    _buildPerformanceMetricRow("Ice Events",
                        "${dailyAggregatesList.first.iceEvents ?? '--'}"),
                    _buildPerformanceMetricRow("Total Readings",
                        "${dailyAggregatesList.first.totalReadings ?? '--'}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPerformanceMetricRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        Text(value,
            style:
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildLegendItem(String label, Color color) {
  return Row(
    children: [
      Container(width: 16, height: 3, color: color),
      SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 10)),
    ],
  );
}

Widget _buildAlertsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text("Recent Warnings",
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          Spacer(),
          Text("${alertsList.length} total warnings",
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          SizedBox(
            width: 12,
          )
        ],
      ),
      SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: alertsList.isEmpty
            ? Container(
                height: 120,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Constants.ctaColorLight, size: 48),
                      SizedBox(height: 8),
                      Text("No active alerts",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Constants.ctaColorLight,
                              fontWeight: FontWeight.w500)),
                      Text("All systems operating normally",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: alertsList.take(5).length, // Show max 5 alerts
                  itemBuilder: (context, index) {
                    final alert = alertsList[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 5)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Constants.ctaColorLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  alert.severity?.toUpperCase() ?? 'UNKNOWN',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.alertType ?? 'System Alert',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                timeAgo
                                    .format(DateTime.parse(alert.timestamp!)),
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            alert.message ?? 'No message available',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.grey.shade800),
                          ),
                          if (alert.details != null) ...[
                            SizedBox(height: 4),
                            Text(
                              alert.details!,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                          if (alert.recommendedAction != null) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      alert.recommendedAction!,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Constants.ctaColorLight),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    ],
  );
}

Color _getAlertSeverityColor(String? severity) {
  switch (severity?.toLowerCase()) {
    case 'critical':
      return Colors.red;
    case 'high':
      return Colors.grey;
    case 'medium':
      return Colors.grey;
    case 'low':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}

Widget _buildDeviceMapSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Device Locations",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
      SizedBox(height: 16),
      Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers.values.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _map_controller.complete(controller);
            },
          ),
        ),
      ),
    ],
  );
}

Widget _buildSidebarMenu() {
  // Simplified sidebar - you can expand this based on your existing sidebar items
  return Container();
}

Color _getStatusColor2(bool is_online) {
  switch (is_online) {
    case true:
      return Colors.green;
    case false:
      return Colors.grey;
  }
}

// Helper method to get status color
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Constants.ctaColorLight;
    case 'inactive':
      return Colors.grey;
    case 'faulty':
      return Colors.red;
    case 'maintenance':
      return Constants.ctaColorLight;
    case 'detached':
      return Colors.red.shade300;
    case 'new':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

class ArticDashboardTab extends StatefulWidget {
  const ArticDashboardTab({super.key});

  @override
  State<ArticDashboardTab> createState() => _ArticDashboardTabState();
}

class _ArticDashboardTabState extends State<ArticDashboardTab>
    with TickerProviderStateMixin {
  bool isLoading = true;
  bool isInitialLoad = true;

  // Device Selection
  String? selectedDeviceId;
  List<DeviceModel3> availableDevices = [];
  List<DeviceModel3> totalDetached = [];
  List<DeviceModel3> totalActive = [];
  List<DeviceModel3> totalInactive = [];
  List<DeviceModel3> totalNew = [];
  List<DeviceModel3> totalFaulty = [];
  List<DeviceModel3> totalDevice = [];

  // Tab Controller for metrics
  late TabController _metricsTabController;
  late TabController _chartTabController;

  // Auto-refresh timer
  Timer? _refreshTimer;
  DateTime? lastRefreshTime;

  // Performance metrics
  PerformanceMetrics? currentPerformanceMetrics;
  List<TemperatureRange> temperatureRanges = [];
  PressureMetrics? pressureMetrics;
  CompressorMetrics? compressorMetrics;

  List<TopNavbar> navBarList = [
    TopNavbar(1, "home", "HOME"),
    TopNavbar(3, "about_us", "About Us"),
    TopNavbar(4, "contact", "Contact"),
    TopNavbar(5, "services", "Services"),
    TopNavbar(6, "resources", "Resources")
  ];

  List<SideBarItems> sideBarList = [
    SideBarItems(1, "dashboard", "Dashboard", Iconsax.home),
    SideBarItems(
        2, "activity_tracking", "Activity Tracking", FontAwesomeIcons.list),
    SideBarItems(
        3, "geo_fencing", "Geo Fencing", FontAwesomeIcons.locationCrosshairs),
    SideBarItems(5, "device_management", "Device Management",
        FontAwesomeIcons.cameraRetro),
    SideBarItems(8, "notification", "Notification", FontAwesomeIcons.bell),
    SideBarItems(9, "settings", "Settings", CupertinoIcons.gear),
    SideBarItems(10, "help", "Help", FontAwesomeIcons.question),
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

  @override
  void initState() {
    super.initState();
    print('Dashboard Home initState called');
    _metricsTabController = TabController(length: 4, vsync: this);
    _chartTabController = TabController(length: 3, vsync: this);
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
    _metricsTabController.dispose();
    _chartTabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    print('Starting auto-refresh timer for Dashboard Home...');
    // Cancel any existing timer first
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('Auto-refresh triggered for Dashboard Home at ${DateTime.now()}');
      if (mounted && context.mounted) {
        print('Widget is mounted, refreshing dashboard home data...');
        _loadAllData(
            showLoading: false); // Background refresh without loading indicator
      } else {
        print('Widget not mounted, cancelling timer');
        timer.cancel();
      }
    });
    print('Auto-refresh timer started successfully for Dashboard Home');
  }

  // [Include all the existing API methods here - fetchLatestDeviceData, fetchDashboardData, etc.]

  void _processDashboardData() {
    // Build all metrics using the fetched data
    _buildPerformanceMetrics();
    _buildDesktopDoorMetrics();
    _buildTemperatureRanges();
    _buildPressureMetrics();
    _buildCompressorMetrics();
    _buildEnhancedSummaryCards();

    // Process alerts
    //_processActiveAlerts();
  }

  void _buildPerformanceMetrics() {
    // Check if we have any data at all
    if (latestDeviceDataList.isEmpty) {
      currentPerformanceMetrics = PerformanceMetrics(
        performanceScore: 0,
        systemStatus: 'No Data Available',
        efficiencyRatio: 0.0,
        uptimePercentage: 0.0,
        totalAlerts: 0,
        criticalAlerts: 0,
      );
      return;
    }

    final latestData = latestDeviceDataList.first;
    final dailyData =
        dailyAggregatesList.isNotEmpty ? dailyAggregatesList.first : null;

    currentPerformanceMetrics = PerformanceMetrics(
      performanceScore: latestData.performanceScore ?? 0,
      systemStatus: latestData.systemStatus ?? 'Unknown',
      efficiencyRatio: latestData.efficiencyRatio ?? 0.0,
      uptimePercentage: dailyData?.compressorRuntimePercentage ?? 0.0,
      totalAlerts: dashboardData?.alerts.length ?? 0,
      criticalAlerts: alertsList
          .where((alert) =>
              alert.severity == 'critical' || alert.severity == 'high')
          .length,
    );
  }

  void _buildTemperatureRanges() {
    // Check if we have required data
    if (latestDeviceDataList.isEmpty ||
        selectedDeviceId == null ||
        selectedDeviceId!.isEmpty) {
      temperatureRanges = [
        TemperatureRange(
          sensor: 'Air Temperature',
          current: null,
          min: null,
          max: null,
          avg: null,
          status: 'No Data',
        ),
        TemperatureRange(
          sensor: 'Coil Temperature',
          current: null,
          min: null,
          max: null,
          avg: null,
          status: 'No Data',
        ),
        TemperatureRange(
          sensor: 'Drain Temperature',
          current: null,
          min: null,
          max: null,
          avg: null,
          status: 'No Data',
        ),
      ];
      return;
    }

    final dailyData =
        dailyAggregatesList.isNotEmpty ? dailyAggregatesList.first : null;
    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;

    if (selectedDevice == null) {
      temperatureRanges = [
        TemperatureRange(
          sensor: 'Air Temperature',
          current: null,
          min: null,
          max: null,
          avg: null,
          status: 'Device Not Found',
        ),
        TemperatureRange(
          sensor: 'Coil Temperature',
          current: null,
          min: null,
          max: null,
          avg: null,
          status: 'Device Not Found',
        ),
        TemperatureRange(
          sensor: 'Drain Temperature',
          current: null,
          min: null,
          max: null,
          avg: null,
          status: 'Device Not Found',
        ),
      ];
      return;
    }

    temperatureRanges = [
      TemperatureRange(
        sensor: 'Air Temperature',
        current: selectedDevice.temperatureAir,
        min: dailyData?.minTempAir,
        max: dailyData?.maxTempAir,
        avg: dailyData?.avgTempAir,
        status: _getTemperatureStatus(selectedDevice.temperatureAir, -25, 5),
        minTimestamp: dailyData?.minTempAirTimestamp,
        maxTimestamp: dailyData?.maxTempAirTimestamp,
      ),
      TemperatureRange(
        sensor: 'Coil Temperature',
        current: selectedDevice.temperatureCoil,
        min: dailyData?.minTempCoil,
        max: dailyData?.maxTempCoil,
        avg: dailyData?.avgTempCoil,
        status: _getTemperatureStatus(selectedDevice.temperatureCoil, -30, 10),
        minTimestamp: dailyData?.minTempCoilTimestamp,
        maxTimestamp: dailyData?.maxTempCoilTimestamp,
      ),
      TemperatureRange(
        sensor: 'Drain Temperature',
        current: selectedDevice.temperatureDrain,
        min: dailyData?.minTempDrain,
        max: dailyData?.maxTempDrain,
        avg: dailyData?.avgTempDrain,
        status: _getTemperatureStatus(selectedDevice.temperatureDrain, -20, 15),
        minTimestamp: dailyData?.minTempDrainTimestamp,
        maxTimestamp: dailyData?.maxTempDrainTimestamp,
      ),
    ];
  }

  void _buildPressureMetrics() {
    // Check if we have required data
    if (latestDeviceDataList.isEmpty ||
        selectedDeviceId == null ||
        selectedDeviceId!.isEmpty) {
      pressureMetrics = PressureMetrics(
        lowSideCurrent: null,
        lowSideMin: null,
        lowSideMax: null,
        lowSideAvg: null,
        highSideCurrent: null,
        highSideMin: null,
        highSideMax: null,
        highSideAvg: null,
        status: 'No Data Available',
      );
      return;
    }

    // Find the daily data for the selected device
    final dailyData = dailyAggregatesList
        .where((data) => data.deviceId == selectedDeviceId)
        .firstOrNull;

    // Find the latest data for the selected device
    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;

    if (selectedDevice == null) {
      pressureMetrics = PressureMetrics(
        lowSideCurrent: null,
        lowSideMin: null,
        lowSideMax: null,
        lowSideAvg: null,
        highSideCurrent: null,
        highSideMin: null,
        highSideMax: null,
        highSideAvg: null,
        status: 'Device Not Found',
      );
      return;
    }

    // --- FIX STARTS HERE: This is the missing part ---
    // Populate the pressureMetrics object with the fetched data
    pressureMetrics = PressureMetrics(
      // Low Side Pressure Data
      lowSideCurrent: selectedDevice.compressorLow,
      lowSideMin: dailyData?.minLowSidePressure,
      lowSideMax: dailyData?.maxLowSidePressure,
      lowSideAvg: dailyData?.avgLowSidePressure,
      lowSideMinTimestamp: dailyData?.minLowSidePressureTimestamp,
      lowSideMaxTimestamp: dailyData?.maxLowSidePressureTimestamp,

      // High Side Pressure Data
      highSideCurrent: selectedDevice.compressorHigh,
      highSideMin: dailyData?.minHighSidePressure,
      highSideMax: dailyData?.maxHighSidePressure,
      highSideAvg: dailyData?.avgHighSidePressure,
      highSideMinTimestamp: dailyData?.minHighSidePressureTimestamp,
      highSideMaxTimestamp: dailyData?.maxHighSidePressureTimestamp,

      // Overall Status
      status: _getPressureStatus(
          selectedDevice.compressorLow, selectedDevice.compressorHigh),
    );
    // --- FIX ENDS HERE ---
  }

  void _buildCompressorMetrics() {
    // Check if we have required data
    if (latestDeviceDataList.isEmpty ||
        selectedDeviceId == null ||
        selectedDeviceId!.isEmpty) {
      compressorMetrics = CompressorMetrics(
        avgAmp: null,
        maxAmp: null,
        ph1Amp: null,
        ph2Amp: null,
        ph3Amp: null,
        imbalance: null,
        runtimePercentage: null,
        onCount: null,
        status: 'No Data Available',
      );
      return;
    }

    final dailyData =
        dailyAggregatesList.isNotEmpty ? dailyAggregatesList.first : null;

    // Find the selected device safely
    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;

    if (selectedDevice == null) {
      compressorMetrics = CompressorMetrics(
        avgAmp: null,
        maxAmp: null,
        ph1Amp: null,
        ph2Amp: null,
        ph3Amp: null,
        imbalance: null,
        runtimePercentage: null,
        onCount: null,
        status: 'Device Not Found',
      );
      return;
    }

    compressorMetrics = CompressorMetrics(
      avgAmp: selectedDevice.avgCompAmp ?? dailyData?.avgCompAmp,
      maxAmp: selectedDevice.maxCompAmp ?? dailyData?.maxCompAmp,
      ph1Amp: selectedDevice.compAmpPh1,
      ph2Amp: selectedDevice.compAmpPh2,
      ph3Amp: selectedDevice.compAmpPh3,
      imbalance: selectedDevice.ampImbalance,
      runtimePercentage: dailyData?.compressorRuntimePercentage,
      onCount: dailyData?.compressorOnCount,
      status: _getCompressorStatus(
          selectedDevice.avgCompAmp, selectedDevice.ampImbalance),
    );
  }

  void _buildEnhancedSummaryCards() {
    // Check if we have required data
    if (latestDeviceDataList.isEmpty ||
        selectedDeviceId == null ||
        selectedDeviceId!.isEmpty) {
      enhancedSummaryCards = [
        EnhancedSummaryCard(
          title: 'Performance Score',
          value: '--',
          unit: '/100',
          subtitle: 'No Data Available',
          trend: 'Unknown',
          trendDirection: 'stable',
          cardColor: Colors.grey[200]!,
          accentColor: Colors.grey,
          icon: FontAwesomeIcons.chartLine,
          alerts: null,
        ),
        EnhancedSummaryCard(
          title: 'Air Temperature',
          value: '--',
          unit: '°C',
          subtitle: 'No data available',
          trend: 'Unknown',
          trendDirection: 'stable',
          cardColor: Colors.grey[200]!,
          accentColor: Colors.grey,
          icon: FontAwesomeIcons.snowflake,
        ),
        // Add more empty cards as needed...
      ];
      return;
    }

    // Find the selected device safely
    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;

    if (selectedDevice == null) {
      enhancedSummaryCards = [
        EnhancedSummaryCard(
          title: 'Device Not Found',
          value: '--',
          unit: '',
          subtitle: 'Selected device not available',
          trend: 'Unknown',
          trendDirection: 'stable',
          cardColor: Colors.red[100]!,
          accentColor: Colors.red,
          icon: FontAwesomeIcons.exclamationTriangle,
          alerts: null,
        ),
      ];
      return;
    }

    final dailyData =
        dailyAggregatesList.isNotEmpty ? dailyAggregatesList.first : null;

    enhancedSummaryCards = [
      EnhancedSummaryCard(
        title: 'Door Analysis',
        value: selectedDevice.door == false ? "Door Closed" : "Door Opened",
        unit: "",
        subtitle: selectedDevice.door == false
            ? "The door is currently closed"
            : "The door is currently opened",
        trend: '',
        trendDirection: '',
        cardColor:
            _getPerformanceCardColor(selectedDevice.performanceScore ?? 0),
        accentColor: Constants.ctaColorLight,
        icon: FontAwesomeIcons.chartLine,
        alerts: [],
      ),
      EnhancedSummaryCard(
        title: 'Air Temperature',
        value: '${selectedDevice.temperatureAir?.toStringAsFixed(1) ?? '--'}',
        unit: '°C',
        subtitle:
            'Range: ${dailyData?.minTempAir?.toStringAsFixed(1) ?? '--'} to ${dailyData?.maxTempAir?.toStringAsFixed(1) ?? '--'}°C',
        trend:
            _getTempTrend(selectedDevice.temperatureAir, dailyData?.avgTempAir),
        trendDirection: _getTempTrendDirection(
            selectedDevice.temperatureAir, dailyData?.avgTempAir),
        cardColor: const Color(0XFFF4F4F4),
        accentColor: _getTemperatureColor(selectedDevice.temperatureAir),
        icon: FontAwesomeIcons.snowflake,
      ),
      EnhancedSummaryCard(
        title: 'System Efficiency',
        value: '${selectedDevice.efficiencyRatio?.toStringAsFixed(2) ?? '--'}',
        unit: 'kW/°C',
        subtitle: 'Energy consumption ratio',
        trend: 'Optimized',
        trendDirection: 'stable',
        cardColor: const Color(0XccF4F4F4),
        accentColor: Constants.ctaColorLight,
        icon: FontAwesomeIcons.leaf,
      ),
      EnhancedSummaryCard(
        title: 'Runtime Today',
        value:
            '${dailyData?.compressorRuntimePercentage?.toStringAsFixed(1) ?? '--'}',
        unit: '%',
        subtitle: '${dailyData?.compressorOnCount ?? 0} cycles',
        trend: 'Normal range',
        trendDirection: 'stable',
        cardColor: const Color(0Xcc3C514933),
        accentColor: Constants.ctaColorLight,
        icon: FontAwesomeIcons.clock,
      ),
      EnhancedSummaryCard(
        title: 'Pressure Status',
        value: '${selectedDevice.compressorHigh?.toStringAsFixed(0) ?? '--'}',
        unit: 'psi',
        subtitle:
            'Low: ${selectedDevice.compressorLow?.toStringAsFixed(0) ?? '--'} psi',
        trend: pressureMetrics?.status ?? 'Unknown',
        trendDirection:
            _getPressureTrendDirection(selectedDevice.compressorHigh),
        cardColor: const Color(0XccF4F4F4),
        accentColor: _getPressureColor(selectedDevice.compressorHigh),
        icon: FontAwesomeIcons.gaugeHigh,
      ),
    ];
  }

// Detailed Temperature Metrics with timestamps
  Widget _buildDetailedTemperatureMetrics() {
    if (temperatureRanges == null || temperatureRanges!.isEmpty) {
      return _buildEmptyDetailedTemperatureView();
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'Detailed Temperature Analysis',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          (temperatureRanges == null || temperatureRanges!.isEmpty)
              ? _buildEmptyAnalyticsView()
              : Container(
                  margin: EdgeInsets.all(0),
                  padding: EdgeInsets.all(16),
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
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temperature Analytics',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            // Temperature spread analysis
                            Expanded(child: _buildTemperatureSpreadCard()),
                            SizedBox(width: 12),

                            // Temperature stability indicator
                            Expanded(child: _buildTemperatureStabilityCard()),
                            SizedBox(width: 12),

                            // Temperature alerts summary
                            Expanded(child: _buildTemperatureAlertsCard()),
                          ],
                        ),
                      ]),
                ),
          SizedBox(height: 16),
          Row(
            children: [
              if (temperatureRanges.length > 0)
                Expanded(
                    child: _buildDetailedTemperatureCard(temperatureRanges[0])),
              SizedBox(width: 16),
              if (temperatureRanges.length > 1)
                Expanded(
                    child: _buildDetailedTemperatureCard(temperatureRanges[1])),
              SizedBox(width: 16),
              if (temperatureRanges.length > 2)
                Expanded(
                    child: _buildDetailedTemperatureCard(temperatureRanges[2]))
            ],
          )
          // ...temperatureRanges!.map((range) => _buildDetailedTemperatureCard(range)),
        ],
      ),
    );
  }

// Detailed Pressure Metrics with timestamps
  Widget _buildDetailedPressureMetrics() {
    if (pressureMetrics == null) {
      return _buildEmptyDetailedPressureView();
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'Detailed Pressure Analysis',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          (pressureMetrics == null)
              ? _buildEmptyAnalyticsView()
              : Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pressure Analytics',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          // Pressure ratio analysis
                          Expanded(child: _buildPressureRatioCard()),
                          SizedBox(width: 12),

                          // Pressure stability
                          Expanded(child: _buildPressureStabilityCard()),
                        ],
                      ),
                    ],
                  ),
                ),
          SizedBox(height: 16),
          Row(
            children: [
              // Low Side Pressure
              Expanded(
                child: _buildDetailedPressureCard(
                  'Low Side Pressure',
                  pressureMetrics!.lowSideCurrent,
                  pressureMetrics!.lowSideMin,
                  pressureMetrics!.lowSideMax,
                  pressureMetrics!.lowSideMinTimestamp, // Add to your model
                  pressureMetrics!.lowSideMaxTimestamp, // Add to your model
                  Constants.ctaColorLight,
                  Icons.compress,
                ),
              ),

              SizedBox(width: 16),

              // High Side Pressure
              Expanded(
                child: _buildDetailedPressureCard(
                  'High Side Pressure',
                  pressureMetrics!.highSideCurrent,
                  pressureMetrics!.highSideMin,
                  pressureMetrics!.highSideMax,
                  pressureMetrics!.highSideMinTimestamp, // Add to your model
                  pressureMetrics!.highSideMaxTimestamp, // Add to your model
                  Colors.red,
                  Icons.unfold_more,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // System Status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPressureStatusColor(pressureMetrics!.status)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPressureStatusColor(pressureMetrics!.status)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getPressureStatusIcon(pressureMetrics!.status),
                  color: _getPressureStatusColor(pressureMetrics!.status),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'System Status: ${pressureMetrics!.status?.toUpperCase() ?? 'UNKNOWN'}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getPressureStatusColor(pressureMetrics!.status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCompressorMetrics() {
    if (compressorMetrics == null) {
      return _buildEmptyDetailedCompressorView();
    }

    // Get real-time compressor status
    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Compressor Analysis',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          (compressorMetrics == null)
              ? _buildEmptyAnalyticsView()
              : Container(
                  // margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
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
                          // Efficiency indicator
                          Expanded(child: _buildCompressorEfficiencyCard()),
                          SizedBox(width: 12),

                          // Load analysis
                          Expanded(child: _buildCompressorLoadCard()),
                          SizedBox(width: 12),

                          // Health status
                          Expanded(child: _buildCompressorHealthCard()),
                        ],
                      ),
                    ],
                  ),
                ),

          // Real-time Status Card
          _buildCompressorStatusCard(selectedDevice),

          SizedBox(height: 16),
          Container(child: _buildLastOffCard(selectedDevice)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPhaseAmperageCard(selectedDevice)),
              SizedBox(width: 12),
              // Runtime & Cycle Details
              Expanded(child: _buildRuntimeDetailsCard()),
              SizedBox(width: 12),

              // Last Off Information
            ],
          ),
          // Phase Amperage Details

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailedTemperatureCard(TemperatureRange range) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.thermostat,
                color: _getTemperatureStatusColor(range.status),
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  range.sensor ?? 'Unknown Sensor',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTemperatureStatusColor(range.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  range.status?.toUpperCase() ?? 'UNKNOWN',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Current Temperature (Large display)
          Center(
            child: Column(
              children: [
                Text(
                  'Current',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${range.current?.toStringAsFixed(1) ?? '--'}°C',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getTemperatureStatusColor(range.status),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Min/Max with timestamps
          Row(
            children: [
              Expanded(
                child: _buildTemperatureExtremeCard(
                  'Lowest',
                  range.min,
                  range.minTimestamp,
                  Constants.ctaColorLight,
                  Icons.trending_down,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTemperatureExtremeCard(
                  'Highest',
                  range.max,
                  range
                      .maxTimestamp, // Add this field to your TemperatureRange model
                  Constants.ctaColorLight,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Average
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined,
                    size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'Average: ${range.avg?.toStringAsFixed(1) ?? '--'}°C',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureExtremeCard(String label, double? value,
      DateTime? timestamp, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
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
          SizedBox(height: 8),
          Text(
            '${value?.toStringAsFixed(1) ?? '--'}°C',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            timestamp != null ? _formatDateTime(timestamp) : 'No data',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedPressureCard(
      String title,
      double? current,
      double? min,
      double? max,
      DateTime? minTimestamp,
      DateTime? maxTimestamp,
      Color color,
      IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Current Pressure (Large display)
          Center(
            child: Column(
              children: [
                Text(
                  'Current',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${current?.toStringAsFixed(1) ?? '--'} psi',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Min/Max with timestamps
          Row(
            children: [
              Expanded(
                child: _buildPressureExtremeCard(
                  'Lowest',
                  min,
                  minTimestamp,
                  Constants.ctaColorLight,
                  Icons.trending_down,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPressureExtremeCard(
                  'Highest',
                  max,
                  maxTimestamp,
                  Colors.red,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureExtremeCard(String label, double? value,
      DateTime? timestamp, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
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
          SizedBox(height: 8),
          Text(
            '${value?.toStringAsFixed(1) ?? '--'} psi',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            timestamp != null ? _formatDateTime(timestamp) : 'No data',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompressorStatusCard(LatestDeviceData? device) {
    bool isCompressorOn = device?.compressorStatus == 'ON' ||
        (device?.avgCompAmp ?? 0) > 1.0; // Threshold for "on"

    return Container(
      padding: EdgeInsets.all(Constants.spacingMd),
      decoration: BoxDecoration(
        color: isCompressorOn
            ? Constants.compressorOnColor.withOpacity(Constants.opacityLight)
            : Constants.compressorOffColor.withOpacity(Constants.opacityLight),
        borderRadius: BorderRadius.circular(Constants.spacingSm),
        border: Border.all(
          color: isCompressorOn
              ? Constants.compressorOnColor
              : Constants.compressorOffColor,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(Constants.spacingSm),
                decoration: BoxDecoration(
                  color: isCompressorOn
                      ? Constants.compressorOnColor
                      : Constants.compressorOffColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompressorOn ? Icons.power : Icons.power_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: Constants.spacingMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compressor Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Constants.ctaTextColor,
                    ),
                  ),
                  Text(
                    isCompressorOn ? 'RUNNING' : 'STOPPED',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompressorOn
                          ? Constants.compressorOnColor
                          : Constants.compressorOffColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isCompressorOn) ...[
            SizedBox(height: Constants.spacingSm),
            Text(
              'Current Draw: ${device?.avgCompAmp?.toStringAsFixed(1) ?? '--'} A',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Constants.compressorOnColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseAmperageCard(LatestDeviceData? device) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phase Amperage (Live)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPhaseCard(
                  'Phase 1',
                  device?.compAmpPh1,
                  Colors.red,
                  Icons.electrical_services,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPhaseCard(
                  'Phase 2',
                  device?.compAmpPh2,
                  Constants.ctaColorLight,
                  Icons.electrical_services,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPhaseCard(
                  'Phase 3',
                  device?.compAmpPh3,
                  Constants.ctaColorLight,
                  Icons.electrical_services,
                ),
              ),
            ],
          ),
          if (device?.ampImbalance != null && device!.ampImbalance! > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: device.ampImbalance! > 5
                    ? Constants.ctaColorLight.withOpacity(0.09)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: device.ampImbalance! > 5
                      ? Constants.ctaColorLight.withOpacity(0.15)
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    device.ampImbalance! > 5
                        ? Icons.warning
                        : Icons.check_circle,
                    color: device.ampImbalance! > 5
                        ? Constants.ctaColorLight
                        : Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Phase Imbalance: ${device.ampImbalance!.toStringAsFixed(1)} A',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: device.ampImbalance! > 5
                          ? Constants.ctaColorLight
                          : Colors.green.shade700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    device.ampImbalance! > 5 ? 'HIGH' : 'NORMAL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: device.ampImbalance! > 5
                          ? Constants.ctaColorLight
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseCard(
      String phase, double? amperage, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            phase,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${amperage?.toStringAsFixed(1) ?? '--'} A',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

// Enhanced Door Analysis Widget
  Widget _buildDoorAnalysisCard() {
    if (latestDeviceDataList.isEmpty ||
        selectedDeviceId == null ||
        selectedDeviceId!.isEmpty) {
      return _buildEmptyDoorAnalysisView();
    }

    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;

    final dailyData = dailyAggregatesList
        .where((data) => data.deviceId == selectedDeviceId)
        .firstOrNull;

    if (selectedDevice == null) {
      return _buildEmptyDoorAnalysisView();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getDoorStatusColor(
                  selectedDevice.door, dailyData?.doorStabilityStatus)
              .withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with current status
          _buildDoorAnalysisHeader(selectedDevice, dailyData),

          SizedBox(height: 20),

          // Metrics grid - responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Use row layout for desktop (width > 600), column for mobile
              bool isDesktop = constraints.maxWidth > 600;

              if (isDesktop) {
                return _buildDesktopDoorMetrics();
              } else {
                return _buildMobileDoorMetrics(selectedDevice, dailyData);
              }
            },
          ),

          SizedBox(height: 16),

          // Status indicator bar
          _buildDoorStatusIndicator(dailyData?.doorStabilityStatus),
        ],
      ),
    );
  }

  Widget _buildDoorAnalysisHeader(
      LatestDeviceData selectedDevice, DailyAggregate? dailyData) {
    final isOpen = selectedDevice.door == true;
    final statusColor = _getDoorStatusColor(
        selectedDevice.door, dailyData?.doorStabilityStatus);

    return Row(
      children: [
        // Door icon with status
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isOpen ? FontAwesomeIcons.doorOpen : FontAwesomeIcons.doorClosed,
            color: statusColor,
            size: 24,
          ),
        ),

        SizedBox(width: 16),

        // Title and current status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Door Analysis',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    isOpen ? 'Currently Open' : 'Currently Closed',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quick stability status badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStabilityStatusColor(dailyData?.doorStabilityStatus),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStabilityStatusText(dailyData?.doorStabilityStatus),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopDoorMetrics() {
    final dailyData =
        dailyAggregatesList.isNotEmpty ? dailyAggregatesList.first : null;
    final selectedDevice = latestDeviceDataList
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;
    return Row(
      children: [
        // Open count
        Expanded(
          child: _buildCompactMetricCard(
            'Door Opens',
            '${dailyData?.doorOpenCount ?? 0}',
            'times today',
            FontAwesomeIcons.doorOpen,
            Constants.ctaColorLight,
          ),
        ),

        SizedBox(width: 12),

        // Closed count
        Expanded(
          child: _buildCompactMetricCard(
            'Door Closes',
            '${dailyData?.doorClosedCount ?? 0}',
            'times today',
            FontAwesomeIcons.doorClosed,
            Colors.blueGrey,
          ),
        ),

        SizedBox(width: 12),

        // Total open time
        Expanded(
          child: _buildCompactMetricCard(
            'Open Duration',
            _formatDoorOpenTime(dailyData?.totalDoorOpenMinutes),
            _getDoorTimeUnit(dailyData?.totalDoorOpenMinutes),
            FontAwesomeIcons.clock,
            Colors.orange,
          ),
        ),

        SizedBox(width: 12),

        // Average per opening
        Expanded(
          child: _buildCompactMetricCard(
            'Avg per Open',
            _formatAverageOpenTime(
                dailyData?.totalDoorOpenMinutes, dailyData?.doorOpenCount),
            'minutes',
            FontAwesomeIcons.chartLine,
            Colors.purple,
          ),
        ),

        SizedBox(width: 12),

        // Stability score
        Expanded(
          child: _buildCompactMetricCard(
            'Stability',
            _getStabilityScore(dailyData?.doorStabilityStatus),
            '/100',
            FontAwesomeIcons.shield,
            _getStabilityStatusColor(dailyData?.doorStabilityStatus),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDoorMetrics(
      LatestDeviceData selectedDevice, DailyAggregate? dailyData) {
    return Column(
      children: [
        // First row - Door events
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                'Door Opens',
                '${dailyData?.doorOpenCount ?? 0}',
                'times today',
                FontAwesomeIcons.doorOpen,
                Constants.ctaColorLight,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetricCard(
                'Door Closes',
                '${dailyData?.doorClosedCount ?? 0}',
                'times today',
                FontAwesomeIcons.doorClosed,
                Colors.blueGrey,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Second row - Duration metrics
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                'Open Duration',
                _formatDoorOpenTime(dailyData?.totalDoorOpenMinutes),
                _getDoorTimeUnit(dailyData?.totalDoorOpenMinutes),
                FontAwesomeIcons.clock,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetricCard(
                'Avg/Opening',
                _formatAverageOpenTime(
                    dailyData?.totalDoorOpenMinutes, dailyData?.doorOpenCount),
                'minutes',
                FontAwesomeIcons.chartLine,
                Colors.purple,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Third row - Stability
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                'Stability Score',
                _getStabilityScore(dailyData?.doorStabilityStatus),
                '/100',
                FontAwesomeIcons.shield,
                _getStabilityStatusColor(dailyData?.doorStabilityStatus),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactMetricCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Constants.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(Constants.opacityLight),
        borderRadius: BorderRadius.circular(Constants.spacingSm),
        border: Border.all(
          color: color.withOpacity(Constants.opacityMedium),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: Constants.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Constants.ctaTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Constants.spacingSm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Constants.ctaTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorStatusIndicator(String? stabilityStatus) {
    final status = stabilityStatus ?? 'Unknown';
    final color = _getStabilityStatusColor(status);
    final description = _getStabilityDescription(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getStabilityIcon(status), color: color, size: 20),
              SizedBox(width: 8),
              Text(
                'Status: ${status.toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDoorAnalysisView() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.doorClosed,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Door Analysis Unavailable',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No device data available for door analysis',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Helper methods
  Color _getDoorStatusColor(bool? isOpen, String? stabilityStatus) {
    if (stabilityStatus?.contains('Alert') == true) return Colors.red;
    if (stabilityStatus?.contains('High Traffic') == true)
      return Constants.ctaColorLight;
    return isOpen == true ? Constants.ctaColorLight : Colors.green;
  }

  Color _getStabilityStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('Alert')) return Colors.red;
    if (status.contains('High Traffic')) return Constants.ctaColorLight;
    if (status.contains('Stable')) return Colors.green;
    return Colors.grey;
  }

  IconData _getStabilityIcon(String? status) {
    if (status == null) return FontAwesomeIcons.question;
    if (status.contains('Alert')) return FontAwesomeIcons.exclamationTriangle;
    if (status.contains('High Traffic')) return FontAwesomeIcons.usersCog;
    if (status.contains('Stable')) return FontAwesomeIcons.checkCircle;
    return FontAwesomeIcons.question;
  }

  String _getStabilityStatusText(String? status) {
    if (status == null) return 'Unknown';
    if (status.contains('Alert')) return 'Alert';
    if (status.contains('High Traffic')) return 'High Traffic';
    if (status.contains('Stable')) return 'Stable';
    return 'Unknown';
  }

  String _getStabilityScore(String? status) {
    if (status == null) return '--';
    if (status.contains('Alert')) return '25';
    if (status.contains('High Traffic')) return '65';
    if (status.contains('Stable')) return '95';
    return '50';
  }

  String _getStabilityDescription(String? status) {
    if (status == null) return 'Door stability status unknown';
    if (status.contains('Alert: Left Open')) {
      return 'Door has been left open for extended periods';
    }
    if (status.contains('High Traffic')) {
      return 'Frequent door openings detected';
    }
    if (status.contains('Stable')) {
      return 'Normal door usage patterns observed';
    }
    return 'Door stability status unknown';
  }

  String _formatDoorOpenTime(double? minutes) {
    if (minutes == null || minutes == 0) return '0';

    if (minutes >= 60) {
      final hours = minutes / 60;
      return hours >= 10 ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);
    }

    return minutes >= 10
        ? minutes.toStringAsFixed(0)
        : minutes.toStringAsFixed(1);
  }

  String _getDoorTimeUnit(double? minutes) {
    if (minutes == null || minutes == 0) return 'minutes';
    return minutes >= 60 ? 'hours' : 'minutes';
  }

  String _formatAverageOpenTime(double? totalMinutes, int? openCount) {
    if (totalMinutes == null || openCount == null || openCount == 0) {
      return '0';
    }

    final avgMinutes = totalMinutes / openCount;
    return avgMinutes >= 10
        ? avgMinutes.toStringAsFixed(0)
        : avgMinutes.toStringAsFixed(1);
  }

  Widget _buildRuntimeDetailsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Runtime Details (Today)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricDetailCard(
                  'Runtime %',
                  '${compressorMetrics!.runtimePercentage?.toStringAsFixed(1) ?? '--'}%',
                  Icons.timer,
                  Constants.ctaColorLight,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricDetailCard(
                  'Total Cycles',
                  '${compressorMetrics!.onCount ?? '--'}',
                  Icons.refresh,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastOffCard(LatestDeviceData? device) {
    print("ffgffg ${device?.deviceId.toString()} ${device?.lastOffTimestamp}");
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey.shade600, size: 20),
              SizedBox(width: 8),
              Text(
                device?.lastOffTimestamp != null
                    ? 'Last Compressor Stop : ' +
                        _formatDateTime(device!.lastOffTimestamp!)
                    : 'Last Compressor Stop',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              if (device?.lastOffTimestamp != null) ...[
                SizedBox(height: 8),
                Text(
                  'Duration since last stop: ${_getTimeSinceLastOff(device!.lastOffTimestamp!)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDetailCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

// Empty state views for detailed metrics
  Widget _buildEmptyDetailedTemperatureView() {
    return _buildEmptyDetailedView(
      'No Temperature History',
      'Historical temperature data is not available\nfor detailed analysis',
      Icons.thermostat_outlined,
      Constants.ctaColorLight,
    );
  }

  Widget _buildEmptyDetailedPressureView() {
    return _buildEmptyDetailedView(
      'No Pressure History',
      'Historical pressure data is not available\nfor detailed analysis',
      Icons.speed_outlined,
      Constants.ctaColorLight,
    );
  }

  Widget _buildEmptyDetailedCompressorView() {
    return _buildEmptyDetailedView(
      'No Compressor Data',
      'Compressor status and amperage data\nis not currently available',
      Icons.settings_outlined,
      Colors.purple,
    );
  }

  Widget _buildEmptyDetailedView(
      String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 48, color: color.withOpacity(0.7)),
          ),
          SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Helper methods
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago at${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${difference.inMinutes}m ago at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTimeSinceLastOff(DateTime lastOff) {
    final now = DateTime.now();
    final difference = now.difference(lastOff);

    if (difference.inDays > 0) {
      return '${difference.inDays} days, ${difference.inHours % 24} hours';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours, ${difference.inMinutes % 60} minutes';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }

  // Helper widgets for empty states
  Widget _buildEmptyEfficiencyView() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Device Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your device connection and try again',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Add refresh functionality
              _refreshData();
            },
            child: Text('Refresh Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceNotFoundView() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.device_unknown,
            size: 48,
            color: Constants.ctaColorLight,
          ),
          SizedBox(height: 16),
          Text(
            'Device Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Constants.ctaColorLight,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The selected device (ID: $selectedDeviceId) is not available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Add device selection functionality
              _selectDevice();
            },
            child: Text('Select Device'),
          ),
        ],
      ),
    );
  }

  // Helper method to refresh data
  void _refreshData() {
    // Implement your data refresh logic here
    setState(() {
      // Trigger rebuild
    });
  }

  // Helper method to select device
  void _selectDevice() {
    // Implement device selection logic here
  }

  // Helper methods for status determination
  String _getTemperatureStatus(double? temp, double min, double max) {
    if (temp == null) return 'unknown';
    if (temp < min - 5 || temp > max + 5) return 'critical';
    if (temp < min || temp > max) return 'warning';
    return 'normal';
  }

  String _getPressureStatus(double? lowPressure, double? highPressure) {
    if (lowPressure == null || highPressure == null) return 'unknown';
    if (lowPressure < 10 || highPressure > 400) return 'critical';
    if (lowPressure < 15 || highPressure > 350) return 'warning';
    return 'normal';
  }

  String _getCompressorStatus(double? avgAmp, double? imbalance) {
    if (avgAmp == null) return 'unknown';
    if (avgAmp > 50 || (imbalance != null && imbalance > 10)) return 'warning';
    if (avgAmp > 40 || (imbalance != null && imbalance > 5)) return 'caution';
    return 'normal';
  }

  Color _getPerformanceCardColor(int score) {
    if (score >= 80) return Constants.ctaColorLight.withOpacity(0.05);
    if (score >= 60) return Constants.ctaColorLight.withOpacity(0.09);
    return Colors.red.shade50;
  }

  Color _getTemperatureColor(double? temp) {
    if (temp == null) return Colors.grey;
    if (temp < -25 || temp > 5) return Colors.red;
    if (temp < -20 || temp > 0) return Constants.ctaColorLight;
    return Constants.ctaColorLight;
  }

  Color _getPressureColor(double? pressure) {
    if (pressure == null) return Colors.grey;
    if (pressure > 400) return Colors.red;
    if (pressure > 350) return Constants.ctaColorLight;
    return Constants.ctaColorLight;
  }

  String _getTempTrend(double? current, double? average) {
    if (current == null || average == null) return '--';
    double diff = current - average;
    if (diff.abs() < 1) return 'Stable';
    return '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}°C vs avg';
  }

  String _getTempTrendDirection(double? current, double? average) {
    if (current == null || average == null) return 'stable';
    double diff = current - average;
    if (diff > 1) return 'up';
    if (diff < -1) return 'down';
    return 'stable';
  }

  String _getPressureTrendDirection(double? pressure) {
    if (pressure == null) return 'stable';
    if (pressure > 400) return 'up';
    if (pressure < 200) return 'down';
    return 'stable';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isLoading
          ? Container(
              height: MediaQuery.of(context).size.height / 2,
              child: Center(
                  child: CircularProgressIndicator(
                color: Constants.ctaColorLight,
                strokeWidth: 1.5,
              )),
            )
          : Row(
              children: [
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(),
                        SizedBox(height: 24),
                        _buildPerformanceOverview(),
                        SizedBox(height: 24),
                        _buildEnhancedSummaryCards2(),
                        SizedBox(height: 24),
                        _buildMetricsTabView(),
                        SizedBox(height: 24),
                        //_buildChartsTabView(),
                        SizedBox(height: 24),
                        _buildAlertsSection(),
                        SizedBox(height: 24),
                        _buildDeviceMapSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDeviceDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3)
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDeviceId,
          hint: Text("Select Device",
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          icon: Icon(Icons.keyboard_arrow_down, color: Constants.ctaColorLight),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child:
                  Text("All Devices", style: GoogleFonts.inter(fontSize: 12)),
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
                        color: _getStatusColor2(device.isOnline ?? false),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${device.name} - ${device.isOnline == true ? 'Online' : 'Offline'}",
                        style: GoogleFonts.inter(fontSize: 11),
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
            fetchDashboardData();
            _loadAllData();
          },
        ),
      ),
    );
  }

  // Include all the existing API methods here
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
      _processDashboardData();
    } catch (e) {
      print('Error refreshing data for selected device: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadAllData({bool showLoading = true}) async {
    print(
        '_loadAllData called for Dashboard Home with showLoading: $showLoading at ${DateTime.now()}');

    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      print('Starting data fetch operations for Dashboard Home...');
      await Future.wait([
        getDeviceByClient(Constants.myBusiness.businessUid),
        fetchLatestDeviceData(),
        fetchDashboardData(),
        fetchAlerts(),
      ]);
      _processDashboardData();

      print('Data fetch completed successfully for Dashboard Home');
      if (mounted) {
        setState(() {
          isLoading = false;
          isInitialLoad = false;
          lastRefreshTime = DateTime.now();
        });
        print('Dashboard Home state updated');
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

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Welcome ',
            style: GoogleFonts.inter(
                fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: Constants.myDisplayname,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' to ${Constants.business_name} Dashboard',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Divider(thickness: 0.5, color: Colors.grey.shade300),
        if (latestDeviceDataList.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Last Updated: ${DateFormat('EEE, dd MMM - HH:mm').format(DateTime.parse(latestDeviceDataList.first.time!).add(Duration(hours: 2)))}",
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  Widget _buildPerformanceOverview() {
    if (currentPerformanceMetrics == null) return Container();

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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("System Performance Overview",
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                Spacer(),
                Container(width: 300, child: _buildDeviceDropdown()),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    "Performance Score",
                    "${currentPerformanceMetrics!.performanceScore}/100",
                    _getPerformanceScoreColor(
                        currentPerformanceMetrics!.performanceScore ?? 0),
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    "System Status",
                    // --- MODIFICATION START ---
                    (currentPerformanceMetrics!.systemStatus
                                ?.replaceAll('_', ' ') ??
                            'Unknown')
                        .split(' ')
                        .map((word) {
                      if (word.isEmpty) return '';
                      return word[0].toUpperCase() + word.substring(1);
                    }).join(' '),
                    // --- MODIFICATION END ---
                    _getSystemStatusColor(
                        currentPerformanceMetrics!.systemStatus),
                    Icons.stadium_outlined,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    "Uptime Today",
                    dailyAggregatesList.isEmpty
                        ? "-"
                        : "${dailyAggregatesList.last.dataTransmissionPercentage?.toStringAsFixed(1) ?? '0.0'}%",
                    Constants.ctaColorLight,
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    "Active Alerts",
                    "${currentPerformanceMetrics!.totalAlerts}",
                    //   "${currentPerformanceMetrics!.totalAlerts}/${currentPerformanceMetrics!.totalAlerts}",
                    currentPerformanceMetrics!.criticalAlerts! > 0
                        ? Colors.red
                        : Constants.ctaColorLight,
                    Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Constants.ctaColorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Constants.ctaColorLight, size: 24),
          SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.ctaColorLight)),
          Text(title,
              style:
                  GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Color _getPerformanceScoreColor(int score) {
    if (score >= 80) return Constants.ctaColorLight;
    if (score >= 60) return Constants.ctaColorLight;
    return Colors.red;
  }

  Color _getSystemStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'running_normal':
      case 'idle_normal':
        return Constants.ctaColorLight;

      case 'high_pressure_warning':
      case 'low_pressure_warning':
        return Constants.ctaColorLight;
      case 'temperature_alert':
      case 'pressure_alert':
      case 'high_pressure_alert':
      case 'compressor_alert':
      case 'door_alert':
      case 'maintenance_required':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEnhancedSummaryCards2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Metrics",
            style:
                GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 16),
        Container(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: enhancedSummaryCards.length,
            itemBuilder: (context, index) {
              final card = enhancedSummaryCards[index];
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  width: 220,
                  margin: EdgeInsets.only(right: 16),
                  child: Container(
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
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: card.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(card.icon,
                                    color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.title,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    Row(
                                      children: [
                                        Text("${card.value}${card.unit}",
                                            style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        if (card.trendDirection != 'stable')
                                          Icon(
                                            card.trendDirection == 'up'
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            size: 16,
                                            color: card.trendDirection == 'up'
                                                ? Constants.ctaColorLight
                                                : Colors.red,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (card.subtitle != null)
                            Text(card.subtitle!,
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.grey.shade600)),
                          if (card.trend != null)
                            Text(card.trend!,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: card.accentColor,
                                    fontWeight: FontWeight.w500)),
                          if (card.alerts != null && card.alerts!.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Constants.ctaColorLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text("${card.alerts!.length} alert(s)",
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Constants.ctaColorLight)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsTabView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Detailed Metrics",
            style:
                GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5)
            ],
          ),
          child: Column(
            children: [
              // TabBar with corrected and logical order
              TabBar(
                isScrollable: false,
                enableFeedback: false,
                physics: const NeverScrollableScrollPhysics(),
                controller: _metricsTabController,
                tabs: [
                  // Tab(text: "Temperature Analytics"),
                  Tab(text: "Detailed Temperature"),
                  //  Tab(text: "Pressure Analytics"),
                  Tab(text: "Detailed Pressure"),
                  //Tab(text: "Compressor Analytics"),
                  Tab(text: "Detailed Compressor"),
                  Tab(
                      text:
                          "Door Analytics"), // Consolidated from "Door Analysis"
                ],
                labelColor: Constants.ctaColorLight,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Constants.ctaColorLight,
              ),

              // TabBarView with its children reordered to match the TabBar
              Container(
                height: 655,
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _metricsTabController,
                  children: [
                    // 1. Temperature

                    _buildDetailedTemperatureMetrics(),

                    // 2. Pressure
                    // _buildPressureAnalytics(),
                    _buildDetailedPressureMetrics(),

                    // 3. Compressor
                    //_buildCompressorAnalytics(),
                    _buildDetailedCompressorMetrics(),

                    // 4. Door
                    Column(
                      children: [
                        SizedBox(
                          height: 16,
                        ),
                        Container(
                            height: 100, child: _buildDesktopDoorMetrics()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> fetchLatestDeviceData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.articBaseUrl2}latest-device-data/${Constants.myBusiness.businessUid}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("dfgfgf ${data}");

        final newDeviceList =
            data.map((item) => LatestDeviceData.fromJson(item)).toList();

        if (newDeviceList.isNotEmpty) {
          setState(() {
            latestDeviceDataList = newDeviceList;

            // --- FIX STARTS HERE ---
            // Check if no device is selected OR if the current selection is no longer valid
            final isSelectionInvalid = selectedDeviceId == null ||
                !latestDeviceDataList
                    .any((d) => d.deviceId == selectedDeviceId);

            if (isSelectionInvalid) {
              // Default the selection to the first device from the fetched list
              selectedDeviceId = latestDeviceDataList.first.deviceId;
            }
            // --- FIX ENDS HERE ---
          });

          // Now that a device is guaranteed to be selected, update the UI
          _updateDailySummaryFromLatestData();
        }
      } else {
        print('Failed to fetch latest device data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest device data: $e');
    }
  }

  void _updateDailySummaryFromLatestData() {
    if (latestDeviceDataList.isNotEmpty) {
      // --- FIX STARTS HERE ---
      late final LatestDeviceData deviceToDisplay;

      // Find the selected device.
      final matchingDevices = latestDeviceDataList
          .where((device) => device.deviceId == selectedDeviceId)
          .toList();

      if (matchingDevices.isNotEmpty) {
        // If found, use it.
        deviceToDisplay = matchingDevices.first;
      } else {
        // If not found (e.g., selection is out of sync), default to the first device.
        print(
            "Fallback: selectedDeviceId '$selectedDeviceId' not found. Defaulting to the first device.");
        deviceToDisplay = latestDeviceDataList.first;
      }
      // --- FIX ENDS HERE ---

      // The rest of the function now uses the safe 'deviceToDisplay' variable
      print(
          "gfgfgfgfg ${deviceToDisplay.deviceId} ${deviceToDisplay.compressorHigh}");

      dailySummaryList = [
        DailySummaryRecords(
          deviceToDisplay.temperatureAir?.toInt() ?? 0,
          0,
          "Freezer Room Temperature",
          FontAwesomeIcons.snowflake,
          const Color(0XFFF4F4F4),
        ),
        DailySummaryRecords(
          deviceToDisplay.compressorLow?.toInt() ?? 0,
          0,
          "Pressure [Low Side]",
          FontAwesomeIcons.gauge,
          const Color(0Xcc3C514933),
        ),
        DailySummaryRecords(
          deviceToDisplay.compressorHigh?.toInt() ?? 0,
          0,
          "Pressure [High Side]",
          FontAwesomeIcons.gaugeHigh,
          const Color(0XccF4F4F4),
        ),
        DailySummaryRecords(
          deviceToDisplay.temperatureCoil?.toInt() ?? 0,
          0,
          "Heater Coil Temperature",
          FontAwesomeIcons.fire,
          const Color(0Xcc3C514914),
        ),
        DailySummaryRecords(
          deviceToDisplay.temperatureDrain?.toInt() ?? 0,
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
          deviceToDisplay.door ?? false,
        ),
        DailySummaryRecords2(
          "Compressor On",
          FontAwesomeIcons.fan,
          const Color(0XFFF4F4F4),
          deviceToDisplay.comp ?? false,
        ),
        DailySummaryRecords2(
          "Ice Build-Up",
          FontAwesomeIcons.icicles,
          const Color(0XFFF4F4F4),
          deviceToDisplay.iceBuiltUp ?? false,
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
    print("fghghg ${Constants.hourlyData.length}");

    // averageTamWidgetValue.value++;
  }

  void _updateNotificationList() {
    recentNotificationList = alertsList
        .map((alert) => NotificationModel(
              id: 0,
              message: alert.message ?? '',
              alertType: alert.alertType ?? '',
              timestamp: alert.timestamp ?? '',
              deviceId: alert.deviceId ?? '',
              alertCategory: '',
              isResolved: false,
              isSystemAlert: true,
              paramCode: '',
            ))
        .toList();
    setState(() {});
  }

  Future<void> fetchDashboardData() async {
    try {
      String url =
          '${Constants.articBaseUrl2}dashboard-data/?business_uid=${Constants.myBusiness.businessUid}';
      print("Fetching dashboard data from: $url $selectedDeviceId");

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
          // Parse the comprehensive dashboard data
          dashboardData = DashboardData.fromJson(data);

          // Update individual lists for backwards compatibility
          latestDeviceDataList = dashboardData!.currentData
              .where((device) =>
                  selectedDeviceId == null ||
                  device.deviceId == selectedDeviceId)
              .toList();

          dailyAggregatesList = dashboardData!.dailyAggregates
              .where((aggregate) =>
                  selectedDeviceId == null ||
                  aggregate.deviceId == selectedDeviceId)
              .toList();

          hourlyAggregatesList = dashboardData!.hourlyAggregates;
          activeAlerts = dashboardData!.alerts;
        });

        print('Successfully fetched dashboard data');
        print('Current devices: ${latestDeviceDataList.length}');
        print('Daily aggregates: ${dailyAggregatesList.length}');
        print('Hourly aggregates: ${hourlyAggregatesList.length}');
        print('Active alerts: ${activeAlerts.length}');

        // Process the data to build metrics
        _processDashboardData();
      } else {
        print('Failed to fetch dashboard data: ${response.statusCode}');
        //  _showError('Failed to load dashboard data');
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      // _showErrorSnackBar('Error loading dashboard: $e');
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
          print("ghghghj ${alertsList.length}");
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

  Widget _buildCompressorEfficiencyCard() {
    final runtime = compressorMetrics!.runtimePercentage ?? 0;
    final isEfficient = runtime >= 30 && runtime <= 70; // Optimal range

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEfficient
            ? Colors.green.shade50
            : Constants.ctaColorLight.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEfficient
              ? Colors.green.shade200
              : Constants.ctaColorLight.withOpacity(0.09),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEfficient ? Icons.eco : Icons.warning,
            color: isEfficient ? Colors.green : Constants.ctaColorLight,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Runtime Efficiency',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${runtime.toStringAsFixed(1)}% today',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEfficient
                        ? Colors.green.shade700
                        : Constants.ctaColorLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isEfficient
                ? 'OPTIMAL'
                : (runtime < 30 ? 'UNDERUSED' : 'OVERWORKED'),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  isEfficient ? Colors.green.shade700 : Constants.ctaColorLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressorLoadCard() {
    final avgAmp = compressorMetrics!.avgAmp ?? 0;
    final maxAmp = compressorMetrics!.maxAmp ?? 0;
    final loadRatio = maxAmp > 0 ? (avgAmp / maxAmp) : 0;
    final isGoodLoad = loadRatio >= 0.7 && loadRatio <= 0.9;

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGoodLoad
            ? Constants.ctaColorLight.withOpacity(0.08)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGoodLoad
              ? Constants.ctaColorLight.withOpacity(0.15)
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGoodLoad ? Icons.battery_charging_full : Icons.battery_alert,
            color: isGoodLoad ? Colors.blue : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Load Efficiency',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${(loadRatio * 100).toStringAsFixed(0)}% of max load',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGoodLoad
                        ? Constants.ctaColorLight
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isGoodLoad ? 'EFFICIENT' : 'INEFFICIENT',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isGoodLoad ? Constants.ctaColorLight : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressorHealthCard() {
    final imbalance = compressorMetrics!.imbalance ?? 0;
    final cycles = compressorMetrics!.onCount ?? 0;

    // Health score based on imbalance and cycle count
    bool isHealthy = imbalance <= 5 && cycles <= 50; // Reasonable thresholds

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.favorite : Icons.healing,
            color: isHealthy ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Health',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$cycles cycles, ${imbalance.toStringAsFixed(1)}A imbalance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isHealthy ? 'HEALTHY' : 'ATTENTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureRatioCard() {
    final lowSide = pressureMetrics!.lowSideCurrent ?? 0;
    final highSide = pressureMetrics!.highSideCurrent ?? 0;
    final ratio = lowSide > 0 ? (highSide / lowSide) : 0;
    final isGoodRatio = ratio >= 2.5 && ratio <= 4.0; // Typical good range

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGoodRatio
            ? Colors.green.shade50
            : Constants.ctaColorLight.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGoodRatio
              ? Colors.green.shade200
              : Constants.ctaColorLight.withOpacity(0.09),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGoodRatio ? Icons.balance : Icons.warning,
            color: isGoodRatio ? Colors.green : Constants.ctaColorLight,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pressure Ratio',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${ratio.toStringAsFixed(1)}:1 (High/Low)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGoodRatio
                        ? Colors.green.shade700
                        : Constants.ctaColorLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isGoodRatio ? 'NORMAL' : 'CHECK',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  isGoodRatio ? Colors.green.shade700 : Constants.ctaColorLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureStabilityCard() {
    final lowRange =
        (pressureMetrics!.lowSideMax ?? 0) - (pressureMetrics!.lowSideMin ?? 0);
    final highRange = (pressureMetrics!.highSideMax ?? 0) -
        (pressureMetrics!.highSideMin ?? 0);
    final isStable =
        lowRange <= 10 && highRange <= 20; // Reasonable stability thresholds

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStable
            ? Constants.ctaColorLight.withOpacity(0.08)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStable
              ? Constants.ctaColorLight.withOpacity(0.15)
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStable ? Icons.trending_flat : Icons.trending_up,
            color: isStable ? Colors.blue : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isStable
                  ? 'Pressure levels stable throughout the day'
                  : 'Pressure fluctuations detected',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isStable ? Constants.ctaColorLight : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSpreadCard() {
    final airTemp = temperatureRanges!.firstWhere(
      (range) => range.sensor?.toLowerCase().contains('air') ?? false,
      orElse: () => temperatureRanges!.first,
    );

    final spread = (airTemp.max ?? 0) - (airTemp.min ?? 0);
    final isGoodSpread = spread <= 10; // Threshold for good temperature control

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGoodSpread
            ? Colors.green.shade50
            : Constants.ctaColorLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGoodSpread
              ? Colors.green.shade200
              : Constants.ctaColorLight.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGoodSpread ? Icons.check_circle : Icons.warning,
            color: isGoodSpread ? Colors.green : Constants.ctaColorLight,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature Spread',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${spread.toStringAsFixed(1)}°C range',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGoodSpread
                        ? Colors.green.shade700
                        : Constants.ctaColorLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isGoodSpread ? 'STABLE' : 'VARIABLE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isGoodSpread
                  ? Colors.green.shade700
                  : Constants.ctaColorLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureStabilityCard() {
    // Calculate stability based on how close current is to average
    final airTemp = temperatureRanges!.firstWhere(
      (range) => range.sensor?.toLowerCase().contains('air') ?? false,
      orElse: () => temperatureRanges!.first,
    );

    if (airTemp.current == null || airTemp.avg == null) {
      return SizedBox.shrink();
    }

    final deviation = (airTemp.current! - airTemp.avg!).abs();
    final isStable = deviation <= 2.0; // Within 2 degrees of average

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStable
            ? Constants.ctaColorLight.withOpacity(0.08)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStable
              ? Constants.ctaColorLight.withOpacity(0.15)
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStable ? Icons.trending_flat : Icons.trending_up,
            color: isStable ? Colors.blue : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current vs Average',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${deviation.toStringAsFixed(1)}°C deviation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isStable
                        ? Constants.ctaColorLight
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isStable ? 'STABLE' : 'DEVIATION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isStable ? Constants.ctaColorLight : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureAlertsCard() {
    int tempAlerts = 0;
    // Count temperature-related alerts (you'll need to filter from your alerts list)
    for (var range in temperatureRanges!) {
      if (range.status == 'High' ||
          range.status == 'Low' ||
          range.status == 'Critical') {
        tempAlerts++;
      }
    }

    return Container(
      height: 65,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tempAlerts > 0 ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tempAlerts > 0 ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            tempAlerts > 0 ? Icons.error : Icons.check_circle,
            color: tempAlerts > 0 ? Colors.red : Colors.green,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              tempAlerts > 0
                  ? '$tempAlerts active temperature alerts'
                  : 'All temperature sensors normal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tempAlerts > 0
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalyticsView() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12),
          Text(
            'Analytics Unavailable',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Insufficient data for analysis',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
