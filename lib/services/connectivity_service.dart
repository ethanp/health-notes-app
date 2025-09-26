import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity
class ConnectivityService {
  factory ConnectivityService() => _singleton;

  ConnectivityService._();

  static final ConnectivityService _singleton = ConnectivityService._();

  final _connectivityStreamController = StreamController<bool>.broadcast();
  bool _isConnected = false;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    await _checkConnectivity();

    Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) => _checkConnectivity(),
    );
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      _updateConnectivity(
        await _checkIos() && await _validateThatDnsLookupWorks(),
      );
    } catch (e) {
      _updateConnectivity(false);
    }
  }

  Future<bool> _validateThatDnsLookupWorks() async {
    final dnsResult = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 5));
    return dnsResult.isNotEmpty && dnsResult[0].rawAddress.isNotEmpty;
  }

  Future<bool> _checkIos() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    return connectivityResult.isNotEmpty &&
        connectivityResult.first != ConnectivityResult.none;
  }

  /// Update connectivity status and notify listeners
  void _updateConnectivity(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectivityStreamController.add(connected);
    }
  }

  /// Force check connectivity
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivityStreamController.close();
  }
}
