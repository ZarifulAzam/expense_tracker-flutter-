import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_repository/expense_repository.dart';
import 'simple_bloc_observer.dart';
import 'features/auth/bloc/auth_bloc/auth_bloc.dart';
import 'screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'features/income/bloc/income_bloc/income_bloc.dart';
import 'features/settings/bloc/reset_bloc/reset_bloc.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Bloc.observer = SimpleBlocObserver();

  final expenseRepository = FirebaseExpenseRepo();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseRepository>(
          create: (context) => expenseRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc()),
          BlocProvider(
            create: (context) => GetExpensesBloc(
              context.read<ExpenseRepository>(),
            )..add(GetExpenses()),
          ),
          BlocProvider(
            create: (context) => IncomeBloc(
              context.read<ExpenseRepository>(),
            )..add(GetIncomes()),
          ),
          BlocProvider(
            create: (context) => ResetBloc(
              context.read<ExpenseRepository>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
