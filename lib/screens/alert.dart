import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../models/alert.dart';
import '../services/shared_preferences.dart';
import '../widgets/compact_header.dart';

class AlertApiService {
  static final String _baseUrl = Constants.articBaseUrl2;

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Fetch alerts for a specific business
  static Future<AlertResponse> fetchAlerts(
    int businessId, {
    String? status,
    String? severity,
    int? deviceId,
    int page = 1,
    int pageSize = 50,
  }) async {
    Map<String, dynamic> requestData = {
      "business_id": businessId,
      "page": page,
      "page_size": pageSize,
    };

    if (status != null && status.isNotEmpty) {
      requestData['status'] = status;
    }
    if (severity != null && severity.isNotEmpty) {
      requestData['severity'] = severity;
    }
    if (deviceId != null) {
      requestData['device_id'] = deviceId;
    }

    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/list/'),
      headers: await _getHeaders(),
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return AlertResponse.fromJson(responseData);
    } else {
      throw Exception('Failed to load alerts: ${response.body}');
    }
  }

  // Get alerts by status
  static Future<List<Alert>> getAlertsByStatus(
      int businessId, String status) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/by-status/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "status": status,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> alertList = responseData['alerts'] ?? [];
      return alertList.map((item) => Alert.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get alerts by status: ${response.body}');
    }
  }

  // Get alerts by severity
  static Future<List<Alert>> getAlertsBySeverity(
      int businessId, String severity) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/by-severity/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "severity": severity,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> alertList = responseData['alerts'] ?? [];
      return alertList.map((item) => Alert.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get alerts by severity: ${response.body}');
    }
  }

  // Acknowledge an alert
  static Future<bool> acknowledgeAlert(int businessId, int alertId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/acknowledge/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "alert_id": alertId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception('Failed to acknowledge alert: ${response.body}');
    }
  }

  // Resolve an alert
  static Future<bool> resolveAlert(int businessId, int alertId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/resolve/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "alert_id": alertId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception('Failed to resolve alert: ${response.body}');
    }
  }

  // Mark alert as false positive
  static Future<bool> markAsFalsePositive(
      String businessId, int alertId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/false-positive/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "alert_id": alertId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception(
          'Failed to mark alert as false positive: ${response.body}');
    }
  }

  // Mark all alerts as read/acknowledged
  static Future<bool> markAllAsRead(int businessId, {String? status}) async {
    Map<String, dynamic> requestData = {
      "business_id": businessId,
    };

    if (status != null && status.isNotEmpty) {
      requestData['status'] = status;
    }

    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/mark-all-read/'),
      headers: await _getHeaders(),
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception('Failed to mark all alerts as read: ${response.body}');
    }
  }

  // Get alert statistics
  static Future<Map<String, dynamic>> getAlertStatistics(int businessId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/statistics/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get alert statistics: ${response.body}');
    }
  }

  // Get alert details
  static Future<Alert> getAlertDetails(String businessId, int alertId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/alerts/detail/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "business_id": businessId,
        "alert_id": alertId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Alert.fromJson(responseData['alert'] ?? responseData);
    } else {
      throw Exception('Failed to get alert details: ${response.body}');
    }
  }
}

class NotificationTopNav {
  String itemName;
  String item_id;
  int id;
  int itemTotal;
  String? status;
  String? severity;

  NotificationTopNav(this.itemName, this.item_id, this.id, this.itemTotal,
      {this.status, this.severity});
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationTopNav> notTopNavList = [];
  List<Alert> currentAlerts = [];
  Map<String, dynamic> alertStatistics = {};

  int navIndex = 0;
  String navStringId = "all";
  bool _isLoading = true;
  bool _isLoadingStatistics = true;

  @override
  void initState() {
    super.initState();
    _loadAlertStatistics();
    _loadAlerts();
  }

