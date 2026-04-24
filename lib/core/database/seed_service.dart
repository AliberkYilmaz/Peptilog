import 'package:isar/isar.dart';

import '../../features/peptides/domain/peptide.dart';

/// Seeds the 5 preset peptides defined in SPEC.md §9.1.
/// Runs once on first launch (idempotent — skips if presets already exist).
class SeedService {
  final Isar _isar;

  const SeedService(this._isar);

  static const _presets = [
    _PresetPeptide(name: 'Tirzepatide', color: '#7B61FF', unit: 'mg'),
    _PresetPeptide(name: 'GHK-Cu', color: '#3A86FF', unit: 'mg'),
    _PresetPeptide(name: 'NAD+', color: '#2EC4B6', unit: 'mg'),
    _PresetPeptide(name: 'Retatrutide', color: '#FB5607', unit: 'mg'),
    _PresetPeptide(name: 'Tesamorelin', color: '#FFBE0B', unit: 'mg'),
  ];

  Future<void> seedPresetsIfNeeded() async {
    final existingCount = await _isar.peptides
        .filter()
        .isCustomEqualTo(false)
        .count();

    if (existingCount >= _presets.length) return;

    await _isar.writeTxn(() async {
      for (final preset in _presets) {
        final exists = await _isar.peptides
            .filter()
            .nameEqualTo(preset.name)
            .findFirst();
        if (exists != null) continue;

        await _isar.peptides.put(
          Peptide()
            ..name = preset.name
            ..color = preset.color
            ..unit = preset.unit
            ..isActive = true
            ..isCustom = false
            ..updatedAt = DateTime.now(),
        );
      }
    });
  }
}

class _PresetPeptide {
  final String name;
  final String color;
  final String unit;
  const _PresetPeptide({
    required this.name,
    required this.color,
    required this.unit,
  });
}
