import 'package:walletconnect_dart/src/session/wallet_connect_session.dart';

abstract class SessionStorage {
  Future store(String storageKey, WalletConnectSession session);

  Future<WalletConnectSession?> getSession(String storageKey);

  Future removeSession(String storageKey);
}
