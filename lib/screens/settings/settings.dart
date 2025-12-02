import 'dart:convert';

import 'package:artic_sentinel/screens/settings/security.dart';
import 'package:artic_sentinel/screens/settings/terms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../constants/Constants.dart';
import '../../custom_widgets/customCard.dart';
import '../../custom_widgets/customInput.dart';
import '../../models/province.dart';
import 'billing.dart';
import '../../widgets/compact_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  int sideColorIndex = 0;
  String itemIdIndex = "my_profile";
  List<SettingSideBar> sideBarList = [
    SettingSideBar(1, "my_profile", "Profile", Icons.person_outline_rounded),
    SettingSideBar(2, "security", "Security", Icons.security_rounded),
    SettingSideBar(3, "terms", "Terms Of Use", Icons.description_outlined),
    SettingSideBar(5, "billing", "Billing", Icons.credit_card_rounded),
  ];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    return Container(
      height: 1000,
      //backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const CompactHeader(
                title: "Settings",
                description: "Configure system preferences",
                icon: Icons.settings_rounded,
              ),

              const SizedBox(height: 24),

              // Main Content Area
              Expanded(
                child: isMobile
                    ? Column(
                        children: [
                          // Section selector dropdown
                          Container(
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
                            child: DropdownButton<String>(
                              value: itemIdIndex,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF64748B),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                              items: sideBarList.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item.item_id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: itemIdIndex == item.item_id
                                            ? Constants.ctaColorGreen
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(item.itemName),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  itemIdIndex = value!;
                                  sideColorIndex = sideBarList
                                      .indexWhere((item) => item.item_id == value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Content area (full width on mobile)
                          Expanded(
                            child: Container(
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
                              child: _buildContentArea(),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sidebar Navigation
                          Container(
                            width: 280,
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
                                // Navigation Header
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.menu_rounded,
                                        color: const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Navigation",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Navigation Items
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        ...sideBarList.asMap().entries.map((entry) {
                                          int index = entry.key;
                                          SettingSideBar item = entry.value;
                                          bool isSelected = sideColorIndex == index;

                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  sideColorIndex = index;
                                                  itemIdIndex = item.item_id;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration:
                                                    const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Constants.ctaColorGreen
                                                          .withOpacity(0.1)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Constants.ctaColorGreen
                                                            .withOpacity(0.3)
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      item.icon,
                                                      size: 20,
                                                      color: isSelected
                                                          ? Constants.ctaColorGreen
                                                          : const Color(0xFF64748B),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        item.itemName,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.w500,
                                                          color: isSelected
                                                              ? Constants
                                                                  .ctaColorGreen
                                                              : const Color(
                                                                  0xFF64748B),
                                                        ),
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Constants.ctaColorGreen,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),

                                        const Spacer(),

                                        // Delete Account Button
                                        Container(
                                          margin: const EdgeInsets.only(top: 20),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFECACA),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              // Handle delete account
                                            },
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Color(0xFFEF4444),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Delete Account",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFFEF4444),
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
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Content Area
                          Expanded(
                            child: Container(
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
                              child: _buildContentArea(),
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

  Widget _buildContentArea() {
    switch (itemIdIndex) {
      case "my_profile":
        return _buildProfileContent();
      case "security":
        return SecurityPage();
      case "terms":
        return TermsOfUse();
      case "billing":
        return BillManagement();
      default:
        return Container();
    }
  }

  Widget _buildProfileContent() {
    final isMobile = _isMobile(context);
    return Column(
      children: [
        // Profile Header with Tabs
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
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
                      color: Constants.ctaColorLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Constants.ctaColorLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profile Settings",
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        "Manage your personal and business information",
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Modern Tab Bar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  indicator: BoxDecoration(
                    color: Constants.ctaColorGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: "Personal Profile"),
                    Tab(text: "Business Profile"),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPersonalProfileTab(),
              _buildBusinessProfileTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalProfileTab() {
    final isMobile = _isMobile(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Constants.ctaColorLight.withOpacity(0.1),
                  Constants.ctaColorLight.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                          CupertinoIcons.person,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            Constants.myDisplayname,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Constants.ctaColorGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Workplace Admin",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Constants.ctaColorGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
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
                          CupertinoIcons.person,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.myDisplayname,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Constants.ctaColorGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Workplace Admin",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Constants.ctaColorGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 32),

          // Personal Information Section
          _buildInfoSection(
            "Personal Information",
            Icons.person_outline_rounded,
            [
              _buildInfoField("First Name", Constants.myFirstname),
              _buildInfoField("Last Name", Constants.myLastname),
              _buildInfoField("Email Address", Constants.myEmail),
              _buildInfoField("Address", Constants.myAddress),
              _buildInfoField("Country", Constants.myCountry),
              _buildInfoField("Postal Code", Constants.myPostalCode),
              _buildInfoField("Province/City", Constants.myProvince),
            ],
          ),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(
            onEdit: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => EditMyProfile(),
              );
            },
            onSave: () {
              // Handle save
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessProfileTab() {
    final isMobile = _isMobile(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Info Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            Constants.myBusinessName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        Constants.myBusinessName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 32),

          // Business Information Section
          _buildInfoSection(
            "Business Information",
            Icons.business_rounded,
            [
              _buildInfoField("Business Name", Constants.myBusinessName),
              _buildInfoField("Country", Constants.myBusinessNationality),
              _buildInfoField(
                  "Business Email", Constants.myBusinessSupportEmail),
              _buildInfoField(
                  "Phone Number", Constants.myBusinessSupportContactNumber),
              _buildInfoField(
                  "Address Line 1", Constants.myBusinessAddressLine1),
              _buildInfoField(
                  "Address Line 2", Constants.myBusinessAddressLine2),
              _buildInfoField("City", Constants.myBusinessCity),
              _buildInfoField("Province", Constants.myBusinessProvince),
              _buildInfoField("Postal Code", Constants.myBusinessPostalCode),
              _buildInfoField("VAT Number", Constants.myBusinessVatNumber),
              _buildInfoField("Registration Number",
                  Constants.myBusinessRegistrationNumber),
            ],
          ),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(
            onEdit: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => EditBusinessInfo(),
              );
            },
            onSave: () {
              // Handle save
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> fields) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
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
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: fields,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      {required VoidCallback onEdit, required VoidCallback onSave}) {
    final isMobile = _isMobile(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isMobile
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      "Edit Information",
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      "Save Changes",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorGreen,
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
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      "Edit Information",
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
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      "Save Changes",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorGreen,
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
    );
  }
}

class SettingSideBar {
  int id;
  String item_id;
  String itemName;
  IconData icon;

  SettingSideBar(this.id, this.item_id, this.itemName, this.icon);
}

class EditMyProfile extends StatefulWidget {
  const EditMyProfile({super.key});

  @override
  State<EditMyProfile> createState() => _EditMyProfileState();
}

class _EditMyProfileState extends State<EditMyProfile> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Profile Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final FocusNode firstNameFocusNode = FocusNode();
  final TextEditingController _lastNameController = TextEditingController();
  final FocusNode lastNameFocusNode = FocusNode();
  final TextEditingController _primaryContactEmailController =
      TextEditingController();
  final FocusNode primaryContactEmailFocusNode = FocusNode();
  final TextEditingController _primaryAddressController =
      TextEditingController();
  final FocusNode primaryAddressFocusNode = FocusNode();
  final TextEditingController _nationalityController = TextEditingController();
  final FocusNode nationalityFocusNode = FocusNode();
  final TextEditingController _postalCodeController = TextEditingController();
  final FocusNode postalCodeFocusNode = FocusNode();

  List<Province> provinceList = [];
  Province? selectedProvince;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _firstNameController.text = Constants.myFirstname;
    _lastNameController.text = Constants.myLastname;
    _primaryContactEmailController.text = Constants.myEmail;
    _primaryAddressController.text = Constants.myAddress;
    _nationalityController.text = Constants.myCountry;
    _postalCodeController.text = Constants.myPostalCode;
    getProvinces();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
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
                    Constants.ctaColorGreen.withOpacity(0.1),
                    Constants.ctaColorGreen.withOpacity(0.05),
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
                      color: Constants.ctaColorGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.ctaColorGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
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
                          'Edit Profile',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your personal information',
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
                      // Personal Information Section
                      _buildSectionHeader(
                          'Personal Information', Icons.person_outline_rounded),
                      const SizedBox(height: 20),

                      // First Name & Last Name Row
                      isMobile
                          ? Column(
                              children: [
                                _buildModernTextField(
                                  controller: _firstNameController,
                                  focusNode: firstNameFocusNode,
                                  label: 'First Name',
                                  hint: 'Enter your first name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'First name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _lastNameController,
                                  focusNode: lastNameFocusNode,
                                  label: 'Last Name',
                                  hint: 'Enter your last name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Last name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _firstNameController,
                                    focusNode: firstNameFocusNode,
                                    label: 'First Name',
                                    hint: 'Enter your first name',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'First name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _lastNameController,
                                    focusNode: lastNameFocusNode,
                                    label: 'Last Name',
                                    hint: 'Enter your last name',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Last name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 20),

                      // Email Field
                      _buildModernTextField(
                        controller: _primaryContactEmailController,
                        focusNode: primaryContactEmailFocusNode,
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value!)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Address Field
                      _buildModernTextField(
                        controller: _primaryAddressController,
                        focusNode: primaryAddressFocusNode,
                        label: 'Street Address',
                        hint: 'Enter your street address',
                        icon: Icons.home_outlined,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Country & Postal Code Row
                      isMobile
                          ? Column(
                              children: [
                                _buildModernTextField(
                                  controller: _nationalityController,
                                  focusNode: nationalityFocusNode,
                                  label: 'Country',
                                  hint: 'Enter your country',
                                  icon: Icons.public_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Country is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _postalCodeController,
                                  focusNode: postalCodeFocusNode,
                                  label: 'Postal Code',
                                  hint: 'Enter postal code',
                                  icon: Icons.markunread_mailbox_outlined,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Postal code is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _nationalityController,
                                    focusNode: nationalityFocusNode,
                                    label: 'Country',
                                    hint: 'Enter your country',
                                    icon: Icons.public_rounded,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Country is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _postalCodeController,
                                    focusNode: postalCodeFocusNode,
                                    label: 'Postal Code',
                                    hint: 'Enter postal code',
                                    icon: Icons.markunread_mailbox_outlined,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Postal code is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 20),

                      // Province Dropdown
                      _buildProvinceDropdown(),

                      const SizedBox(height: 32),
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
                      onPressed: _isSaving ? null : _saveProfile,
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
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorGreen,
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
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
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
          focusNode: focusNode,
          keyboardType: keyboardType,
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
              borderSide: BorderSide(color: Constants.ctaColorGreen, width: 2),
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

  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Province/State',
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
          child: DropdownButtonFormField<Province>(
            value: selectedProvince,
            decoration: InputDecoration(
              hintText: 'Select your province',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Color(0xFF6B7280),
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
            validator: (value) {
              if (value == null) {
                return 'Please select a province';
              }
              return null;
            },
            onChanged: (Province? newValue) {
              setState(() {
                selectedProvince = newValue;
              });
            },
            items: provinceList
                .map<DropdownMenuItem<Province>>((Province province) {
              return DropdownMenuItem<Province>(
                value: province,
                child: Text(
                  province.name,
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a province'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update constants
      Constants.myFirstname = _firstNameController.text.trim();
      Constants.myLastname = _lastNameController.text.trim();
      Constants.myEmail = _primaryContactEmailController.text.trim();
      Constants.myAddress = _primaryAddressController.text.trim();
      Constants.myCountry = _nationalityController.text.trim();
      Constants.myPostalCode = _postalCodeController.text.trim();
      Constants.myProvince = selectedProvince!.name;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> getProvinces() async {
    setState(() {
      _isLoading = true;
    });

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
      'POST',
      Uri.parse("https://qa.miinsightsapps.net/parlour_config/parlour-config/"),
    );
    request.body = json.encode({"identityNumber": ""});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode != 200) {
        // Use fallback data for South African provinces
        String jsonData = '''
        [
          {"id": 1, "name": "Eastern Cape"},
          {"id": 2, "name": "Free State"},
          {"id": 3, "name": "Gauteng"},
          {"id": 4, "name": "KwaZulu-Natal"},
          {"id": 5, "name": "Limpopo"},
          {"id": 6, "name": "Mpumalanga"},
          {"id": 7, "name": "North West"},
          {"id": 8, "name": "Northern Cape"},
          {"id": 9, "name": "Western Cape"}
        ]
        ''';

        List<dynamic> provList = jsonDecode(jsonData);
        provinceList.clear();

        for (var prov in provList) {
          Province province = Province.fromJson(prov);
          provinceList.add(province);
        }

        // Find and set the current province if it exists
        if (Constants.myProvince.isNotEmpty) {
          try {
            selectedProvince = provinceList.firstWhere(
              (province) =>
                  province.name.toLowerCase() ==
                  Constants.myProvince.toLowerCase(),
            );
          } catch (e) {
            // Province not found, leave as null
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print(response.reasonPhrase);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("An error occurred: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _primaryContactEmailController.dispose();
    _primaryAddressController.dispose();
    _nationalityController.dispose();
    _postalCodeController.dispose();
    firstNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    primaryContactEmailFocusNode.dispose();
    primaryAddressFocusNode.dispose();
    nationalityFocusNode.dispose();
    postalCodeFocusNode.dispose();
    super.dispose();
  }
}

class EditBusinessInfo extends StatefulWidget {
  const EditBusinessInfo({super.key});

  @override
  State<EditBusinessInfo> createState() => _EditBusinessInfoState();
}

class _EditBusinessInfoState extends State<EditBusinessInfo> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Business Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final FocusNode businessNameFocusNode = FocusNode();
  final TextEditingController _countryController = TextEditingController();
  final FocusNode countryFocusNode = FocusNode();
  final TextEditingController _businessEmailController =
      TextEditingController();
  final FocusNode businessEmailFocusNode = FocusNode();
  final TextEditingController _businessContactNumberController =
      TextEditingController();
  final FocusNode businessContactNumberFocusNode = FocusNode();
  final TextEditingController _address1Controller = TextEditingController();
  final FocusNode address1FocusNode = FocusNode();
  final TextEditingController _address2Controller = TextEditingController();
  final FocusNode address2FocusNode = FocusNode();
  final TextEditingController _businessCityController = TextEditingController();
  final FocusNode businessCityFocusNode = FocusNode();
  final TextEditingController _businessPostalCodeController =
      TextEditingController();
  final FocusNode businessPostalCodeFocusNode = FocusNode();
  final TextEditingController _vatNumberController = TextEditingController();
  final FocusNode vatNumberFocusNode = FocusNode();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final FocusNode registrationNumberFocusNode = FocusNode();

  List<Province> provinceList = [];
  Province? selectedProvince;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _businessNameController.text = Constants.myBusinessName;
    _businessCityController.text = Constants.myBusinessCity;
    _countryController.text = Constants.myBusinessNationality;
    _businessEmailController.text = Constants.myBusinessSupportEmail;
    _address1Controller.text = Constants.myBusinessAddressLine1;
    _address2Controller.text = Constants.myBusinessAddressLine2;
    _businessPostalCodeController.text = Constants.myBusinessPostalCode;
    _vatNumberController.text = Constants.myBusinessVatNumber;
    _registrationNumberController.text = Constants.myBusinessRegistrationNumber;
    _businessContactNumberController.text =
        Constants.myBusinessSupportContactNumber;
    getProvinces();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
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
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF10B981).withOpacity(0.05),
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
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.business_rounded,
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
                          'Edit Business Profile',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your business information',
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
                          'Basic Information', Icons.business_rounded),
                      const SizedBox(height: 20),

                      // Business Name
                      _buildModernTextField(
                        controller: _businessNameController,
                        focusNode: businessNameFocusNode,
                        label: 'Business Name',
                        hint: 'Enter your business name',
                        icon: Icons.business_rounded,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Business name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Country & Email Row
                      isMobile
                          ? Column(
                              children: [
                                _buildModernTextField(
                                  controller: _countryController,
                                  focusNode: countryFocusNode,
                                  label: 'Country',
                                  hint: 'Enter country',
                                  icon: Icons.public_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Country is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _businessEmailController,
                                  focusNode: businessEmailFocusNode,
                                  label: 'Business Email',
                                  hint: 'Enter business email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value!)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _countryController,
                                    focusNode: countryFocusNode,
                                    label: 'Country',
                                    hint: 'Enter country',
                                    icon: Icons.public_rounded,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Country is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _businessEmailController,
                                    focusNode: businessEmailFocusNode,
                                    label: 'Business Email',
                                    hint: 'Enter business email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value!)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 20),

                      // Phone Number
                      _buildModernTextField(
                        controller: _businessContactNumberController,
                        focusNode: businessContactNumberFocusNode,
                        label: 'Business Phone Number',
                        hint: 'Enter business phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Address Information Section
                      _buildSectionHeader(
                          'Address Information', Icons.location_on_outlined),
                      const SizedBox(height: 20),

                      // Address Line 1
                      _buildModernTextField(
                        controller: _address1Controller,
                        focusNode: address1FocusNode,
                        label: 'Address Line 1',
                        hint: 'Enter address line 1',
                        icon: Icons.home_outlined,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Address line 1 is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Address Line 2 (Optional)
                      _buildModernTextField(
                        controller: _address2Controller,
                        focusNode: address2FocusNode,
                        label: 'Address Line 2 (Optional)',
                        hint: 'Enter address line 2',
                        icon: Icons.home_outlined,
                      ),

                      const SizedBox(height: 20),

                      // City & Province Row
                      isMobile
                          ? Column(
                              children: [
                                _buildModernTextField(
                                  controller: _businessCityController,
                                  focusNode: businessCityFocusNode,
                                  label: 'City',
                                  hint: 'Enter city',
                                  icon: Icons.location_city_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'City is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildProvinceDropdown(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _businessCityController,
                                    focusNode: businessCityFocusNode,
                                    label: 'City',
                                    hint: 'Enter city',
                                    icon: Icons.location_city_rounded,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'City is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildProvinceDropdown(),
                                ),
                              ],
                            ),

                      const SizedBox(height: 20),

                      // Postal Code
                      _buildModernTextField(
                        controller: _businessPostalCodeController,
                        focusNode: businessPostalCodeFocusNode,
                        label: 'Postal Code',
                        hint: 'Enter postal code',
                        icon: Icons.markunread_mailbox_outlined,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Postal code is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Legal Information Section
                      _buildSectionHeader(
                          'Legal Information', Icons.description_outlined),
                      const SizedBox(height: 20),

                      // VAT & Registration Row
                      isMobile
                          ? Column(
                              children: [
                                _buildModernTextField(
                                  controller: _vatNumberController,
                                  focusNode: vatNumberFocusNode,
                                  label: 'VAT Number',
                                  hint: 'Enter VAT number',
                                  icon: Icons.receipt_long_outlined,
                                ),
                                const SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _registrationNumberController,
                                  focusNode: registrationNumberFocusNode,
                                  label: 'Registration Number',
                                  hint: 'Enter registration number',
                                  icon: Icons.verified_outlined,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _vatNumberController,
                                    focusNode: vatNumberFocusNode,
                                    label: 'VAT Number',
                                    hint: 'Enter VAT number',
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _registrationNumberController,
                                    focusNode: registrationNumberFocusNode,
                                    label: 'Registration Number',
                                    hint: 'Enter registration number',
                                    icon: Icons.verified_outlined,
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 32),
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
                      onPressed: _isSaving ? null : _saveBusinessInfo,
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
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
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
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
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
          focusNode: focusNode,
          keyboardType: keyboardType,
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
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
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

  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Province/State',
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
          child: DropdownButtonFormField<Province>(
            value: selectedProvince,
            decoration: InputDecoration(
              hintText: 'Select province',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Color(0xFF6B7280),
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
            validator: (value) {
              if (value == null) {
                return 'Please select a province';
              }
              return null;
            },
            onChanged: (Province? newValue) {
              setState(() {
                selectedProvince = newValue;
              });
            },
            items: provinceList
                .map<DropdownMenuItem<Province>>((Province province) {
              return DropdownMenuItem<Province>(
                value: province,
                child: Text(
                  province.name,
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

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a province'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update constants
      Constants.myBusinessName = _businessNameController.text.trim();
      Constants.myBusinessCity = _businessCityController.text.trim();
      Constants.myBusinessNationality = _countryController.text.trim();
      Constants.myBusinessSupportContactNumber =
          _businessContactNumberController.text.trim();
      Constants.myBusinessSupportEmail = _businessEmailController.text.trim();
      Constants.myBusinessAddressLine1 = _address1Controller.text.trim();
      Constants.myBusinessAddressLine2 = _address2Controller.text.trim();
      Constants.myBusinessPostalCode =
          _businessPostalCodeController.text.trim();
      Constants.myBusinessVatNumber = _vatNumberController.text.trim();
      Constants.myBusinessRegistrationNumber =
          _registrationNumberController.text.trim();
      Constants.myBusinessProvince = selectedProvince!.name;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Business information updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving business information: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> getProvinces() async {
    setState(() {
      _isLoading = true;
    });

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
      'POST',
      Uri.parse("https://qa.miinsightsapps.net/parlour_config/parlour-config/"),
    );
    request.body = json.encode({"identityNumber": ""});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode != 200) {
        // Use fallback data for South African provinces
        String jsonData = '''
        [
          {"id": 1, "name": "Eastern Cape"},
          {"id": 2, "name": "Free State"},
          {"id": 3, "name": "Gauteng"},
          {"id": 4, "name": "KwaZulu-Natal"},
          {"id": 5, "name": "Limpopo"},
          {"id": 6, "name": "Mpumalanga"},
          {"id": 7, "name": "North West"},
          {"id": 8, "name": "Northern Cape"},
          {"id": 9, "name": "Western Cape"}
        ]
        ''';

        List<dynamic> provList = jsonDecode(jsonData);
        provinceList.clear();

        for (var prov in provList) {
          Province province = Province.fromJson(prov);
          provinceList.add(province);
        }

        // Find and set the current province if it exists
        if (Constants.myBusinessProvince.isNotEmpty) {
          try {
            selectedProvince = provinceList.firstWhere(
              (province) =>
                  province.name.toLowerCase() ==
                  Constants.myBusinessProvince.toLowerCase(),
            );
          } catch (e) {
            // Province not found, leave as null
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print(response.reasonPhrase);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("An error occurred: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _countryController.dispose();
    _businessEmailController.dispose();
    _businessContactNumberController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _businessCityController.dispose();
    _businessPostalCodeController.dispose();
    _vatNumberController.dispose();
    _registrationNumberController.dispose();
    businessNameFocusNode.dispose();
    countryFocusNode.dispose();
    businessEmailFocusNode.dispose();
    businessContactNumberFocusNode.dispose();
    address1FocusNode.dispose();
    address2FocusNode.dispose();
    businessCityFocusNode.dispose();
    businessPostalCodeFocusNode.dispose();
    vatNumberFocusNode.dispose();
    registrationNumberFocusNode.dispose();
    super.dispose();
  }
}
