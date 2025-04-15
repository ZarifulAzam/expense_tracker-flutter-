import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:intl/intl.dart';

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;
  const ExpenseChart({super.key, required this.expenses});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  // Static constants for consistent spacing and styling
  static const double kPadding = 16.0;
  static const double kSpacing = 8.0;
  static const double kChartAspectRatio = 1.5;
  static const double kSmallSliceThreshold = 3.0;
  static const double kMinPercentageForDirectLabel = 5.0;
  static const _kAnimationDuration = Duration(milliseconds: 300);
  static const _kTooltipBgColor = Color(0xFF2C3E50);

  // Static colors that don't need theme context
  static const List<Color> _staticColors = [
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
  ];

  // State variables
  int touchedIndex = -1;
  bool showPieChart = true;

  // Cached values
  late Map<String, double> _categoryTotals;
  late Map<int, double> _dailyTotals;
  late double _totalAmount;

  // Memoize formatter for percentages only
  final _percentFormatter =
      NumberFormat.decimalPercentPattern(decimalDigits: 1);

  @override
  void initState() {
    super.initState();
    _recalculateData();
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }

  // Memoized chart colors
  List<Color> get _chartColors {
    final theme = Theme.of(context);
    return [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      ..._staticColors,
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate values when dependencies change (like theme or MediaQuery)
    _recalculateData();
  }

  @override
  void didUpdateWidget(ExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if expense data changes
    if (widget.expenses != oldWidget.expenses) {
      _recalculateData();
    }
  }

  // Calculate data once and cache for reuse
  void _recalculateData() {
    _categoryTotals = _calculateCategoryTotals();
    _dailyTotals = _calculateDailyTotals();
    _totalAmount =
        _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
  }

  // Memory efficient category totals calculation
  Map<String, double> _calculateCategoryTotals() {
    final categoryTotals = <String, double>{};

    for (final expense in widget.expenses) {
      final category = expense.category.name;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + expense.amount;
    }

    // Sort by value in descending order
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // Fixed daily totals calculation for correct week handling
  Map<int, double> _calculateDailyTotals() {
    final now = DateTime.now();
    final dailyTotals = <int, double>{};

    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailyTotals[date.day] = 0;
    }

    // Sum expenses for the last 7 days
    for (final expense in widget.expenses) {
      final difference = now.difference(expense.date).inDays;
      if (difference < 7) {
        dailyTotals[expense.date.day] =
            (dailyTotals[expense.date.day] ?? 0) + expense.amount;
      }
    }

    return dailyTotals;
  }

  // Format currency values in a short format
  String _formatShortValue(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }

  // Format percentage values consistently
  String _formatPercentage(double value) {
    return _percentFormatter.format(value / 100);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Bound text scale factor to prevent extreme sizes
    final textScale = (size.width / 400).clamp(0.8, 1.2);

    if (_categoryTotals.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildChartToggle(),
          SizedBox(height: kSpacing * textScale),
          _buildChart(size, textScale),
          if (showPieChart) ...[
            SizedBox(height: kSpacing * textScale),
            _buildCategoryList(textScale),
          ],
          SizedBox(height: kSpacing * textScale),
          _buildSummaryCards(textScale),
          SizedBox(height: size.height * 0.05),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: kSpacing),
          Text(
            'No expenses to display',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle() {
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: SegmentedButton<bool>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
        selected: {showPieChart},
        onSelectionChanged: (value) =>
            setState(() => showPieChart = value.first),
        segments: const [
          ButtonSegment(
            value: true,
            icon: Icon(Icons.pie_chart, size: 18),
            label: Text('Categories', style: TextStyle(fontSize: 12)),
          ),
          ButtonSegment(
            value: false,
            icon: Icon(Icons.bar_chart, size: 18),
            label: Text('Weekly', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Size size, double textScale) {
    final isLandscape = size.width > size.height;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: kPadding * 0.5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPadding * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                showPieChart ? 'Overall summary' : 'Weekly Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: kSpacing * 1.5),
            AspectRatio(
              aspectRatio:
                  isLandscape ? kChartAspectRatio * 1.5 : kChartAspectRatio,
              child: showPieChart ? _buildPieChart(size) : _buildBarChart(size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Size size) {
    final groupedTotals = _groupSmallSlices(_categoryTotals, _totalAmount);
    final isSmallScreen = size.width < 360;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  touchedIndex = (!event.isInterestedForInteractions ||
                          pieTouchResponse?.touchedSection == null)
                      ? -1
                      : pieTouchResponse!.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sections: _buildPieSections(groupedTotals, size),
            sectionsSpace: isSmallScreen ? 1.0 : 1.8,
            centerSpaceRadius: size.width * (isSmallScreen ? 0.12 : 0.15),
          ),
          swapAnimationDuration: _kAnimationDuration,
        ),
        _buildChartCenter(),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> totals,
    Size size,
  ) {
    final keys = totals.keys.toList();
    final isSmallScreen = size.width < 360;

    return totals.entries.map((entry) {
      final index = keys.indexOf(entry.key);
      final isTouched = index == touchedIndex;
      final percentage = (entry.value / _totalAmount * 100);
      final showLabel = percentage >= kMinPercentageForDirectLabel;

      return PieChartSectionData(
        color: entry.key == 'Other'
            ? Colors.grey.shade400
            : _chartColors[index % _chartColors.length],
        value: entry.value,
        title: showLabel ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched
            ? size.width * (isSmallScreen ? 0.15 : 0.18)
            : size.width * (isSmallScreen ? 0.13 : 0.16),
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
        badgeWidget:
            !showLabel ? _buildBadgeLabel(entry.key, percentage, size) : null,
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();
  }

  Widget _buildBarChart(Size size) {
    final maxY = _dailyTotals.values.isEmpty
        ? 100.0
        : _dailyTotals.values.reduce(max) * 1.2;
    final sortedBarGroups = _dailyTotals.entries
        .map((entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  gradient: LinearGradient(
                    colors: [
                      _chartColors[0],
                      _chartColors[1].withOpacity(0.6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: size.width * 0.04,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barGroups: sortedBarGroups,
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(size),
        barTouchData: _buildBarTouchData(),
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
      ),
      swapAnimationDuration: _kAnimationDuration,
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 2000, // Increased interval for clarity
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData(Size size) {
    return FlTitlesData(
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            // Fixed date calculation for proper day labels
            final today = DateTime.now();
            final date =
                today.subtract(Duration(days: today.day - value.toInt()));
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('EE').format(date),
                style: TextStyle(
                  fontSize: size.width * 0.025,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          reservedSize: 28,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          interval: _calculateInterval(size.height),
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatShortValue(value),
                style: TextStyle(
                  fontSize: size.width * 0.025,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateInterval(double height) {
    // Increased intervals to reduce the number of y-axis labels
    if (height < 600) return 2000;
    if (height < 800) return 1000;
    return 500;
  }

  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: _kTooltipBgColor,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            _formatShortValue(rod.toY),
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _groupSmallSlices(
    Map<String, double> totals,
    double total,
  ) {
    final grouped = <String, double>{};
    var others = 0.0;

    for (final entry in totals.entries) {
      final percentage = (entry.value / total * 100);
      if (percentage < kSmallSliceThreshold) {
        others += entry.value;
      } else {
        grouped[entry.key] = entry.value;
      }
    }

    if (others > 0) {
      grouped['Other'] = others;
    }

    return grouped;
  }

  Widget _buildChartCenter() {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatShortValue(_totalAmount),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeLabel(String category, double percentage, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      constraints: BoxConstraints(maxWidth: size.width * 0.2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.length > 8 ? '${category.substring(0, 8)}...' : category,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatPercentage(percentage),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(double textScale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: kPadding * 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categoryTotals.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _categoryTotals.entries.elementAt(index);
          final percentage = (entry.value / _totalAmount);

          return _CategoryListItem(
            category: entry.key,
            amount: entry.value,
            percentage: percentage,
            color: _chartColors[index % _chartColors.length],
            onSurfaceColor: Theme.of(context).colorScheme.onSurface,
            formatShortCurrency: _formatShortValue,
            formatPercentage: _formatPercentage,
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(double textScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Spent',
              value: _formatShortValue(_totalAmount),
              icon: Icons.account_balance_wallet,
            ),
          ),
          const SizedBox(width: kSpacing * 2),
          Expanded(
            child: _buildSummaryCard(
              title: 'Categories',
              value: _categoryTotals.length.toString(),
              icon: Icons.category,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPadding * 0.75),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: kSpacing),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: kSpacing * 0.5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted widget for better performance
class _CategoryListItem extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final Color onSurfaceColor;
  final String Function(double) formatShortCurrency;
  final String Function(double) formatPercentage;

  const _CategoryListItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.onSurfaceColor,
    required this.formatShortCurrency,
    required this.formatPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatPercentage(percentage * 100),
            style: TextStyle(
              fontSize: 13,
              color: onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            formatShortCurrency(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
