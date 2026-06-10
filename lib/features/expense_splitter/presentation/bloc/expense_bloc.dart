import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/isar_service.dart';
import '../../data/models/expense_model.dart';
import '../../domain/usecases/scan_receipt_usecase.dart';
import '../../domain/usecases/split_expense_usecase.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

final class LoadExpensesRequested extends ExpenseEvent {
  const LoadExpensesRequested();
}

final class AddExpenseRequested extends ExpenseEvent {
  final String title;
  final double totalAmount;
  final List<String> participants;
  final String paidBy;
  final String? receiptImagePath;
  const AddExpenseRequested({
    required this.title,
    required this.totalAmount,
    required this.participants,
    required this.paidBy,
    this.receiptImagePath,
  });
  @override
  List<Object?> get props =>
      [title, totalAmount, participants, paidBy, receiptImagePath];
}

final class PreFillExpenseFromOcr extends ExpenseEvent {
  final double amount;
  final String title;
  const PreFillExpenseFromOcr({required this.amount, required this.title});
  @override
  List<Object?> get props => [amount, title];
}

final class ScanReceiptRequested extends ExpenseEvent {
  final String imagePath;
  const ScanReceiptRequested({required this.imagePath});
  @override
  List<Object?> get props => [imagePath];
}

final class SettleExpenseRequested extends ExpenseEvent {
  final int expenseId;
  const SettleExpenseRequested({required this.expenseId});
  @override
  List<Object?> get props => [expenseId];
}

final class ShareExpenseRequested extends ExpenseEvent {
  final ExpenseModel expense;
  const ShareExpenseRequested({required this.expense});
  @override
  List<Object?> get props => [expense];
}

final class DeleteExpenseRequested extends ExpenseEvent {
  final int expenseId;
  const DeleteExpenseRequested({required this.expenseId});
  @override
  List<Object?> get props => [expenseId];
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class ExpenseState extends Equatable {
  const ExpenseState();
  @override
  List<Object?> get props => [];
}

final class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

final class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

final class ExpensesLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final double totalOwed;
  const ExpensesLoaded({required this.expenses, required this.totalOwed});
  @override
  List<Object?> get props => [expenses, totalOwed];
}

final class ExpenseAddedSuccess extends ExpenseState {
  const ExpenseAddedSuccess();
}

final class ReceiptScanned extends ExpenseState {
  final Map<String, dynamic> receiptData;
  const ReceiptScanned({required this.receiptData});
  @override
  List<Object?> get props => [receiptData];
}

final class ExpensePreFilled extends ExpenseState {
  final double amount;
  final String title;
  const ExpensePreFilled({required this.amount, required this.title});
  @override
  List<Object?> get props => [amount, title];
}

final class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final SplitExpenseUsecase _splitExpenseUsecase;
  final ScanReceiptUsecase _scanReceiptUsecase;
  final DatabaseService _databaseService;

  ExpenseBloc({
    required SplitExpenseUsecase splitExpenseUsecase,
    required ScanReceiptUsecase scanReceiptUsecase,
    required DatabaseService databaseService,
  })  : _splitExpenseUsecase = splitExpenseUsecase,
        _scanReceiptUsecase = scanReceiptUsecase,
        _databaseService = databaseService,
        super(const ExpenseInitial()) {
    on<LoadExpensesRequested>(_onLoadExpenses);
    on<AddExpenseRequested>(_onAddExpense);
    on<PreFillExpenseFromOcr>(_onPreFillFromOcr);
    on<ScanReceiptRequested>(_onScanReceipt);
    on<SettleExpenseRequested>(_onSettleExpense);
    on<ShareExpenseRequested>(_onShareExpense);
    on<DeleteExpenseRequested>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
    LoadExpensesRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());

    try {
      final db = await _databaseService.database;
      final results = await db.query('expenses', orderBy: 'created_at DESC');
      final expenses = results.map((m) => ExpenseModel.fromMap(m)).toList();

      final totalOwed = expenses
          .where((e) => !e.isSettled)
          .fold(0.0, (sum, e) => sum + e.totalAmount);

      emit(ExpensesLoaded(expenses: expenses, totalOwed: totalOwed));
    } catch (e) {
      emit(ExpenseError(message: 'Failed to load expenses: $e'));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    // Calculate splits
    final splitResult = _splitExpenseUsecase(
      totalAmount: event.totalAmount,
      participants: event.participants,
    );

    final splits = splitResult.fold(
      (failure) {
        emit(ExpenseError(message: failure.message));
        return null;
      },
      (splits) => splits,
    );

    if (splits == null) return;

    try {
      final expense = ExpenseModel(
        title: event.title,
        totalAmount: event.totalAmount,
        participantNames: event.participants,
        splitAmounts: splits,
        paidBy: event.paidBy,
        receiptImagePath: event.receiptImagePath,
        createdAt: DateTime.now(),
      );

      final db = await _databaseService.database;
      await db.insert('expenses', expense.toMap());

      emit(const ExpenseAddedSuccess());
      add(const LoadExpensesRequested());
    } catch (e) {
      emit(ExpenseError(message: 'Failed to save expense: $e'));
    }
  }

  Future<void> _onPreFillFromOcr(
    PreFillExpenseFromOcr event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpensePreFilled(amount: event.amount, title: event.title));
  }

  Future<void> _onScanReceipt(
    ScanReceiptRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());

    final result = await _scanReceiptUsecase(event.imagePath);

    result.fold(
      (failure) => emit(ExpenseError(message: failure.message)),
      (data) => emit(ReceiptScanned(receiptData: data)),
    );
  }

  Future<void> _onSettleExpense(
    SettleExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'expenses',
        {'is_settled': 1},
        where: 'id = ?',
        whereArgs: [event.expenseId],
      );
      add(const LoadExpensesRequested());
    } catch (e) {
      emit(ExpenseError(message: 'Failed to settle expense: $e'));
    }
  }

  Future<void> _onShareExpense(
    ShareExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await Share.share(event.expense.toShareString());
    } catch (e) {
      emit(ExpenseError(message: 'Failed to share: $e'));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [event.expenseId]);
      add(const LoadExpensesRequested());
    } catch (e) {
      emit(ExpenseError(message: 'Failed to delete expense: $e'));
    }
  }
}
