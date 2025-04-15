import 'dart:math';
import 'package:expense_repository/expense_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/bloc/auth_bloc/auth_bloc.dart';
import '../../../features/income/screens/income_list_screen.dart';
import '../../../features/income/bloc/income_bloc/income_bloc.dart';

class MainScreen extends StatelessWidget {
  static const double kSpacing = 16.0;
  static const double kIconSize = 24.0;

  final List<Expense> expenses;
  const MainScreen(this.expenses, {super.key});

  String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  String getUsername() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      return user.email!.split('@')[0];
    }
    return 'User';
  }

  double calculateMonthlyIncome(BuildContext context) {
    final state = context.watch<IncomeBloc>().state;
    if (state is IncomeSuccess) {
      return state.incomes
          .where((income) =>
              income.date.month == DateTime.now().month &&
              income.date.year == DateTime.now().year)
          .fold(0.0, (sum, income) => sum + income.amount);
    }
    return 0.0;
  }

  double calculateTotalExpenses() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double calculateTotalBalance(BuildContext context) {
    final monthlyIncome = calculateMonthlyIncome(context);
    final totalExpenses = calculateTotalExpenses();
    return monthlyIncome - totalExpenses;
  }

  Widget _buildHeader(BuildContext context, String username) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(kSpacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.tertiary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(CupertinoIcons.person_fill,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.red,
              onPressed: () => context.read<AuthBloc>().add(SignOutRequested()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, double balance, double income, double expenses) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final cardHeight = isLandscape ? size.height * 0.35 : size.width * 0.42;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        height: cardHeight,
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
            transform: const GradientRotation(pi / 4),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatCurrency(balance),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
              child: _buildBalanceIndicators(context, income, expenses),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceIndicators(
      BuildContext context, double income, double expenses) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBalanceIndicator(
          icon: CupertinoIcons.arrow_down,
          label: 'Income',
          amount: income,
          iconColor: Colors.greenAccent,
          context: context,
        ),
        Container(
          height: size.width * 0.08,
          width: 1,
          color: Colors.white24,
        ),
        _buildBalanceIndicator(
          icon: CupertinoIcons.arrow_up,
          label: 'Expenses',
          amount: expenses,
          iconColor: Colors.redAccent,
          context: context,
        ),
      ],
    );
  }

  Widget _buildBalanceIndicator({
    required IconData icon,
    required String label,
    required double amount,
    required Color iconColor,
    required BuildContext context,
  }) {
    final size = MediaQuery.of(context).size;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(size.width * 0.02),
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: size.width * 0.04, color: iconColor),
        ),
        SizedBox(width: size.width * 0.02),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.035,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatCurrency(amount),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(expense.category.color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/${expense.category.icon}.png',
            width: kIconSize,
            height: kIconSize,
            color: Color(expense.category.color),
          ),
        ),
        title: Text(
          expense.category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
        trailing: Text(
          formatCurrency(expense.amount.toDouble()),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Expense> expenses) {
    return Expanded(
      child: expenses.isEmpty
          ? Center(
              child: Text(
                'No expenses yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: expenses.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _buildExpenseItem(expense);
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = getUsername();
    final monthlyIncome = calculateMonthlyIncome(context);
    final totalExpenses = calculateTotalExpenses();
    final balance = calculateTotalBalance(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, username),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.width * 0.02,
              ),
              child: _buildBalanceCard(
                context,
                balance,
                monthlyIncome,
                totalExpenses,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.width * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IncomeListScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View Income',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: size.width * 0.035,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildTransactionsList(expenses),
            ),
          ],
        ),
      ),
    );
  }
}
