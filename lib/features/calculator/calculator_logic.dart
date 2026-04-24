/// Pure peptide dosing calculator logic.
///
/// Formula from SPEC §10:
///   units = (desiredDoseMg / totalMg) × (reconVolumeMl × 100)
///   Rounded to the nearest whole unit (U-100 syringe).
///
/// All inputs must be > 0, and [desiredDoseMg] must be ≤ [totalMg].
/// Throws [ArgumentError] on invalid inputs.
int calculateUnits({
  required double totalMg,
  required double reconVolumeMl,
  required double desiredDoseMg,
}) {
  if (totalMg <= 0) {
    throw ArgumentError.value(totalMg, 'totalMg', 'must be > 0');
  }
  if (reconVolumeMl <= 0) {
    throw ArgumentError.value(reconVolumeMl, 'reconVolumeMl', 'must be > 0');
  }
  if (desiredDoseMg <= 0) {
    throw ArgumentError.value(desiredDoseMg, 'desiredDoseMg', 'must be > 0');
  }
  if (desiredDoseMg > totalMg) {
    throw ArgumentError(
      'desiredDoseMg ($desiredDoseMg) must be ≤ totalMg ($totalMg)',
    );
  }
  final raw = (desiredDoseMg / totalMg) * (reconVolumeMl * 100);
  return raw.round();
}
