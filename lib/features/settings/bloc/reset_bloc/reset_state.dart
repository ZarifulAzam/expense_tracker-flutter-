part of 'reset_bloc.dart';

abstract class ResetState extends Equatable {
  const ResetState();

  @override
  List<Object> get props => [];
}

class ResetInitial extends ResetState {}

class ResetInProgress extends ResetState {}

class ResetSuccess extends ResetState {}

class ResetFailure extends ResetState {
  final String message;
  const ResetFailure(this.message);

  @override
  List<Object> get props => [message];
}
