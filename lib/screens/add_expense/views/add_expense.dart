import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../blocs/create_expense_bloc/create_expense_bloc.dart';
import '../blocs/get_categories_bloc/get_categories_bloc.dart';
import 'category_creation.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // Keep track of the selected category ID to match against in the UI
  String? selectedCategoryId;
  late Expense expense;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    expense = Expense.empty;
    expense.expenseId = const Uuid().v1();
    expense.date = DateTime.now();
  }

  Widget _buildAmountField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: expenseController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  FontAwesomeIcons.dollarSign,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                hintText: 'Enter amount',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }

                // Check if the value is a valid number
                try {
                  final amount = double.parse(value);
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(GetCategoriesSuccess state) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showCategoryCreation(state),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.categories.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final isSelected = selectedCategoryId == category.categoryId;
                return _buildCategoryTile(category, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category category, bool isSelected) {
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected
          ? Color(category.color).withOpacity(0.2)
          : Theme.of(context).colorScheme.surface,
      child: ListTile(
        onTap: () => _selectCategory(category),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(category.color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/${category.icon}.png',
            width: 24,
            height: 24,
            color: Color(category.color),
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Card(
      child: ListTile(
        onTap: () => _selectDate(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FontAwesomeIcons.calendar,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Date',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        subtitle: Text(
          dateController.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitExpense,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Save Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expense.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
        expense.date = picked;
      });
    }
  }

  Future<void> _showCategoryCreation(GetCategoriesSuccess state) async {
    final newCategory = await getCategoryCreation(context);
    if (newCategory != null && mounted) {
      setState(() {
        state.categories.insert(0, newCategory);
        // Select the newly created category automatically
        _selectCategory(newCategory);
      });
    }
  }

  void _selectCategory(Category category) {
    setState(() {
      expense.category = category;
      selectedCategoryId = category.categoryId;
      categoryController.text = category.name;
    });
  }

  void _submitExpense() {
    if (_formKey.currentState?.validate() ?? false) {
      if (expense.category == Category.empty || selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      try {
        // Parse the amount as double first
        final amountDouble = double.parse(expenseController.text);

        setState(() {
          // Store as integer in your expense model
          expense.amount = amountDouble.toInt();
          isLoading = true;
        });

        print('Submitting expense: ${expense.expenseId}');
        print('Amount: ${expense.amount}');
        print(
            'Category: ${expense.category.name} (${expense.category.categoryId})');
        print('Date: ${expense.date}');

        context.read<CreateExpenseBloc>().add(CreateExpense(expense));
      } catch (e) {
        setState(() => isLoading = false);
        // Handle parse errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid amount format: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateExpenseBloc, CreateExpenseState>(
      listener: (context, state) {
        if (state is CreateExpenseSuccess) {
          // Show success message before popping
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, state.expense ?? expense);
        } else if (state is CreateExpenseLoading) {
          setState(() => isLoading = true);
        } else if (state is CreateExpenseFailure) {
          setState(() => isLoading = false);
          // Show detailed error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create expense: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text("Add Expense"),
            centerTitle: true,
          ),
          body: BlocBuilder<GetCategoriesBloc, GetCategoriesState>(
            builder: (context, state) {
              if (state is GetCategoriesSuccess) {
                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAmountField(),
                      const SizedBox(height: 16),
                      _buildCategorySection(state),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                );
              }
              if (state is GetCategoriesFailure) {
                // Handle the case where categories couldn't be fetched
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Failed to load categories"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<GetCategoriesBloc>()
                            .add(GetCategories()),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    expenseController.dispose();
    categoryController.dispose();
    dateController.dispose();
    super.dispose();
  }
}
