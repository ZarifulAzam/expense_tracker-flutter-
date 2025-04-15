import 'package:equatable/equatable.dart';
import '../entities/income_entity.dart';

class Income extends Equatable {
  final String id;
  final String source;
  final DateTime date;
  final double amount;

  const Income({
    required this.id,
    required this.source,
    required this.date,
    required this.amount,
  });

  @override
  List<Object?> get props => [id, source, date, amount];

  static Income fromEntity(IncomeEntity entity) {
    return Income(
      id: entity.id,
      source: entity.source,
      date: entity.date,
      amount: entity.amount,
    );
  }

  IncomeEntity toEntity() {
    return IncomeEntity(
      id: id,
      source: source,
      date: date,
      amount: amount,
    );
  }
}
