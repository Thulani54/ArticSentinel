import '../widgets/mobile_screen.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_forms.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html_dom;
import 'package:universal_html/parsing.dart' as html_parser;

import '../constants/Constants.dart';
import '../widgets/compact_header.dart';

class CommunicationDashboard extends StatefulWidget {
  @override
  _CommunicationDashboardState createState() => _CommunicationDashboardState();
}

class _CommunicationDashboardState extends State<CommunicationDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';

  // Data
  List<dynamic> _providers = [];
  List<dynamic> _templates = [];
  List<dynamic> _logs = [];
  List<dynamic> _otpCodes = [];
  List<dynamic> _queues = [];
  Map<String, dynamic> _stats = {};
  List<dynamic> _alertLogs = [];
  late Animation<double> _fadeAnimation;
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _loadProviders(),
        _loadTemplates(),
        _loadLogs(),
        _loadOTPCodes(),
        _loadQueues(),
        _loadStats(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Check your connection and try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _loadProviders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/communication/providers/'),
      headers: ApiConfig.headers,
    ).timeout(const Duration(seconds: 20));
    print("sghsahj ${response.body}");

    if (response.statusCode != 200) {
      throw StateError('Communication request failed');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _providers = data['providers'] ?? [];
      });
    }
  }

  Future<void> _loadTemplates() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/communication/templates/'),
      headers: ApiConfig.headers,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError('Communication request failed');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _templates = data['templates'] ?? [];
      });
    }
  }

  Future<void> _loadLogs() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/communication/logs/?per_page=50'),
      headers: ApiConfig.headers,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError('Communication request failed');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _logs = data['logs'] ?? [];
      });
    }
  }

  Future<void> _loadOTPCodes() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/communication/otp/?per_page=50'),
      headers: ApiConfig.headers,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError('Communication request failed');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _otpCodes = data['otp_codes'] ?? [];
      });
    }
  }

  Future<void> _loadQueues() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/communication/queues/'),
      headers: ApiConfig.headers,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError('Communication request failed');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _queues = data['queues'] ?? [];
      });
    }
  }

  Future<void> _loadStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/communication/stats/'),
      headers: ApiConfig.headers,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError('Communication request failed');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _stats = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildPhoneCommunication(context);
    return Container(
      height: 1000,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header Section
              _buildHeader(),

              // Tab Bar Section
              _buildTabBar(),

              // Content Area
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error.isNotEmpty
                        ? _buildErrorState()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildProvidersTab(),
                              _buildTemplatesTab(),
                              _buildLogsTab(),
                              _buildOTPTab(),
                              _buildQueuesTab(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneCommunication(BuildContext context) {
    final totals = _stats['totals'] ?? {};
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height - 100,
        child: ColoredBox(
          color: GasPalette.page,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const MobileScreenHeader(
              title: 'Communication',
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                    color: const Color(0xFFE9EDF4),
                    borderRadius: BorderRadius.circular(32)),
                labelColor: GasPalette.primary,
                unselectedLabelColor: GasPalette.ink2,
                labelStyle: gasBody(context)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(height: 36, text: 'Overview'),
                  Tab(height: 36, text: 'Providers'),
                  Tab(height: 36, text: 'Templates'),
                  Tab(height: 36, text: 'Logs'),
                  Tab(height: 36, text: 'OTP'),
                  Tab(height: 36, text: 'Queues')
                ],
              ),
            ),
            Expanded(
                child: _isLoading
                    ? Center(
                        child: GPanel(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                            const CircularProgressIndicator(
                                color: GasPalette.primary),
                            const SizedBox(height: 16),
                            Text('Loading communication data…',
                                style: gasBody(context)),
                          ])))
                    : _error.isNotEmpty
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: AppEmptyState(
                              kind: AppEmptyStateKind.offline,
                              title: 'Unable to load messages',
                              message: _error,
                              actionLabel: 'Retry',
                              onAction: _loadData,
                            ))
                        : TabBarView(controller: _tabController, children: [
                            _phoneCommunicationList('Overview', [
                              GPanel(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(children: [
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: _phoneCommunicationMetric(
                                                  'SMS sent',
                                                  '${totals['sms_sent'] ?? 0}')),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: _phoneCommunicationMetric(
                                                  'Emails sent',
                                                  '${totals['email_sent'] ?? 0}')),
                                        ]),
                                    const Divider(
                                        height: 20, color: GasPalette.border),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: _phoneCommunicationMetric(
                                                  'OTP generated',
                                                  '${totals['otp_generated'] ?? 0}')),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: _phoneCommunicationMetric(
                                                  'Total cost',
                                                  '\$${(totals['sms_cost'] ?? 0).toStringAsFixed(2)}')),
                                        ]),
                                  ])),
                              const SizedBox(height: 16),
                              Text('Recent activity',
                                  style: gasTitle(context).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              if (_logs.isEmpty)
                                _phoneCommunicationEmpty('No messages yet')
                              else
                                for (final log in _logs.take(5))
                                  _phoneCommunicationLog(log),
                            ]),
                            _phoneCommunicationList('Providers', [
                              for (final provider in _providers)
                                _phoneCommunicationRecord(
                                    provider['name'] ?? '',
                                    '${provider['provider_type_display'] ?? ''} · ${provider['is_active'] == true ? 'Active' : 'Inactive'}',
                                    {
                                      'Sent': '${provider['total_sent'] ?? 0}',
                                      'Failed':
                                          '${provider['total_failed'] ?? 0}',
                                      'Success rate':
                                          '${provider['success_rate'] ?? 0}%',
                                      if (provider['cost_per_message'] != null)
                                        'Cost per message':
                                            '\$${provider['cost_per_message'].toStringAsFixed(4)}',
                                    }),
                            ]),
                            _phoneCommunicationList('Templates', [
                              for (final template in _templates)
                                _phoneCommunicationRecord(
                                    template['name'] ?? '',
                                    '${template['template_type_display'] ?? ''} · ${template['communication_type_display'] ?? ''}',
                                    {
                                      if (template['is_default'] == true)
                                        'Template': 'Default',
                                      if (template['subject'] != null &&
                                          template['subject'].isNotEmpty)
                                        'Subject': template['subject'],
                                      'Message': template['message'] ?? '',
                                      'Usage':
                                          '${template['times_used'] ?? 0} times',
                                    }),
                            ]),
                            _phoneCommunicationList('Logs', [
                              for (final log in _logs)
                                _phoneCommunicationLog(log)
                            ]),
                            _phoneCommunicationList('OTP codes', [
                              for (final otp in _otpCodes)
                                _phoneCommunicationRecord(
                                    'User: ${otp['user'] ?? 'Unknown'}',
                                    '${otp['otp_type_display'] ?? ''} · ${_getOTPStatusText(otp)}',
                                    {
                                      'Attempts':
                                          '${otp['attempts']}/${otp['max_attempts']}',
                                      'Created':
                                          _formatDateTime(otp['created_at']),
                                      'Expires':
                                          _formatDateTime(otp['expires_at']),
                                    }),
                            ]),
                            _phoneCommunicationList('Queues', [
                              for (final queue in _queues)
                                _phoneCommunicationRecord(queue['name'] ?? '',
                                    queue['status_display'] ?? '', {
                                  'Priority': queue['priority_display'] ?? '',
                                  if (queue['description'] != null &&
                                      queue['description'].isNotEmpty)
                                    'Description': queue['description'],
                                  'Recipients': '${queue['total_recipients']}',
                                  'Successful': '${queue['successful_count']}',
                                  'Failed': '${queue['failed_count']}',
                                }),
                            ]),
                          ])),
          ]),
        ),
      );
    });
  }

  Widget _phoneCommunicationList(String title, List<Widget> children) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (children.isEmpty)
            _phoneCommunicationEmpty(title == 'Logs'
                ? 'No messages yet'
                : 'No ${title.toLowerCase()} yet')
          else
            ...children,
        ]),
      );

  Widget _phoneCommunicationEmpty(String title) => AppEmptyState(
        kind: AppEmptyStateKind.records,
        icon: Icons.chat_bubble_outline,
        title: title,
        message: 'Communication activity will appear here when available.',
        compact: true,
      );

  Widget _phoneCommunicationMetric(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(label,
                  style: gasSmall(context).copyWith(fontSize: 10.5))),
          const SizedBox(width: 8),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end, style: gasData(context, size: 18))),
        ],
      );

  Widget _phoneCommunicationValue(String label, String value) {
    if (label == 'Message') return _PhoneMessagePreview(message: value);
    final paragraph =
        ['Message', 'Subject', 'Description', 'Error'].contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: paragraph
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: gasSmall(context)),
              const SizedBox(height: 3),
              Text(value,
                  style: gasBody(context).copyWith(
                      color: GasPalette.ink, height: 1.4, fontSize: 12)),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(label, style: gasSmall(context))),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: gasBody(context).copyWith(
                          color: GasPalette.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))),
            ]),
    );
  }

  Widget _phoneCommunicationRecord(
          String title, String subtitle, Map<String, String> values) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      style: gasTitle(context)
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: gasSmall(context)),
                  const Divider(height: 16, color: GasPalette.border),
                  for (final value in values.entries)
                    _phoneCommunicationValue(value.key, value.value),
                ])),
      );

  Widget _phoneCommunicationLog(Map<String, dynamic> log) {
    final subject = log['subject'] as String?;
    final hasSubject = subject != null && subject.isNotEmpty;
    final status =
        '${log['communication_type_display'] ?? ''} · ${log['status_display'] ?? ''}';
    return _phoneCommunicationRecord(
      hasSubject ? subject : status,
      hasSubject
          ? '$status · ${_formatDateTime(log['created_at'])}'
          : _formatDateTime(log['created_at']),
      {
        'Message': log['message'] ?? '',
        if (log['error_message'] != null && log['error_message'].isNotEmpty)
          'Error': log['error_message'],
      },
    );
  }

  Widget _buildHeader() {
    return CompactHeader(
      title: "Communication",
      description: "Monitor messaging systems and templates",
      icon: Icons.forum_rounded,
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
            _buildTab(Icons.dashboard_rounded, 'Overview'),
            _buildTab(Icons.cloud_rounded, 'Providers'),
            _buildTab(Icons.description_rounded, 'Templates'),
            _buildTab(Icons.timeline_rounded, 'Logs'),
            _buildTab(Icons.verified_user_rounded, 'OTP'),
            _buildTab(Icons.queue_music_rounded, 'Queues'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String title) {
    return Tab(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
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
            CircularProgressIndicator(
              color: Constants.ctaColorLight,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading communication data...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPhoneLayout(context)
                    ? GasPalette.primary
                    : Constants.ctaColorLight,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(isPhoneLayout(context) ? 32 : 12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totals = _stats['totals'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Section
          _buildStatisticsSection(totals),

          const SizedBox(height: 32),

          // Recent Activity Section
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.timeline_rounded,
                size: 20,
                color: Constants.ctaColorLight,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Recent Activity",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          child: _logs.isEmpty
              ? _buildEmptyActivityState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _logs.take(5).length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildActivityItem(log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Communication logs will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> totals) {
    final stats = [
      _StatCard(
        title: 'SMS Sent',
        value: '${totals['sms_sent'] ?? 0}',
        icon: Icons.sms_rounded,
        color: Constants.ctaColorLight,
      ),
      _StatCard(
        title: 'Emails Sent',
        value: '${totals['email_sent'] ?? 0}',
        icon: Icons.email_rounded,
        color: const Color(0xFF10B981),
      ),
      _StatCard(
        title: 'OTP Generated',
        value: '${totals['otp_generated'] ?? 0}',
        icon: Icons.security_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _StatCard(
        title: 'Total Cost',
        value: '\$${(totals['sms_cost'] ?? 0).toStringAsFixed(2)}',
        icon: Icons.monetization_on_rounded,
        color: Constants.ctaColorLight,
      ),
    ];

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
              "Communication Overview",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index]),
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatCard stat) {
    return Container(
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat.icon,
                  size: 20,
                  color: stat.color,
                ),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stat.value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Communication Providers', Icons.settings),
          SizedBox(height: 12),
          ..._providers
              .map((provider) => _buildProviderCard(provider))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Message Templates', Icons.text_snippet),
          SizedBox(height: 12),
          ..._templates
              .map((template) => _buildTemplateCard(template))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Communication Logs', Icons.history),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return _buildLogItem(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('OTP Codes', Icons.security),
          SizedBox(height: 12),
          ..._otpCodes.map((otp) => _buildOTPCard(otp)).toList(),
        ],
      ),
    );
  }

  Widget _buildQueuesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Communication Queues', Icons.queue),
          SizedBox(height: 12),
          ..._queues.map((queue) => _buildQueueCard(queue)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard2(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Constants.ctaColorLight, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider['is_active']
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProviderTypeColor(provider['provider_type'])
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider['provider_type_display'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getProviderTypeColor(provider['provider_type']),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: provider['is_active']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            provider['is_active'] ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider['is_active'] ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            provider['is_active'] ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            provider['name'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProviderStat(
                  'Sent', provider['total_sent']?.toString() ?? '0'),
              const SizedBox(width: 24),
              _buildProviderStat(
                  'Failed', provider['total_failed']?.toString() ?? '0'),
              const SizedBox(width: 24),
              _buildProviderStat('Success Rate',
                  '${provider['success_rate']?.toString() ?? '0'}%'),
            ],
          ),
          if (provider['cost_per_message'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cost per message: \$${provider['cost_per_message'].toStringAsFixed(4)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTemplatesState() {
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
              Icons.text_snippet_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create message templates to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  template['template_type_display'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Constants.ctaColorLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  template['communication_type_display'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
              const Spacer(),
              if (template['is_default'])
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Default',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            template['name'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (template['subject'] != null &&
              template['subject'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Subject: ${template['subject']}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            template['message'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Used ${template['times_used']} times',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(log['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCommunicationIcon(log['communication_type']),
              color: _getStatusColor(log['status']),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log['communication_type_display']} - ${log['status_display']}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log['message'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatDateTime(log['created_at']),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(log['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log['status_display'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(log['status']),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                log['communication_type_display'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Spacer(),
              Text(
                _formatDateTime(log['created_at']),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (log['subject'] != null && log['subject'].isNotEmpty) ...[
            Text(
              'Subject: ${log['subject']}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
          ],
          Text(
            log['message'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (log['error_message'] != null &&
              log['error_message'].isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Error: ${log['error_message']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOTPCard(Map<String, dynamic> otp) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOTPStatusColor(otp).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getOTPStatusText(otp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getOTPStatusColor(otp),
                  ),
                ),
              ),
              Spacer(),
              Text(
                otp['otp_type_display'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'User: ${otp['user'] ?? 'Unknown'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Attempts: ${otp['attempts']}/${otp['max_attempts']}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Created: ${_formatDateTime(otp['created_at'])}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          Text(
            'Expires: ${_formatDateTime(otp['expires_at'])}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> queue) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQueueStatusColor(queue['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  queue['status_display'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getQueueStatusColor(queue['status']),
                  ),
                ),
              ),
              Spacer(),
              Text(
                'Priority: ${queue['priority_display'] ?? ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            queue['name'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          if (queue['description'] != null &&
              queue['description'].isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              queue['description'],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Recipients: ${queue['total_recipients']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Success: ${queue['successful_count']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Failed: ${queue['failed_count']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProviderTypeColor(String? type) {
    switch (type) {
      case 'sms':
        return Colors.blue;
      case 'email':
        return Colors.green;
      case 'push':
        return Colors.orange;
      case 'whatsapp':
        return Colors.teal;
      case 'telegram':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'sent':
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getOTPStatusColor(Map<String, dynamic> otp) {
    if (otp['is_used']) return Colors.green;
    if (otp['is_expired'] || !otp['is_valid']) return Colors.red;
    return Colors.orange;
  }

  String _getOTPStatusText(Map<String, dynamic> otp) {
    if (otp['is_used']) return 'Used';
    if (otp['is_expired']) return 'Expired';
    if (!otp['is_valid']) return 'Invalid';
    return 'Active';
  }

  Color _getQueueStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCommunicationIcon(String? type) {
    switch (type) {
      case 'sms':
        return Icons.sms;
      case 'email':
        return Icons.email;
      case 'push':
        return Icons.notifications;
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.send;
      default:
        return Icons.message;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
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
    } catch (e) {
      return '';
    }
  }
}

class _PhoneMessagePreview extends StatefulWidget {
  const _PhoneMessagePreview({required this.message});

  final String message;

  @override
  State<_PhoneMessagePreview> createState() => _PhoneMessagePreviewState();
}

class _PhoneMessagePreviewState extends State<_PhoneMessagePreview> {
  late String _text;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _text = _readableMessage(widget.message);
  }

  @override
  void didUpdateWidget(covariant _PhoneMessagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _text = _readableMessage(widget.message);
      _expanded = false;
    }
  }

  String _readableMessage(String source) {
    var text = source;
    if (RegExp(r'</?[a-zA-Z][^>]*>').hasMatch(source)) {
      final document = html_parser.parseHtmlDocument(source);
      for (final element in document.querySelectorAll('script, style, head')) {
        element.remove();
      }
      for (final element in document.querySelectorAll(
          'br, p, div, li, tr, td, th, h1, h2, h3, h4, h5, h6, blockquote, section')) {
        element.parent?.insertBefore(html_dom.Text('\n'), element);
        if (element.localName != 'br') element.appendText('\n');
      }
      text = document.body?.text ?? '';
    }
    return text
        .replaceAll(RegExp(r'[\t\r\f\v \u00a0]+'), ' ')
        .split('\n')
        .map((line) => line.trim())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final canExpand = _text.length > 120 || _text.split('\n').length > 3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Message', style: gasSmall(context)),
          const SizedBox(height: 5),
          Text(
            _text.isEmpty
                ? (widget.message.trim().isEmpty
                    ? 'No message content'
                    : 'No text preview available')
                : _text,
            maxLines: canExpand && !_expanded ? 3 : null,
            overflow: canExpand && !_expanded ? TextOverflow.ellipsis : null,
            style:
                gasBody(context).copyWith(color: GasPalette.ink, height: 1.5),
          ),
          if (canExpand)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                foregroundColor: GasPalette.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32)),
              ),
              child: Text(_expanded ? 'Show less' : 'Show full message'),
            ),
        ],
      ),
    );
  }
}

// API Configuration class (add this to your existing API config)
class ApiConfig {
  static String baseUrl = '${Constants.articBaseUrl2}api';
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };
}

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