  Future<void> _loadAlertStatistics() async {
    setState(() {
      _isLoadingStatistics = true;
    });

    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        alertStatistics = await AlertApiService.getAlertStatistics(businessId);
        _updateNavigationList();
      }
    } catch (e) {
      print('Error loading alert statistics: $e');
      _setDefaultNavigation();
    } finally {
      setState(() {
        _isLoadingStatistics = false;
      });
    }
  }

  void _updateNavigationList() {
    notTopNavList = [
      NotificationTopNav("All", "all", 0, alertStatistics['total'] ?? 0),
      NotificationTopNav("Active", "active", 1, alertStatistics['active'] ?? 0,
          status: 'active'),
      NotificationTopNav(
          "Critical", "critical", 2, alertStatistics['critical'] ?? 0,
          severity: 'critical'),
      NotificationTopNav("High", "high", 3, alertStatistics['high'] ?? 0,
          severity: 'high'),
      NotificationTopNav("Medium", "medium", 4, alertStatistics['medium'] ?? 0,
          severity: 'medium'),
      NotificationTopNav(
          "Resolved", "resolved", 5, alertStatistics['resolved'] ?? 0,
          status: 'resolved'),
    ];
  }

  void _setDefaultNavigation() {
    notTopNavList = [
      NotificationTopNav("All", "all", 0, 0),
      NotificationTopNav("Active", "active", 1, 0, status: 'active'),
      NotificationTopNav("Critical", "critical", 2, 0, severity: 'critical'),
      NotificationTopNav("High", "high", 3, 0, severity: 'high'),
      NotificationTopNav("Medium", "medium", 4, 0, severity: 'medium'),
      NotificationTopNav("Resolved", "resolved", 5, 0, status: 'resolved'),
    ];
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        AlertResponse response;

        if (navStringId == "all") {
          response = await AlertApiService.fetchAlerts(businessId);
        } else {
          // Get current navigation item
          NotificationTopNav currentNav = notTopNavList[navIndex];

          if (currentNav.status != null) {
            // Filter by status
            List<Alert> alerts = await AlertApiService.getAlertsByStatus(
                businessId, currentNav.status!);
            response = AlertResponse(alerts: alerts, count: alerts.length);
          } else if (currentNav.severity != null) {
            // Filter by severity
            List<Alert> alerts = await AlertApiService.getAlertsBySeverity(
                businessId, currentNav.severity!);
            response = AlertResponse(alerts: alerts, count: alerts.length);
          } else {
            response = await AlertApiService.fetchAlerts(businessId);
          }
        }

        currentAlerts = response.alerts;
      } else {
        currentAlerts = [];
      }
    } catch (e) {
      print('Error loading alerts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load alerts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      currentAlerts = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0) {
        bool success = await AlertApiService.markAllAsRead(businessId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All alerts marked as read'),
              backgroundColor: Constants.ctaColorLight,
            ),
          );
          _loadAlertStatistics();
          _loadAlerts();
        }
      }
    } catch (e) {
      print('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acknowledgeAlert(Alert alert) async {
    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0 && alert.id != null) {
        bool success =
            await AlertApiService.acknowledgeAlert(businessId, alert.id!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alert acknowledged'),
              backgroundColor: Constants.ctaColorLight,
            ),
          );
          _loadAlertStatistics();
          _loadAlerts();
        }
      }
    } catch (e) {
      print('Error acknowledging alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to acknowledge alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resolveAlert(Alert alert) async {
    try {
      int? businessId = Constants.myBusiness.businessUid;
      if (businessId > 0 && alert.id != null) {
        bool success =
            await AlertApiService.resolveAlert(businessId, alert.id!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alert resolved'),
              backgroundColor: Constants.ctaColorLight,
            ),
          );
          _loadAlertStatistics();
          _loadAlerts();
        }
      }
    } catch (e) {
      print('Error resolving alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resolve alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAlertDetails(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDetailsDialog(
        alert: alert,
        onAcknowledge: () => _acknowledgeAlert(alert),
        onResolve: () => _resolveAlert(alert),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const CompactHeader(
              title: "Alerts",
              description: "View and manage system alerts",
              icon: Icons.notifications_active_rounded,
            ),

            const SizedBox(height: 24),

            // Main Content Card
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation Tabs
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoadingStatistics
                        ? const SizedBox(
                            height: 60,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  notTopNavList.asMap().entries.map((entry) {
                                int index = entry.key;
                                NotificationTopNav nav = entry.value;
                                bool isSelected = navIndex == index;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < notTopNavList.length - 1
                                        ? 8
                                        : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        navIndex = index;
                                        navStringId = nav.item_id;
                                      });
                                      _loadAlerts();
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            nav.itemName,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? _getSeverityColor(
                                                      nav.item_id)
                                                  : const Color(0xFF94A3B8),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              nav.itemTotal.toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "${navStringId.toUpperCase()} ALERTS",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Alerts List
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 600, // Set a reasonable max height
                    ),
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : currentAlerts.isEmpty
                            ? Container(
                                height: 200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No alerts found',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'All clear for now!',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: currentAlerts.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  Alert alert = currentAlerts[index];
                                  return GestureDetector(
                                    onTap: () => _showAlertDetails(alert),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAFAFA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: alert.severityColor
                                              .withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.02),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Alert Icon
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: alert.severityColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: alert.severityColor
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              alert.severityIcon,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),

                                          const SizedBox(width: 16),

                                          // Alert Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        alert.title,
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                              0xFF1E293B),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            alert.severityColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        alert.severityDisplay,
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            alert.statusColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            alert.deviceName ??
                                                                'Device ID: ${alert.deviceId}',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: const Color(
                                                                  0xFF475569),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            alert.message,
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              color: const Color(
                                                                  0xFF64748B),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          timeAgo.format(alert
                                                              .triggeredDateTime),
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: const Color(
                                                                0xFF64748B),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          'Duration: ${alert.duration}',
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 10,
                                                            color: const Color(
                                                                0xFF94A3B8),
                                                          ),
                                                        ),
                                                      ],
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
                                },
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

  Color _getSeverityColor(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return Constants.ctaColorLight;
      case 'medium':
        return Constants.ctaColorLight;
      case 'active':
        return Constants.ctaColorLight;
      case 'resolved':
        return Constants.ctaColorLight;
      default:
        return Constants.ctaColorGreen;
    }
  }
}

