// lib/screens/expenses/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../services/camera_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/loading_button.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? existing;
  const AddExpenseScreen({super.key, this.existing});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  String   _category  = AppConstants.categories.first;
  DateTime _date      = DateTime.now();
  String?  _receiptUrl;
  bool     _scanning   = false;
  bool     _attachLoc  = false;
  bool     _saving     = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _descCtrl.text   = e.description;
      _category        = e.category;
      _date            = e.date;
      _receiptUrl      = e.receiptImageUrl.isNotEmpty ? e.receiptImageUrl : null;
    }
  }

  @override
  void dispose() { _amountCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _scanReceipt() async {
    setState(() => _scanning = true);
    try {
      final result = await CameraService.scanReceiptFromCamera();
      if (result == null) { setState(() => _scanning = false); return; }
      setState(() {
        if (result.amount != null)
          _amountCtrl.text = result.amount!.toStringAsFixed(2);
        if (result.category != null &&
            AppConstants.categories.contains(result.category))
          _category = result.category!;
        if (result.date != null) _date = result.date!;
        if (result.vendor != null && _descCtrl.text.isEmpty)
          _descCtrl.text = result.vendor!;
        if (result.receiptImageUrl != null)
          _receiptUrl = result.receiptImageUrl;
        _scanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Receipt scanned — please review the details'),
        backgroundColor: AppColors.success,
      ));
    } catch (_) { setState(() => _scanning = false); }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.teal)),
        child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ExpenseProvider>();
    bool ok;

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        amount: double.parse(_amountCtrl.text),
        category: _category,
        description: _descCtrl.text.trim(),
        date: _date,
        receiptImageUrl: _receiptUrl ?? '',
      );
      ok = await provider.editExpense(widget.existing!, updated);
    } else {
      ok = await provider.addExpense(
        amount: double.parse(_amountCtrl.text),
        category: _category,
        description: _descCtrl.text.trim(),
        date: _date,
        receiptImageUrl: _receiptUrl,
        attachLocation: _attachLoc,
      );
    }

    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Expense updated' : 'Expense saved'),
        backgroundColor: AppColors.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to save'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (!_isEdit)
            _scanning
              ? const Padding(padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                      color: AppColors.teal)))
              : TextButton.icon(
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.camera_alt, color: AppColors.teal),
                  label: const Text('Scan',
                    style: TextStyle(color: AppColors.teal))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_receiptUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_receiptUrl!, height: 140,
                  width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            AppTextField(
              controller: _amountCtrl, label: 'Amount (GH₵)', hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null || double.parse(v) <= 0)
                  return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text('Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.slate600)),
            const SizedBox(height: 8),
            CategoryPicker(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 16),

            AppTextField(
              controller: _descCtrl, label: 'Description',
              hint: 'e.g. Flour from Makola Market',
              prefixIcon: Icons.notes, maxLines: 2,
              validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 20,
                    color: AppColors.slate400),
                  const SizedBox(width: 12),
                  Text(DateFormat('EEE, dd MMM yyyy').format(_date),
                    style: const TextStyle(fontSize: 15,
                      color: AppColors.slate800)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: AppColors.slate400),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            Row(children: [
              Switch(
                value: _attachLoc,
                onChanged: (v) => setState(() => _attachLoc = v),
                activeColor: AppColors.teal,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on_outlined, size: 20,
                color: AppColors.slate400),
              const SizedBox(width: 4),
              const Text('Tag with current location',
                style: TextStyle(fontSize: 14, color: AppColors.slate600)),
            ]),
            const SizedBox(height: 32),

            LoadingButton(
              label: _isEdit ? 'Update Expense' : 'Save Expense',
              loading: _saving,
              onPressed: _save,
            ),
          ]),
        ),
      ),
    );
  }
}
