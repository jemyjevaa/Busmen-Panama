import 'dart:async';
import 'package:flutter/material.dart';
import '../services/request_service.dart';
import '../services/url_service.dart';
import '../services/simulation_service.dart';
import '../services/models/info_schedules_model.dart';

class OperatorViewModel extends ChangeNotifier {
  final RequestService _api = RequestService.instance;
  final UrlService _urlService = UrlService();

  List<RouteData> _availableRoutes = [];
  List<RouteData> get availableRoutes => _availableRoutes;

  RouteData? _selectedRoute;
  RouteData? get selectedRoute => _selectedRoute;

  List<StopData> _stops = [];
  List<StopData> get stops => _stops;

  int _currentStopIndex = -1;
  int get currentStopIndex => _currentStopIndex;

  bool _isRouteStarted = false;
  bool get isRouteStarted => _isRouteStarted;

  bool _isBusFull = false;
  bool get isBusFull => _isBusFull;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInTransit = false;
  bool get isInTransit => _isInTransit;

  final Map<int, String> _stopWaitTimes = {};
  Map<int, String> get stopWaitTimes => _stopWaitTimes;

  // Timer logic
  Timer? _stopTimer;
  int _secondsAtStop = 0;
  int get secondsAtStop => _secondsAtStop;
  static const int minWaitSeconds = 300; // 5 minutes

  bool get canLeaveStop => _secondsAtStop >= minWaitSeconds;

  Future<void> fetchRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final resp = await _api.handlingRequestParsed<ResponseInfoRoutes>(
        urlParam: _urlService.getUrlInfoRoutes(),
        method: "POST",
        fromJson: (json) => ResponseInfoRoutes.fromJson(json),
      );
      
      _availableRoutes = resp?.datos ?? [];

      // Ensure Pacora is always available for simulation
      bool hasPacora = _availableRoutes.any((r) => r.nombre.toUpperCase().contains('PACORA'));
      if (!hasPacora) {
        _availableRoutes.insert(0, RouteData(
          claveruta: 'SIM_PACORA',
          nombre: 'PACORA - Vía España',
          tipo_ruta: 'ENTRADA',
          tramo: 'PACORA',
        ));
      }
    } catch (e) {
      // Fallback to only Pacora if API fails
      _availableRoutes = [
        RouteData(
          claveruta: 'SIM_PACORA',
          nombre: 'PACORA - Vía España',
          tipo_ruta: 'ENTRADA',
          tramo: 'PACORA',
        )
      ];
      print("Operator error fetching routes: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectRoute(RouteData route) async {
    _selectedRoute = route;
    _isRouteStarted = false;
    _currentStopIndex = -1;
    _isBusFull = false;
    _isInTransit = false;
    _stopWaitTimes.clear();
    _stopTimer?.cancel();
    _secondsAtStop = 0;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      if (route.claveruta == 'SIM_PACORA') {
        // Mock stops for Pacora with pseudo-coordinates for simulation
        _stops = [
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'C.C. La Doña (Inicio)', horario: '06:00', estatus: 'A tiempo', hora_parada: '06:00', latitud: 9.071852, longitud: -79.370503, numero_parada: 1),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Megamall', horario: '06:15', estatus: 'A tiempo', hora_parada: '06:15', latitud: 9.068222, longitud: -79.385202, numero_parada: 2),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Plaza Tocumen', horario: '06:30', estatus: 'A tiempo', hora_parada: '06:30', latitud: 9.055877, longitud: -79.431252, numero_parada: 3),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Metro Mall', horario: '06:45', estatus: 'A tiempo', hora_parada: '06:45', latitud: 9.050519, longitud: -79.453303, numero_parada: 4),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Plaza Carolina', horario: '07:00', estatus: 'A tiempo', hora_parada: '07:00', latitud: 9.020583, longitud: -79.489370, numero_parada: 5),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Vía España (Final)', horario: '07:15', estatus: 'A tiempo', hora_parada: '07:15', latitud: 8.986617, longitud: -79.529844, numero_parada: 6),
        ];
      } else {
        final resp = await _api.handlingRequestParsed<ResponseInfoStops>(
          urlParam: _urlService.getUrlInfoStops(),
          method: "POST",
          params: {'claveruta': route.claveruta},
          fromJson: (json) => ResponseInfoStops.fromJson(json),
        );
        if (resp != null) {
          _stops = resp.datos;
        }
      }
    } catch (e) {
      print("Operator error fetching stops: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startRoute() {
    _isRouteStarted = true;
    _currentStopIndex = 0;
    _isInTransit = false;
    _stopWaitTimes.clear();
    
    // BROADCAST INITIAL POSITION (Arrival at first stop)
    if (_stops.isNotEmpty) {
      SimulationService().broadcastPosition(_stops[0].latitud, _stops[0].longitud);
    }
    
    _startStopTimer();
    notifyListeners();
  }

  void endRoute() {
    _isRouteStarted = false;
    _currentStopIndex = -1;
    _isInTransit = false;
    _stopTimer?.cancel();
    _secondsAtStop = 0;
    notifyListeners();
  }

  void toggleBusFull() {
    _isBusFull = !_isBusFull;
    notifyListeners();
  }

  // STEP 1: Leaving current stop
  void nextStop() {
    if (_currentStopIndex >= 0) {
      // Record wait time
      _stopWaitTimes[_currentStopIndex] = formattedWaitTime;
      
      // Stop timer and set transit state
      _stopTimer?.cancel();
      _isInTransit = true;
      notifyListeners();
    }
  }

  // STEP 2: Arriving at next stop
  void arriveAtNextStop() {
    if (_currentStopIndex < _stops.length - 1) {
      _currentStopIndex++;
      _isInTransit = false;
      
      // BROADCAST POSITION for simulated tracking
      final stop = _stops[_currentStopIndex];
      SimulationService().broadcastPosition(stop.latitud, stop.longitud);
      
      _startStopTimer();
      notifyListeners();
    } else {
      // Last stop reached
      endRoute();
    }
  }

  void _startStopTimer() {
    _stopTimer?.cancel();
    _secondsAtStop = 0;
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsAtStop++;
      notifyListeners();
    });
  }

  String get formattedWaitTime {
    int minutes = _secondsAtStop ~/ 60;
    int seconds = _secondsAtStop % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    super.dispose();
  }
}
