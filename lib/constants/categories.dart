import 'package:flutter/material.dart';
import '../models/category.dart';

class AppCategories {
  static const List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    ExpenseCategory(
      name: 'Transport',
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.purple,
    ),
    ExpenseCategory(
      name: 'Health',
      icon: Icons.medical_services,
      color: Colors.red,
    ),
    ExpenseCategory(
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.pink,
    ),
    ExpenseCategory(
      name: 'Bills',
      icon: Icons.receipt,
      color: Colors.teal,
    ),
    ExpenseCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Colors.grey,
    ),
  ];
}
