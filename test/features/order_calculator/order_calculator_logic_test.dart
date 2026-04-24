import 'package:flutter_test/flutter_test.dart';
import 'package:peptilog_app/features/order_calculator/order_calculator_logic.dart';

void main() {
  group('calculateVialsNeeded — formula correctness (SPEC §3.2, §11)', () {
    // Formula: vials = ceil(dose × injections/week × weeks / mgPerVial)

    test('exact division: 0.5 mg × 3/week × 4 weeks ÷ 6 mg = 1 vial', () {
      // totalMg = 0.5 × 3 × 4 = 6, 6 / 6 = 1.0 → ceil = 1
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 3,
          weeksOfSupply: 4,
          mgPerVial: 6,
        ),
        equals(1),
      );
    });

    test('always rounds up: 0.5 mg × 3/week × 4 weeks ÷ 5 mg = 2 vials', () {
      // totalMg = 6, 6 / 5 = 1.2 → ceil = 2
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 3,
          weeksOfSupply: 4,
          mgPerVial: 5,
        ),
        equals(2),
      );
    });

    test('1 mg × 1/week × 10 weeks ÷ 5 mg = 2 vials', () {
      // totalMg = 10, 10 / 5 = 2.0 → ceil = 2
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 1,
          injectionsPerWeek: 1,
          weeksOfSupply: 10,
          mgPerVial: 5,
        ),
        equals(2),
      );
    });

    test('small dose: 0.25 mg × 2/week × 8 weeks ÷ 5 mg = 1 vial', () {
      // totalMg = 4, 4 / 5 = 0.8 → ceil = 1
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 0.25,
          injectionsPerWeek: 2,
          weeksOfSupply: 8,
          mgPerVial: 5,
        ),
        equals(1),
      );
    });

    test('large supply: 2 mg × 5/week × 12 weeks ÷ 10 mg = 12 vials', () {
      // totalMg = 120, 120 / 10 = 12.0 → ceil = 12
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 2,
          injectionsPerWeek: 5,
          weeksOfSupply: 12,
          mgPerVial: 10,
        ),
        equals(12),
      );
    });

    test('always rounds up (fractional): 1 mg × 1/week × 1 week ÷ 3 mg = 1 vial', () {
      // totalMg = 1, 1 / 3 ≈ 0.333 → ceil = 1
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 1,
          injectionsPerWeek: 1,
          weeksOfSupply: 1,
          mgPerVial: 3,
        ),
        equals(1),
      );
    });

    test('daily injection: 0.3 mg × 7/week × 4 weeks ÷ 5 mg = 2 vials', () {
      // totalMg = 8.4, 8.4 / 5 = 1.68 → ceil = 2
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 0.3,
          injectionsPerWeek: 7,
          weeksOfSupply: 4,
          mgPerVial: 5,
        ),
        equals(2),
      );
    });

    test('ceil semantics: exactly N vials returns N, not N+1', () {
      // totalMg = 1 × 2 × 5 = 10, 10 / 5 = 2 (exact) → ceil = 2
      expect(
        calculateVialsNeeded(
          dosePerInjectionMg: 1,
          injectionsPerWeek: 2,
          weeksOfSupply: 5,
          mgPerVial: 5,
        ),
        equals(2),
      );
    });
  });

  group('calculateVialsNeeded — input validation', () {
    test('throws when dosePerInjectionMg is 0', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0,
          injectionsPerWeek: 3,
          weeksOfSupply: 4,
          mgPerVial: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws when dosePerInjectionMg is negative', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: -1,
          injectionsPerWeek: 3,
          weeksOfSupply: 4,
          mgPerVial: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws when injectionsPerWeek is 0', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 0,
          weeksOfSupply: 4,
          mgPerVial: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws when injectionsPerWeek is negative', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: -2,
          weeksOfSupply: 4,
          mgPerVial: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws when weeksOfSupply is 0', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 3,
          weeksOfSupply: 0,
          mgPerVial: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws when weeksOfSupply is negative', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 3,
          weeksOfSupply: -4,
          mgPerVial: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws when mgPerVial is 0', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 3,
          weeksOfSupply: 4,
          mgPerVial: 0,
        ),
        throwsArgumentError,
      );
    });

    test('throws when mgPerVial is negative', () {
      expect(
        () => calculateVialsNeeded(
          dosePerInjectionMg: 0.5,
          injectionsPerWeek: 3,
          weeksOfSupply: 4,
          mgPerVial: -5,
        ),
        throwsArgumentError,
      );
    });
  });
}
