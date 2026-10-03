import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../services/auth_session.dart';

class SideBarItems {
  int id;
  String item_id;
  String itemName;
  IconData itemIcon;

  SideBarItems(this.id, this.item_id, this.itemName, this.itemIcon);
}

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await AuthSession.signOut();
    if (mounted) context.go('/login');
  }

  // Helper method to check if screen is mobile
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(
      begin: 252.0,
      end: 80.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

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
    SideBarItems(6, "control", "Control", CupertinoIcons.slider_horizontal_3),
    SideBarItems(11, "reports", "Reports", CupertinoIcons.doc_chart_fill),
    SideBarItems(8, "notification", "Notifications", CupertinoIcons.bell),
    SideBarItems(8, "maintenance", "Maintenance", CupertinoIcons.wrench_fill),
    SideBarItems(8, "access", "Access Management", CupertinoIcons.person_2),
    SideBarItems(9, "settings", "Settings", CupertinoIcons.gear_alt),
    SideBarItems(10, "help", "Help & Support", CupertinoIcons.question_circle),
    SideBarItems(12, "products", "Products", Iconsax.box),
    SideBarItems(13, "device_setup", "Connect a device", Iconsax.link),
  ];

  static const _mobileDrawerIcons = [
    Iconsax.home_2,
    Iconsax.chart_2,
    Iconsax.element_3,
    Iconsax.messages,
    Iconsax.location,
    Iconsax.cpu,
    Iconsax.setting_4,
    Iconsax.document_text,
    Iconsax.notification,
    Iconsax.setting,
    Iconsax.people,
    Iconsax.setting_2,
    Iconsax.message_question,
    Iconsax.box,
    Iconsax.link,
  ];

  int get sideColorIndex {
    // Determine active index based on current route
    switch (widget.currentRoute) {
      case '/dashboard':
      case '/dashboard-home':
        return 0;
      case '/device-performance':
        return 1;
      case '/units':
        return 2;
      case '/communication':
        return 3;
      case '/geo-fencing':
        return 4;
      case '/device-management':
        return 5;
      case '/control':
        return 6;
      case '/reports':
        return 7;
      case '/alerts':
        return 8;
      case '/maintenance':
        return 9;
      case '/roles':
        return 10;
      case '/settings':
      case '/settings/billing':
      case '/settings/security':
      case '/settings/terms':
        return 11;
      case '/help':
        return 12;
      case '/products':
        return 13;
      case '/device-setup':
        return 14;
      default:
        return 0;
    }
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
        context.go('/device-performance');
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
      case "reports":
        context.go('/reports');
        break;
      case "control":
        context.go('/control');
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
      case "products":
        context.push('/products');
        break;
      case "device_setup":
        context.push('/device-setup');
        break;
    }
  }

  Widget _buildMobileDrawer() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 20),
            child: Row(children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Workspace',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                          color: GasPalette.ink2)),
                  const SizedBox(height: 8),
                  Text(
                      Constants.business_name.isEmpty
                          ? 'Artic Sentinel'
                          : Constants.business_name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GasPalette.ink)),
                ],
              )),
              IconButton(
                  tooltip: 'Close navigation',
                  onPressed: () => Navigator.of(context).pop(),
                  icon:
                      const Icon(Iconsax.close_circle, color: GasPalette.ink2)),
            ]),
          ),
          const Divider(height: 1, color: GasPalette.border),
          Expanded(
              child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sideBarList.length,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 9 ? 16 : 4),
            itemBuilder: (context, index) {
              final item = sideBarList[index];
              final selected = sideColorIndex == index;
              return Material(
                color: selected ? GasPalette.page : Colors.transparent,
                borderRadius: BorderRadius.circular(32),
                child: ListTile(
                  selected: selected,
                  selectedColor: GasPalette.primary,
                  textColor: GasPalette.ink,
                  iconColor: GasPalette.ink2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  minLeadingWidth: 20,
                  leading: Icon(_mobileDrawerIcons[index], size: 20),
                  title: Text(item.itemName,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToRoute(item.item_id);
                  },
                ),
              );
            },
          )),
          const Divider(height: 1, color: GasPalette.border),
          Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: const Icon(Iconsax.logout, size: 18),
                label: const Text('Sign out'),
              )),
        ],
      ),
    );
  }

  // Build sidebar content (reusable for both drawer and inline sidebar)
  Widget _buildSidebarContent({required bool isMobileDrawer}) {
    return Container(
      padding: EdgeInsets.all(_isSidebarExpanded ? 16 : 8),
      color:
          isMobileDrawer ? Colors.white : Colors.grey.withValues(alpha: 0.25),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Toggle button at top of sidebar with Home text (hidden on mobile drawer)
            if (!isMobileDrawer)
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isSidebarExpanded)
                      Text(
                        "Home",
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (!_isSidebarExpanded)
                      Icon(
                        CupertinoIcons.home,
                        color: Colors.black54,
                        size: 20,
                      ),
                    IconButton(
                      onPressed: _toggleSidebar,
                      icon: Icon(
                        _isSidebarExpanded
                            ? CupertinoIcons.chevron_left
                            : CupertinoIcons.chevron_right,
                        color: Colors.black54,
                        size: 20,
                      ),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            // Mobile drawer header (shown only on mobile)
            if (isMobileDrawer)
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 16, bottom: 24),
                child: Text(
                  "Navigation",
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ListView.builder(
                itemCount: sideBarList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == 7 ? 100 : 16),
                    child: InkWell(
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      child: Container(
                        height:
                            (isMobileDrawer || _isSidebarExpanded) ? 50 : 40,
                        padding: EdgeInsets.only(
                            left:
                                (isMobileDrawer || _isSidebarExpanded) ? 16 : 8,
                            right: (isMobileDrawer || _isSidebarExpanded)
                                ? 12
                                : 8),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              (isMobileDrawer || _isSidebarExpanded) ? 24 : 20),
                          color: sideColorIndex == index
                              ? Constants.ctaColorLight
                              : (isMobileDrawer
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.white60),
                        ),
                        child: (isMobileDrawer || _isSidebarExpanded)
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    sideBarList[index].itemIcon,
                                    size: 20,
                                    color: sideColorIndex == index
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      sideBarList[index].itemName,
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                            fontSize: 12,
                                            color: sideColorIndex == index
                                                ? Colors.white
                                                : Colors.black54,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  sideBarList[index].itemIcon,
                                  size: 20,
                                  color: sideColorIndex == index
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                      ),
                      onTap: () {
                        _navigateToRoute(sideBarList[index].item_id);
                        // Close drawer on mobile after navigation
                        if (isMobileDrawer) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  );
                }),
            SizedBox(height: 16),
            InkWell(
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: Container(
                height: 40,
                padding: EdgeInsets.only(
                    left: (isMobileDrawer || _isSidebarExpanded) ? 16 : 8,
                    right: (isMobileDrawer || _isSidebarExpanded) ? 12 : 8),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      (isMobileDrawer || _isSidebarExpanded) ? 32 : 20),
                  color: Constants.ctaColorLight,
                ),
                child: Center(
                  child: (isMobileDrawer || _isSidebarExpanded)
                      ? Text(
                          "Sign Out",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal),
                          ),
                        )
                      : Icon(
                          CupertinoIcons.square_arrow_right,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              onTap: _signingOut ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNavigation() {
    const destinations = [
      ('Home', '/dashboard-home', Iconsax.home_2),
      ('Equipment', '/device-management', Iconsax.category),
      ('Alerts', '/alerts', Iconsax.notification),
      ('Settings', '/settings', Iconsax.setting_2),
    ];
    return ClipRRect(
      key: const ValueKey('mobile-navigation-surface'),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.fromBorderSide(BorderSide(color: GasPalette.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                for (final destination in destinations)
                  Expanded(
                    child: Builder(builder: (context) {
                      final selected = widget.currentRoute == destination.$2 ||
                          (destination.$2 == '/dashboard-home' &&
                              widget.currentRoute == '/dashboard') ||
                          (destination.$2 == '/settings' &&
                              widget.currentRoute.startsWith('/settings/'));
                      return Semantics(
                        selected: selected,
                        child: TextButton(
                          key: ValueKey('mobile-nav-${destination.$1}'),
                          onPressed: () => context.go(destination.$2),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                selected ? GasPalette.primary : GasPalette.ink2,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFE9EDF4)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Icon(destination.$3, size: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(destination.$1,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isMobile ? GasPalette.page : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: isMobile ? 56 : 64,
        leading: isMobile
            ? IconButton(
                tooltip: 'Open navigation',
                icon: const Icon(Iconsax.more, color: GasPalette.ink),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              )
            : null,
        titleSpacing: isMobile ? 0 : null,
        title: Row(
          children: [
            // Logo and brand
            if (!isMobile)
              Container(
                height: isMobile ? 28 : 40,
                width: isMobile ? 28 : 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage("lib/assets/artic_logo.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (!isMobile) const SizedBox(width: 12),
            Flexible(
                child: Text(
              isMobile ? 'Artic Sentinel.' : 'Artic Sentinel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isMobile
                  ? const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 18,
                      color: GasPalette.ink,
                      fontWeight: FontWeight.w300)
                  : GoogleFonts.inter(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5),
            )),
          ],
        ),
        actions: [
          // Phone alerts are in the persistent navigation.
          if (!isMobile)
            Container(
              height: isMobile ? 32 : 40,
              width: isMobile ? 32 : 40,
              margin: EdgeInsets.only(right: isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: isMobile
                    ? Colors.transparent
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                CupertinoIcons.bell,
                color: Colors.black54,
                size: 20,
              ),
            ),

          // User info
          Container(
            margin: EdgeInsets.only(right: isMobile ? 12 : 24),
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 12, vertical: isMobile ? 4 : 8),
            decoration: BoxDecoration(
              color: isMobile
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: isMobile
                ? InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () => context.go('/settings'),
                    child: Tooltip(
                      message: 'Open account settings',
                      child: CircleAvatar(
                        backgroundColor: Constants.ctaColorLight,
                        radius: 16,
                        child: Text(
                          Constants.myDisplayname.isNotEmpty
                              ? Constants.myDisplayname[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Constants.ctaColorLight,
                        radius: 16,
                        child: Text(
                          Constants.myDisplayname.isNotEmpty
                              ? Constants.myDisplayname[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Constants.myDisplayname,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            "Administrator",
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                      SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.black54,
                        size: 16,
                      ),
                    ],
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: GasPalette.border,
          ),
        ),
      ),
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              width: MediaQuery.sizeOf(context).width.clamp(0, 360) * 0.9,
              child: _buildMobileDrawer(),
            )
          : null,
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 600
          ? _buildPhoneNavigation()
          : null,
      body: isMobile
          ? widget.child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: _sidebarAnimation.value,
                      child: _buildSidebarContent(isMobileDrawer: false),
                    );
                  },
                ),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
    );
  }
}
