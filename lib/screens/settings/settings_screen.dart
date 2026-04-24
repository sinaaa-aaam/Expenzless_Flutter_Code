// lib/screens/settings/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/offline_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user     = context.read<AuthProvider>().user;
    final queueCnt = OfflineService.queueCount();

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(title: const Text('Settings'),
        automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: AppColors.tealBg,
                  child: Text(
                    (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w700, color: AppColors.teal)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? 'User',
                    style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700, color: AppColors.slate800)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '',
                    style: const TextStyle(fontSize: 13,
                      color: AppColors.slate400)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          if (queueCnt > 0)
            Card(
              color: AppColors.warning.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.cloud_off, color: AppColors.warning),
                title: Text('$queueCnt expense(s) waiting to sync',
                  style: const TextStyle(fontWeight: FontWeight.w600,
                    color: AppColors.slate800)),
                trailing: TextButton(
                  onPressed: () async {
                    final synced = await OfflineService.syncQueued();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Synced $synced record(s)'),
                        backgroundColor: AppColors.success));
                    }
                  },
                  child: const Text('Sync now',
                    style: TextStyle(color: AppColors.teal))),
              ),
            ),

          const SizedBox(height: 8),
          _sectionLabel('Data'),
          _settingsTile(
            icon: Icons.download_outlined, label: 'Export to CSV',
            subtitle: 'Download all expenses as a spreadsheet',
            onTap: () => _exportCsv(context)),

          _sectionLabel('App'),
          _settingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notification Preferences',
            subtitle: 'Budget alerts and goal reminders',
            onTap: () {}),
          _settingsTile(
            icon: Icons.currency_exchange, label: 'Currency',
            subtitle: 'GH₵ Ghanaian Cedi', onTap: () {}),

          _sectionLabel('Account'),
          _settingsTile(
            icon: Icons.logout, label: 'Log Out',
            iconColor: AppColors.error, textColor: AppColors.error,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log Out')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),

          const SizedBox(height: 32),
          const Center(child: Text('Expenzless v1.0.0',
            style: TextStyle(fontSize: 12, color: AppColors.slate400))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
    child: Text(label.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.slate400, letterSpacing: 0.8)),
  );

  Widget _settingsTile({
    required IconData icon, required String label,
    String? subtitle,
    Color iconColor = AppColors.slate600,
    Color textColor = AppColors.slate800,
    required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 4),
    child: ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20)),
      title: Text(label, style: TextStyle(fontSize: 14,
        fontWeight: FontWeight.w600, color: textColor)),
      subtitle: subtitle != null
        ? Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.slate400))
        : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final provider  = context.read<ExpenseProvider>();
      final expenses  = await provider.getExpensesForReport();
      final csvString = await provider.exportToCsv(expenses);
      final dir  = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/expenzless_export_$date.csv');
      await file.writeAsString(csvString);
      await Share.shareXFiles([XFile(file.path)],
        subject: 'Expenzless Expense Export $date');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Export failed. Please try again.'),
          backgroundColor: AppColors.error));
      }
    }
  }
}