// Alert Details Dialog
class AlertDetailsDialog extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  const AlertDetailsDialog({
    Key? key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    alert.severityColor.withOpacity(0.1),
                    alert.severityColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: alert.severityColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: alert.severityColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          alert.severityIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert Details',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: alert.severityColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    alert.severityDisplay,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: alert.statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  alert.statusDisplay,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          foregroundColor: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    alert.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert Information Card
                    _buildModernInfoCard(
                      'Alert Information',
                      Icons.info_outline_rounded,
                      [
                        _buildModernInfoRow(
                            'Message', alert.message, Icons.message_outlined),
                        _buildModernInfoRow('Severity', alert.severityDisplay,
                            Icons.warning_amber_rounded,
                            valueColor: alert.severityColor),
                        _buildModernInfoRow(
                            'Status', alert.statusDisplay, Icons.circle,
                            valueColor: alert.statusColor),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Device Information Card
                    _buildModernInfoCard(
                      'Device Information',
                      Icons.devices_rounded,
                      [
                        _buildModernInfoRow(
                            'Device Name',
                            alert.deviceName ?? 'Unknown',
                            Icons.device_hub_rounded),
                        _buildModernInfoRow(
                            'Device ID',
                            alert.deviceId.toString(),
                            Icons.fingerprint_rounded),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Timing Information Card
                    _buildModernInfoCard(
                      'Timing Information',
                      Icons.schedule_rounded,
                      [
                        _buildModernInfoRow(
                            'Triggered At',
                            alert.formattedTriggeredAt,
                            Icons.play_arrow_rounded),
                        _buildModernInfoRow(
                            'Duration', alert.duration, Icons.timer_outlined),
                        if (alert.acknowledgedAt != null)
                          _buildModernInfoRow(
                              'Acknowledged At',
                              _formatDateTime(alert.acknowledgedAt!),
                              Icons.check_circle_outline),
                        if (alert.resolvedAt != null)
                          _buildModernInfoRow(
                              'Resolved At',
                              _formatDateTime(alert.resolvedAt!),
                              Icons.task_alt_rounded,
                              valueColor: Constants.ctaColorLight),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Notification Status Card
                    _buildModernInfoCard(
                      'Notification Status',
                      Icons.notifications_outlined,
                      [
                        _buildModernStatusRow('Email Notification',
                            alert.emailSent, Icons.email_outlined),
                        _buildModernStatusRow('SMS Notification', alert.smsSent,
                            Icons.sms_outlined),
                        if (alert.emailSentAt != null)
                          _buildModernInfoRow(
                              'Email Sent At',
                              _formatDateTime(alert.emailSentAt!),
                              Icons.email_outlined),
                        if (alert.smsSentAt != null)
                          _buildModernInfoRow(
                              'SMS Sent At',
                              _formatDateTime(alert.smsSentAt!),
                              Icons.sms_outlined),
                      ],
                    ),

                    // Trigger Data Card (if available)
                    if (alert.triggerData != null &&
                        alert.triggerData!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildModernInfoCard(
                        'Trigger Data',
                        Icons.code_rounded,
                        [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              alert.triggerData.toString(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Close Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  // Acknowledge Button
                  if (alert.isActive && onAcknowledge != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAcknowledge!();
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        'Acknowledge',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ],

                  // Resolve Button
                  if (!alert.isResolved && onResolve != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onResolve!();
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: Text(
                        'Resolve',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoCard(
      String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: Constants.ctaColorLight,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusRow(String label, bool status, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status
                  ? Constants.ctaColorLight.withOpacity(0.1)
                  : const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: status
                    ? Constants.ctaColorLight.withOpacity(0.2)
                    : const Color(0xFFEF4444).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 14,
                  color: status
                      ? Constants.ctaColorLight
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 6),
                Text(
                  status ? 'Sent' : 'Not Sent',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status
                        ? Constants.ctaColorLight
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
