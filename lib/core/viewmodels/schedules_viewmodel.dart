import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/models/info_schedules_model.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:busmen_panama/core/services/google_directions_service.dart';
import 'package:busmen_panama/core/services/socket_service.dart';
import 'dart:async';
import 'dart:convert';

class SchedulesViewModel extends ChangeNotifier {
  final _session = CacheUserSession();
  final _urlService = UrlService();
  final _requestService = RequestService.instance;
  final _directionsService = GoogleDirectionsService();
  final _socketService = SocketService();
  StreamSubscription? _socketSubscription;

  List<LatLng> _roadPoints = [];
  List<LatLng> get roadPoints => _roadPoints;

  List<RouteData> _routes = [];
  List<RouteData> get routes => _routes;

  List<StopData> _stops = [];
  List<StopData> get stops => _stops;

  UnitData? _unit;
  UnitData? get unit => _unit;

  RouteData? _selectedRoute;
  RouteData? get selectedRoute => _selectedRoute;

  String _filterOption = 'TODAS';
  String get filterOption => _filterOption;

  void setFilterOption(String option) {
    _filterOption = option;
    notifyListeners();
  }

  // Flyers State
  List<FlyerData> _bulletins = [];
  List<FlyerData> _regulations = [];
  List<FlyerData> _manuals = [];
  bool _isLoadingFlyers = false;

  List<FlyerData> get bulletins => _bulletins;
  List<FlyerData> get regulations => _regulations;
  List<FlyerData> get manuals => _manuals;
  bool get isLoadingFlyers => _isLoadingFlyers;

  List<FlyerData> get allFlyers => [..._bulletins, ..._regulations, ..._manuals];

  // Live Tracking States
  StopData? _selectedUserStop;
  StopData? get selectedUserStop => _selectedUserStop;

  int _currentUnitStopIndex = -1; // Index in the _stops list
  int get currentUnitStopIndex => _currentUnitStopIndex;

  void selectUserStop(StopData stop) {
    _selectedUserStop = stop;
    notifyListeners();
  }

  void clearUserStop() {
    _selectedUserStop = null;
    notifyListeners();
  }

  bool _showFilteredStops = false;
  bool get showFilteredStops => _showFilteredStops;

  void toggleFilteredStops() {
    _showFilteredStops = !_showFilteredStops;
    notifyListeners();
  }

  StopData? getPreviousStop() {
    if (_unit == null || _stops.isEmpty || _currentUnitStopIndex <= 0) return null;
    return _stops[_currentUnitStopIndex - 1];
  }

  StopData? getCurrentStop() {
    if (_unit == null || _stops.isEmpty || _currentUnitStopIndex < 0) return null;
    return _stops[_currentUnitStopIndex];
  }

  StopData? getNextStop() {
    if (_unit == null || _stops.isEmpty || _currentUnitStopIndex < 0 || _currentUnitStopIndex >= _stops.length - 1) return null;
    return _stops[_currentUnitStopIndex + 1];
  }

  // Status Enum Logic: 
  // 'Ya Realizada', 'En Camino', 'Unidad en el punto', 'Aún no Realizada'
  String getStopLiveStatus(StopData stop) {
    if (_unit == null || _stops.isEmpty) return 'Aún no Realizada';
    
    final unitLat = double.tryParse(_unit!.lat) ?? 0.0;
    final unitLon = double.tryParse(_unit!.lon) ?? 0.0;
    
    // 1. Proximity check for "Unidad en el punto" (Threshold 50 meters)
    final distance = Geolocator.distanceBetween(
      unitLat, unitLon, 
      stop.latitud, stop.longitud
    );
    
    if (distance < 50) return 'Unidad en el punto';

    // 2. Index based logic
    final stopIndex = _stops.indexOf(stop);
    
    // Update internal current tracker if not set or found a better match
    _updateTrackingIndex(unitLat, unitLon);

    if (stopIndex < _currentUnitStopIndex) return 'Ya Realizada';
    if (stopIndex == _currentUnitStopIndex + 1) return 'En Camino';
    if (stopIndex > _currentUnitStopIndex) return 'Aún no Realizada';
    
    return 'Aún no Realizada';
  }

