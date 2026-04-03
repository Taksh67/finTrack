import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage_service.dart';
import '../models/expense.dart';
import 'package:flutter/foundation.dart';

class FirebaseSyncService {
  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> syncExpenses() async {
    final user = _auth.currentUser;
    if (user == null) return; // Ignore if guest

    try {
      final String uid = user.uid;
      final CollectionReference expensesRef = _db.collection('users').doc(uid).collection('expenses');

      // 1. Fetch Cloud Data
      final QuerySnapshot snapshot = await expensesRef.get();
      final Map<String, Expense> cloudExpenses = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        cloudExpenses[doc.id] = Expense.fromMap(data);
      }

      // 2. Fetch Local Data
      final List<Expense> localList = await _localStorage.getExpenses();
      final Map<String, Expense> localExpenses = {for (var e in localList) e.id: e};

      // 3. Merge Logic: Cloud takes priority on conflict.
      final Map<String, Expense> merged = {};

      cloudExpenses.forEach((id, expense) {
        merged[id] = expense;
      });

      for (var localEntry in localExpenses.entries) {
        if (!cloudExpenses.containsKey(localEntry.key)) {
           // Local exists but Cloud doesn't -> Write to Cloud
           await expensesRef.doc(localEntry.key).set(localEntry.value.toMap());
           merged[localEntry.key] = localEntry.value;
        }
      }

      // 4. Save merged list purely back to Local Storage
      await _localStorage.saveExpenses(merged.values.toList());
      
      debugPrint("Sync Complete!");
      
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }
}
