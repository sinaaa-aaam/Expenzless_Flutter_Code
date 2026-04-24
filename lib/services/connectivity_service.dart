// lib/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Stream<bool> get onConnectivityChange =>
    Connectivity().onConnectivityChanged
      .map((r) => r != ConnectivityResult.none);
}
