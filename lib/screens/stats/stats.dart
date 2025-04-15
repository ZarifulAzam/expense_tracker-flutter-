import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'expense_chart.dart';
import 'spending_analysis/views/spending_analysis_view.dart';
import 'spending_analysis/bloc/spending_analysis_bloc/spending_analysis_bloc.dart';
import 'spending_analysis/bloc/spending_analysis_bloc/spending_analysis_event.dart';

class StatScreen extends StatelessWidget {
  const StatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GetExpensesBloc, GetExpensesState>(
      builder: (context, state) {
        if (state is GetExpensesSuccess) {
          if (state.expenses.isEmpty) {
            return _buildEmptyState(context);
          }

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: AppBar(
                // Fixed: removed 'pinned' parameter since it's not valid for AppBar
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                title: Text(
                  'Statistics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Charts'),
                    Tab(text: 'Analysis'),
                  ],
                ),
              ),
              body: SafeArea(
                child: TabBarView(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ExpenseChart(expenses: state.expenses),
                        ),
                      ],
                    ),
                    BlocProvider(
                      create: (context) => SpendingAnalysisBloc()
                        // Fixed: explicitly imported the AnalyzeSpending event
                        ..add(AnalyzeSpending(state.expenses)),
                      child: const SpendingAnalysisView(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.show_chart,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No spending records yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start tracking your expenses to view insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add expense screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
