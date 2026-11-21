import 'app_tone.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../services/auth_session.dart';
import '../services/biometric_lock.dart';

/// Put this in MaterialApp.builder so dialogs, deep links and standalone routes
/// are covered too. The navigator stays mounted while locked.
class BiometricSessionGate extends StatefulWidget {
  const BiometricSessionGate(
      {super.key, required this.child, required this.onSignIn, this.lock});
  final Widget child;
  final VoidCallback onSignIn;
  final BiometricLock? lock;

  @override
  State<BiometricSessionGate> createState() => _BiometricSessionGateState();
}

class _BiometricSessionGateState extends State<BiometricSessionGate>
    with WidgetsBindingObserver {
  late final _lock = widget.lock ?? BiometricLock.instance;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_lock.initialize().then((_) {
      if (mounted && _lock.locked && _lock.enabled) unawaited(_lock.unlock());
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lock.lock();
    } else if (state == AppLifecycleState.resumed && _lock.locked) {
      unawaited(_lock.unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _signingOut = true);
    try {
      await AuthSession.signOut();
    } catch (_) {
      // Never leave the user stuck behind the lock screen.
      _lock.sessionCleared();
    }
    if (!mounted) return;
    setState(() => _signingOut = false);
    widget.onSignIn();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _lock,
        builder: (context, _) {
          final hide = (_lock.supported && !_lock.initialized) ||
              _lock.locked ||
              _signingOut;
          return Stack(fit: StackFit.expand, children: [
            ExcludeSemantics(
                excluding: hide,
                child: Offstage(offstage: hide, child: widget.child)),
            if (hide)
              Material(
                  color: Tone.bg(const Color(0xFFF3F7FA)),
                  child: SafeArea(
                    child: Center(
                        child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Iconsax.lock,
                                size: 48, color: Tone.fg(Color(0xFF222B45))),
                            const SizedBox(height: 24),
                            Text('Your workspace is locked',
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            const Text(
                                'Use Face ID or your fingerprint to continue. You can also sign in again with your account.',
                                textAlign: TextAlign.center),
                            if (_lock.message != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(_lock.message!,
                                      textAlign: TextAlign.center)),
                            const SizedBox(height: 24),
                            if (_lock.busy || _signingOut || !_lock.initialized)
                              const CircularProgressIndicator()
                            else ...[
                              if (_lock.enabled)
                                SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                        onPressed: _lock.unlock,
                                        child: const Text('Unlock'))),
                              TextButton(
                                  onPressed: _signIn,
                                  child: const Text('Sign in instead')),
                            ],
                          ])),
                    )),
                  )),
          ]);
        },
      );
}

class BiometricSettingsTile extends StatelessWidget {
  const BiometricSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = BiometricLock.instance;
    if (!lock.supported) return const SizedBox.shrink();
    return ListenableBuilder(
        listenable: lock,
        builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Face ID / fingerprint unlock'),
                  subtitle: const Text(
                      'Lock this signed-in account when you leave the app. Applies to this phone only.'),
                  value: lock.enabled,
                  onChanged: lock.busy
                      ? null
                      : (value) async {
                          await lock.setEnabled(value);
                        },
                ),
                if (lock.message != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(lock.message!,
                          style: Theme.of(context).textTheme.bodySmall)),
              ],
            ));
  }
}
