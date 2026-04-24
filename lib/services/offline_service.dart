// lib/services/offline_service.dart
// LOCAL RESOURCE 3: Background Tasks + Offline Use
// WorkManager only runs on Android/iOS. Windows/web fall back to direct sync.

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

const _kBoxName  = 'offline_expense_queue';
const _kSyncTask = 'syncOfflineExpenses';

bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _kSyncTask) await OfflineService.syncQueued();
    return true;
  });
}

class OfflineService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_kBoxName);

    if (_isMobile) {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      Workmanager().registerPeriodicTask(
        'expenzless_sync', _kSyncTask,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(seconds: 30),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
    }
  }

  static Future<void> queueExpense(Map<String, dynamic> expenseMap) async {
    final box = Hive.box(_kBoxName);
    final key = 'expense_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, jsonEncode(expenseMap));
  }

  static int queueCount() => Hive.box(_kBoxName).length;

  static Future<int> syncQueued() async {
    final box = Hive.box(_kBoxName);
    final db  = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || box.isEmpty) return 0;

    int synced = 0;
    for (final key in List.from(box.keys)) {
      try {
        final raw  = box.get(key) as String;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _convertDates(data);
        await db.collection('expenses').doc(data['id'] as String).set(data);
        await box.delete(key);
        synced++;
      } catch (_) {}
    }
    return synced;
  }

  static void _convertDates(Map<String, dynamic> data) {
    for (final key in ['date', 'createdAt', 'updatedAt']) {
      if (data[key] is String) {
        final dt = DateTime.tryParse(data[key] as String);
        if (dt != null) data[key] = Timestamp.fromDate(dt);
      }
    }
  }

  static Future<void> triggerImmediateSync() async {
    if (_isMobile) {
      await Workmanager().registerOneOffTask(
        'immediate_sync', _kSyncTask,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } else {
      await syncQueued();
    }
  }
}
