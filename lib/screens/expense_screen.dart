import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/app_background.dart';

class ExpenseScreen extends StatefulWidget {
  static const routeName = '/expense';
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _amount = TextEditingController();
  String _category = 'personal';
  final _note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final personal = exp.expenses
        .where((e) => e.category == 'personal')
        .fold(0.0, (a, b) => a + b.amount);
    final company = exp.expenses
        .where((e) => e.category == 'company')
        .fold(0.0, (a, b) => a + b.amount);

    final dataMap = {
      'Personal': personal,
      'Company': company,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _category,
                      items: const [
                        DropdownMenuItem(value: 'personal', child: Text('Personal')),
                        DropdownMenuItem(value: 'company', child: Text('Company')),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? 'personal'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.note_alt_outlined)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final amt = double.tryParse(_amount.text.trim());
                if (amt == null) return;
                await context.read<ExpenseProvider>().addExpense(
                  amount: amt,
                  category: _category,
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                );
                _amount.clear();
                _note.clear();
              },
              icon: const Icon(Icons.addchart),
              label: const Text('Add Expense'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: PieChart(dataMap: dataMap, chartRadius: 140),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Recent', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ...exp.expenses.map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('₹${e.amount.toStringAsFixed(2)} - ${e.category}'),
                    subtitle: Text(e.note ?? ''),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}


