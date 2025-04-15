import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reset_bloc/reset_bloc.dart';
import '../../../screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import '../../../features/income/bloc/income_bloc/income_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResetBloc, ResetState>(
      listener: (context, state) {
        if (state is ResetInProgress) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resetting data...'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is ResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been reset successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          context.read<GetExpensesBloc>().add(GetExpenses());
          context.read<IncomeBloc>().add(GetIncomes());

          Navigator.pop(context);
        } else if (state is ResetFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reset failed: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: BlocBuilder<ResetBloc, ResetState>(
          builder: (context, resetState) {
            return ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.red),
                  title: const Text('Reset All Data'),
                  subtitle: const Text(
                    'This will permanently delete all your expenses, categories, and income records',
                  ),
                  enabled: resetState is! ResetInProgress,
                  onTap: () => _showResetConfirmation(context, resetState),
                ),
                if (resetState is ResetInProgress)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, ResetState resetState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'Are you sure you want to reset all data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: resetState is ResetInProgress
                ? null
                : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: resetState is ResetInProgress
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    context.read<ResetBloc>().add(ResetDataRequested());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
