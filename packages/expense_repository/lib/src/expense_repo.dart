import 'package:expense_repository/expense_repository.dart';
import 'models/models.dart';

abstract class ExpenseRepository {
  Future<void> createCategory(Category category);

  Future<List<Category>> getCategory();

  Future<void> createExpense(Expense expense);

  Future<List<Expense>> getExpenses();
  Future<void> createIncome(Income income);
  Future<List<Income>> getIncomes();

  Future<void> resetAllData();
}
