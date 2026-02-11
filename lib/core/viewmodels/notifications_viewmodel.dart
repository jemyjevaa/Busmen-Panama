import 'dart:async';
import 'package:flutter/material.dart';
import 'package:busmen_panama/core/services/models/notification_model.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:busmen_panama/core/services/cache_user_session.dart';

class NotificationsViewModel extends ChangeNotifier {
  final _requestService = RequestService.instance;
  final _urlService = UrlService();
  final _session = CacheUserSession();
  
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasUnread = false;
  bool get hasUnread => _hasUnread;

  String? _pendingFlyerType;
  String? get pendingFlyerType => _pendingFlyerType;

  Timer? _refreshTimer;

  NotificationsViewModel() {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _refreshTimer?.cancel();
    // Check every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_session.isLogin) {
        checkNewNotifications();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void setPendingFlyerType(String? type) {
    _pendingFlyerType = type;
    notifyListeners();
  }

  void clearPendingFlyerType() {
    _pendingFlyerType = null;
    notifyListeners();
  }

  void setHasUnread(bool value) {
    _hasUnread = value;
    notifyListeners();
  }

  Future<void> checkNewNotifications() async {
    if (!_session.isLogin) return;

    try {
      final company = _session.companyClave ?? "";
      final response = await _requestService.handlingRequestParsed<ResponseNotifications>(
        urlParam: _urlService.getUrlInfoNotifications(),
        params: {
          'empresa': company,
          'segmento': 'todos',
        },
        method: 'POST',
        fromJson: (json) => ResponseNotifications.fromJson(json),
      );

      if (response != null) {
        final st = response.respuesta.toLowerCase();
        if (st == 'existe' || st == 'ok' || st == 'success') {
          final newCount = response.datos.length;
          final lastCount = _session.notificationsCount;
          
          if (newCount > lastCount) {
            // debugPrint("DEBUG - New notifications detected! Previous: $lastCount, New: $newCount");
            _hasUnread = true;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("ERROR - checkNewNotifications: $e");
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final company = _session.companyClave ?? "";
      // debugPrint("DEBUG - Fetching notifications for company: '$company'");
      
      final response = await _requestService.handlingRequestParsed<ResponseNotifications>(
        urlParam: _urlService.getUrlInfoNotifications(),
        params: {
          'empresa': company,
          'segmento': 'todos',
        },
        method: 'POST',
        fromJson: (json) {
          // debugPrint("DEBUG - Notifications API Raw Response: $json");
          return ResponseNotifications.fromJson(json);
        },
      );

      if (response != null) {
        final st = response.respuesta.toLowerCase();
        // debugPrint("DEBUG - Notifications API status: $st, Count: ${response.datos.length}");
        if (st == 'existe' || st == 'correcto' || st == 'ok' || st == 'success') {
          _notifications = response.datos;
          
          // Update persistent count and clear unread flag
          _session.notificationsCount = _notifications.length;
          _hasUnread = false;
        } else {
          debugPrint("DEBUG - No notifications found (respuesta: ${response.respuesta})");
        }
      } else {
        debugPrint("DEBUG - Response was null");
      }
    } catch (e) {
      debugPrint("ERROR - Loading notifications: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
