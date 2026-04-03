import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/budget.dart';

class LocalStorageService {
  static const String _expensesKey = 'expenses_data';
  static const String _budgetsKey = 'budgets_data';

  // --- Expenses ---
  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString(_expensesKey);
    if (expensesJson == null) return [];
    
    final List<dynamic> decodedList = jsonDecode(expensesJson);
    return decodedList.map((item) => Expense.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(expenses.map((e) => e.toMap()).toList());
    await prefs.setString(_expensesKey, encodedList);
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await saveExpenses(expenses);
  }

  Future<void> deleteExpense(String id) async {
    final expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == id);
    await saveExpenses(expenses);
  }

  // --- Budgets ---
  Future<List<Budget>> getBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? budgetsJson = prefs.getString(_budgetsKey);
    if (budgetsJson == null) return [];
    
    final List<dynamic> decodedList = jsonDecode(budgetsJson);
    return decodedList.map((item) => Budget.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(budgets.map((b) => b.toMap()).toList());
    await prefs.setString(_budgetsKey, encodedList);
  }
}
