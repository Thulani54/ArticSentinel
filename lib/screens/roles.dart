import 'dart:async';
import 'dart:io';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/compact_header.dart';

// Models
class Role {
  final int roleId;
  final String name;
  final String description;
  final String category;
  final String categoryDisplay;
  final int permissionCount;
  final int userCount;
  final bool isActive;
  final DateTime createdAt;

  Role({
    required this.roleId,
    required this.name,
    required this.description,
    required this.category,
    required this.categoryDisplay,
    required this.permissionCount,
    required this.userCount,
    required this.isActive,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['role_id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'],
      categoryDisplay: json['category_display'],
      permissionCount: json['permission_count'] ?? 0,
      userCount: json['user_count'] ?? 0,
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Permission {
  final int permissionId;
  final String name;
  final String type;
  final String typeDisplay;
  final String module;
  final String moduleDisplay;
  final String description;
  final bool requiresApproval;
  final bool emergencyOverride;

  Permission({
    required this.permissionId,
    required this.name,
    required this.type,
    required this.typeDisplay,
    required this.module,
    required this.moduleDisplay,
    required this.description,
    required this.requiresApproval,
    required this.emergencyOverride,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      permissionId: json['permission_id'],
      name: json['name'],
      type: json['type'],
      typeDisplay: json['type_display'],
      module: json['module'],
      moduleDisplay: json['module_display'],
      description: json['description'] ?? '',
      requiresApproval: json['requires_approval'],
      emergencyOverride: json['emergency_override'],
    );
  }
}

class PermissionRequest {
  final int requestId;
  final String userFullName;
  final String requestedByName;
  final String? roleName;
  final String? permissionName;
  final String? companyName;
  final String requestStatus;
  final String statusDisplay;
  final String justification;
  final bool emergencyRequest;
  final DateTime requestTimestamp;

  PermissionRequest({
    required this.requestId,
    required this.userFullName,
    required this.requestedByName,
    this.roleName,
    this.permissionName,
    this.companyName,
    required this.requestStatus,
    required this.statusDisplay,
    required this.justification,
    required this.emergencyRequest,
    required this.requestTimestamp,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      requestId: json['request_id'],
      userFullName: json['user_full_name'],
      requestedByName: json['requested_by_name'],
      roleName: json['role_name'],
      permissionName: json['permission_name'],
      companyName: json['company_name'],
      requestStatus: json['request_status'],
      statusDisplay: json['status_display'],
      justification: json['justification'],
      emergencyRequest: json['emergency_request'],
      requestTimestamp: DateTime.parse(json['request_timestamp']),
    );
  }
}

// API Service
class AuthApiService {
  static String baseUrl = '${Constants.articBaseUrl2}api';

  static Future<List<Role>> getRoles({String? category, String? search}) async {
    String url = '$baseUrl/roles/';
    Map<String, String> params = {};

    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;

    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['results'];
      return data.map((json) => Role.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  static Future<Role> createRole(Map<String, dynamic> roleData) async {
    try {
      print("Creating role with data: $roleData");
      print("Base URL: ${baseUrl}/create_role/");
      final response = await http.post(
        Uri.parse('$baseUrl/create_role/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(roleData),
      );
      print("gfghg ${response.body}");

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Role.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);

        // Handle specific validation errors
        if (errorData.containsKey('name')) {
          throw Exception('Role name ${errorData['name'][0]}');
        } else if (errorData.containsKey('category')) {
          throw Exception('Invalid category selected');
        } else if (errorData.containsKey('role_types')) {
          throw Exception('Invalid role types selected');
        } else {
          print("fggghgh ${errorData}");
          throw Exception(
              'Validation error: ${errorData['detail'] ?? 'Invalid data provided'}');
        }
      } else if (response.statusCode == 403) {
        throw Exception('permission denied');
      } else if (response.statusCode == 409) {
        throw Exception('already exists');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later');
      } else {
        throw Exception(
            'Failed to create role. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('network error');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Unexpected error: $e');
      }
    }
  }

  static Future<List<Permission>> getPermissions(
      {String? module, String? type}) async {
    String url = '${baseUrl}/permissions/';
    Map<String, String> params = {};

    if (module != null) params['module'] = module;
    if (type != null) params['type'] = type;

    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['results'];
      return data.map((json) => Permission.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  static Future<List<PermissionRequest>> getPermissionRequests(
      {String? status}) async {
    String url = '$baseUrl/permission-requests/';
    if (status != null) url += '?status=$status';

    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['results'];
      return data.map((json) => PermissionRequest.fromJson(json)).toList();
    } else {
      return [];
      // throw Exception('Failed to load permission requests');
    }
  }

  static Future<bool> approveRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/permission-requests/$requestId/approve/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> rejectRequest(int requestId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/permission-requests/$requestId/reject/'),
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN',
        'Content-Type': 'application/json',
      },
      body: json.encode({'rejection_reason': reason}),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/stats/'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {};
    }
  }
}

// Main Role Management Page
class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Role> roles = [];
  List<Permission> permissions = [];
  List<PermissionRequest> pendingRequests = [];
  Map<String, dynamic> dashboardStats = {};

  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedModule;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AuthApiService.getRoles(),
        AuthApiService.getPermissions(),
        AuthApiService.getPermissionRequests(status: 'pending'),
        AuthApiService.getDashboardStats(),
      ]);

