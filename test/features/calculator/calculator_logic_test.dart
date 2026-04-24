import 'package:flutter_test/flutter_test.dart';
import 'package:peptilog_app/features/calculator/calculator_logic.dart';

void main() {
  group('calculateUnits — formula correctness (SPEC §10)', () {
    // Formula: units = (desiredDose / totalMg) × (reconVolume × 100), rounded
    test('standard case: 5 mg vial, 2 mL recon, 0.25 mg dose → 10 units', () {
      // (0.25/5) × (2×100) = 0.05 × 200 = 10
      expect(
        calculateUnits(totalMg: 5, reconVolumeMl: 2, desiredDoseMg: 0.25),
        equals(10),
      );
    });

    test('1 mg vial, 1 mL recon, 1 mg dose → 100 units (full vial)', () {
      expect(
        calculateUnits(totalMg: 1, reconVolumeMl: 1, desiredDoseMg: 1),
        equals(100),
        // (1/1) × (1×100) = 100
      );
    });

    test('10 mg vial, 2 mL recon, 0.5 mg dose → 10 units', () {
      expect(
        calculateUnits(totalMg: 10, reconVolumeMl: 2, desiredDoseMg: 0.5),
        equals(10),
        // (0.5/10) × (2×100) = 0.05 × 200 = 10
      );
    });

    test('5 mg vial, 3 mL recon, 1 mg dose → 60 units', () {
      expect(
        calculateUnits(totalMg: 5, reconVolumeMl: 3, desiredDoseMg: 1),
        equals(60),
        // (1/5) × (3×100) = 0.2 × 300 = 60
      );
    });

    test('rounding: result is rounded to nearest integer', () {
      // (0.3/1) × (1×100) = 30 — exact
      expect(
        calculateUnits(totalMg: 1, reconVolumeMl: 1, desiredDoseMg: 0.3),
        equals(30),
      );
      // (0.333/1) × (1×100) = 33.3 → rounds to 33
      expect(
        calculateUnits(totalMg: 1, reconVolumeMl: 1, desiredDoseMg: 0.333),
        equals(33),
      );
      // (0.667/1) × (1×100) = 66.7 → rounds to 67
      expect(
        calculateUnits(totalMg: 1, reconVolumeMl: 1, desiredDoseMg: 0.667),
        equals(67),
      );
    });

    test('dose equals total mg → 100 units (1 mL recon)', () {
      expect(
        calculateUnits(totalMg: 5, reconVolumeMl: 1, desiredDoseMg: 5),
        equals(100),
        // (5/5) × (1×100) = 100
      );
    });

    test('small dose: 2 mg vial, 1 mL recon, 0.1 mg → 5 units', () {
      expect(
        calculateUnits(totalMg: 2, reconVolumeMl: 1, desiredDoseMg: 0.1),
        equals(5),
        // (0.1/2) × (1×100) = 0.05 × 100 = 5
      );
    });
  });

  group('calculateUnits — input validation', () {
    test('throws when totalMg is 0', () {
      expect(
        () => calculateUnits(totalMg: 0, reconVolumeMl: 1, desiredDoseMg: 0.5),
        throwsArgumentError,
      );
    });

    test('throws when totalMg is negative', () {
      expect(
        () =>
            calculateUnits(totalMg: -1, reconVolumeMl: 1, desiredDoseMg: 0.5),
        throwsArgumentError,
      );
    });

    test('throws when reconVolumeMl is 0', () {
      expect(
        () => calculateUnits(totalMg: 5, reconVolumeMl: 0, desiredDoseMg: 0.5),
        throwsArgumentError,
      );
    });

    test('throws when reconVolumeMl is negative', () {
      expect(
        () =>
            calculateUnits(totalMg: 5, reconVolumeMl: -2, desiredDoseMg: 0.5),
        throwsArgumentError,
      );
    });

    test('throws when desiredDoseMg is 0', () {
      expect(
        () => calculateUnits(totalMg: 5, reconVolumeMl: 1, desiredDoseMg: 0),
        throwsArgumentError,
      );
    });

    test('throws when desiredDoseMg is negative', () {
      expect(
        () =>
            calculateUnits(totalMg: 5, reconVolumeMl: 1, desiredDoseMg: -1),
        throwsArgumentError,
      );
    });

    test('throws when desiredDoseMg > totalMg', () {
      expect(
        () => calculateUnits(totalMg: 5, reconVolumeMl: 1, desiredDoseMg: 6),
        throwsArgumentError,
      );
    });

    test('does NOT throw when desiredDoseMg == totalMg', () {
      expect(
        () => calculateUnits(totalMg: 5, reconVolumeMl: 1, desiredDoseMg: 5),
        returnsNormally,
      );
    });
  });
}
