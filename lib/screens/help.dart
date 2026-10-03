import 'settings/mobile_account_widgets.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/mobile_forms.dart';
import '../widgets/mobile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../widgets/compact_header.dart';

class HelpSupport extends StatefulWidget {
  const HelpSupport({super.key});

  @override
  State<HelpSupport> createState() => _HelpSupportState();
}

class _HelpSupportState extends State<HelpSupport> {
  List<TradingHours> tradingList = [
    TradingHours(id: 1, day_id: "monday", day: "Monday", times: "7am - 6pm"),
    TradingHours(id: 2, day_id: "tuesday", day: "Tuesday", times: "7am - 6pm"),
    TradingHours(
        id: 3, day_id: "wednesday", day: "Wednesday", times: "7am - 6pm"),
    TradingHours(
        id: 4, day_id: "thursday", day: "Thursday", times: "7am - 6pm"),
    TradingHours(id: 5, day_id: "friday", day: "Friday", times: "7am - 6pm"),
    TradingHours(
        id: 6, day_id: "saturday", day: "Saturday", times: "8am - 4pm"),
    TradingHours(id: 7, day_id: "sunday", day: "Sunday", times: "9am - 5pm"),
  ];

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildMobileHelp();
    return Container(
      height: 1000,
      // backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const CompactHeader(
                title: "Help",
                description: "Get support and documentation",
                icon: Icons.help_rounded,
              ),

              const SizedBox(height: 32),

              // Quick Actions Grid
              _buildQuickActionsGrid(),

              const SizedBox(height: 32),

              // Contact Information Card
              _buildContactCard(),

              const SizedBox(height: 32),

              // Trading Hours Card
              _buildTradingHoursCard(),

              const SizedBox(height: 32),

