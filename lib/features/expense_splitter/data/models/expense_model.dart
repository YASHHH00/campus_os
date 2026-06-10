import 'dart:convert';

/// SQLite-backed data model for shared expenses.
class ExpenseModel {
  final int? id;
  final String title;
  final double totalAmount;
  final List<String> participantNames;
  final List<double> splitAmounts; // parallel array with participantNames
  final String paidBy;
  final String? receiptImagePath;
  final bool isSettled;
  final DateTime createdAt;

  const ExpenseModel({
    this.id,
    required this.title,
    required this.totalAmount,
    required this.participantNames,
    required this.splitAmounts,
    required this.paidBy,
    this.receiptImagePath,
    this.isSettled = false,
    required this.createdAt,
  });

  ExpenseModel copyWith({
    int? id,
    String? title,
    double? totalAmount,
    List<String>? participantNames,
    List<double>? splitAmounts,
    String? paidBy,
    String? receiptImagePath,
    bool? isSettled,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      participantNames: participantNames ?? this.participantNames,
      splitAmounts: splitAmounts ?? this.splitAmounts,
      paidBy: paidBy ?? this.paidBy,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Build a WhatsApp-shareable formatted string.
  String toShareString() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Expense: $title');
    buffer.writeln('Total: ₹${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('Paid by: $paidBy');
    buffer.writeln('');
    buffer.writeln('Split:');
    for (var i = 0; i < participantNames.length; i++) {
      final amount = i < splitAmounts.length ? splitAmounts[i] : 0.0;
      buffer.writeln(
          '${participantNames[i]}: ₹${amount.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln('— Sent via Campus OS');
    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'total_amount': totalAmount,
      'participant_names': jsonEncode(participantNames),
      'split_amounts': jsonEncode(splitAmounts),
      'paid_by': paidBy,
      'receipt_image_path': receiptImagePath,
      'is_settled': isSettled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      participantNames: _parseStringList(map['participant_names']),
      splitAmounts: _parseDoubleList(map['split_amounts']),
      paidBy: map['paid_by'] as String? ?? '',
      receiptImagePath: map['receipt_image_path'] as String?,
      isSettled: (map['is_settled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null || raw == '') return [];
    try {
      return (jsonDecode(raw as String) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  static List<double> _parseDoubleList(dynamic raw) {
    if (raw == null || raw == '') return [];
    try {
      return (jsonDecode(raw as String) as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } catch (_) {
      return [];
    }
  }
}
