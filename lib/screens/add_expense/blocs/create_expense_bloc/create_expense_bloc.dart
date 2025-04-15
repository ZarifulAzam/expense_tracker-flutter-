import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'create_expense_event.dart';
part 'create_expense_state.dart';

class CreateExpenseBloc extends Bloc<CreateExpenseEvent, CreateExpenseState> {
  final ExpenseRepository expenseRepository;

  CreateExpenseBloc(this.expenseRepository) : super(CreateExpenseInitial()) {
    on<CreateExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        // Add debug logging
        print('Creating expense in bloc:');
        print('ID: ${event.expense.expenseId}');
        print('Amount: ${event.expense.amount}');
        print(
            'Category: ${event.expense.category.name} (${event.expense.category.categoryId})');
        print('Date: ${event.expense.date}');

        await expenseRepository.createExpense(event.expense);
        print('Expense created successfully');
        emit(CreateExpenseSuccess(event.expense));
      } catch (e) {
        print('Error creating expense: $e');
        emit(CreateExpenseFailure(e.toString()));
      }
    });
  }
}
