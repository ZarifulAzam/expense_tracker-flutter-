import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';

import '../../../features/settings/screens/settings_screen.dart';
import '../../../features/settings/bloc/reset_bloc/reset_bloc.dart';
import '../../../features/income/bloc/income_bloc/income_bloc.dart';
import '../../../screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import '../../../screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import '../../../screens/add_expense/views/add_expense.dart';
import '../../../screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import '../../../features/income/screens/add_income_screen.dart';
import '../blocs/get_expenses_bloc/get_expenses_bloc.dart';
import '../../stats/stats.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetExpensesBloc, GetExpensesState>(
      builder: (context, state) {
        if (state is GetExpensesSuccess) {
          return Scaffold(
            extendBody: true,
            appBar: AppBar(
              title: const Text('Expense Tracker'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _navigateToSettings(context),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Main content
                index == 0 ? MainScreen(state.expenses) : const StatScreen(),

                // Show FABs only on main screen (index == 0)
                if (index == 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 90,
                    child: _buildFloatingActionButtons(context),
                  ),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(context),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFloatingActionButton(
            context: context,
            heroTag: 'addExpense',
            onPressed: () => _addExpense(context),
            gradient: [
              Theme.of(context).colorScheme.tertiary.withOpacity(0.9),
              Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            ],
            icon: const Icon(CupertinoIcons.minus, color: Colors.white),
          ),
          _buildFloatingActionButton(
            context: context,
            heroTag: 'addIncome',
            onPressed: () => _addIncome(context),
            gradient: [
              Theme.of(context).colorScheme.primary.withOpacity(0.9),
              Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            ],
            icon: const Icon(CupertinoIcons.plus, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required BuildContext context,
    required String heroTag,
    required VoidCallback onPressed,
    required List<Color> gradient,
    required Icon icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: FloatingActionButton(
              heroTag: heroTag,
              onPressed: onPressed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (value) => setState(() => index = value),
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.graph_square_fill),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => ResetBloc(context.read<ExpenseRepository>()),
            ),
            BlocProvider.value(value: context.read<GetExpensesBloc>()),
            BlocProvider.value(value: context.read<IncomeBloc>()),
          ],
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    final newExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CreateCategoryBloc(FirebaseExpenseRepo()),
            ),
            BlocProvider(
              create: (context) => GetCategoriesBloc(FirebaseExpenseRepo())
                ..add(GetCategories()),
            ),
            BlocProvider(
              create: (context) => CreateExpenseBloc(FirebaseExpenseRepo()),
            ),
          ],
          child: const AddExpense(),
        ),
      ),
    );

    if (newExpense != null && mounted) {
      // Refresh the expenses list from Firebase
      context.read<GetExpensesBloc>().add(GetExpenses());
    }
  }

  void _addIncome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddIncomeScreen(),
      ),
    );
  }
}