  void _updateTrackingIndex(double unitLat, double unitLon) {
    // Find the furthest stop the unit has already passed
    // For simplicity, we find the stop with minimum distance or the the last one where distance was small.
    // In a real scenario, we'd check if index i-1 distance < threshold and current distance is increasing.
    
    double minDistance = double.infinity;
    int bestIndex = -1;

    for (int i = 0; i < _stops.length; i++) {
       final d = Geolocator.distanceBetween(unitLat, unitLon, _stops[i].latitud, _stops[i].longitud);
       if (d < 100) { // If it's within 100m of ANY stop, that's our anchor
          bestIndex = i;
       }
       if (d < minDistance) {
         minDistance = d;
       }
    }

    // Only update if we found a clear anchor or if the unit is moving forward
    if (bestIndex != -1 && bestIndex >= _currentUnitStopIndex) {
      _currentUnitStopIndex = bestIndex;
    }
  }

  List<RouteData> _recentRoutes = [];
  List<RouteData> get recentRoutes => _recentRoutes;

  // Group routes by name
  Map<String, List<RouteData>> get groupedRoutes {
    Map<String, List<RouteData>> groups = {};
    for (var route in _routes) {
      if (!groups.containsKey(route.nombre)) {
        groups[route.nombre] = [];
      }
      groups[route.nombre]!.add(route);
    }
    return groups;
  }

  void addToRecent(RouteData route) {
    if (_recentRoutes.any((r) => r.claveruta == route.claveruta)) {
      _recentRoutes.removeWhere((r) => r.claveruta == route.claveruta);
    }
    _recentRoutes.insert(0, route);
    if (_recentRoutes.length > 6) {
      _recentRoutes = _recentRoutes.take(6).toList();
    }
    notifyListeners();
  }

  List<RouteData> get filteredRoutes {
    switch (_filterOption) {
      case 'FRECUENTES':
        return recentRoutes;
      case 'EN TIEMPO':
        return _routes.where(_isRouteInTime).toList();
      case 'TODAS':
      default:
        return _routes;
    }
  }

  bool _isRouteInTime(RouteData route) {
    try {
      final now = DateTime.now();
      final String turno = route.tipo_ruta.toUpperCase();
      final String diaRuta = (route.dia_ruta ?? '').toUpperCase();
      
      // 1. Check Day - Use dia_ruta field if available, otherwise fallback to tipo_ruta
      bool dayMatch = false;
      int weekday = now.weekday; // 1 (Mon) - 7 (Sun)
      
      // Prefer dia_ruta field for day matching
      final daySource = diaRuta.isNotEmpty ? diaRuta : turno;
      
      // Expanded day keywords
      if (daySource.contains('L-V') || daySource.contains('LUN-VIE') || daySource.contains('LUNES A VIERNES')) {
        dayMatch = (weekday >= 1 && weekday <= 5);
      } else if (daySource.contains('SAB') || daySource.contains('SÁB') || daySource.contains('SABADO') || daySource.contains('SÁBADO')) {
        dayMatch = (weekday == 6);
      } else if (daySource.contains('DOM') || daySource.contains('DOMINGO')) {
        dayMatch = (weekday == 7);
      } else if (daySource.isEmpty || daySource.contains('DIARIO') || daySource.contains('TODOS') || daySource.contains('TODOS LOS DIAS')) {
        dayMatch = true; 
      } else {
        // If we can't determine the day, log it and default to false to avoid showing wrong routes
        print("DEBUG - Unknown day format for route ${route.claveruta}: dia_ruta='$diaRuta', tipo_ruta='$turno'");
        dayMatch = false;
      }
      
      if (!dayMatch) {
        print("DEBUG - Route ${route.claveruta} filtered out: today=$weekday, dia_ruta='$diaRuta'");
        return false;
      }

      // 2. Check Time Range
      // Try using hora_inicio and hora_fin if they exist
      String startTimeStr = route.hora_inicio ?? "";
      String endTimeStr = route.hora_fin ?? "";

      // If they are missing, try extracting from tipo_ruta/turno
      if (startTimeStr.isEmpty) {
        final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(turno);
        if (timeMatch != null) {
          startTimeStr = "${timeMatch.group(1)}:${timeMatch.group(2)}";
        }
      }

      if (startTimeStr.isEmpty) return true; // Show it if we can't parse ANY time

      final startParts = startTimeStr.split(':');
      int startHour = int.parse(startParts[0]);
      int startMin = int.parse(startParts[1]);

      final routeStartTime = DateTime(now.year, now.month, now.day, startHour, startMin);
      
      DateTime windowStart;
      DateTime windowEnd;

      if (endTimeStr.isNotEmpty && endTimeStr.contains(':')) {
        final endParts = endTimeStr.split(':');
        int endHour = int.parse(endParts[0]);
        int endMin = int.parse(endParts[1]);
        
        // Window: 1 hour BEFORE start to ACTUAL end
        windowStart = routeStartTime.subtract(const Duration(hours: 1));
        windowEnd = DateTime(now.year, now.month, now.day, endHour, endMin);
        
        // If end is before start, it might cross midnight (unlikely for these routes, but good to handle)
        if (windowEnd.isBefore(routeStartTime)) {
           windowEnd = windowEnd.add(const Duration(days: 1));
        }
      } else {
        // Fallback: 60 minutes before to 3 hours after start if no end time exists
        windowStart = routeStartTime.subtract(const Duration(minutes: 60));
        windowEnd = routeStartTime.add(const Duration(hours: 3));
      }

      // Final check: Is current time within the active operational window?
      final isInTimeWindow = now.isAfter(windowStart) && now.isBefore(windowEnd);
      
      if (!isInTimeWindow) {
        print("DEBUG - Route ${route.claveruta} filtered out by time: now=${now.hour}:${now.minute}, window=${startTimeStr}-${endTimeStr}");
      }
      
      return isInTimeWindow;
    } catch (e) {
      debugPrint("Error in _isRouteInTime: $e");
      return false; // Changed from true to false - don't show routes with errors
    }
  }

