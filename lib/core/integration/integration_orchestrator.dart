import '../../features/expense_splitter/presentation/bloc/expense_bloc.dart';
import '../../features/timetable/presentation/bloc/timetable_bloc.dart';

/// Cross-module integration engine.
///
/// Registered as a singleton in GetIt. Called after every OCR result
/// to dispatch cross-cutting events to other BLoCs:
/// - Deadline detected → TimetableBloc.AddEventFromOcr
/// - Amount detected → ExpenseBloc.PreFillExpenseFromOcr
///
/// This is the "magic" of the app — a single scan can trigger
/// timetable entries and expense pre-fills automatically.
class IntegrationOrchestrator {
  final TimetableBloc _timetableBloc;
  final ExpenseBloc _expenseBloc;

  IntegrationOrchestrator({
    required TimetableBloc timetableBloc,
    required ExpenseBloc expenseBloc,
  })  : _timetableBloc = timetableBloc,
        _expenseBloc = expenseBloc;

  /// Process an OCR result and dispatch to relevant modules.
  void processOcrResult(OcrResult result) {
    if (result.hasDeadline) {
      _timetableBloc.add(AddEventFromOcr(
        deadline: result.deadline!,
        title: result.title ?? 'Scanned Deadline',
        linkedNoteId: result.noteId,
      ));
    }

    if (result.hasAmount) {
      _expenseBloc.add(PreFillExpenseFromOcr(
        amount: result.amount!,
        title: result.title ?? 'Scanned Receipt',
      ));
    }
  }
}

/// Lightweight data class representing an OCR scan result
/// for cross-module dispatch.
class OcrResult {
  final int? noteId;
  final String? title;
  final DateTime? deadline;
  final double? amount;

  const OcrResult({
    this.noteId,
    this.title,
    this.deadline,
    this.amount,
  });

  bool get hasDeadline => deadline != null;
  bool get hasAmount => amount != null && amount! > 0;
}
