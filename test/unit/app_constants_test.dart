import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/core/constants/app_constants.dart';

void main() {
  group('AppConstants thresholds', () {
    test('journalPageSize is positive', () {
      expect(AppConstants.journalPageSize, greaterThan(0));
    });

    test('safeIncomeMax equals warningIncomeMin (contiguous range)', () {
      // safe:    amount < safeIncomeMax
      // warning: safeIncomeMax <= amount < warningIncomeMax
      // exceeded: amount >= exceededIncomeMin
      expect(AppConstants.safeIncomeMax, equals(AppConstants.warningIncomeMin));
    });

    test('warningIncomeMax equals exceededIncomeMin (contiguous range)', () {
      expect(
        AppConstants.warningIncomeMax,
        equals(AppConstants.exceededIncomeMin),
      );
    });

    test('warning range is valid (min < max)', () {
      expect(
        AppConstants.warningIncomeMin,
        lessThan(AppConstants.warningIncomeMax),
      );
    });

    test('deposit thresholds are valid', () {
      expect(
        AppConstants.warningDepositMin,
        lessThan(AppConstants.warningDepositMax),
      );
      expect(
        AppConstants.warningDepositMax,
        equals(AppConstants.successDepositThreshold),
      );
    });
  });
}
