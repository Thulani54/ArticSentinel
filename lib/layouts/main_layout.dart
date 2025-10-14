import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';

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
    SideBarItems(11, "reports", "Reports", CupertinoIcons.doc_chart_fill),
    SideBarItems(8, "notification", "Notifications", CupertinoIcons.bell),
    SideBarItems(8, "maintenance", "Maintenance", CupertinoIcons.wrench_fill),
    SideBarItems(8, "access", "Access Management", CupertinoIcons.person_2),
    SideBarItems(9, "settings", "Settings", CupertinoIcons.gear_alt),
    SideBarItems(10, "help", "Help & Support", CupertinoIcons.question_circle),
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
      case '/reports':
        return 6;
      case '/alerts':
        return 7;
      case '/maintenance':
        return 8;
      case '/roles':
        return 8;
      case '/settings':
      case '/settings/billing':
      case '/settings/security':
      case '/settings/terms':
        return 9;
      case '/help':
        return 10;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        title: Row(
          children: [
            // Logo and brand
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage("lib/assets/artic_logo.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Artic Sentinel",
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell
          Container(
            height: 40,
            width: 40,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.bell,
              color: Colors.black54,
              size: 20,
            ),
          ),

          // User info
          Container(
            margin: EdgeInsets.only(right: 24),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
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
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Sidebar
            AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                return Container(
                    height: MediaQuery.of(context).size.height,
                    width: _sidebarAnimation.value,
                    padding: EdgeInsets.all(_isSidebarExpanded ? 16 : 8),
                    color: Colors.grey.withValues(alpha: 0.25),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Toggle button at top of sidebar with Home text
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
                          ListView.builder(
                              itemCount: sideBarList.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: index == 7 ? 100 : 16),
                                  child: InkWell(
                                    highlightColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    child: Container(
                                      height: _isSidebarExpanded ? 50 : 40,
                                      padding: EdgeInsets.only(
                                          left: _isSidebarExpanded ? 16 : 8,
                                          right: _isSidebarExpanded ? 12 : 8),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            _isSidebarExpanded ? 24 : 20),
                                        color: sideColorIndex == index
                                            ? Constants.ctaColorLight
                                            : Colors.white60,
                                      ),
                                      child: _isSidebarExpanded
                                          ? Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
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
                                                          color:
                                                              sideColorIndex ==
                                                                      index
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black54,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                      _navigateToRoute(
                                          sideBarList[index].item_id);
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
                                  left: _isSidebarExpanded ? 16 : 8,
                                  right: _isSidebarExpanded ? 12 : 8),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    _isSidebarExpanded ? 32 : 20),
                                color: Constants.ctaColorLight,
                              ),
                              child: Center(
                                child: _isSidebarExpanded
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
                            onTap: () {
                              context.go('/login');
                            },
                          ),
                        ],
                      ),
                    ));
              },
            ),
            // Main content
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxWidth: 1200),
                child: widget.child,
              ),
            )
          ],
        ),
      ),
    );
  }
}
