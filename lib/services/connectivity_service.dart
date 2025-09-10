import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivityController = StreamController<bool>.broadcast();
  bool _isConnected = false;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    await _checkConnectivity();

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _checkConnectivity();
    });
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.isEmpty ||
          connectivityResult.first == ConnectivityResult.none) {
        _updateConnectivity(false);
        return;
      }

      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectivity(isConnected);
    } catch (e) {
      _updateConnectivity(false);
    }
  }

  /// Update connectivity status and notify listeners
  void _updateConnectivity(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectivityController.add(connected);
    }
  }

  /// Force check connectivity
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivityController.close();
  }
}
