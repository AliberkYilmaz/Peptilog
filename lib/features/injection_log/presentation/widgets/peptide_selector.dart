import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../peptides/domain/peptide.dart';
import '../providers/quick_log_notifier.dart';
import 'peptide_chip.dart';

/// Horizontally-scrollable row of [PeptideChip]s for the active peptide list.
///
/// Reads [activePeptidesProvider] and shows a loading / empty / chip state.
/// The selected peptide is driven by [quickLogProvider].
class PeptideSelector extends ConsumerWidget {
  const PeptideSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peptidesAsync = ref.watch(activePeptidesProvider);
    final selectedPeptide = ref.watch(
      quickLogProvider.select((s) => s.selectedPeptide),
    );
    final notifier = ref.read(quickLogProvider.notifier);

    return peptidesAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, st) => const SizedBox.shrink(),
      data: (peptides) {
        if (peptides.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No active peptides — add one in Profile',
              style: TextStyle(
                color: AppTheme.onSurface.withAlpha(153),
                fontSize: 13,
              ),
            ),
          );
        }
        return _ChipRow(
          peptides: peptides,
          selectedPeptide: selectedPeptide,
          onSelect: notifier.selectPeptide,
        );
      },
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.peptides,
    required this.selectedPeptide,
    required this.onSelect,
  });

  final List<Peptide> peptides;
  final Peptide? selectedPeptide;
  final void Function(Peptide) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        itemCount: peptides.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final peptide = peptides[index];
          return PeptideChip(
            peptide: peptide,
            isSelected: selectedPeptide?.id == peptide.id,
            onTap: () => onSelect(peptide),
          );
        },
      ),
    );
  }
}
