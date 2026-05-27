import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/Constants.dart';
import '../services/ai_assistant_service.dart';

class AIAlertsSettingsTile extends StatefulWidget {
  const AIAlertsSettingsTile({super.key});

  @override
  State<AIAlertsSettingsTile> createState() => _AIAlertsSettingsTileState();
}

class _AIAlertsSettingsTileState extends State<AIAlertsSettingsTile> {
  AIAlertSettings? _settings;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final s = await AIAssistantService.getSettings(Constants.myBusiness.businessUid);
      if (!mounted) return;
      setState(() {
        _settings = s;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save(AIAlertSettings updated) async {
    setState(() {
      _settings = updated;
      _busy = true;
      _error = null;
    });
    try {
      final saved = await AIAssistantService.updateSettings(
        businessId: Constants.myBusiness.businessUid,
        settings: updated,
      );
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Alerts', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(
                      'Get plain-English alerts from the AI when something looks off.',
                      style: GoogleFonts.inter(fontSize: 12, color: Constants.ctaTextColor),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: _settings?.enabled ?? false,
                  onChanged: _settings == null
                      ? null
                      : (v) => _save(AIAlertSettings(
                            enabled: v,
                            compressorHealth: _settings!.compressorHealth,
                            leakDetection: _settings!.leakDetection,
                            smartDefrost: _settings!.smartDefrost,
                            minSeverity: _settings!.minSeverity,
                          )),
                  activeColor: Constants.ctaColorGreen,
                ),
            ],
          ),
          if (_settings != null && _settings!.enabled) ...[
            const Divider(height: 24),
            _featureRow(
              'Compressor health monitor',
              _settings!.compressorHealth,
              (v) => _save(AIAlertSettings(
                enabled: _settings!.enabled,
                compressorHealth: v,
                leakDetection: _settings!.leakDetection,
                smartDefrost: _settings!.smartDefrost,
                minSeverity: _settings!.minSeverity,
              )),
            ),
            _featureRow(
              'Refrigerant leak detection',
              _settings!.leakDetection,
              (v) => _save(AIAlertSettings(
                enabled: _settings!.enabled,
                compressorHealth: _settings!.compressorHealth,
                leakDetection: v,
                smartDefrost: _settings!.smartDefrost,
                minSeverity: _settings!.minSeverity,
              )),
            ),
            _featureRow(
              'Smart defrost recommendations',
              _settings!.smartDefrost,
              (v) => _save(AIAlertSettings(
                enabled: _settings!.enabled,
                compressorHealth: _settings!.compressorHealth,
                leakDetection: _settings!.leakDetection,
                smartDefrost: v,
                minSeverity: _settings!.minSeverity,
              )),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: Constants.criticalColor)),
          ],
        ],
      ),
    );
  }

  Widget _featureRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13))),
          Switch(value: value, onChanged: _busy ? null : onChanged, activeColor: Constants.ctaColorGreen),
        ],
      ),
    );
  }
}
