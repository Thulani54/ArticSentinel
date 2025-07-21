import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../constants/Constants.dart';
import '../../custom_widgets/customCard.dart';
import '../../models/billing_management.dart';
import '../../widgets/compact_header.dart';

class BillManagement extends StatefulWidget {
  const BillManagement({super.key});

  @override
  State<BillManagement> createState() => _BillManagementState();
}

class _BillManagementState extends State<BillManagement>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String _selectedFilter = 'All';
  bool _isGridView = false;
  List<BillingManagement> _allBills = [];
  List<BillingManagement> _filteredBills = [];
  Map<String, dynamic> _statistics = {};

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
    _loadBills();
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
    _filterBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);

    try {
      await _getAllBillings('All');
      _calculateStatistics();
      _animationController.forward();
    } catch (e) {
      _showErrorSnackBar('Failed to load bills: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStatistics() {
    final totalBills = _allBills.length;
    final recurringBills =
        _allBills.where((bill) => bill.type == 'Recurring').length;
    final oneTimeBills =
        _allBills.where((bill) => bill.type == 'One-time').length;
    final paidBills = _allBills.where((bill) => bill.status == 'Paid').length;
    final pendingBills =
        _allBills.where((bill) => bill.status == 'Sent').length;
    final draftBills = _allBills.where((bill) => bill.status == 'Draft').length;
    final totalAmount = _allBills.fold(0.0, (sum, bill) => sum + bill.amount);

    _statistics = {
      'total_bills': totalBills,
      'recurring_bills': recurringBills,
      'one_time_bills': oneTimeBills,
      'paid_bills': paidBills,
      'pending_bills': pendingBills,
      'draft_bills': draftBills,
      'total_amount': totalAmount,
    };
  }

  Future<void> _getAllBillings(String billFilter) async {
    // Mock data for demonstration
    String jsonString = '''
[
    {
        "id": 1,
        "sentDate": "2024-10-01T12:00:00Z",
        "description": "Payment for services rendered",
        "amount": 150.00,
        "recipients": "John Doe",
        "dueDate": "2024-11-01T12:00:00Z",
        "status": "Paid",
        "type": "Recurring"
    },
    {
        "id": 2,
        "sentDate": "2024-10-02T09:30:00Z",
        "description": "Invoice #1234",
        "amount": 200.50,
        "recipients": "Jane Smith",
        "dueDate": "2024-10-15T12:00:00Z",
        "status": "Draft",
        "type": "One-time"
    },
    {
        "id": 3,
        "sentDate": "2024-10-03T15:45:00Z",
        "description": "Consulting fee",
        "amount": 300.75,
        "recipients": "Acme Corp.",
        "dueDate": "2024-11-03T12:00:00Z",
        "status": "Sent",
        "type": "Recurring"
    },
    {
        "id": 4,
        "sentDate": "2024-10-04T11:15:00Z",
        "description": "Monthly subscription",
        "amount": 29.99,
        "recipients": "Tech Solutions",
        "dueDate": "2024-10-31T12:00:00Z",
        "status": "Paid",
        "type": "Recurring"
    },
    {
        "id": 5,
        "sentDate": "2024-10-05T08:00:00Z",
        "description": "Refund for cancellation",
        "amount": 75.00,
        "recipients": "Alice Johnson",
        "dueDate": "2024-10-20T12:00:00Z",
        "status": "Paid",
        "type": "One-time"
    }
]
''';

    List<dynamic> billList = jsonDecode(jsonString);
    _allBills =
        billList.map((item) => BillingManagement.fromMap(item)).toList();
    _filteredBills = List.from(_allBills);
  }

  void _filterBills() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredBills = _allBills.where((bill) {
        bool matchesSearch = query.isEmpty ||
            bill.description.toLowerCase().contains(query) ||
            bill.recipients.toLowerCase().contains(query) ||
            bill.status.toLowerCase().contains(query) ||
            bill.amount.toString().contains(query);

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Recurring' && bill.type == 'Recurring') ||
            (_selectedFilter == 'One-time' && bill.type == 'One-time') ||
            (_selectedFilter == 'Paid' && bill.status == 'Paid') ||
            (_selectedFilter == 'Sent' && bill.status == 'Sent') ||
            (_selectedFilter == 'Draft' && bill.status == 'Draft');

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

  List<_BillStatCard> get billStatistics {
    return [
      _BillStatCard(
        title: 'Total Bills',
        value: '${_statistics['total_bills'] ?? 0}',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _BillStatCard(
        title: 'Recurring',
        value: '${_statistics['recurring_bills'] ?? 0}',
        icon: Icons.repeat_rounded,
        color: const Color(0xFF10B981),
      ),
      _BillStatCard(
        title: 'Paid Bills',
        value: '${_statistics['paid_bills'] ?? 0}',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF06B6D4),
      ),
      _BillStatCard(
        title: 'Total Amount',
        value: 'R${(_statistics['total_amount'] ?? 0).toStringAsFixed(2)}',
        icon: Icons.monetization_on_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _BillStatCard(
        title: 'Pending',
        value: '${_statistics['pending_bills'] ?? 0}',
        icon: Icons.pending_rounded,
        color: const Color(0xFFF59E0B),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
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

                      // Bills Display
                      _buildBillsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendBill,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Send Bill',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const CompactHeader(
      title: "Billing",
      description: "Manage billing and payment information",
      icon: Icons.credit_card_rounded,
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
              "Billing Overview",
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
            itemCount: billStatistics.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final stat = billStatistics[index];
              return _buildStatCard(stat, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(_BillStatCard stat, int index) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 1:
            _selectedFilter = 'Recurring';
            break;
          case 2:
            _selectedFilter = 'Paid';
            break;
          case 4:
            _selectedFilter = 'Sent';
            break;
          default:
            _selectedFilter = 'All';
            break;
        }
        _filterBills();
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stat.color.withOpacity(0.2)),
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
                    color: stat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat.icon,
                    color: stat.color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  stat.value.contains('R')
                      ? stat.value.split('R')[1]
                      : stat.value,
                  style: GoogleFonts.inter(
                    fontSize: stat.value.contains('R') ? 16 : 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            if (stat.value.contains('R')) ...[
              const SizedBox(height: 4),
              Text(
                'R${stat.value.split('R')[1]}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: stat.color,
                ),
              ),
            ],
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
                        'Search bills by description, recipient, or amount...',
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
                      : const Color(0xFF3B82F6),
                  side: BorderSide(
                    color: _selectedFilter == 'All'
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF3B82F6),
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
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isGridView = true),
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: _isGridView
                            ? const Color(0xFF3B82F6)
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
                    _filterBills();
                  },
                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                  labelStyle: GoogleFonts.inter(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                  deleteIconColor: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillsSection() {
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
                Icons.receipt_rounded,
                size: 20,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Bills (${_filteredBills.length})",
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
            : _filteredBills.isEmpty
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
              Icons.receipt_long_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No bills found',
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
                  : 'Get started by sending your first bill',
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
                  _filterBills();
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
      itemCount: _filteredBills.length,
      itemBuilder: (context, index) {
        final bill = _filteredBills[index];
        return _buildBillCard(bill);
      },
    );
  }

  Widget _buildBillCard(BillingManagement bill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(bill.status).withOpacity(0.3),
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
                  color: _getStatusColor(bill.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  bill.type == 'Recurring'
                      ? Icons.repeat_rounded
                      : Icons.receipt_rounded,
                  size: 16,
                  color: _getStatusColor(bill.status),
                ),
              ),
              const Spacer(),
              _buildQuickActions(bill),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bill.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            bill.recipients,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'R${bill.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(bill.status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bill.status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                  child: Text(
                    'Type',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Recipients',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Amount',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Due Date',
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
            itemCount: _filteredBills.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bill = _filteredBills[index];
              return _buildBillRow(bill, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(BillingManagement bill, int index) {
    return Container(
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

          // Type
          Expanded(
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bill.type == 'Recurring'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bill.type == 'Recurring'
                            ? Icons.repeat_rounded
                            : Icons.receipt_rounded,
                        size: 12,
                        color: bill.type == 'Recurring'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bill.type,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: bill.type == 'Recurring'
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sent: ${_formatDate(bill.sentDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Recipients
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bill.recipients,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Expanded(
            child: Text(
              'R${bill.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),

          // Due Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(bill.dueDate),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _getDueDateStatus(bill.dueDate),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _getDueDateColor(bill.dueDate),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(bill.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bill.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Actions
          _buildQuickActions(bill),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BillingManagement bill) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewBill(bill);
            break;
          case 'edit':
            _editBill(bill);
            break;
          case 'duplicate':
            _duplicateBill(bill);
            break;
          case 'delete':
            _deleteBill(bill);
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
                'Edit Bill',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              const Icon(Icons.content_copy_rounded,
                  size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'Duplicate',
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
                'Delete Bill',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
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
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                        color: const Color(0xFF3B82F6),
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
                      'Filter Bills',
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
                    'Recurring',
                    'One-time',
                    'Paid',
                    'Sent',
                    'Draft'
                  ].map((filter) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedFilter == filter
                              ? const Color(0xFF3B82F6)
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
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) {
                          setState(() => _selectedFilter = value!);
                          Navigator.pop(context);
                          _filterBills();
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

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF10B981);
      case 'sent':
        return const Color(0xFFF59E0B);
      case 'draft':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDueDateStatus(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference <= 7) {
      return 'Due in $difference days';
    } else {
      return 'Due in ${(difference / 7).ceil()} weeks';
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return const Color(0xFFEF4444);
    } else if (difference <= 7) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF10B981);
    }
  }

  // Action methods
  void _sendBill() {
    _showSuccessSnackBar('Send Bill functionality coming soon');
  }

  void _viewBill(BillingManagement bill) {
    _showSuccessSnackBar('View bill: ${bill.description}');
  }

  void _editBill(BillingManagement bill) {
    _showSuccessSnackBar('Edit bill: ${bill.description}');
  }

  void _duplicateBill(BillingManagement bill) {
    _showSuccessSnackBar('Duplicated bill: ${bill.description}');
  }

  void _deleteBill(BillingManagement bill) {
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
                      'Are you sure you want to delete this bill? This action cannot be undone.',
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
                            onPressed: () => Navigator.of(context).pop(),
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
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showSuccessSnackBar('Bill deleted successfully');
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
  }
}

// Helper class for statistics
class _BillStatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _BillStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
