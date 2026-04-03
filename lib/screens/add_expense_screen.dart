import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../constants/categories.dart';
import '../services/local_storage_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final newExpense = Expense(
      title: _titleController.text.trim(),
      amount: enteredAmount,
      category: _selectedCategory!,
      date: _selectedDate,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    // Save Expense
    await _storageService.addExpense(newExpense);
    
    // --- Budget Warning Alert Logic ---
    final budgets = await _storageService.getBudgets();
    final budgetForCat = budgets.where((b) => b.category == _selectedCategory).toList();
    
    if (budgetForCat.isNotEmpty) {
      final monthlyLimit = budgetForCat.first.monthlyLimit;
      
      final allExpenses = await _storageService.getExpenses();
      final now = DateTime.now();
      
      final currentMonthSpent = allExpenses
          .where((e) => e.category == _selectedCategory && e.date.month == now.month && e.date.year == now.year)
          .fold(0.0, (sum, item) => sum + item.amount);
          
      if (currentMonthSpent > monthlyLimit && mounted) {
        // Show Warning via ScaffoldMessenger which persists when we pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ You have exceeded your $_selectedCategory budget!'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    
    if (mounted) {
      Navigator.of(context).pop(true); // Return true to refresh parent screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(DateFormat.yMd().format(_selectedDate)),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: _presentDatePicker,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  items: AppCategories.defaultCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color),
                          const SizedBox(width: 10),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitData,
                  child: const Text('Save Expense', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