      setState(() {
        roles = results[0] as List<Role>;
        permissions = results[1] as List<Permission>;
        pendingRequests = results[2] as List<PermissionRequest>;
        dashboardStats = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1000,
      //backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            const CompactHeader(
              title: "Roles",
              description: "Manage user roles and permissions",
              icon: Icons.group_rounded,
            ),

            // Modern Tab Navigation
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
                  Tab(
                    height: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Roles'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Permissions'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Requests'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Audit Logs'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRolesTab(),
                        _buildPermissionsTab(),
                        _buildRequestsTab(),
                        _buildAuditLogsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total Users",
            "${dashboardStats['total_users'] ?? 0}",
            Icons.people_rounded,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Active Roles",
            "${dashboardStats['total_roles'] ?? 0}",
            Icons.security_rounded,
            Constants.ctaColorLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Permissions",
            "${dashboardStats['total_permissions'] ?? 0}",
            Icons.key_rounded,
            const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Pending",
            "${dashboardStats['pending_requests'] ?? 0}",
            Icons.pending_actions_rounded,
            const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Constants.ctaColorLight,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Bar
          _buildSearchAndFilter(),

          const SizedBox(height: 20),

          // Roles List
          Expanded(
            child: ListView.separated(
              itemCount: roles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final role = roles[index];
                return _buildRoleCard(role);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search roles, permissions, or users...',
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
              // In your main widget button:
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const AddRoleDialog(),
                  );

                  if (result == true) {
                    _loadRoles();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Add Role"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(Role role) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(role.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(role.category),
                  color: _getCategoryColor(role.category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getCategoryColor(role.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role.categoryDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(role.category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      // Edit role
                      break;
                    case 'permissions':
                      // View permissions
                      break;
                    case 'users':
                      // View users
                      break;
                    case 'delete':
                      // Delete role
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Role')),
                  const PopupMenuItem(
                      value: 'permissions', child: Text('Manage Permissions')),
                  const PopupMenuItem(
                      value: 'users', child: Text('View Users')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete Role')),
                ],
                child: const Icon(Icons.more_vert_rounded,
                    color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            role.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildRoleMetric(
                  "Permissions", role.permissionCount, Icons.key_rounded),
              const SizedBox(width: 24),
              _buildRoleMetric("Users", role.userCount, Icons.people_rounded),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: role.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role.isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: role.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleMetric(String label, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSearchAndFilter(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: permissions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final permission = permissions[index];
                return _buildPermissionCard(permission);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(Permission permission) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _getPermissionTypeColor(permission.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPermissionTypeIcon(permission.type),
                  color: _getPermissionTypeColor(permission.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPermissionTypeColor(permission.type)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            permission.typeDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getPermissionTypeColor(permission.type),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          permission.moduleDisplay,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (permission.requiresApproval)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.approval_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
              if (permission.emergencyOverride)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          if (permission.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              permission.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: pendingRequests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return _buildRequestCard(request);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PermissionRequest request) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: request.emergencyRequest
              ? Colors.red.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
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
              if (request.emergencyRequest)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.request_page_rounded,
                    color: Constants.ctaColorLight,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request for ${request.userFullName}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested by ${request.requestedByName}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(request.requestStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.statusDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(request.requestStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (request.roleName != null || request.permissionName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    request.roleName != null
                        ? Icons.security_rounded
                        : Icons.key_rounded,
                    size: 16,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${request.roleName ?? request.permissionName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Constants.ctaColorLight,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            request.justification,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Requested ${_formatTimeAgo(request.requestTimestamp)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              if (request.requestStatus == 'pending') ...[
                OutlinedButton(
                  onPressed: () => _rejectRequest(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    return const Center(
      child: Text(
        'Audit Logs',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Helper methods
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'executive':
        return const Color(0xFF8B5CF6);
      case 'operations_management':
        return Constants.ctaColorLight;
      case 'technical_management':
        return const Color(0xFF06B6D4);
      case 'field_technician':
        return const Color(0xFF10B981);
      case 'customer_user':
        return const Color(0xFFF59E0B);
      case 'system_admin':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'executive':
        return Icons.business_center_rounded;
      case 'operations_management':
        return Icons.manage_accounts;
      case 'technical_management':
        return Icons.engineering_rounded;
      case 'field_technician':
        return Icons.build_rounded;
      case 'customer_user':
        return Icons.person_rounded;
      case 'system_admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  Color _getPermissionTypeColor(String type) {
    switch (type) {
      case 'view_only':
        return const Color(0xFF64748B);
      case 'create':
        return const Color(0xFF10B981);
      case 'edit':
        return Constants.ctaColorLight;
      case 'delete':
        return const Color(0xFFEF4444);
      case 'manage':
        return const Color(0xFF8B5CF6);
      case 'admin':
        return const Color(0xFFDC2626);
      case 'approve':
        return const Color(0xFFF59E0B);
      case 'override':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getPermissionTypeIcon(String type) {
    switch (type) {
      case 'view_only':
        return Icons.visibility_rounded;
      case 'create':
        return Icons.add_circle_rounded;
      case 'edit':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'manage':
        return Icons.settings_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'approve':
        return Icons.approval_rounded;
      case 'override':
        return Icons.emergency_rounded;
      default:
        return Icons.key_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'expired':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _approveRequest(PermissionRequest request) async {
    try {
      final success = await AuthApiService.approveRequest(request.requestId);
      if (success) {
        _showSuccessSnackBar('Request approved successfully');
        _loadData(); // Refresh data
      } else {
        _showErrorSnackBar('Failed to approve request');
      }
    } catch (e) {
      _showErrorSnackBar('Error approving request: $e');
    }
  }

  Future<void> _rejectRequest(PermissionRequest request) async {
    // Show dialog to get rejection reason
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectRequestDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final success =
            await AuthApiService.rejectRequest(request.requestId, reason);
        if (success) {
          _showSuccessSnackBar('Request rejected');
          _loadData(); // Refresh data
        } else {
          _showErrorSnackBar('Failed to reject request');
        }
      } catch (e) {
        _showErrorSnackBar('Error rejecting request: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadRoles() {}
}

// Reject Request Dialog
class _RejectRequestDialog extends StatefulWidget {
  @override
  State<_RejectRequestDialog> createState() => _RejectRequestDialogState();
}

class _RejectRequestDialogState extends State<_RejectRequestDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reject Request',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Constants.ctaColorLight,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please provide a reason for rejecting this request:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter rejection reason...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
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
                        borderSide: const BorderSide(
                            color: Color(0xFFEF4444), width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                      onPressed: () {
                        if (_reasonController.text.trim().isNotEmpty) {
                          Navigator.of(context)
                              .pop(_reasonController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Reject'),
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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}

// Role Details Dialog
class RoleDetailsDialog extends StatelessWidget {
  final Role role;

  const RoleDetailsDialog({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(role.category).withOpacity(0.1),
                    _getCategoryColor(role.category).withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(role.category),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _getCategoryColor(role.category).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(role.category),
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
                          role.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Constants.ctaColorLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.categoryDisplay,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
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
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _buildInfoSection('Description', role.description),

                    const SizedBox(height: 24),

                    // Statistics
                    _buildInfoSection('Statistics', ''),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Permissions',
                              role.permissionCount, Icons.key_rounded),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                              'Users', role.userCount, Icons.people_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // View permissions
                            },
                            icon: const Icon(Icons.key_rounded, size: 18),
                            label: const Text('View Permissions'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Edit role
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Edit Role'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getCategoryColor(role.category),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Constants.ctaColorLight,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _getCategoryColor(role.category), size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Constants.ctaColorLight,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'executive':
        return const Color(0xFF8B5CF6);
      case 'operations_management':
        return Constants.ctaColorLight;
      case 'technical_management':
        return const Color(0xFF06B6D4);
      case 'field_technician':
        return const Color(0xFF10B981);
      case 'customer_user':
        return const Color(0xFFF59E0B);
      case 'system_admin':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'executive':
        return Icons.business_center_rounded;
      case 'operations_management':
        return Icons.manage_accounts;
      case 'technical_management':
        return Icons.engineering_rounded;
      case 'field_technician':
        return Icons.build_rounded;
      case 'customer_user':
        return Icons.person_rounded;
      case 'system_admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.security_rounded;
    }
  }
}

class AddRoleDialog extends StatefulWidget {
  const AddRoleDialog({super.key});

  @override
  State<AddRoleDialog> createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends State<AddRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedParentRole;
  bool _isCompanySpecific = false;
  bool _isSystemRole = false;
  bool _isActive = true;
  bool _isSaving = false;

  List<String> _selectedRoleTypes = [];
  List<Permission> _selectedPermissions = [];

  // Sample data - replace with your actual data
  final List<Map<String, String>> _categories = [
    {'value': 'executive', 'label': 'Executive'},
    {'value': 'operations_management', 'label': 'Operations Management'},
    {'value': 'technical_management', 'label': 'Technical Management'},
    {'value': 'field_technician', 'label': 'Field Technician'},
    {'value': 'monitoring_specialist', 'label': 'Monitoring Specialist'},
    {'value': 'customer_user', 'label': 'Customer User'},
    {'value': 'customer_admin', 'label': 'Customer Admin'},
    {'value': 'system_admin', 'label': 'System Administrator'},
    {'value': 'support_staff', 'label': 'Support Staff'},
    {'value': 'service_provider', 'label': 'Service Provider'},
    {'value': 'custom', 'label': 'Custom'},
  ];

  final List<Map<String, String>> _roleTypes = [
    {'value': 'operational', 'label': 'Operational'},
    {'value': 'technical', 'label': 'Technical'},
    {'value': 'management', 'label': 'Management'},
    {'value': 'customer', 'label': 'Customer'},
    {'value': 'administrator', 'label': 'Administrator'},
    {'value': 'support', 'label': 'Support'},
    {'value': 'service_provider', 'label': 'Service Provider'},
  ];

  final List<String> _parentRoles = [
    'Administrator',
    'Manager',
    'Supervisor',
    'Team Lead',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 800,
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
                    Constants.ctaColorLight.withOpacity(0.1),
                    Constants.ctaColorLight.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.ctaColorLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_circle_rounded,
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
                          'Create New Role',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Constants.ctaColorLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Define a new role with specific permissions and access levels',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
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
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionHeader(
                          'Basic Information', Icons.info_outline_rounded),
                      const SizedBox(height: 20),

                      // Role Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Role Name',
                        hint: 'Enter role name (e.g., Senior Technician)',
                        icon: Icons.security_rounded,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Role name is required';
                          }
                          if (value!.length < 3) {
                            return 'Role name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe the role responsibilities and scope...',
                        icon: Icons.description_rounded,
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Category and Parent Role Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Category',
                              hint: 'Select role category',
                              icon: Icons.category_rounded,
                              value: _selectedCategory,
                              items: _categories,
                              onChanged: (value) =>
                                  setState(() => _selectedCategory = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Parent Role (Optional)',
                              hint: 'Select parent role',
                              icon: Icons.account_tree_rounded,
                              value: _selectedParentRole,
                              items: _parentRoles
                                  .map((role) => {
                                        'value': role,
                                        'label': role,
                                      })
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedParentRole = value),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Role Types Section
                      _buildSectionHeader(
                          'Role Types', Icons.category_outlined),
                      const SizedBox(height: 16),
                      Text(
                        'Select one or more role types that define this role\'s nature:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRoleTypesGrid(),

                      const SizedBox(height: 32),

                      // Role Settings Section
                      _buildSectionHeader(
                          'Role Settings', Icons.settings_rounded),
                      const SizedBox(height: 16),
                      _buildSettingsToggles(),

                      const SizedBox(height: 32),

                      // Permissions Section
                      _buildSectionHeader(
                          'Permissions Preview', Icons.key_rounded),
                      const SizedBox(height: 16),
                      _buildPermissionsPreview(),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
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
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRole,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Creating...' : 'Create Role',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Constants.ctaColorLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Constants.ctaColorLight,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Constants.ctaColorLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
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
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: const Color(0xFF6B7280),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
            ),
            isExpanded: true,
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Text(
                  item['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleTypesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _roleTypes.map((roleType) {
          final isSelected = _selectedRoleTypes.contains(roleType['value']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedRoleTypes.remove(roleType['value']);
                } else {
                  _selectedRoleTypes.add(roleType['value']!);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Constants.ctaColorLight.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Constants.ctaColorLight
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: isSelected
                        ? Constants.ctaColorLight
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    roleType['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Constants.ctaColorLight
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsToggles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildToggleOption(
            'Company Specific',
            'Role is specific to customer companies',
            Icons.business_rounded,
            _isCompanySpecific,
            (value) => setState(() => _isCompanySpecific = value),
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            'System Role',
            'Role has system-wide access',
            Icons.admin_panel_settings_rounded,
            _isSystemRole,
            (value) => setState(() => _isSystemRole = value),
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            'Active',
            'Role is active and can be assigned',
            Icons.toggle_on_rounded,
            _isActive,
            (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFF64748B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: value ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Constants.ctaColorLight,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildPermissionsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permissions can be assigned after creating the role',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Navigate to permission selection
              _showPermissionSelection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0284C7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF0284C7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Permissions (${_selectedPermissions.length})',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionSelection() {
    // TODO: Show permission selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Permission selection will be available after creating the role'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one role type'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Create role object
      final roleData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'parent_role': _selectedParentRole,
        'role_types': _selectedRoleTypes,
        'company_specific': _isCompanySpecific,
        'system_role': _isSystemRole,
        'is_active': _isActive,
      };

      final newRole = await AuthApiService.createRole(roleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Role "${_nameController.text}" created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('Error creating role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating role: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

/*

// Solution 2: Update Flutter to fetch available parent roles dynamically

class _AddRoleDialogState extends State<AddRoleDialog> {
  // ... existing code ...

  List<Map<String, String>> _parentRoles = [];
  bool _loadingParentRoles = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableParentRoles();
  }

  // Fetch available parent roles from API
  Future<void> _loadAvailableParentRoles() async {
    setState(() => _loadingParentRoles = true);

    try {
      // Call API to get available roles that can be parent roles
      final roles = await AuthApiService.getRoles();

      setState(() {
        _parentRoles = roles
            .where((role) => role.isActive && _canBeParentRole(role))
            .map((role) => {
                  'value': role.name, // Use role name as value
                  'label': role.name,
                })
            .toList();
        _loadingParentRoles = false;
      });
    } catch (e) {
      setState(() => _loadingParentRoles = false);
      // Handle error - maybe show default roles or empty list
      _setDefaultParentRoles();
    }
  }

  // Define which roles can be parent roles
  bool _canBeParentRole(Role role) {
    // Only management and administrative roles can be parent roles
    const parentEligibleCategories = [
      'executive',
      'operations_management',
      'technical_management',
      'system_admin',
    ];

    return parentEligibleCategories.contains(role.category);
  }

  // Fallback to default parent roles if API fails
  void _setDefaultParentRoles() {
    setState(() {
      _parentRoles = [
        {'value': 'System Administrator', 'label': 'System Administrator'},
        {'value': 'Manager', 'label': 'Manager'},
        {'value': 'Supervisor', 'label': 'Supervisor'},
        {'value': 'Team Lead', 'label': 'Team Lead'},
      ];
    });
  }

  // Updated parent role dropdown with loading state
  Widget _buildParentRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parent Role (Optional)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: _loadingParentRoles
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading available roles...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedParentRole,
                  decoration: InputDecoration(
                    hintText: _parentRoles.isEmpty
                        ? 'No parent roles available'
                        : 'Select parent role',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: const Icon(
                      Icons.account_tree_rounded,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                  dropdownColor: Colors.white,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280),
                  ),
                  isExpanded: true,
                  onChanged: _parentRoles.isEmpty
                      ? null
                      : (value) => setState(() => _selectedParentRole = value),
                  items: _parentRoles.map<DropdownMenuItem<String>>((role) {
                    return DropdownMenuItem<String>(
                      value: role['value'],
                      child: Text(
                        role['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        if (_parentRoles.isEmpty && !_loadingParentRoles)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No eligible parent roles found. Create management roles first.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFF59E0B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // Update the form to use the new parent role dropdown
  Widget build(BuildContext context) {
    return Dialog(
      // ... existing dialog code ...
      child: Column(
        children: [
          // ... existing header ...

          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... existing basic information section ...

                    // Updated Category and Parent Role Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Category',
                            hint: 'Select role category',
                            icon: Icons.category_rounded,
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (value) => setState(() => _selectedCategory = value),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildParentRoleDropdown(), // Use the new dropdown
                        ),
                      ],
                    ),

                    // ... rest of the form ...
                  ],
                ),
              ),
            ),
          ),

          // ... existing action buttons ...
        ],
      ),
    );
  }
}

// Update AuthApiService to include a method for fetching roles
class AuthApiService {
  // ... existing code ...

  static Future<List<Role>> getAvailableParentRoles() async {
    try {
      // Get roles that can be parent roles (management categories)
      final response = await http.get(
        Uri.parse('$baseUrl/roles/?category=executive,operations_management,technical_management,system_admin'),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['results'];
        return data.map((json) => Role.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load parent roles');
      }
    } catch (e) {
      throw Exception('Error fetching parent roles: $e');
    }
  }
}*/
