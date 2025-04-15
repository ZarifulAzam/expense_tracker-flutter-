import 'package:equatable/equatable.dart';
import '../../models/spending_insight.dart';

abstract class SpendingAnalysisState extends Equatable {
  const SpendingAnalysisState();

  @override
  List<Object> get props => [];
}

class SpendingAnalysisInitial extends SpendingAnalysisState {}

class SpendingAnalysisLoading extends SpendingAnalysisState {}

class SpendingAnalysisSuccess extends SpendingAnalysisState {
  final List<SpendingInsight> insights;
  final double totalSpent;
  final double averageDaily;

  const SpendingAnalysisSuccess({
    required this.insights,
    required this.totalSpent,
    required this.averageDaily,
  });

  @override
  List<Object> get props => [insights, totalSpent, averageDaily];
}

class SpendingAnalysisFailure extends SpendingAnalysisState {
  final String message;

  const SpendingAnalysisFailure(this.message);

  @override
  List<Object> get props => [message];
}
