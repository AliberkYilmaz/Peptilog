/// Pure vial order calculator logic.
///
/// Formula from SPEC §3.2, §11:
///   totalMgNeeded = dosePerInjection × injectionsPerWeek × weeks
///   vialsNeeded   = ceil(totalMgNeeded / mgPerVial)
///
/// All inputs must be > 0. Throws [ArgumentError] on invalid inputs.
int calculateVialsNeeded({
  required double dosePerInjectionMg,
  required double injectionsPerWeek,
  required double weeksOfSupply,
  required double mgPerVial,
}) {
  if (dosePerInjectionMg <= 0) {
    throw ArgumentError.value(
      dosePerInjectionMg,
      'dosePerInjectionMg',
      'must be > 0',
    );
  }
  if (injectionsPerWeek <= 0) {
    throw ArgumentError.value(
      injectionsPerWeek,
      'injectionsPerWeek',
      'must be > 0',
    );
  }
  if (weeksOfSupply <= 0) {
    throw ArgumentError.value(
      weeksOfSupply,
      'weeksOfSupply',
      'must be > 0',
    );
  }
  if (mgPerVial <= 0) {
    throw ArgumentError.value(mgPerVial, 'mgPerVial', 'must be > 0');
  }

  final totalMg = dosePerInjectionMg * injectionsPerWeek * weeksOfSupply;
  return (totalMg / mgPerVial).ceil();
}
