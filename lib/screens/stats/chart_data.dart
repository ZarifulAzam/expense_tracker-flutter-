import 'package:expense_repository/expense_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartData {
  static List<BarChartGroupData> getBarGroups(List<Expense> expenses) {
    Map<int, double> dailyTotals = {};
    double maxAmount = 0;

    // Calculate daily totals and find maximum amount
    for (var expense in expenses) {
      int day = expense.date.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
      if (dailyTotals[day]! > maxAmount) maxAmount = dailyTotals[day]!;
    }

    // Create and sort bar groups
    return dailyTotals.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            gradient: const LinearGradient(
              colors: [Color(0xFF00B2E7), Color(0xFFE064F7)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18, // Slightly wider bars
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8), // More rounded corners
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxAmount,
              color:
                  Colors.grey.withAlpha(20), // Slightly more visible background
            ),
          ),
        ],
        // Add shadow for depth
        showingTooltipIndicators: [],
      );
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  // New method for gradient color generation based on category or value
  static List<Color> getCategoryColors(int index, BuildContext context) {
    final List<List<Color>> gradients = [
      [const Color(0xFF00B2E7), const Color(0xFFE064F7)], // Default gradient
      [const Color(0xFF00C853), const Color(0xFF64FFDA)], // Green gradient
      [const Color(0xFFFF6D00), const Color(0xFFFFAB40)], // Orange gradient
      [const Color(0xFFD500F9), const Color(0xFF9C27B0)], // Purple gradient
      [const Color(0xFFFF1744), const Color(0xFFFF8A80)], // Red gradient
      [const Color(0xFF2962FF), const Color(0xFF82B1FF)], // Blue gradient
    ];

    // Use theme colors if index exceeds predefined gradients
    if (index >= gradients.length) {
      final theme = Theme.of(context);
      return [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
      ];
    }

    return gradients[index % gradients.length];
  }
}
