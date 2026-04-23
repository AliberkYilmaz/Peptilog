import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/pin_notifier.dart';
import 'widgets/pin_pad.dart';

enum _SetupStep { enter, confirm }

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  _SetupStep _step = _SetupStep.enter;
  String _firstPin = '';
  String _current = '';

  static const _pinLength = 6;

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
    if (_step == _SetupStep.enter) {
      setState(() {
        _firstPin = _current;
        _current = '';
        _step = _SetupStep.confirm;
      });
    } else {
      if (_current == _firstPin) {
        final ok = await ref.read(pinNotifierProvider.notifier).setup(_current);
        if (ok && mounted) context.go('/dashboard');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PINs did not match — try again'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _firstPin = '';
            _current = '';
            _step = _SetupStep.enter;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Text(
              _step == _SetupStep.enter ? 'Set your PIN' : 'Confirm your PIN',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _step == _SetupStep.enter
                  ? 'Choose a 6-digit PIN to secure the app'
                  : 'Enter the same PIN again',
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

            PinPad(onDigit: _onDigit, onBackspace: _onBackspace),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
