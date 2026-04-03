import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/local_storage_service.dart';
import '../constants/categories.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Expense> _cachedExpenses = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final expenses = await _storageService.getExpenses();
    // Sort by date descending (newest first)
    expenses.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _cachedExpenses = expenses;
      _isLoading = false;
    });
  }

  Future<void> _navigateToAddScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  void _deleteExpense(Expense expense) async {
    await _storageService.deleteExpense(expense.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _storageService.addExpense(expense);
              _loadExpenses();
            },
          ),
        ),
      );
    }
    _loadExpenses();
  }

  List<Expense> get _filteredExpenses {
    if (_selectedFilter == 'All') return _cachedExpenses;
    return _cachedExpenses.where((e) => e.category == _selectedFilter).toList();
  }

  Map<String, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final grouped = <String, List<Expense>>{};
    for (var current in expenses) {
      final dateString = DateFormat('MMM d, yyyy').format(current.date);
      if (grouped[dateString] == null) {
        grouped[dateString] = [];
      }
      grouped[dateString]!.add(current);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final displayedExpenses = _filteredExpenses;
    final groupedExpenses = _groupExpensesByDate(displayedExpenses);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Section
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  ...AppCategories.defaultCategories.map((c) => _buildFilterChip(c.name)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Expense List Section
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : displayedExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No expenses yet!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Tap the + button to add your first expense.', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: groupedExpenses.keys.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedExpenses.keys.elementAt(index);
                          final expensesForDate = groupedExpenses[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                                child: Text(
                                  dateKey,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              ...expensesForDate.map((expense) {
                                final cat = AppCategories.defaultCategories.firstWhere(
                                  (c) => c.name == expense.category,
                                  orElse: () => AppCategories.defaultCategories.last,
                                );
                                return Dismissible(
                                  key: ValueKey(expense.id),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) => _deleteExpense(expense),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: cat.color.withOpacity(0.2),
                                        child: Icon(cat.icon, color: cat.color),
                                      ),
                                      title: Text(expense.title),
                                      subtitle: expense.note != null && expense.note!.isNotEmpty 
                                          ? Text(expense.note!) 
                                          : Text(expense.category),
                                      trailing: Text(
                                        '\$${expense.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String title) {
    final isSelected = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(title),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = title;
          });
        },
      ),
    );
  }
}
