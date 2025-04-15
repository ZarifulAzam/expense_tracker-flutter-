part of 'income_bloc.dart';

abstract class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object> get props => [];
}

class IncomeInitial extends IncomeState {}

class IncomeLoading extends IncomeState {}

class IncomeSuccess extends IncomeState {
  final List<Income> incomes;

  const IncomeSuccess(this.incomes);

  @override
  List<Object> get props => [incomes];
}

class IncomeFailure extends IncomeState {}
