import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';

/// Numeric PIN pad — digits 1-9 in a 3x3 grid, then backspace | 0 | confirm.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.extraAction,
    this.extraActionIcon,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  /// Optional widget for the bottom-left cell (e.g. biometric button).
  final VoidCallback? extraAction;
  final IconData? extraActionIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          _row(['4', '5', '6']),
          _row(['7', '8', '9']),
          // Bottom row: extra | 0 | backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (extraAction != null && extraActionIcon != null)
                _iconKey(extraActionIcon!, extraAction!)
              else
                const SizedBox(width: 72, height: 72),
              _digitKey('0'),
              _iconKey(Icons.backspace_outlined, onBackspace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitKey).toList(),
    );
  }

  Widget _digitKey(String digit) {
    return _PadKey(
      onTap: () => onDigit(digit),
      child: Text(
        digit,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppTheme.onBackground,
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, VoidCallback onTap) {
    return _PadKey(
      onTap: onTap,
      child: Icon(icon, color: AppTheme.onSurface, size: 22),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
