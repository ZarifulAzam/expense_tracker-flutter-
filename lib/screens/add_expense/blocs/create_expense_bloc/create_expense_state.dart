part of 'create_expense_bloc.dart';

sealed class CreateExpenseState extends Equatable {
  const CreateExpenseState();

  @override
  List<Object> get props => [];
}

final class CreateExpenseInitial extends CreateExpenseState {}

final class CreateExpenseLoading extends CreateExpenseState {}

final class CreateExpenseSuccess extends CreateExpenseState {
  final Expense? expense;

  const CreateExpenseSuccess([this.expense]);

  @override
  List<Object> get props => expense != null ? [expense!] : [];
}

final class CreateExpenseFailure extends CreateExpenseState {
  final String error;

  const CreateExpenseFailure(this.error);

  @override
  List<Object> get props => [error];
}
