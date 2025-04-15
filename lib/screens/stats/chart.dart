import 'package:expense_repository/expense_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'chart_data.dart';

class MyChart extends StatefulWidget {
  final List<Expense> expenses;

  const MyChart({super.key, required this.expenses});

  @override
  State<MyChart> createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  minY: 0,
                  groupsSpace: 20, // Increased space between groups
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: const Color(0xFF2C3E50),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '\$${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex =
                            barTouchResponse.spot!.touchedBarGroupIndex;
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Add a calendar day label to make it more intuitive
                          final dayNum = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: touchedIndex == dayNum
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              // Format currency values
                              value > 1000
                                  ? '\$${(value / 1000).toStringAsFixed(1)}K'
                                  : '\$${value.toInt()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        reservedSize: 45,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(_getMaxY()),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [5, 5], // Dashed grid lines
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  barGroups: _getAnimatedBarGroups(),
                ),
                swapAnimationDuration: const Duration(milliseconds: 400),
              );
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getAnimatedBarGroups() {
    final barGroups = ChartData.getBarGroups(widget.expenses);

    // Apply the animation to each bar
    return barGroups.map((group) {
      final rods = group.barRods.map((rod) {
        return rod.copyWith(
          toY: rod.toY * _animation.value,
          width: rod.width,
          borderRadius: rod.borderRadius,
        );
      }).toList();

      return group.copyWith(
        barRods: rods,
        showingTooltipIndicators: touchedIndex == group.x ? [0] : [],
      );
    }).toList();
  }

  double _getMaxY() {
    if (widget.expenses.isEmpty) return 1000;
    double maxAmount = widget.expenses
        .map((e) => e.amount.toDouble())
        .reduce((max, amount) => amount > max ? amount : max);
    return maxAmount * 1.2; // Add 20% padding
  }

  // Calculate appropriate interval based on max value
  double _calculateInterval(double maxY) {
    if (maxY > 10000) return 2000;
    if (maxY > 5000) return 1000;
    if (maxY > 1000) return 500;
    return 200;
  }
}
