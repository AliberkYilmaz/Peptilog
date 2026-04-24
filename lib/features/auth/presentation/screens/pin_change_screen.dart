import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/pin_repository.dart';
import 'widgets/pin_pad.dart';

enum _Step { currentPin, newPin, confirmPin }

class PinChangeScreen extends ConsumerStatefulWidget {
  const PinChangeScreen({super.key});

  @override
  ConsumerState<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends ConsumerState<PinChangeScreen> {
  _Step _step = _Step.currentPin;
  String _newPin = '';
  String _current = '';

  static const _pinLength = 6;

  String get _title => switch (_step) {
    _Step.currentPin => 'Enter Current PIN',
    _Step.newPin => 'Enter New PIN',
    _Step.confirmPin => 'Confirm New PIN',
  };

  void _onDigit(String digit) {
    if (_current.length >= _pinLength) return;
    setState(() => _current += digit);
    if (_current.length == _pinLength) _handleComplete();
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _handleComplete() async {
    await Future.delayed(const Duration(milliseconds: 120));

    switch (_step) {
      case _Step.currentPin:
        final ok = await ref.read(pinRepositoryProvider).verifyPin(_current);
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN — try again'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() => _current = '');
        } else {
          setState(() {
            _current = '';
            _step = _Step.newPin;
          });
        }

      case _Step.newPin:
        setState(() {
          _newPin = _current;
          _current = '';
          _step = _Step.confirmPin;
        });

      case _Step.confirmPin:
        if (_current != _newPin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PINs did not match — try again'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() {
            _newPin = '';
            _current = '';
            _step = _Step.newPin;
          });
        } else {
          await ref.read(pinRepositoryProvider).setPin(_current);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN updated successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(
      _pinLength,
      (i) => Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < _current.length ? AppTheme.amber : AppTheme.divider,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            _title,
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: dots),
          const Spacer(),
          PinPad(onDigit: _onDigit, onBackspace: _onBackspace),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
