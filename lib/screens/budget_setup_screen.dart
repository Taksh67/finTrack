import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/budget.dart';
import '../services/local_storage_service.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({Key? key}) : super(key: key);

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (var cat in AppCategories.defaultCategories) {
      _controllers[cat.name] = TextEditingController();
    }
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final existingBudgets = await _storageService.getBudgets();
    for (var budget in existingBudgets) {
      if (_controllers.containsKey(budget.category)) {
        _controllers[budget.category]!.text = budget.monthlyLimit > 0 
            ? budget.monthlyLimit.toStringAsFixed(0) 
            : '';
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudgets() async {
    final List<Budget> newBudgets = [];
    for (var cat in AppCategories.defaultCategories) {
      final textValue = _controllers[cat.name]!.text;
      final limit = double.tryParse(textValue) ?? 0.0;
      if (limit > 0) {
        newBudgets.add(Budget(category: cat.name, monthlyLimit: limit));
      }
    }
    await _storageService.saveBudgets(newBudgets);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budgets saved successfully!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBudgets,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: AppCategories.defaultCategories.length,
              itemBuilder: (context, index) {
                final category = AppCategories.defaultCategories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: category.color.withOpacity(0.2),
                          child: Icon(category.icon, color: category.color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _controllers[category.name],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Limit',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
