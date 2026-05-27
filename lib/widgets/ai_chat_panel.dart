import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/Constants.dart';
import '../services/ai_assistant_service.dart';

class _ChatTurn {
  final String role;
  final String content;
  _ChatTurn(this.role, this.content);
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
  String? _sessionId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
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
        _turns.add(_ChatTurn('assistant', response.answer));
        _busy = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final hasDevice = widget.deviceId != null && widget.deviceId!.isNotEmpty;

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
                child: Icon(Iconsax.message_question, color: Constants.ctaColorLight, size: 18),
              ),
              SizedBox(width: Constants.spacingSm),
              Expanded(
                child: Text(
                  hasDevice
                      ? 'Ask about ${widget.deviceName ?? widget.deviceId} '
                      : 'AI Assistant',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (_turns.isNotEmpty)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _turns.clear();
                            _sessionId = null;
                            _error = null;
                          }),
                  child: Text('Clear', style: GoogleFonts.inter(fontSize: 12)),
                ),
            ],
          ),
          SizedBox(height: Constants.spacingSm),
          if (_turns.isEmpty)
            _Suggestions(
              onTap: (s) {
                _controller.text = s;
                _send();
              },
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, minHeight: 60),
              child: ListView.builder(
                controller: _scroll,
                shrinkWrap: true,
                itemCount: _turns.length,
                itemBuilder: (context, i) => _Bubble(turn: _turns[i]),
              ),
            ),
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
                        ? 'How is this unit performing?'
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
                onPressed: _busy ? null : _send,
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Constants.ctaColorLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          turn.content,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.4,
            color: isUser ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _Suggestions({required this.onTap});

  static const _suggestions = [
    'Any issues with this unit?',
    "Today's energy report?",
    'When should it defrost next?',
    'Is there a refrigerant leak?',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions
          .map(
            (s) => ActionChip(
              label: Text(s, style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              onPressed: () => onTap(s),
            ),
          )
          .toList(),
    );
  }
}
