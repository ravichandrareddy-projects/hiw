// lib/core/hw_wallet.dart — Non-cash virtual in-app reward currency (HW Coins).
// IMPORTANT: HW Coins have NO cash or financial value. They cannot be purchased
// with real money or redeemed for cash. They represent in-app consistency rewards.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HWTransaction {
  final String id;
  final int amount; // positive = earned, negative = spent on cosmetics
  final String reason;
  final DateTime timestamp;

  const HWTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HWTransaction.fromJson(Map<String, dynamic> json) => HWTransaction(
        id: json['id'] as String,
        amount: json['amount'] as int,
        reason: json['reason'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class HWWallet extends ChangeNotifier {
  static final HWWallet _instance = HWWallet._internal();
  factory HWWallet() => _instance;
  HWWallet._internal();

  static const _balanceKey = 'hiw_hw_coins_balance';
  static const _ledgerKey = 'hiw_hw_coins_ledger';

  int _balance = 0;
  final List<HWTransaction> _ledger = [];
  bool _initialized = false;

  int get balance => _balance;
  List<HWTransaction> get ledger => List.unmodifiable(_ledger);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_balanceKey) ?? 0;

    final rawList = prefs.getStringList(_ledgerKey) ?? [];
    _ledger.clear();
    for (final raw in rawList) {
      try {
        _ledger.add(HWTransaction.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    _initialized = true;
    notifyListeners();
  }

  /// Credits HW Coins to the user's virtual wallet.
  Future<void> credit(int amount, {required String reason}) async {
    if (amount <= 0) return;
    await init();
    _balance += amount;

    final tx = HWTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
    );
    _ledger.insert(0, tx);
    if (_ledger.length > 50) {
      _ledger.removeRange(50, _ledger.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, _balance);
    await prefs.setStringList(
      _ledgerKey,
      _ledger.map((t) => jsonEncode(t.toJson())).toList(),
    );

    notifyListeners();
  }
}
