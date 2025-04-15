import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_repository/expense_repository.dart';
import '../../models/spending_insight.dart';
import 'spending_analysis_state.dart';
import 'spending_analysis_event.dart';

class SpendingAnalysisBloc
    extends Bloc<SpendingAnalysisEvent, SpendingAnalysisState> {
  SpendingAnalysisBloc() : super(SpendingAnalysisInitial()) {
    on<AnalyzeSpending>(_onAnalyzeSpending);
  }

  void _onAnalyzeSpending(
    AnalyzeSpending event,
    Emitter<SpendingAnalysisState> emit,
  ) {
    emit(SpendingAnalysisLoading());

    try {
      final insights = _analyzeExpenses(event.expenses);
      final totalSpent = event.expenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );

      final daysSpan =
          event.expenses.isEmpty ? 1 : _calculateDaysSpan(event.expenses);

      final averageDaily = totalSpent / daysSpan;

      emit(SpendingAnalysisSuccess(
        insights: insights,
        totalSpent: totalSpent,
        averageDaily: averageDaily,
      ));
    } catch (e) {
      emit(SpendingAnalysisFailure(e.toString()));
    }
  }

  List<SpendingInsight> _analyzeExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) return [];

    final categoryTotals = <String, double>{};
    final totalSpent = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    // Calculate category totals
    for (final expense in expenses) {
      final category = expense.category.name;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + expense.amount;
    }

    // Create insights
    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / totalSpent) * 100;
      return SpendingInsight(
        category: entry.key,
        amount: entry.value,
        percentage: percentage,
        isHighSpending: percentage > 30,
        warning: percentage > 30
            ? 'High spending: ${percentage.toStringAsFixed(1)}% of total'
            : null,
      );
    }).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  int _calculateDaysSpan(List<Expense> expenses) {
    final dates = expenses.map((e) => e.date).toList();
    final firstDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return lastDate.difference(firstDate).inDays + 1;
  }
}
