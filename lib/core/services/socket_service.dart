import 'dart:convert';
import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/main.dart';
import 'package:busmen_panama/core/viewmodels/notifications_viewmodel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  final UrlService _urlService = UrlService();
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _sessionCookie;
  List<int> _deviceIds = [];

  StreamController<Map<String, dynamic>>? _positionController;
  Stream<Map<String, dynamic>>? get positionStream => _positionController?.stream;

  /// Initialize session cookie for WebSocket authentication
  Future<bool> initSessionCookie() async {
    try {
      print("DEBUG - Initializing GPS session cookie...");
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we already have a valid cookie
      final existingCookie = prefs.getString('gps_session_cookie');
      if (existingCookie != null && existingCookie.isNotEmpty) {
        _sessionCookie = existingCookie;
        print("DEBUG - Using existing GPS session cookie");
        return true;
      }

      // Get new session cookie using URLEncoded format (not JSON)
      final response = await http.post(
        Uri.parse('https://rastreobusmenpa.geovoy.com/api/session'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'email=usuariosapp&password=usuarios0904',
      );

      if (response.statusCode == 200) {
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          _sessionCookie = setCookie.split(';')[0]; // Extract cookie value (JSESSIONID=...)
          await prefs.setString('gps_session_cookie', _sessionCookie!);
          print("DEBUG - GPS session cookie initialized: ${_sessionCookie!.substring(0, 20)}...");
          return true;
        }
      }
      
      print("ERROR - Failed to get GPS session cookie: ${response.statusCode}");
      return false;
    } catch (e) {
      print("ERROR - initSessionCookie: $e");
      return false;
    }
  }

  /// Set device IDs to filter WebSocket messages
  void setDeviceIds(List<String?> ids) {
    _deviceIds = ids
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => int.tryParse(id!))
        .where((id) => id != null)
        .cast<int>()
        .toList();
    print("DEBUG - Device IDs set: $_deviceIds");
  }

  /// Connect to WebSocket with authentication
  Future<void> connect() async {
    if (_isConnected) {
      print("DEBUG - Already connected to WebSocket");
      return;
    }

    // Ensure we have a session cookie
    if (_sessionCookie == null) {
      final success = await initSessionCookie();
      if (!success) {
        print("ERROR - Cannot connect without session cookie");
        return;
      }
    }

    try {
      final url = Uri.parse(_urlService.getUrlSocket());
      print("DEBUG - Connecting to WebSocket: $url");
      
      _channel = WebSocketChannel.connect(
        url,
        protocols: null,
      );

      // Note: web_socket_channel doesn't support custom headers directly
      // The cookie should be sent via the browser's cookie jar in web
      // For mobile, we might need to use a different approach or library
      
      _positionController = StreamController<Map<String, dynamic>>.broadcast();
      _isConnected = true;

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          print("ERROR - WebSocket error: $error");
          _handleDisconnect();
        },
        onDone: () {
          print("DEBUG - WebSocket connection closed");
          _handleDisconnect();
        },
      );

      print("DEBUG - WebSocket connected successfully");
    } catch (e) {
      print("ERROR - Failed to connect to WebSocket: $e");
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = data is String ? json.decode(data) : data;
      
      // Filter by device IDs if available
      if (_deviceIds.isNotEmpty) {
        final deviceId = message['deviceId'] ?? message['id'] ?? message['idplataformagps'];
        if (deviceId != null) {
          final intId = deviceId is int ? deviceId : int.tryParse(deviceId.toString());
          if (intId != null && !_deviceIds.contains(intId)) {
            return; // Ignore messages from other devices
          }
        }
      }

      // Emit position update
      if (message.containsKey('latitude') || message.containsKey('lat')) {
        _positionController?.add(message);
      }
    } catch (e) {
      print("ERROR - Failed to parse WebSocket message: $e");
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _positionController?.close();
    _positionController = null;
  }

  void disconnect() {
    _channel?.sink.close();
    _handleDisconnect();
    print("DEBUG - WebSocket disconnected");
  }

  void dispose() {
    disconnect();
  }

  // region OneSignal
  static const String _oneSignalAppId = "0749cbc5-802c-42fe-8a70-7f9dc7c2253f";

  Future<void> initOneSignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
      _setupOneSignalListeners();
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  void _setupOneSignalListeners() {
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('NOTIFICATION RECEIVED IN FOREGROUND: ${event.notification.title}');
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        Provider.of<NotificationsViewModel>(context, listen: false).setHasUnread(true);
      }
    });

    OneSignal.Notifications.addClickListener((event) {
      debugPrint('NOTIFICATION CLICKED: ${event.notification.title}');
      _handleNotificationClick(event.notification);
    });
  }

  void _handleNotificationClick(OSNotification notification) {
    final additionalData = notification.additionalData;
    if (additionalData != null && additionalData.containsKey('tipo_flyer')) {
      final tipoFlyer = additionalData['tipo_flyer'].toString();
      
      // If tipo_flyer is "1", don't navigate (purely informative)
      if (tipoFlyer == "1") {
        debugPrint('DEEP LINK IGNORED: tipo_flyer is 1 (informative only)');
        return;
      }

      debugPrint('DEEP LINK TRIGGERED: tipo_flyer = $tipoFlyer');
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        Provider.of<NotificationsViewModel>(context, listen: false).setPendingFlyerType(tipoFlyer);
      }
    }
  }

  Future<void> setOneSignalTags(String company, String userId) async {
    debugPrint('SETTING ONESIGNAL TAGS: empresaNombre=$company, empresasidusuario=$company-$userId');
    OneSignal.User.addTagWithKey("empresaNombre", company);
    OneSignal.User.addTagWithKey("empresaidusuario", "$company-$userId");
  }

  Future<void> removeOneSignalTags() async {
    OneSignal.User.removeTags(["empresaNombre", "empresaidusuario"]);
  }
  // endregion
}
