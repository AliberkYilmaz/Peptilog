import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../peptides/domain/peptide.dart';

/// A single tappable peptide color chip.
///
/// Shows the peptide name with a colored leading dot.
/// When [isSelected], renders with an amber border.
class PeptideChip extends StatelessWidget {
  const PeptideChip({
    super.key,
    required this.peptide,
    required this.isSelected,
    required this.onTap,
  });

  final Peptide peptide;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = _parseHex(peptide.color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.amber.withAlpha(26) // ~10% amber tint
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.amber : AppTheme.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              peptide.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.amber : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parses a hex color string like `#7B61FF` or `7B61FF`.
  static Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    }
    return AppTheme.amber;
  }
}
