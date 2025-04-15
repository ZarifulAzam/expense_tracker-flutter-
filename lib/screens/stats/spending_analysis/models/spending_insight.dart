class SpendingInsight {
  final String category;
  final double amount;
  final double percentage;
  final bool isHighSpending;
  final String? warning;

  const SpendingInsight({
    required this.category,
    required this.amount,
    required this.percentage,
    this.isHighSpending = false,
    this.warning,
  });
}