  bool _isLoadingRoutes = false;
  bool get isLoadingRoutes => _isLoadingRoutes;

  bool _isLoadingStops = false;
  bool get isLoadingStops => _isLoadingStops;

  SchedulesViewModel() {
    print("DEBUG - SchedulesViewModel constructor called");
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    print("DEBUG - fetchRoutes - userSide: ${_session.userSide}");
    _isLoadingRoutes = true;
    notifyListeners();

    try {
      print("DEBUG - fetchRoutes - Starting request...");
      print("DEBUG - fetchRoutes - URL: ${_urlService.getUrlInfoRoutes()}");
      print("DEBUG - fetchRoutes - Params: tipo_ruta=${_session.userSide == 1 ? 'EXT' : '1'}, empresa=${_session.companyClave}");
      
      final response = await _requestService.handlingRequestParsed<ResponseInfoRoutes>(
        urlParam: _urlService.getUrlInfoRoutes(),
        params: {
          'tipo_ruta': _session.userSide == 1 ? 'EXT' : '1', 
          'empresa': _session.companyClave ?? '',
        },
        method: 'POST',
        fromJson: (json) {
          print("DEBUG - fetchRoutes JSON: $json");
          return ResponseInfoRoutes.fromJson(json);
        },
      );

      if (response != null && (response.respuesta == 'existe' || response.respuesta == 'correcto')) {
        _routes = response.datos;
        print("DEBUG - fetchRoutes success. Loaded ${_routes.length} routes.");
      } else {
        _routes = [];
        print("DEBUG - fetchRoutes failed or empty. Response: ${response?.respuesta}");
      }
    } catch (e) {
      debugPrint('Error fetching routes: $e');
      _routes = [];
    } finally {
      _isLoadingRoutes = false;
      notifyListeners();
      // Fetch general flyers (without route) for the lateral menu
      fetchAllFlyers("");
    }
  }

  Future<void> fetchFlyersByCategory(String routeClave, String tipo) async {
    try {
      print("DEBUG - fetchFlyersByCategory: tipo=$tipo, route=$routeClave");
      final response = await _requestService.handlingRequestParsed<ResponseFlyers>(
        urlParam: _urlService.getUrlInfoFlyers(),
        params: {
          'tipo_flyer': tipo,
          'claveruta': routeClave,
          'empresa': _session.companyClave ?? '',
        },
        method: 'POST',
        asJson: true, // Crucial: User specified JSON encoding
        fromJson: (json) {
          print("DEBUG - Flyers Response ($tipo): $json");
          return ResponseFlyers.fromJson(json);
        },
      );

      if (response != null && response.respuesta == 'correcto') {
        print("DEBUG - Found ${response.datos.length} flyers for tipo $tipo");
        // Sort by date (most recent first)
        final sorted = response.datos.toList()
          ..sort((a, b) => b.fecha_alta.compareTo(a.fecha_alta));
        
        if (tipo == '2') _bulletins = sorted;
        if (tipo == '3') _regulations = sorted;
        if (tipo == '4') _manuals = sorted;
      } else {
        if (tipo == '2') _bulletins = [];
        if (tipo == '3') _regulations = [];
        if (tipo == '4') _manuals = [];
      }
    } catch (e) {
      debugPrint('Error fetching flyers ($tipo): $e');
    }
  }

