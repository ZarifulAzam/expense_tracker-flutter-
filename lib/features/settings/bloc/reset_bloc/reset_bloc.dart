import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'reset_event.dart';
part 'reset_state.dart';

class ResetBloc extends Bloc<ResetEvent, ResetState> {
  final ExpenseRepository _repository;

  ResetBloc(this._repository) : super(ResetInitial()) {
    on<ResetDataRequested>(_onResetDataRequested);
  }

  Future<void> _onResetDataRequested(
    ResetDataRequested event,
    Emitter<ResetState> emit,
  ) async {
    emit(ResetInProgress());
    try {
      await _repository.resetAllData();
      emit(ResetSuccess());
    } catch (e) {
      emit(ResetFailure(e.toString()));
    }
  }
}
