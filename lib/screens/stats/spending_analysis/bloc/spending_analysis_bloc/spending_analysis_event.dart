import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

abstract class SpendingAnalysisEvent extends Equatable {
  const SpendingAnalysisEvent();

  @override
  List<Object> get props => [];
}

class AnalyzeSpending extends SpendingAnalysisEvent {
  final List<Expense> expenses;

  const AnalyzeSpending(this.expenses);

  @override
  List<Object> get props => [expenses];
}