              // FAQ Section
              _buildFAQSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHelp() {
    return ColoredBox(
      color: GasPalette.page,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const MobileScreenHeader(title: 'Help & support', padding: EdgeInsets.zero),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(),
          const SizedBox(height: 14),
          GPanel(padding: const EdgeInsets.all(14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Contact', style: gasTitle(context).copyWith(fontSize: 14)),
              const SizedBox(height: 12),
              _buildContactMethod('Email support', Constants.myBusinessSupportEmail,
                  'Send us an email anytime', Icons.email_outlined, GasPalette.ink2),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: GasPalette.border)),
              _buildContactMethod('Phone support', Constants.myBusinessSupportContactNumber,
                  'Call us during business hours', Icons.phone_outlined, GasPalette.ink2),
            ],
          )),
          const SizedBox(height: 14),
          GPanel(padding: const EdgeInsets.all(14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Business hours', style: gasTitle(context).copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              for (final hours in tradingList)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(hours.day, style: gasBody(context).copyWith(
                        color: GasPalette.ink,
                        fontWeight: _isToday(hours.day_id) ? FontWeight.w700 : FontWeight.w400))),
                    const SizedBox(width: 12),
                    Flexible(child: Text(hours.times, textAlign: TextAlign.end, style: gasBody(context))),
                  ]),
                ),
            ],
          )),
          const SizedBox(height: 14),
          _buildFAQSection(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    if (isPhoneLayout(context)) {
      return GPanel(padding: EdgeInsets.zero, child: Column(children: [
        _buildActionCard('Live Chat', 'Get instant help',
            Icons.chat_bubble_outline_rounded, GasPalette.ink, () {
          // Handle live chat
        }),
        const Divider(height: 1, color: GasPalette.border),
        _buildActionCard('Submit Ticket', 'Report an issue',
            Icons.support_agent_rounded, GasPalette.ink, () {
          // Handle ticket submission
        }),
      ]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Constants.ctaColorGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.flash_on_rounded,
                size: 20,
                color: Constants.ctaColorGreen,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Quick Actions",
              style: accountInter(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MobileFormRow(
          children: [
            Expanded(
              child: _buildActionCard(
                "Live Chat",
                "Get instant help",
                Icons.chat_bubble_outline_rounded,
                const Color(0xFF10B981),
                () {
                  // Handle live chat
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                "Submit Ticket",
                "Report an issue",
                Icons.support_agent_rounded,
                Constants.ctaColorLight,
                () {
                  // Handle ticket submission
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    if (isPhoneLayout(context)) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14), onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Icon(icon, size: 20, color: GasPalette.ink2),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: gasTitle(context).copyWith(fontSize: 14)),
              const SizedBox(height: 3),
              Text(subtitle, style: gasSmall(context)),
            ])),
            const Icon(Icons.chevron_right, size: 18, color: GasPalette.muted),
          ])),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: accountSurface(
            context,
            BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: accountInter(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: accountInter(
                context,
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: accountSurface(
          context,
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: mobileFlatDecoration(
                context,
                BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Constants.ctaColorGreen.withOpacity(0.1),
                      Constants.ctaColorGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                )),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorGreen,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Constants.ctaColorGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.contact_support_rounded,
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
                        "Get In Touch",
                        style: accountInter(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Providing expert livestock solutions to help farmers thrive",
                        style: accountInter(
                          context,
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact Methods
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Email Contact
                _buildContactMethod(
                  "Email Support",
                  Constants.myBusinessSupportEmail,
                  "Send us an email anytime",
                  Icons.email_outlined,
                  Constants.ctaColorLight,
                ),

                const SizedBox(height: 20),

                // Phone Contact
                _buildContactMethod(
                  "Phone Support",
                  Constants.myBusinessSupportContactNumber,
                  "Call us during business hours",
                  Icons.phone_outlined,
                  const Color(0xFF10B981),
                ),

                const SizedBox(height: 20),

                // Response Time Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "We typically respond within 2-4 business hours",
                          style: accountInter(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
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

  Widget _buildContactMethod(String title, String contact, String description,
      IconData icon, Color color) {
    if (isPhoneLayout(context)) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: GasPalette.muted),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: gasSmall(context)),
          const SizedBox(height: 4),
          SelectableText(contact.trim().isEmpty ? 'Not provided' : contact,
              style: gasBody(context).copyWith(color: GasPalette.ink, height: 1.4)),
        ])),
      ]);
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: accountInter(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  style: accountInter(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: accountInter(
                    context,
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingHoursCard() {
    return Container(
      decoration: accountSurface(
          context,
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
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
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Business Hours",
                  style: accountInter(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          // Hours List
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: tradingList.map((hours) {
                bool isWeekend =
                    hours.day_id == "saturday" || hours.day_id == "sunday";
                bool isToday = _isToday(hours.day_id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Constants.ctaColorGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? Constants.ctaColorGreen.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Constants.ctaColorGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (isToday) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Text(
                          hours.day,
                          style: accountInter(
                            context,
                            fontSize: 15,
                            fontWeight:
                                isToday ? FontWeight.w600 : FontWeight.w500,
                            color: isToday
                                ? Constants.ctaColorGreen
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isWeekend
                                    ? const Color(0xFFF59E0B).withOpacity(0.1)
                                    : const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hours.times,
                                style: accountInter(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isWeekend
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<FAQItem> faqs = [
      FAQItem(
        question: "How do I reset my password?",
        answer:
            "You can reset your password by clicking on the 'Forgot Password' link on the login page and following the instructions sent to your email.",
      ),
      FAQItem(
        question: "How can I update my account information?",
        answer:
            "Navigate to Settings > Profile to update your personal and business information.",
      ),
      FAQItem(
        question: "What payment methods do you accept?",
        answer:
            "We accept all major credit cards, bank transfers, and digital payment methods.",
      ),
    ];

    if (isPhoneLayout(context)) {
      return GPanel(padding: EdgeInsets.zero, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.all(14),
              child: Text('Common questions', style: gasTitle(context).copyWith(fontSize: 14))),
          for (final faq in faqs) ...[
            const Divider(height: 1, color: GasPalette.border),
            _buildFAQItem(faq),
          ],
        ],
      ));
    }
    return Container(
      decoration: accountSurface(
          context,
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
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
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(
                  "Frequently Asked Questions",
                  style: accountInter(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                )),
              ],
            ),
          ),

          // FAQ Items
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: faqs.map((faq) => _buildFAQItem(faq)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    if (isPhoneLayout(context)) {
      return Material(color: Colors.transparent, child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(), collapsedShape: const Border(),
        iconColor: GasPalette.ink2, collapsedIconColor: GasPalette.muted,
        title: Text(faq.question, style: gasBody(context).copyWith(color: GasPalette.ink)),
        children: [Text(faq.answer, style: gasBody(context).copyWith(height: 1.5))],
      ));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            title: Text(
              faq.question,
              style: accountInter(
                context,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  faq.answer,
                  style: accountInter(
                    context,
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          )),
    );
  }

  bool _isToday(String dayId) {
    final now = DateTime.now();
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final todayIndex = now.weekday - 1; // DateTime.weekday is 1-7, we need 0-6
    return weekdays[todayIndex] == dayId;
  }
}

class TradingHours {
  int id;
  String day_id;
  String day;
  String times;

  TradingHours({
    required this.id,
    required this.day_id,
    required this.day,
    this.times = "7am - 6pm",
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
