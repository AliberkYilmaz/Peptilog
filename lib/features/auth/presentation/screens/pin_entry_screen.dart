import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/biometric_repository.dart';
import '../../data/pin_repository.dart';
import '../providers/pin_notifier.dart';
import 'widgets/pin_pad.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _current = '';
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _biometricTypes = [];

  static const _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final biometricRepo = ref.read(biometricRepositoryProvider);
    final pinRepo = ref.read(pinRepositoryProvider);
    final available = await biometricRepo.isAvailable();
    final enabled = await pinRepo.isBiometricEnabled();
    final types = available
        ? await biometricRepo.getAvailableBiometrics()
        : <BiometricType>[];

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricTypes = types;
      });
    }

    if (available && enabled) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await ref
        .read(pinNotifierProvider.notifier)
        .verifyWithBiometrics('Unlock Peptilog');
    if (ok && mounted) context.go('/dashboard');
  }

  void _onDigit(String digit) {
    if (_current.length >= _pinLength) return;
    setState(() => _current += digit);
    if (_current.length == _pinLength) _onComplete();
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _onComplete() async {
    await Future.delayed(const Duration(milliseconds: 120));
    final ok = await ref.read(pinNotifierProvider.notifier).verify(_current);
    if (mounted) {
      if (ok) {
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN — try again'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _current = '');
      }
    }
  }

  IconData get _biometricIcon {
    if (_biometricTypes.contains(BiometricType.face))
      return Icons.face_outlined;
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    final showBiometric = _biometricAvailable && _biometricEnabled;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Text(
              'Peptilog',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
            ),

            const SizedBox(height: 48),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _current.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.amber : Colors.transparent,
                    border: Border.all(
                      color: filled ? AppTheme.amber : AppTheme.divider,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            PinPad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              extraAction: showBiometric ? _tryBiometric : null,
              extraActionIcon: showBiometric ? _biometricIcon : null,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
