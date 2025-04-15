import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/spending_analysis_bloc/spending_analysis_bloc.dart';
import '../bloc/spending_analysis_bloc/spending_analysis_state.dart';
import '../models/spending_insight.dart';

class SpendingAnalysisView extends StatelessWidget {
  const SpendingAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpendingAnalysisBloc, SpendingAnalysisState>(
      builder: (context, state) {
        if (state is SpendingAnalysisSuccess) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, state),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildInsightCard(
                    context,
                    state.insights[index],
                  ),
                  childCount: state.insights.length,
                ),
              ),
            ],
          );
        }
        if (state is SpendingAnalysisFailure) {
          return Center(child: Text(state.message));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildHeader(BuildContext context, SpendingAnalysisSuccess state) {
    final formatter = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              context,
              'Total Spent',
              formatter.format(state.totalSpent),
            ),
            _buildSummaryItem(
              context,
              'Daily Average',
              formatter.format(state.averageDaily),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, SpendingInsight insight) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(insight.category),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: insight.percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                insight.isHighSpending
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            if (insight.warning != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  insight.warning!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          '${insight.percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
