import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';

/// Splits an expense equally among participants.
///
/// Handles:
/// - Zero amount validation
/// - Single participant validation (need >= 2)
/// - Float rounding: remainder assigned to first participant
/// - Returns a list of split amounts parallel to the participant list
class SplitExpenseUsecase {
  const SplitExpenseUsecase();

  Either<Failure, List<double>> call({
    required double totalAmount,
    required List<String> participants,
  }) {
    // Validate amount
    if (totalAmount <= 0) {
      return const Left(ValidationFailure(
        message: 'Amount must be greater than zero.',
        fieldErrors: {'amount': 'Enter a valid positive amount'},
      ));
    }

    // Validate participants
    if (participants.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Add at least ${AppConstants.minParticipants} participants.',
        fieldErrors: {'participants': 'Add participants to split with'},
      ));
    }

    if (participants.length < AppConstants.minParticipants) {
      return const Left(ValidationFailure(
        message:
            'Need at least ${AppConstants.minParticipants} participants to split.',
        fieldErrors: {'participants': 'Add more participants'},
      ));
    }

    // Calculate equal split, rounded to 2 decimal places
    final count = participants.length;
    final perPerson = (totalAmount * 100).floor() ~/ count;
    final perPersonAmount = perPerson / 100.0;

    // Calculate remainder (leftover from rounding)
    final totalSplit = perPersonAmount * count;
    final remainder =
        ((totalAmount * 100).round() - (totalSplit * 100).round()) / 100.0;

    // Assign remainder to first participant (standard accounting practice)
    final splits = List<double>.filled(count, perPersonAmount);
    if (remainder > 0) {
      splits[0] = double.parse(
        (splits[0] + remainder).toStringAsFixed(2),
      );
    }

    return Right(splits);
  }
}
