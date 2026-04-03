import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../constants/categories.dart';
import '../services/local_storage_service.dart';
import 'add_expense_screen.dart';
import 'budget_setup_screen.dart';
import 'expense_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  
  double _totalSpentThisMonth = 0;
  List<Budget> _budgets = [];
  Map<String, double> _categorySpentMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    final expenses = await _storageService.getExpenses();
    final budgets = await _storageService.getBudgets();
    
    final now = DateTime.now();
    double totalSpent = 0;
    Map<String, double> catSpent = {};

    for (var expense in expenses) {
      if (expense.date.month == now.month && expense.date.year == now.year) {
        totalSpent += expense.amount;
        catSpent[expense.category] = (catSpent[expense.category] ?? 0) + expense.amount;
      }
    }

    setState(() {
      _totalSpentThisMonth = totalSpent;
      _budgets = budgets;
      _categorySpentMap = catSpent;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'All Expenses',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
              _loadDashboardData(); // Refresh if expenses were modified
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Setup Budgets',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetSetupScreen()));
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                   // Large Summary Card
                   Card(
                     color: Theme.of(context).colorScheme.primaryContainer,
                     elevation: 4,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     child: Padding(
                       padding: const EdgeInsets.all(32.0),
                       child: Column(
                         children: [
                           Text(
                             'Spent this month', 
                             style: TextStyle(
                               fontSize: 16, 
                               fontWeight: FontWeight.w500,
                               color: Theme.of(context).colorScheme.onPrimaryContainer,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             '\$${_totalSpentThisMonth.toStringAsFixed(2)}',
                             style: TextStyle(
                               fontSize: 42, 
                               fontWeight: FontWeight.bold,
                               color: Theme.of(context).colorScheme.onPrimaryContainer,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 32),
                   const Text(
                     'Budget Progress',
                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 16),
                   if (_budgets.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetSetupScreen()));
                              _loadDashboardData();
                            }, 
                            icon: const Icon(Icons.add_chart), 
                            label: const Text('Setup Your Budgets'),
                          ),
                        ),
                      )
                   else
                      ..._budgets.map((budget) {
                        final catMeta = AppCategories.defaultCategories.firstWhere(
                          (c) => c.name == budget.category,
                          orElse: () => AppCategories.defaultCategories.last,
                        );
                        final spent = _categorySpentMap[budget.category] ?? 0.0;
                        final percent = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) : 0.0;
                        final clampedPercent = percent > 1.0 ? 1.0 : percent;
                        final isWarning = percent > 0.8; // User requested > 80% shows warning
                        final isExceeded = percent > 1.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                       radius: 16,
                                       backgroundColor: catMeta.color.withOpacity(0.15),
                                       child: Icon(catMeta.icon, color: catMeta.color, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        budget.category, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                      )
                                    ),
                                    if (isWarning) ...[
                                      const Icon(Icons.error_outline, color: Colors.orange, size: 20),
                                      const SizedBox(width: 4),
                                    ] else if (isExceeded) ...[
                                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      '\$${spent.toStringAsFixed(0)} / \$${budget.monthlyLimit.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isExceeded ? Colors.red : (isWarning ? Colors.orange[800] : Colors.grey[700]),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: clampedPercent,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey.withOpacity(0.15),
                                    color: isExceeded ? Colors.red : (isWarning ? Colors.orange : catMeta.color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ],
              ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
          if (result == true) {
            _loadDashboardData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Expense'),
      ),
    );
  }
}
