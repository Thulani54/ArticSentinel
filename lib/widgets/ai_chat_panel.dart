import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/Constants.dart';
import '../services/ai_assistant_service.dart';

class _ChatTurn {
  final String role;
  final String content;
  final List<Map<String, dynamic>> toolCalls;
  _ChatTurn(this.role, this.content, {this.toolCalls = const []});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'tool_calls': toolCalls,
      };

  factory _ChatTurn.fromJson(Map<String, dynamic> json) => _ChatTurn(
        json['role']?.toString() ?? 'assistant',
        json['content']?.toString() ?? '',
        toolCalls: ((json['tool_calls'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
      );
}

class AIChatPanel extends StatefulWidget {
  final String? deviceId;
  final String? deviceName;

  const AIChatPanel({super.key, required this.deviceId, this.deviceName});

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatTurn> _turns = [];
  List<String> _suggestedFollowups = const [];
  String? _sessionId;
  bool _busy = false;
  String? _error;

  static const _defaultSuggestions = [
    'Any issues with this unit?',
    "How did it perform this week vs last week?",
    'How much did it cost me this week?',
    'When should it defrost next?',
  ];

  @override
  void initState() {
    super.initState();
    _restoreHistory();
  }

  @override
  void didUpdateWidget(covariant AIChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      setState(() {
        _turns.clear();
        _sessionId = null;
        _error = null;
        _suggestedFollowups = const [];
      });
      _restoreHistory();
    }
  }

  String? get _storageKey {
    final id = widget.deviceId;
    if (id == null || id.isEmpty) return null;
    return 'ai_chat_history_v1_${Constants.myBusiness.businessUid}_$id';
  }

  Future<void> _restoreHistory() async {
    final key = _storageKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List).cast<dynamic>();
      if (!mounted) return;
      setState(() {
        _turns.addAll(list
            .map((e) => _ChatTurn.fromJson((e as Map).cast<String, dynamic>()))
            .where((t) => t.content.trim().isNotEmpty));
      });
      _scrollToBottom();
    } catch (_) {
      // corrupt history — silently ignore
    }
  }

  Future<void> _persistHistory() async {
    final key = _storageKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // keep last 30 turns max
      final tail = _turns.length > 30 ? _turns.sublist(_turns.length - 30) : _turns;
      await prefs.setString(key, jsonEncode(tail.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _busy) return;

    final deviceId = widget.deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      setState(() => _error = 'Pick a device first so I can answer with its data.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _turns.add(_ChatTurn('user', text));
      _suggestedFollowups = const [];
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await AIAssistantService.sendMessage(
        businessId: Constants.myBusiness.businessUid,
        deviceId: deviceId,
        message: text,
        history: _turns
            .where((t) => t.role == 'user' || t.role == 'assistant')
            .map((t) => {'role': t.role, 'content': t.content})
            .toList(),
        sessionId: _sessionId,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = response.sessionId.isNotEmpty ? response.sessionId : _sessionId;
        _turns.add(_ChatTurn('assistant', response.answer, toolCalls: response.toolCalls));
        _suggestedFollowups = response.suggestedFollowups;
        _busy = false;
      });
      _persistHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearHistory() async {
    setState(() {
      _turns.clear();
      _sessionId = null;
      _error = null;
      _suggestedFollowups = const [];
    });
    final key = _storageKey;
    if (key != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDevice = widget.deviceId != null && widget.deviceId!.isNotEmpty;
    final activeSuggestions = _turns.isEmpty ? _defaultSuggestions : _suggestedFollowups;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Constants.spacingMd),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(Constants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.cpu, color: Constants.ctaColorLight, size: 18),
              ),
              SizedBox(width: Constants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Assistant',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      hasDevice
                          ? 'Ask about ${widget.deviceName ?? widget.deviceId}'
                          : 'Select a device to begin',
                      style: GoogleFonts.inter(fontSize: 11, color: Constants.ctaTextColor),
                    ),
                  ],
                ),
              ),
              if (_turns.isNotEmpty)
                TextButton.icon(
                  onPressed: _busy ? null : _clearHistory,
                  icon: const Icon(Iconsax.trash, size: 14),
                  label: Text('Clear', style: GoogleFonts.inter(fontSize: 12)),
                ),
            ],
          ),
          SizedBox(height: Constants.spacingSm),
          if (_turns.isEmpty && !_busy)
            _Suggestions(suggestions: activeSuggestions, onTap: (s) => _send(s))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360, minHeight: 80),
              child: ListView.builder(
                controller: _scroll,
                shrinkWrap: true,
                itemCount: _turns.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_busy && i == _turns.length) return const _TypingIndicator();
                  return _Bubble(turn: _turns[i]);
                },
              ),
            ),
          if (_turns.isNotEmpty && !_busy && activeSuggestions.isNotEmpty) ...[
            SizedBox(height: Constants.spacingSm),
            _Suggestions(suggestions: activeSuggestions, onTap: (s) => _send(s), compact: true),
          ],
          if (_error != null) ...[
            SizedBox(height: Constants.spacingSm),
            Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: Constants.criticalColor)),
          ],
          SizedBox(height: Constants.spacingMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_busy,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: hasDevice
                        ? 'Ask anything about this unit…'
                        : 'Select a device first…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Constants.ctaTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Constants.ctaColorLight, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
              SizedBox(width: Constants.spacingSm),
              ElevatedButton(
                onPressed: _busy ? null : () => _send(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Iconsax.send_1, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _Bubble extends StatelessWidget {
  final _ChatTurn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? Constants.ctaColorLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              Text(
                turn.content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
              )
            else
              MarkdownBody(
                data: turn.content,
                shrinkWrap: true,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.inter(fontSize: 13, height: 1.45, color: const Color(0xFF111827)),
                  strong: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  em: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF111827)),
                  listBullet: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
                  code: GoogleFonts.robotoMono(fontSize: 12, backgroundColor: const Color(0xFFE5E7EB)),
                ),
              ),
            if (turn.toolCalls.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: turn.toolCalls
                    .map((tc) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            '${tc['name']}',
                            style: GoogleFonts.robotoMono(fontSize: 10, color: const Color(0xFF6B7280)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (t + i / 3) % 1.0;
                final scale = 0.6 + 0.6 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  final bool compact;
  const _Suggestions({required this.suggestions, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: suggestions
          .map(
            (s) => ActionChip(
              label: Text(s, style: GoogleFonts.inter(fontSize: compact ? 11 : 12)),
              backgroundColor: compact ? Colors.white : const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
              onPressed: () => onTap(s),
            ),
          )
          .toList(),
    );
  }
}
