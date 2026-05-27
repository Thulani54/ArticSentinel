import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _industriesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _newsletterController = TextEditingController();

  bool _mobileMenuOpen = false;

  void _scrollToSection(GlobalKey key) {
    setState(() => _mobileMenuOpen = false);
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _newsletterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, isMobile),
          if (_mobileMenuOpen && isMobile) _buildMobileMenu(context),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeroSection(context, isMobile),
                  _buildTrustedBySection(context, isMobile),
                  _buildAboutSection(context, isMobile),
                  _buildStatsSection(context, isMobile),
                  _buildFeaturesSection(context, isMobile),
                  _buildIndustriesSection(context, isMobile),
                  _buildHowItWorksSection(context, isMobile),
                  _buildWhyChooseUsSection(context, isMobile),
                  _buildPricingSection(context, isMobile),
                  _buildTestimonialsSection(context, isMobile),
                  _buildFaqSection(context, isMobile),
                  _buildContactSection(context, isMobile),
                  _buildNewsletterSection(context, isMobile),
                  _buildCtaSection(context, isMobile),
                  _buildFooter(context, isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Image.asset("lib/assets/artic_logo.png", height: 36, width: 36),
              const SizedBox(width: 10),
              Text(
                "Artic Sentinel",
                style: GoogleFonts.lato(
                  fontSize: isMobile ? 18 : 22,
                  color: Constants.ctaColorLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Desktop nav
          if (!isMobile)
            Row(
              children: [
                _navLink("About", () => _scrollToSection(_aboutKey)),
                const SizedBox(width: 24),
                _navLink("Features", () => _scrollToSection(_featuresKey)),
                const SizedBox(width: 24),
                _navLink("Industries", () => _scrollToSection(_industriesKey)),
                const SizedBox(width: 24),
                _navLink("Pricing", () => _scrollToSection(_pricingKey)),
                const SizedBox(width: 24),
                _navLink("FAQ", () => _scrollToSection(_faqKey)),
                const SizedBox(width: 24),
                _navLink("Contact", () => _scrollToSection(_contactKey)),
              ],
            ),
          // Auth buttons + hamburger
          Row(
            children: [
              if (!isMobile) ...[
                TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    backgroundColor: Constants.ctaColorLight,
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(color: Constants.ctaColorLight),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.lato(color: Constants.ctaColorLight, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              if (isMobile)
                IconButton(
                  onPressed: () => setState(() => _mobileMenuOpen = !_mobileMenuOpen),
                  icon: Icon(
                    _mobileMenuOpen ? Icons.close : Icons.menu,
                    color: Constants.ctaColorLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenu(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mobileNavItem("About", () => _scrollToSection(_aboutKey)),
          _mobileNavItem("Features", () => _scrollToSection(_featuresKey)),
          _mobileNavItem("Industries", () => _scrollToSection(_industriesKey)),
          _mobileNavItem("Pricing", () => _scrollToSection(_pricingKey)),
          _mobileNavItem("FAQ", () => _scrollToSection(_faqKey)),
          _mobileNavItem("Contact", () => _scrollToSection(_contactKey)),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Text('Login', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => context.go('/signup'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(color: Constants.ctaColorLight),
                    ),
                  ),
                  child: Text('Sign Up', style: GoogleFonts.lato(color: Constants.ctaColorLight, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _mobileNavItem(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: GoogleFonts.lato(fontSize: 15, color: Constants.ctaColorLight, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          label,
          style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaColorLight, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 56 : 100,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF222b45), Color(0xFF1a2540), Color(0xFF0f172a)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              "IoT Monitoring Platform for Africa",
              style: GoogleFonts.lato(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          const SizedBox(height: 28),
          Image.asset("lib/assets/artic_logo.png", height: isMobile ? 64 : 90, width: isMobile ? 64 : 90),
          const SizedBox(height: 28),
          Text(
            "Smart Monitoring.\nReal-Time Control.\nTotal Peace of Mind.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: isMobile ? 28 : 48,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              "Protect your assets, livestock, and cold chain operations with real-time monitoring, "
              "intelligent alerts, and powerful analytics — all from a single dashboard accessible anywhere.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: isMobile ? 15 : 18,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              _heroButton(label: 'Start Free Trial', onPressed: () => context.go('/signup'), filled: true),
              _heroButton(label: 'Login to Dashboard', onPressed: () => context.go('/login'), filled: false),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "No credit card required  •  Free 14-day trial  •  Cancel anytime",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _heroButton({required String label, required VoidCallback onPressed, required bool filled}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: filled ? BorderSide.none : const BorderSide(color: Colors.white, width: 1.5),
        ),
        backgroundColor: filled ? Constants.ctaColorGreen : Colors.transparent,
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── TRUSTED BY ───────────────────────────────────────────────────────────────

  Widget _buildTrustedBySection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 28),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Text(
            "TRUSTED BY BUSINESSES ACROSS SOUTH AFRICA",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Constants.ctaTextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 24 : 48,
            runSpacing: 16,
            children: [
              _trustBadge(Icons.agriculture, "Agriculture"),
              _trustBadge(Icons.local_shipping, "Logistics"),
              _trustBadge(Icons.restaurant, "Food & Beverage"),
              _trustBadge(Icons.medical_services, "Pharmaceuticals"),
              _trustBadge(Icons.store, "Retail"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Constants.ctaTextColor),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.lato(fontSize: 13, color: Constants.ctaTextColor, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── ABOUT ────────────────────────────────────────────────────────────────────

  Widget _buildAboutSection(BuildContext context, bool isMobile) {
    return Container(
      key: _aboutKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel("ABOUT US"),
          const SizedBox(height: 12),
          Text(
            "Who We Are",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              "Artic Sentinel is a proudly South African IoT monitoring platform built for businesses "
              "that depend on reliable cold chain operations, livestock management, and remote asset tracking. "
              "Founded with the mission to bring enterprise-grade monitoring to African businesses, we combine "
              "cutting-edge sensor technology with intelligent software to provide full visibility and control "
              "over your critical operations — no matter where you are.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: isMobile ? 15 : 17, color: Constants.ctaTextColor, height: 1.7),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _aboutCard(
                icon: Icons.flag,
                title: "Our Mission",
                description: "To provide accessible, reliable monitoring solutions that help African businesses "
                    "prevent losses, ensure regulatory compliance, and operate more efficiently.",
                isMobile: isMobile,
              ),
              _aboutCard(
                icon: Icons.remove_red_eye,
                title: "Our Vision",
                description: "A connected Africa where no cold chain breaks silently, no livestock goes unmonitored, "
                    "and every business has the tools to protect what matters most.",
                isMobile: isMobile,
              ),
              _aboutCard(
                icon: Icons.security,
                title: "Security First",
                description: "Enterprise-grade encryption, role-based access control, and secure data storage. "
                    "Your operational data is protected with the highest standards.",
                isMobile: isMobile,
              ),
              _aboutCard(
                icon: Icons.public,
                title: "Built for Africa",
                description: "Designed for the unique challenges of the African market — unreliable connectivity, "
                    "vast distances, extreme temperatures, and diverse farm environments.",
                isMobile: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aboutCard({required IconData icon, required String title, required String description, required bool isMobile}) {
    return SizedBox(
      width: isMobile ? double.infinity : 280,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Constants.ctaColorGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Constants.ctaColorGreen, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.lato(fontSize: 17, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(description, style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaTextColor, height: 1.6)),
          ],
        ),
      ),
    );
  }

  // ─── STATS ────────────────────────────────────────────────────────────────────

  Widget _buildStatsSection(BuildContext context, bool isMobile) {
    final stats = [
      {'value': '24/7', 'label': 'Real-Time Monitoring'},
      {'value': '99.9%', 'label': 'Platform Uptime'},
      {'value': '<30s', 'label': 'Alert Response Time'},
      {'value': '500+', 'label': 'Active Devices'},
      {'value': '50+', 'label': 'Businesses Served'},
      {'value': '1M+', 'label': 'Data Points Daily'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 40 : 56),
      color: Constants.ctaColorLight,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: isMobile ? 20 : 48,
        runSpacing: 24,
        children: stats.map((stat) {
          return SizedBox(
            width: isMobile ? 130 : 160,
            child: Column(
              children: [
                Text(
                  stat['value']!,
                  style: GoogleFonts.lato(fontSize: isMobile ? 26 : 34, color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: isMobile ? 12 : 14, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── FEATURES ─────────────────────────────────────────────────────────────────

  Widget _buildFeaturesSection(BuildContext context, bool isMobile) {
    final features = [
      {'icon': Icons.thermostat, 'title': 'Cold Chain Monitoring', 'description': 'Real-time temperature and humidity tracking with configurable thresholds. Get instant alerts when conditions breach safe ranges. Full compliance reporting.'},
      {'icon': Icons.pets, 'title': 'Livestock Management', 'description': 'Track animal health, location, and activity levels. Manage herds with IoT-enabled wearable devices and automated health scoring.'},
      {'icon': Icons.notifications_active, 'title': 'Smart Alerts', 'description': 'Multi-channel notifications via SMS, email, and push alerts. Customizable trigger rules with escalation paths so nothing falls through the cracks.'},
      {'icon': Icons.map, 'title': 'Geo-Fencing', 'description': 'Define virtual boundaries for assets and livestock. Instant alerts when anything moves outside designated zones with GPS tracking history.'},
      {'icon': Icons.bar_chart, 'title': 'Reports & Analytics', 'description': 'Comprehensive historical reports, trend analysis, and exportable PDF/CSV documents for audits, compliance, and operational insights.'},
      {'icon': Icons.devices, 'title': 'Device Management', 'description': 'Centralized control for all IoT devices. Monitor battery, connectivity, firmware versions, and performance metrics from one dashboard.'},
      {'icon': Icons.schedule, 'title': 'Scheduling & Automation', 'description': 'Automate relay controls, irrigation, lighting, and ventilation. Time-based or condition-based triggers with manual override capability.'},
      {'icon': Icons.build, 'title': 'Maintenance Tracking', 'description': 'Preventive and corrective maintenance management. Schedule inspections, track service history, and reduce unplanned downtime.'},
      {'icon': Icons.people, 'title': 'Team Management', 'description': 'Multi-user access with granular role-based permissions. Assign responsibilities, track activities, and maintain full accountability.'},
      {'icon': Icons.sms, 'title': 'Communication Hub', 'description': 'Send bulk SMS and email notifications to your team. Template-based messaging for alerts, reports, and scheduled communications.'},
      {'icon': Icons.electric_bolt, 'title': 'Relay Control', 'description': 'Remote on/off control for connected equipment. Manage compressors, pumps, fans, and more from your phone or desktop.'},
      {'icon': Icons.health_and_safety, 'title': 'Health & Wellness', 'description': 'Monitor environmental conditions affecting worker safety. Track air quality, temperature extremes, and generate compliance reports.'},
    ];

    return Container(
      key: _featuresKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          _sectionLabel("FEATURES"),
          const SizedBox(height: 12),
          Text(
            "Powerful Features for Modern Operations",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Everything you need to monitor, control, and optimize — in one platform",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 14 : 16, color: Constants.ctaTextColor),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features.map((f) => _featureCard(f, isMobile)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(Map<String, dynamic> feature, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(feature['icon'] as IconData, color: Constants.ctaColorLight, size: 24),
            ),
            const SizedBox(height: 14),
            Text(feature['title'] as String, style: GoogleFonts.lato(fontSize: 16, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(feature['description'] as String, style: GoogleFonts.lato(fontSize: 13, color: Constants.ctaTextColor, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ─── INDUSTRIES ───────────────────────────────────────────────────────────────

  Widget _buildIndustriesSection(BuildContext context, bool isMobile) {
    final industries = [
      {'icon': Icons.agriculture, 'title': 'Agriculture & Farming', 'description': 'Livestock tracking, crop monitoring, irrigation automation, and environmental sensing for modern farms.'},
      {'icon': Icons.ac_unit, 'title': 'Cold Chain & Logistics', 'description': 'Temperature monitoring for refrigerated transport, cold rooms, and warehouse storage facilities.'},
      {'icon': Icons.restaurant, 'title': 'Food & Beverage', 'description': 'HACCP compliance monitoring, food safety tracking, and storage condition management across the supply chain.'},
      {'icon': Icons.medical_services, 'title': 'Pharmaceuticals', 'description': 'Strict temperature control for medicine storage, vaccine cold chains, and regulatory compliance documentation.'},
      {'icon': Icons.solar_power, 'title': 'Energy & Utilities', 'description': 'Solar panel monitoring, water pump automation, generator tracking, and energy usage optimization.'},
      {'icon': Icons.warehouse, 'title': 'Warehousing', 'description': 'Multi-zone climate control, access monitoring, inventory condition tracking, and automated alerts.'},
    ];

    return Container(
      key: _industriesKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel("INDUSTRIES"),
          const SizedBox(height: 12),
          Text(
            "Industries We Serve",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Tailored solutions for diverse operational environments",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 14 : 16, color: Constants.ctaTextColor),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: industries.map((ind) {
              return SizedBox(
                width: isMobile ? double.infinity : 320,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Constants.ctaColorGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(ind['icon'] as IconData, color: Constants.ctaColorGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ind['title'] as String, style: GoogleFonts.lato(fontSize: 15, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(ind['description'] as String, style: GoogleFonts.lato(fontSize: 13, color: Constants.ctaTextColor, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── HOW IT WORKS ─────────────────────────────────────────────────────────────

  Widget _buildHowItWorksSection(BuildContext context, bool isMobile) {
    final steps = [
      {'step': '1', 'title': 'Create Account', 'description': 'Sign up in under 2 minutes. Set up your business profile and invite team members.'},
      {'step': '2', 'title': 'Connect Devices', 'description': 'Add your IoT sensors and devices. We support 100+ hardware types with guided setup.'},
      {'step': '3', 'title': 'Configure Rules', 'description': 'Set alert thresholds, geo-fences, schedules, and notification preferences.'},
      {'step': '4', 'title': 'Monitor & Act', 'description': 'View real-time data, receive instant alerts, generate reports, and control devices remotely.'},
    ];

    return Container(
      key: _howItWorksKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          _sectionLabel("HOW IT WORKS"),
          const SizedBox(height: 12),
          Text(
            "Up and Running in Minutes",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: steps.map((step) {
              return SizedBox(
                width: isMobile ? double.infinity : 240,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: Constants.ctaColorGreen, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(step['step']!, style: GoogleFonts.lato(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 16),
                    Text(step['title']!, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 17, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(step['description']!, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaTextColor, height: 1.5)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── WHY CHOOSE US ────────────────────────────────────────────────────────────

  Widget _buildWhyChooseUsSection(BuildContext context, bool isMobile) {
    final reasons = [
      {'icon': Icons.speed, 'title': 'Fast Setup', 'description': 'Get started in minutes, not days. No complex installations or IT teams required.'},
      {'icon': Icons.cloud_done, 'title': 'Cloud-Based', 'description': 'Access your dashboard from any device, anywhere. No software to install or maintain.'},
      {'icon': Icons.support_agent, 'title': 'Local Support', 'description': 'South African-based support team that understands your business and time zone.'},
      {'icon': Icons.lock, 'title': 'Data Privacy', 'description': 'POPIA-compliant data handling. Your data stays secure and under your control.'},
      {'icon': Icons.trending_up, 'title': 'Scalable', 'description': 'Start with one device, scale to thousands. Our platform grows with your business.'},
      {'icon': Icons.integration_instructions, 'title': 'Open API', 'description': 'Integrate with your existing systems. REST API available for custom integrations.'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel("WHY ARTIC SENTINEL"),
          const SizedBox(height: 12),
          Text(
            "Why Businesses Choose Us",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: reasons.map((r) {
              return SizedBox(
                width: isMobile ? double.infinity : 320,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(r['icon'] as IconData, color: Constants.ctaColorGreen, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'] as String, style: GoogleFonts.lato(fontSize: 16, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(r['description'] as String, style: GoogleFonts.lato(fontSize: 13, color: Constants.ctaTextColor, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── PRICING ──────────────────────────────────────────────────────────────────

  Widget _buildPricingSection(BuildContext context, bool isMobile) {
    return Container(
      key: _pricingKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          _sectionLabel("PRICING"),
          const SizedBox(height: 12),
          Text(
            "Simple, Transparent Pricing",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Start free. Upgrade as you grow. No hidden fees.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 14 : 16, color: Constants.ctaTextColor),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _pricingCard(
                title: "Starter",
                price: "Free",
                period: "14-day trial",
                features: ["Up to 5 devices", "Email alerts", "Basic reports", "1 user", "Community support"],
                ctaLabel: "Start Free Trial",
                highlighted: false,
                isMobile: isMobile,
                onPressed: () => context.go('/signup'),
              ),
              _pricingCard(
                title: "Professional",
                price: "R499",
                period: "/month",
                features: ["Up to 50 devices", "SMS & email alerts", "Advanced reports & PDF export", "5 users", "Geo-fencing", "Priority support"],
                ctaLabel: "Get Started",
                highlighted: true,
                isMobile: isMobile,
                onPressed: () => context.go('/signup'),
              ),
              _pricingCard(
                title: "Enterprise",
                price: "Custom",
                period: "contact us",
                features: ["Unlimited devices", "All alert channels", "Custom integrations", "Unlimited users", "API access", "Dedicated account manager", "SLA guarantee"],
                ctaLabel: "Contact Sales",
                highlighted: false,
                isMobile: isMobile,
                onPressed: () => _scrollToSection(_contactKey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pricingCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required String ctaLabel,
    required bool highlighted,
    required bool isMobile,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: highlighted ? Constants.ctaColorLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: highlighted ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: highlighted
              ? [BoxShadow(color: Constants.ctaColorLight.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            if (highlighted)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Constants.ctaColorGreen, borderRadius: BorderRadius.circular(12)),
                child: Text("Most Popular", style: GoogleFonts.lato(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            Text(title, style: GoogleFonts.lato(fontSize: 18, color: highlighted ? Colors.white : Constants.ctaColorLight, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: GoogleFonts.lato(fontSize: 36, color: highlighted ? Colors.white : Constants.ctaColorLight, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(period, style: GoogleFonts.lato(fontSize: 14, color: highlighted ? Colors.white.withValues(alpha: 0.7) : Constants.ctaTextColor)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: highlighted ? Constants.ctaColorGreen : Constants.ctaColorGreen),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: GoogleFonts.lato(fontSize: 13, color: highlighted ? Colors.white.withValues(alpha: 0.9) : Constants.ctaTextColor))),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: highlighted ? Colors.white : Constants.ctaColorLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: Text(ctaLabel, style: GoogleFonts.lato(color: highlighted ? Constants.ctaColorLight : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TESTIMONIALS ─────────────────────────────────────────────────────────────

  Widget _buildTestimonialsSection(BuildContext context, bool isMobile) {
    final testimonials = [
      {'quote': "Artic Sentinel has completely transformed how we manage our cold storage. We caught a compressor failure at 2am that would have cost us R200,000 in spoiled stock.", 'name': 'Johan van der Merwe', 'role': 'Operations Manager, FreshCo Logistics'},
      {'quote': "The livestock tracking gives us peace of mind we never had before. We can monitor 500 head of cattle across 3,000 hectares from our phones.", 'name': 'Thandi Nkosi', 'role': 'Farm Owner, Nkosi Cattle Ranch'},
      {'quote': "Setup was incredibly simple. Within a day we had all our cold rooms monitored and alerts configured. The support team was with us every step.", 'name': 'Ahmed Patel', 'role': 'Quality Manager, MedPharma Distribution'},
      {'quote': "The automated reports save us hours every week. Compliance audits that used to take days are now handled automatically.", 'name': 'Sarah Botha', 'role': 'Compliance Officer, GreenLeaf Foods'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel("TESTIMONIALS"),
          const SizedBox(height: 12),
          Text(
            "What Our Customers Say",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: testimonials.map((t) {
              return SizedBox(
                width: isMobile ? double.infinity : 300,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) => const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16)),
                      ),
                      const SizedBox(height: 14),
                      Text('"${t['quote']!}"', style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaTextColor, height: 1.6, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      Text(t['name']!, style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(t['role']!, style: GoogleFonts.lato(fontSize: 12, color: Constants.ctaTextColor)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── FAQ ──────────────────────────────────────────────────────────────────────

  Widget _buildFaqSection(BuildContext context, bool isMobile) {
    final faqs = [
      {'q': 'What types of devices does Artic Sentinel support?', 'a': 'We support a wide range of IoT devices including temperature sensors, GPS trackers, humidity sensors, relay controllers, and more. Our platform is hardware-agnostic and supports MQTT, HTTP, and LoRaWAN protocols.'},
      {'q': 'How quickly can I get started?', 'a': 'Most businesses are up and running within a day. Create your account, add your devices using our guided setup wizard, configure your alert rules, and you\'re live. No complex installation required.'},
      {'q': 'Is my data secure?', 'a': 'Absolutely. We use industry-standard AES-256 encryption for data at rest and TLS 1.3 for data in transit. Our platform is POPIA-compliant with role-based access controls and full audit trails.'},
      {'q': 'Can I try before I buy?', 'a': 'Yes! We offer a free 14-day trial with full access to all Professional features. No credit card required to start. Simply sign up and begin monitoring.'},
      {'q': 'Do you offer on-site installation support?', 'a': 'Yes, for Enterprise customers we provide on-site installation, device commissioning, and staff training. Contact our sales team for details on installation support in your area.'},
      {'q': 'What happens if my internet goes down?', 'a': 'Our devices have local data buffering capabilities. When connectivity is restored, all buffered readings are synced to the cloud. You\'ll also receive a connectivity alert so you\'re always informed.'},
      {'q': 'Can I integrate Artic Sentinel with other systems?', 'a': 'Yes. Our REST API allows integration with ERP systems, accounting software, and other platforms. Enterprise customers get access to webhooks and custom integration support.'},
      {'q': 'What kind of support do you offer?', 'a': 'Starter plans include community support and documentation. Professional plans include priority email and phone support during business hours. Enterprise plans include a dedicated account manager and 24/7 emergency support.'},
    ];

    return Container(
      key: _faqKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          _sectionLabel("FAQ"),
          const SizedBox(height: 12),
          Text(
            "Frequently Asked Questions",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Can't find what you're looking for? Contact our support team.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 14 : 16, color: Constants.ctaTextColor),
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: faqs.map((faq) => _faqItem(faq['q']!, faq['a']!)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(question, style: GoogleFonts.lato(fontSize: 15, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
        children: [
          Text(answer, style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaTextColor, height: 1.6)),
        ],
      ),
    );
  }

  // ─── CONTACT ──────────────────────────────────────────────────────────────────

  Widget _buildContactSection(BuildContext context, bool isMobile) {
    return Container(
      key: _contactKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 72),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel("CONTACT"),
          const SizedBox(height: 12),
          Text(
            "Get In Touch",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 24 : 34, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Have questions or need a demo? Our team is ready to help.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 14 : 16, color: Constants.ctaTextColor),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 32,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _contactInfoCard(Icons.email_outlined, "Email Us", "support@articsentinel.com", "General inquiries & support", isMobile),
              _contactInfoCard(Icons.phone_outlined, "Call Us", "+27 (0) 12 345 6789", "Mon-Fri, 8am - 5pm SAST", isMobile),
              _contactInfoCard(Icons.location_on_outlined, "Visit Us", "Pretoria, Gauteng", "South Africa", isMobile),
              _contactInfoCard(Icons.access_time, "Business Hours", "Mon - Fri: 8:00 - 17:00", "Emergency support 24/7", isMobile),
            ],
          ),
          const SizedBox(height: 48),
          // Contact form
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Send us a message", style: GoogleFonts.lato(fontSize: 18, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  if (!isMobile)
                    Row(
                      children: [
                        Expanded(child: _inputField(controller: _nameController, hint: "Full Name", icon: Icons.person_outline)),
                        const SizedBox(width: 16),
                        Expanded(child: _inputField(controller: _emailController, hint: "Email Address", icon: Icons.email_outlined)),
                      ],
                    )
                  else ...[
                    _inputField(controller: _nameController, hint: "Full Name", icon: Icons.person_outline),
                    const SizedBox(height: 14),
                    _inputField(controller: _emailController, hint: "Email Address", icon: Icons.email_outlined),
                  ],
                  const SizedBox(height: 14),
                  _inputField(controller: _subjectController, hint: "Subject", icon: Icons.subject),
                  const SizedBox(height: 14),
                  _inputField(controller: _messageController, hint: "Your message...", maxLines: 5),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Thank you! We'll get back to you within 24 hours.", style: GoogleFonts.lato(color: Colors.white)),
                            backgroundColor: Constants.ctaColorGreen,
                          ),
                        );
                        _nameController.clear();
                        _emailController.clear();
                        _subjectController.clear();
                        _messageController.clear();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        backgroundColor: Constants.ctaColorLight,
                      ),
                      child: Text('Send Message', style: GoogleFonts.lato(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
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

  Widget _contactInfoCard(IconData icon, String title, String detail, String subtitle, bool isMobile) {
    return SizedBox(
      width: isMobile ? (MediaQuery.of(context).size.width - 80) / 2 : 200,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Constants.ctaColorLight, size: 24),
          ),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.lato(fontSize: 14, color: Constants.ctaColorLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(detail, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 13, color: Constants.ctaTextColor)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 12, color: Constants.ctaTextColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _inputField({TextEditingController? controller, required String hint, int maxLines = 1, IconData? icon}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lato(color: Constants.ctaTextColor.withValues(alpha: 0.6), fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: Constants.ctaTextColor.withValues(alpha: 0.5)) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Constants.ctaColorLight)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── NEWSLETTER ───────────────────────────────────────────────────────────────

  Widget _buildNewsletterSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 40 : 56),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          Text(
            "Stay Updated",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 22 : 28, color: Constants.ctaColorLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "Subscribe to our newsletter for product updates, tips, and industry insights.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 14 : 15, color: Constants.ctaTextColor),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newsletterController,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: GoogleFonts.lato(color: Constants.ctaTextColor.withValues(alpha: 0.5), fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide(color: Constants.ctaColorLight)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Subscribed successfully!", style: GoogleFonts.lato(color: Colors.white)), backgroundColor: Constants.ctaColorGreen),
                    );
                    _newsletterController.clear();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: Constants.ctaColorGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Text("Subscribe", style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No spam, ever. Unsubscribe at any time.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 12, color: Constants.ctaTextColor.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // ─── CTA ──────────────────────────────────────────────────────────────────────

  Widget _buildCtaSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
      ),
      child: Column(
        children: [
          Text(
            "Ready to protect what matters most?",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: isMobile ? 22 : 32, color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              "Join leading businesses across South Africa who trust Artic Sentinel "
              "to monitor their critical operations around the clock.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: isMobile ? 14 : 17, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              TextButton(
                onPressed: () => context.go('/signup'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: Text('Start Free Trial', style: GoogleFonts.lato(color: Constants.ctaColorGreen, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => _scrollToSection(_contactKey),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Colors.white, width: 1.5)),
                ),
                child: Text('Request Demo', style: GoogleFonts.lato(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 48),
      color: const Color(0xFF0f172a),
      child: Column(
        children: [
          Wrap(
            spacing: isMobile ? 32 : 64,
            runSpacing: 32,
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Brand
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: Column(
                  crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("lib/assets/artic_logo.png", height: 28, width: 28),
                        const SizedBox(width: 8),
                        Text("Artic Sentinel", style: GoogleFonts.lato(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Smart monitoring and control for modern agriculture, cold chain, and IoT operations across Africa.",
                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                      style: GoogleFonts.lato(fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    // Social icons placeholder
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _socialIcon(Icons.language),
                        const SizedBox(width: 12),
                        _socialIcon(Icons.alternate_email),
                        const SizedBox(width: 12),
                        _socialIcon(Icons.phone),
                      ],
                    ),
                  ],
                ),
              ),
              // Platform links
              _footerColumn("Platform", [
                _FooterLink("Features", () => _scrollToSection(_featuresKey)),
                _FooterLink("Pricing", () => _scrollToSection(_pricingKey)),
                _FooterLink("Industries", () => _scrollToSection(_industriesKey)),
                _FooterLink("How It Works", () => _scrollToSection(_howItWorksKey)),
              ], isMobile),
              // Company links
              _footerColumn("Company", [
                _FooterLink("About Us", () => _scrollToSection(_aboutKey)),
                _FooterLink("Contact", () => _scrollToSection(_contactKey)),
                _FooterLink("Careers", () {}),
                _FooterLink("Blog", () {}),
              ], isMobile),
              // Support links
              _footerColumn("Support", [
                _FooterLink("Help Center", () {}),
                _FooterLink("Documentation", () {}),
                _FooterLink("API Reference", () {}),
                _FooterLink("System Status", () {}),
              ], isMobile),
              // Legal links
              _footerColumn("Legal", [
                _FooterLink("Privacy Policy", () {}),
                _FooterLink("Terms of Service", () {}),
                _FooterLink("POPIA Compliance", () {}),
                _FooterLink("Cookie Policy", () {}),
              ], isMobile),
            ],
          ),
          const SizedBox(height: 40),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              Text(
                '\u00a9 ${DateTime.now().year} Artic Sentinel (Pty) Ltd. All rights reserved.',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
              ),
              Text(
                'Made with \u2764 in South Africa',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
    );
  }

  Widget _footerColumn(String title, List<_FooterLink> links, bool isMobile) {
    return SizedBox(
      width: isMobile ? (MediaQuery.of(context).size.width - 80) / 2 : 140,
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.lato(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...links.map((link) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: link.onTap,
              child: Text(link.label, style: GoogleFonts.lato(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ),
          )),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Constants.ctaColorGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(fontSize: 12, color: Constants.ctaColorGreen, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );
  }
}

class _FooterLink {
  final String label;
  final VoidCallback onTap;
  _FooterLink(this.label, this.onTap);
}
