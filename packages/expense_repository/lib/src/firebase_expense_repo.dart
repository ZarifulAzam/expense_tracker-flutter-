import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';

class FirebaseExpenseRepo implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CollectionReference _categoryCollection;
  final CollectionReference _expenseCollection;

  FirebaseExpenseRepo({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _categoryCollection =
            (firestore ?? FirebaseFirestore.instance).collection('categories'),
        _expenseCollection =
            (firestore ?? FirebaseFirestore.instance).collection('expenses');

  @override
  Future<void> createCategory(Category category) async {
    try {
      await _categoryCollection
          .doc(category.categoryId)
          .set(category.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategory() async {
    try {
      return await _categoryCollection.get().then((value) => value.docs
          .map((e) => Category.fromEntity(
              CategoryEntity.fromDocument(e.data() as Map<String, dynamic>)))
          .toList());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      print('==== FIREBASE REPO: Creating expense ====');
      print('Expense ID: ${expense.expenseId}');
      print('Category ID: ${expense.category.categoryId}');
      print('Category Name: ${expense.category.name}');
      print('Amount: ${expense.amount}');
      print('Date: ${expense.date}');

      final expenseDoc = expense.toEntity().toDocument();
      print('Document to save: $expenseDoc');

      await _expenseCollection.doc(expense.expenseId).set(expenseDoc);

      print('==== FIREBASE REPO: Expense created successfully ====');
    } catch (e) {
      print('==== FIREBASE REPO: Error creating expense ====');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      return await _expenseCollection
          .orderBy('date', descending: true) // Sort by date, newest first
          .get()
          .then((value) => value.docs
              .map((e) => Expense.fromEntity(
                  ExpenseEntity.fromDocument(e.data() as Map<String, dynamic>)))
              .toList());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createIncome(Income income) async {
    try {
      final userDoc =
          _firestore.collection('users').doc(_auth.currentUser?.uid);
      await userDoc
          .collection('incomes')
          .doc(income.id)
          .set(income.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Income>> getIncomes() async {
    try {
      final userDoc =
          _firestore.collection('users').doc(_auth.currentUser?.uid);
      final snapshot = await userDoc
          .collection('incomes')
          .orderBy('date', descending: true) // Sort by date, newest first
          .get();
      return snapshot.docs
          .map(
              (doc) => Income.fromEntity(IncomeEntity.fromDocument(doc.data())))
          .toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> resetAllData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();

      // Delete expenses
      final expensesSnapshot = await _expenseCollection.get();
      for (var doc in expensesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete categories
      final categoriesSnapshot = await _categoryCollection.get();
      for (var doc in categoriesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete incomes
      final userDoc = _firestore.collection('users').doc(userId);
      final incomesSnapshot = await userDoc.collection('incomes').get();
      for (var doc in incomesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Execute batch delete
      await batch.commit();
    } catch (e) {
      log('Reset data error: $e');
      rethrow;
    }
  }
}
