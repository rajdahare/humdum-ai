import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get monthTotal => _expenses
      .where((e) => e.createdAt.month == DateTime.now().month && e.createdAt.year == DateTime.now().year)
      .fold(0.0, (a, b) => a + b.amount);

  Future<void> addExpense({
    required double amount,
    required String category,
    String? note,
    String? photoPath,
  }) async {
    await ApiService.post('/expense/add', {
      'amount': amount,
      'category': category,
      'note': note,
    });

    final exp = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      note: note,
      photoPath: photoPath,
      createdAt: DateTime.now(),
    );
    _expenses.add(exp);
    notifyListeners();
  }
}


