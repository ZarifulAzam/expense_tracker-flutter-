part of 'income_bloc.dart';

abstract class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object> get props => [];
}

class GetIncomes extends IncomeEvent {}

class AddIncome extends IncomeEvent {
  final Income income;

  const AddIncome(this.income);

  @override
  List<Object> get props => [income];
}
