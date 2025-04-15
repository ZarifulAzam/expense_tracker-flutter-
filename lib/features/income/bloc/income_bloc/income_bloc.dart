import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'income_event.dart';
part 'income_state.dart';

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  final ExpenseRepository _expenseRepository;

  IncomeBloc(this._expenseRepository) : super(IncomeInitial()) {
    on<GetIncomes>(_onGetIncomes);
    on<AddIncome>(_onAddIncome);
  }

  Future<void> _onGetIncomes(
      GetIncomes event, Emitter<IncomeState> emit) async {
    emit(IncomeLoading());
    try {
      final incomes = await _expenseRepository.getIncomes();
      emit(IncomeSuccess(incomes));
    } catch (e) {
      emit(IncomeFailure());
    }
  }

  Future<void> _onAddIncome(AddIncome event, Emitter<IncomeState> emit) async {
    emit(IncomeLoading());
    try {
      await _expenseRepository.createIncome(event.income);
      final incomes = await _expenseRepository.getIncomes();
      emit(IncomeSuccess(incomes));
    } catch (e) {
      emit(IncomeFailure());
    }
  }
}
