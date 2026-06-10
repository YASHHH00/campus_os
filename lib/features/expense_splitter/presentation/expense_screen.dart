import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/campus_app_bar.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../data/models/expense_model.dart';
import 'bloc/expense_bloc.dart';

/// Expense splitter screen — list, add, settle, and share expenses.
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const LoadExpensesRequested());
  }

  void _showAddExpenseSheet({double? prefillAmount, String? prefillTitle}) {
    final titleCtrl = TextEditingController(text: prefillTitle ?? '');
    final amountCtrl = TextEditingController(
        text: prefillAmount != null ? prefillAmount.toStringAsFixed(2) : '');
    final participantCtrl = TextEditingController();
    final participants = <String>[];
    String? paidBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Expense',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Dinner at Canteen',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total Amount (₹)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: participantCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add participant',
                          hintText: 'Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        if (participantCtrl.text.trim().isNotEmpty) {
                          setSheetState(() {
                            participants.add(participantCtrl.text.trim());
                            participantCtrl.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                if (participants.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: participants
                        .map((name) => Chip(
                              label: Text(name),
                              onDeleted: () {
                                setSheetState(() {
                                  participants.remove(name);
                                  if (paidBy == name) paidBy = null;
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paidBy,
                    decoration: const InputDecoration(labelText: 'Paid by'),
                    items: participants
                        .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: (val) => setSheetState(() => paidBy = val),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (titleCtrl.text.trim().isNotEmpty &&
                          amount > 0 &&
                          participants.length >= 2 &&
                          paidBy != null) {
                        context.read<ExpenseBloc>().add(AddExpenseRequested(
                              title: titleCtrl.text.trim(),
                              totalAmount: amount,
                              participants: participants,
                              paidBy: paidBy!,
                            ));
                        Navigator.pop(ctx);
                      } else {
                        ErrorSnackbar.showWarning(
                          context,
                          'Fill all fields and add at least 2 participants.',
                        );
                      }
                    },
                    child: const Text('Split & Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CampusAppBar(
        title: 'Expenses',
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Scan receipt',
            onPressed: () async {
              final image =
                  await _picker.pickImage(source: ImageSource.camera);
              if (image != null && mounted) {
                context
                    .read<ExpenseBloc>()
                    .add(ScanReceiptRequested(imagePath: image.path));
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          switch (state) {
            case ExpenseAddedSuccess():
              ErrorSnackbar.showSuccess(context, 'Expense split and saved!');
            case ReceiptScanned(receiptData: final data):
              final total = (data['total'] as num?)?.toDouble() ?? 0;
              _showAddExpenseSheet(
                prefillAmount: total > 0 ? total : null,
                prefillTitle: 'Scanned Receipt',
              );
            case ExpensePreFilled(amount: final amt, title: final title):
              _showAddExpenseSheet(prefillAmount: amt, prefillTitle: title);
            case ExpenseError(message: final msg):
              ErrorSnackbar.showError(context, msg);
            default:
              break;
          }
        },
        builder: (context, state) {
          return switch (state) {
            ExpensesLoaded(
              expenses: final expenses,
              totalOwed: final totalOwed
            ) =>
              _buildExpenseList(expenses, totalOwed),
            ExpenseLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
            _ => _buildExpenseList(const [], 0),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Split'),
        heroTag: 'add_expense_fab',
      ),
    );
  }

  Widget _buildExpenseList(List<ExpenseModel> expenses, double totalOwed) {
    if (expenses.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_rounded,
        title: 'No Expenses',
        subtitle: 'Split costs with friends by tapping the button below.',
      );
    }

    return Column(
      children: [
        // Total owed banner
        if (totalOwed > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Unsettled Total',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalOwed.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

        // Expense list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: expenses.length,
            itemBuilder: (context, index) =>
                _ExpenseTile(expense: expenses[index]),
          ),
        ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: expense.isSettled
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  expense.isSettled
                      ? Icons.check_circle_rounded
                      : Icons.receipt_rounded,
                  color: expense.isSettled
                      ? AppColors.success
                      : AppColors.accentAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.participantNames.length} people • ${AppDateUtils.timeAgo(expense.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${expense.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Paid by ${expense.paidBy} • ₹${expense.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ...List.generate(expense.participantNames.length, (i) {
                final name = expense.participantNames[i];
                final amount = i < expense.splitAmounts.length
                    ? expense.splitAmounts[i]
                    : 0.0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primaryPurple.withValues(alpha: 0.15),
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(name),
                  trailing: Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<ExpenseBloc>().add(
                              ShareExpenseRequested(expense: expense),
                            );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!expense.isSettled)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (expense.id != null) {
                            context.read<ExpenseBloc>().add(
                                  SettleExpenseRequested(
                                      expenseId: expense.id!),
                                );
                          }
                        },
                        child: const Text('Settle Up'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
