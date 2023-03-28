import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WalletConnectSecureStorage implements SessionStorage {

  @override
  Future<WalletConnectSession?> getSession(String storageKey) async {
    var storage = await SharedPreferences.getInstance();

    final json = storage.getString(storageKey);
    if (json == null) {
      return null;
    }

    try {
      final data = jsonDecode(json);
      return WalletConnectSession.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  @override
  Future store(String storageKey, WalletConnectSession session) async {
    var storage = await SharedPreferences.getInstance();
    await storage.setString(storageKey, jsonEncode(session.toJson()));
  }

  @override
  Future removeSession(String storageKey) async {
    var storage = await SharedPreferences.getInstance();
    await storage.remove(storageKey);
  }
}
