import 'package:flutter/material.dart';

class SchedulesViewModel extends ChangeNotifier {
  String? _selectedRoute;
  String? get selectedRoute => _selectedRoute;

  final List<String> _routes = [
    'Ruta A - Centro',
    'Ruta B - Norte',
    'Ruta C - Sur',
    'Ruta Express',
  ];
  List<String> get routes => _routes;

  final List<Map<String, String>> _allSchedules = [
    {'route': 'Ruta A - Centro', 'departure': '06:00 AM', 'arrival': '07:30 AM', 'status': 'A tiempo'},
    {'route': 'Ruta A - Centro', 'departure': '08:00 AM', 'arrival': '09:30 AM', 'status': 'Retrasado'},
    {'route': 'Ruta B - Norte', 'departure': '07:15 AM', 'arrival': '08:45 AM', 'status': 'A tiempo'},
    {'route': 'Ruta C - Sur', 'departure': '09:00 AM', 'arrival': '10:15 AM', 'status': 'A tiempo'},
    {'route': 'Ruta Express', 'departure': '06:30 AM', 'arrival': '07:15 AM', 'status': 'A tiempo'},
  ];

  List<Map<String, String>> get schedules {
    if (_selectedRoute == null) return [];
    return _allSchedules.where((s) => s['route'] == _selectedRoute).toList();
  }

  void selectRoute(String route) {
    _selectedRoute = route;
    notifyListeners();
  }
}