  Future<void> fetchAllFlyers(String routeClave) async {
    _isLoadingFlyers = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchFlyersByCategory(routeClave, '2'), // Comunicados
        fetchFlyersByCategory(routeClave, '3'), // Reglamentacion
        fetchFlyersByCategory(routeClave, '4'), // Manual
      ]);
    } finally {
      _isLoadingFlyers = false;
      notifyListeners();
    }
  }

  Future<void> selectRoute(RouteData? route, {VoidCallback? onRouteLoaded}) async {
    _selectedRoute = route;
    _stops = [];
    _unit = null;
    _bulletins = [];
    _regulations = [];
    _manuals = [];
    notifyListeners();

    if (route != null) {
      _currentUnitStopIndex = -1; // Reset tracking
      addToRecent(route);
      
      print("DEBUG - selectRoute called for: ${route.claveruta}");
      
      final futures = [
        fetchStops(route.claveruta),
        fetchUnit(route.claveruta),
        fetchLastPosition(route.claveruta), // Always fetch last position for all companies
        fetchAllFlyers(route.claveruta), // Added for Flyers feature
      ];
      
      await Future.wait(futures);
      
      print("DEBUG - After Future.wait: stops=${_stops.length}, unit=${_unit != null}");
      
      // Always enable road-following and real-time tracking for all companies
      // BUT make it non-blocking if it fails
      try {
        print("DEBUG - Fetching road points...");
        await _fetchRoadPoints();
        print("DEBUG - Road points fetched: ${_roadPoints.length}");
      } catch (e) {
        print("ERROR - Failed to fetch road points: $e");
      }
      
      // WebSocket tracking is completely optional and TEMPORARILY DISABLED
      // TODO: Fix WebSocket cookie header issue before re-enabling
      /*
      try {
        print("DEBUG - Starting socket tracking...");
        await _startSocketTracking();
      } catch (e) {
        print("ERROR - Failed to start socket tracking (non-critical): $e");
      }
      */
      print("DEBUG - WebSocket tracking disabled temporarily");
      
      print("DEBUG - selectRoute completed. Notifying listeners...");
      notifyListeners();
      
      // Call the callback after everything is loaded
      if (onRouteLoaded != null) {
        print("DEBUG - Calling onRouteLoaded callback");
        onRouteLoaded();
      }
    } else {
      _stopSocketTracking();
    }
  }

  Future<void> _fetchRoadPoints() async {
    if (_stops.isEmpty) return;
    final stopPoints = _stops.map((s) => LatLng(s.latitud, s.longitud)).toList();
    _roadPoints = await _directionsService.getRoutePolyline(stopPoints);
    notifyListeners();
  }

  void _startSocketTracking() async {
    _socketSubscription?.cancel();
    
    // Set device IDs for filtering if available
    if (_unit != null && _unit!.idplataformagps != null) {
      _socketService.setDeviceIds([_unit!.idplataformagps]);
    }
    
    await _socketService.connect();
    
    _socketSubscription = _socketService.positionStream?.listen((packet) {
      try {
        // Handle both formats: 'lat'/'lon' and 'latitude'/'longitude'
        final lat = packet['lat'] ?? packet['latitude'];
        final lon = packet['lon'] ?? packet['longitude'];
        
        if (lat != null && lon != null) {
          _updateUnitPosition(
            lat.toString(),
            lon.toString()
          );
        }
      } catch (e) {
        print("Error parsing socket data: $e");
      }
    });
  }

  void _stopSocketTracking() {
    _socketSubscription?.cancel();
    _socketService.disconnect();
  }

  void _updateUnitPosition(String lat, String lon) {
    if (_unit != null) {
      _unit = UnitData(
        economico: _unit!.economico,
        lat: lat,
        lon: lon,
        claveruta: _unit!.claveruta,
      );
      notifyListeners();
    }
  }

  Future<void> fetchLastPosition(String claveruta) async {
    try {
      print("DEBUG - fetchLastPosition for route: $claveruta");
      final responseBody = await _requestService.handlingRequest(
        urlParam: _urlService.getUrlInfoPositions(),
        params: {
          'claveruta': claveruta,
          'empresa': _session.companyClave ?? '',
        },
        method: 'GET',
      );

      if (responseBody != null) {
        print("DEBUG - Position API raw response: $responseBody");
        final List<dynamic> data = json.decode(responseBody);
        print("DEBUG - Position API parsed ${data.length} records");
        
        if (data.isNotEmpty) {
          final lastPos = data.first;
          print("DEBUG - Position record fields: ${lastPos.keys.toList()}");
          
          // Try different possible field names
          final lat = lastPos['latitud'] ?? lastPos['latitude'] ?? lastPos['lat'];
          final lon = lastPos['longitud'] ?? lastPos['longitude'] ?? lastPos['lon'];
          
          if (lat != null && lon != null) {
            _updateUnitPosition(lat.toString(), lon.toString());
            print("DEBUG - Last position updated: $lat, $lon");
          } else {
            print("WARNING - Position data has null coordinates. Record: $lastPos");
            _updateUnitPosition('null', 'null');
          }
        } else {
          print("WARNING - Position API returned empty array");
        }
      } else {
        print("WARNING - Position API returned null response");
      }
    } catch (e) {
      print("ERROR - fetchLastPosition: $e");
    }
  }

  Future<void> fetchStops(String claveruta) async {
    print("DEBUG - fetchStops called for: $claveruta");
    _isLoadingStops = true;
    notifyListeners();

    try {
      print("DEBUG - fetchStops - Making API request...");
      final response = await _requestService.handlingRequestParsed<ResponseInfoStops>(
        urlParam: _urlService.getUrlInfoStops(),
        params: {
          'claveruta': claveruta,
          'empresa': _session.companyClave ?? '',
        },
        method: 'POST',
        fromJson: (json) {
          print("DEBUG - fetchStops JSON: $json");
          return ResponseInfoStops.fromJson(json);
        },
      );

      if (response != null && (response.respuesta == 'existe' || response.respuesta == 'correcto')) {
        _stops = response.datos;
        // Sort stops by numero_parada to ensure tracking logic works
        _stops.sort((a, b) => a.numero_parada.compareTo(b.numero_parada));
        print("DEBUG - fetchStops SUCCESS: Loaded ${_stops.length} stops");
      } else {
        _stops = [];
        print("DEBUG - fetchStops FAILED: Response = ${response?.respuesta}");
      }
    } catch (e) {
      debugPrint('ERROR - fetchStops exception: $e');
      _stops = [];
    } finally {
      _isLoadingStops = false;
      notifyListeners();
      print("DEBUG - fetchStops completed. Total stops: ${_stops.length}");
      
      // Check for duplicate coordinates (database issue)
      _checkDuplicateCoordinates();
    }
  }

  /// Detect if all stops have the same coordinates (database issue)
  void _checkDuplicateCoordinates() {
    if (_stops.length < 2) return;
    
    final firstLat = _stops.first.latitud;
    final firstLon = _stops.first.longitud;
    
    final allSame = _stops.every((stop) => 
      stop.latitud == firstLat && stop.longitud == firstLon
    );
    
    if (allSame) {
      print(" WARNING - All ${_stops.length} stops have identical coordinates ($firstLat, $firstLon)");
      print(" This is a DATABASE ISSUE - coordinates need to be updated in the backend");
      print(" Route: ${_selectedRoute?.claveruta} - ${_selectedRoute?.nombre}");
    }
  }

  Future<void> fetchUnit(String claveruta) async {
    try {
      final response = await _requestService.handlingRequestParsed<ResponseInfoUnit>(
        urlParam: _urlService.getUrlInfoUnit(),
        params: {
          'claveruta': claveruta,
          'empresa': _session.companyClave ?? '',
        },
        method: 'POST',
        fromJson: (json) {
          print("DEBUG - fetchUnit JSON: $json");
          return ResponseInfoUnit.fromJson(json);
        },
      );

      if (response != null && 
          (response.respuesta == 'existe' || response.respuesta == 'correcto') && 
          response.datos.isNotEmpty) {
        _unit = response.datos.first;
      } else {
        _unit = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching unit: $e');
      _unit = null;
      notifyListeners();
    }
  }

  String getActiveDays(String turno) {
    final t = turno.toUpperCase();
    if (t.contains('L-V') || t.contains('LUN-VIE') || t.contains('LUNES A VIERNES')) return 'Lunes a Viernes';
    if (t.contains('SAB') || t.contains('SÁB') || t.contains('SABADO') || t.contains('SÁBADO')) return 'Sábados';
    if (t.contains('DOM') || t.contains('DOMINGO')) return 'Domingos';
    if (t.contains('DIARIO') || t.contains('TODOS') || t.isEmpty) return 'Todos los días';
    return 'Horario específico';
  }

  String getActiveDaysForRoute(RouteData route) {
    // Prefer dia_ruta field, fallback to tipo_ruta
    final dayInfo = route.dia_ruta ?? route.tipo_ruta;
    return getActiveDays(dayInfo);
  }

  bool isRouteActiveNow(RouteData route) => _isRouteInTime(route);

  @override
  void dispose() {
    _stopSocketTracking();
    super.dispose();
  }
}
