import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/models/info_schedules_model.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:busmen_panama/core/services/google_directions_service.dart';
import 'package:busmen_panama/core/services/socket_service.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/core/services/simulation_service.dart';
import 'dart:async';
import 'dart:convert';

class SchedulesViewModel extends ChangeNotifier {
  final _session = CacheUserSession();
  final _urlService = UrlService();
  final _requestService = RequestService.instance;
  final _directionsService = GoogleDirectionsService();
  final _socketService = SocketService();
  StreamSubscription? _socketSubscription;
  StreamSubscription? _simSubscription;

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

  String _filterOption = 'filter_all';
  String get filterOption => _filterOption;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setFilterOption(String option) {
    // Normalize option to handle different formats (e.g., 'FRECUENTES' -> 'filter_frequent')
    final normalized = option.toLowerCase();
    if (normalized.contains('favorite') || normalized.contains('favorita')) {
      _filterOption = 'filter_favorite';
    } else if (normalized.contains('frequent') || normalized.contains('frecuentes')) {
      _filterOption = 'filter_frequent';
    } else if (normalized.contains('time') || normalized.contains('tiempo')) {
      _filterOption = 'filter_on_time';
    } else {
      _filterOption = 'filter_all';
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
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
    if (_unit == null || _stops.isEmpty) return 'status_pending';
    
    final stopIndex = _stops.indexOf(stop);
    
    // If route finished or bus already passed this stop based on index
    if (stopIndex < _currentUnitStopIndex) return 'status_completed';

    final unitLat = double.tryParse(_unit!.lat) ?? 0.0;
    final unitLon = double.tryParse(_unit!.lon) ?? 0.0;
    final distance = Geolocator.distanceBetween(unitLat, unitLon, stop.latitud, stop.longitud);
    
    // Physically at the stop
    if (distance < 80) return 'status_at_stop';

    // If it's the current "anchor" stop but unit moved away
    if (stopIndex == _currentUnitStopIndex) return 'status_completed';

    // If it's the next one
    if (stopIndex == _currentUnitStopIndex + 1) return 'status_in_transit';
    
    return 'status_pending';
  }

  bool get isRouteFinished {
    if (_unit == null || _stops.isEmpty || _currentUnitStopIndex < 0) return false;
    // Route is finished if we reached the last stop
    return _currentUnitStopIndex >= _stops.length - 1;
  }

  String getTrackingBannerText(LanguageService localization) {
    if (isRouteFinished) return localization.getString('status_route_finished');
    
    final current = getCurrentStop();
    final next = getNextStop();
    
    if (current != null) {
      final unitLat = double.tryParse(_unit!.lat) ?? 0.0;
      final unitLon = double.tryParse(_unit!.lon) ?? 0.0;
      final distance = Geolocator.distanceBetween(unitLat, unitLon, current.latitud, current.longitud);
      
      if (distance < 70) {
        return "${localization.getString('current_stop_label')}: ${current.nombre_parada}";
      }
    }
    
    if (next != null) {
      return "${localization.getString('next_stop_label')}: ${next.nombre_parada}";
    }
    
    return localization.getString('live_tracking');
  }

  void _updateTrackingIndex(double unitLat, double unitLon) {
    if (_stops.isEmpty) return;

    // 1. INITIAL SNAP (On entering): 
    // Mark all stops the bus ALREADY PASSED.
    if (_currentUnitStopIndex == -1) {
      int lastPassedIndex = -1;
      
      // Look for the last stop the bus approached or passed
      // Use historical proximity logic
      for (int i = 0; i < _stops.length; i++) {
        final d = Geolocator.distanceBetween(unitLat, unitLon, _stops[i].latitud, _stops[i].longitud);
        
        // If bus is within 150m of a stop, mark it as passed/reached
        if (d < 150) {
          lastPassedIndex = i;
        } 
      }

      if (lastPassedIndex != -1) {
        _currentUnitStopIndex = lastPassedIndex;
        final stopName = _stops[lastPassedIndex].nombre_parada;
        final nextStopName = (lastPassedIndex + 1 < _stops.length) ? _stops[lastPassedIndex + 1].nombre_parada : null;
        
        print("⚡ Initial Snap: Bus already passed up to stop index $lastPassedIndex ($stopName)");
        
        // Trigger banner on initial snap too
        SimulationService().notifyArrival(stopName, nextStopName: nextStopName);
        
        notifyListeners();
      }
      return;
    }

    // 2. REAL-TIME TRACKING:
    // Only advance if bus touches a stop AFTER the current anchor.
    int nextFoundIndex = -1;
    for (int i = _currentUnitStopIndex + 1; i < _stops.length; i++) {
      final d = Geolocator.distanceBetween(unitLat, unitLon, _stops[i].latitud, _stops[i].longitud);
      if (d < 130) { // Detection threshold
        nextFoundIndex = i;
      }
    }

    if (nextFoundIndex != -1) {
      _currentUnitStopIndex = nextFoundIndex;
      final stopName = _stops[nextFoundIndex].nombre_parada;
      final nextStopName = (nextFoundIndex + 1 < _stops.length) ? _stops[nextFoundIndex + 1].nombre_parada : null;
      
      print("🚌 Bus advanced to stop: $stopName");
      
      // TRIGGER BANNER NOTIFICATION
      SimulationService().notifyArrival(stopName, nextStopName: nextStopName);
      
      notifyListeners();
    }
  }

  List<RouteData> _recentRoutes = [];
  List<RouteData> get recentRoutes => _recentRoutes;

  List<String> _favoriteRouteClaves = [];
  List<String> get favoriteRouteClaves => _favoriteRouteClaves;

  bool isFavorite(String claveruta) => _favoriteRouteClaves.contains(claveruta);

  void toggleFavorite(RouteData route) {
    if (isFavorite(route.claveruta)) {
      _favoriteRouteClaves.remove(route.claveruta);
    } else {
      _favoriteRouteClaves.add(route.claveruta);
    }
    _session.favoriteRoutes = _favoriteRouteClaves;
    notifyListeners();
  }

  // Group routes by name
  Map<String, List<RouteData>> get groupedRoutes {
    Map<String, List<RouteData>> groups = {};
    
    // Apply search filter to grouped routes
    final visibleRoutes = _searchQuery.isEmpty 
        ? _routes 
        : _routes.where((r) => r.nombre.toLowerCase().contains(_searchQuery) || 
                              r.claveruta.toLowerCase().contains(_searchQuery)).toList();

    for (var route in visibleRoutes) {
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
    List<RouteData> baseRoutes;
    switch (_filterOption) {
      case 'filter_favorite':
        baseRoutes = _routes.where((r) => isFavorite(r.claveruta)).toList();
        break;
      case 'filter_frequent':
        baseRoutes = recentRoutes;
        break;
      case 'filter_on_time':
        baseRoutes = _routes.where(_isRouteInTime).toList();
        break;
      case 'filter_all':
      default:
        baseRoutes = _routes;
        break;
    }

    if (_searchQuery.isEmpty) return baseRoutes;

    return baseRoutes.where((r) => 
      r.nombre.toLowerCase().contains(_searchQuery) || 
      r.claveruta.toLowerCase().contains(_searchQuery)
    ).toList();
  }

  bool _isRouteInTime(RouteData route) {
    // 0. Use specialized logic for Copaair/Grainger
    if (CacheUserSession().isCopaair) {
      return _isRouteOnTimeCopaGrainger(route);
    }

    try {
      final now = DateTime.now();
      final String turno = route.tipo_ruta.toUpperCase();
      final String diaRuta = (route.dia_ruta ?? '').toUpperCase();

      // 1. Check Day
      bool dayMatch = false;
      int weekday = now.weekday;

      final daySource = diaRuta.isNotEmpty ? diaRuta : turno;

      if (daySource.contains('DIARIO') ||
          daySource.contains('TODOS') ||
          daySource.contains('LUN-DOM') ||
          daySource.isEmpty) {
        dayMatch = true;
      } else if (daySource.contains('L-V') ||
          daySource.contains('LUN-VIE') ||
          daySource.contains('LUNES A VIERNES')) {
        dayMatch = (weekday >= 1 && weekday <= 5);
      } else if (daySource.contains('SAB') ||
          daySource.contains('SÁB') ||
          daySource.contains('SABADO') ||
          daySource.contains('SÁBADO')) {
        dayMatch = (weekday == 6);
      } else if (daySource.contains('DOM') || daySource.contains('DOMINGO')) {
        dayMatch = (weekday == 7);
      } else {
        print(
            "DEBUG - Unknown day format for route ${route.claveruta}: dia_ruta='$diaRuta', tipo_ruta='$turno'");
        dayMatch = false;
      }

      if (!dayMatch) {
        print(
            "DEBUG - Route ${route.claveruta} filtered out: today=$weekday, dia_ruta='$diaRuta'");
        return false;
      }

      // 2. Check Time (same logic as Kotlin)

      print("turno => ${route.tipo_ruta}");

      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(turno);

      if (timeMatch == null) {
        print("DEBUG - No time found in tipo_ruta for route ${route.claveruta}");
        return false;
      }

      int routeHour = int.parse(timeMatch.group(1)!);

      final nowHour = now.hour;
      final nextHour = now.add(const Duration(hours: 1)).hour;

      final routeHourStr = routeHour.toString().padLeft(2, '0');
      final nowHourStr = nowHour.toString().padLeft(2, '0');
      final nextHourStr = nextHour.toString().padLeft(2, '0');

      print("DEBUG - Route hour: $routeHourStr");
      print("DEBUG - Now hour: $nowHourStr");
      print("DEBUG - Next hour: $nextHourStr");

      bool isInTimeWindow =
          routeHourStr.compareTo(nowHourStr) >= 0 &&
              routeHourStr.compareTo(nextHourStr) < 0;

      if (!isInTimeWindow) {
        print(
            "DEBUG - Route ${route.claveruta} filtered out by hour window");
      }

      return isInTimeWindow;
    } catch (e) {
      debugPrint("Error in _isRouteInTime: $e");
      return false;
    }
  }

  /// Specialized filtering logic for Copaair and Grainger accounts.
  /// Follows the Swift implementation provided by the user.
  bool _isRouteOnTimeCopaGrainger(RouteData route) {
    try {
      final now = DateTime.now();

      // 1. Time Validation (HH:mm:ss comparison)
      if (route.hora_inicio == null || route.hora_fin == null) return false;

      final String currentTimeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final String start = route.hora_inicio!.trim();
      final String end = route.hora_fin!.trim();

      // Basic string comparison works for HH:mm:ss if correctly padded
      bool timeMatch =
          currentTimeStr.compareTo(start) >= 0 && currentTimeStr.compareTo(end) <= 0;

      if (!timeMatch) {
        print("DEBUG - Route ${route.claveruta} filtered out by time: $currentTimeStr not in [$start, $end]");
        return false;
      }

      // 2. Day Validation (Normalization and Range support)
      String dayFilter = (route.dia_ruta ?? '').toUpperCase().trim();
      // Remove diacritics / normalize
      dayFilter = dayFilter.replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U');
      dayFilter = dayFilter.replaceAll('MIE', 'MIE'); // Standardize Wed

      if (dayFilter.isEmpty) return true; // Follow current pattern if empty

      final List<String> allDays = ["LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"];
      final String currentDay = allDays[now.weekday - 1]; // Mon=1, Sun=7

      if (dayFilter.contains("-")) {
        final List<String> range = dayFilter.split("-").map((d) => d.trim()).toList();
        if (range.length == 2) {
          int startDayIdx = allDays.indexOf(range[0]);
          int endDayIdx = allDays.indexOf(range[1]);
          int todayIdx = allDays.indexOf(currentDay);

          if (startDayIdx != -1 && endDayIdx != -1 && todayIdx != -1) {
            if (startDayIdx <= endDayIdx) {
              return todayIdx >= startDayIdx && todayIdx <= endDayIdx;
            } else {
              // Wrap around (e.g., SAB-MAR means SAB, DOM, LUN, MAR)
              return todayIdx >= startDayIdx || todayIdx <= endDayIdx;
            }
          }
        }
      } else {
        return dayFilter == currentDay;
      }

      return false;
    } catch (e) {
      debugPrint("Error in _isRouteOnTimeCopaGrainger: $e");
      return false;
    }
  }

  bool _isLoadingRoutes = false;
  bool get isLoadingRoutes => _isLoadingRoutes;

  bool _isLoadingStops = false;
  bool get isLoadingStops => _isLoadingStops;

  SchedulesViewModel() {
    print("DEBUG - SchedulesViewModel constructor called");
    _favoriteRouteClaves = _session.favoriteRoutes;
    fetchRoutes();
    
    // Listen to simulation position broadcasts
    _simSubscription = SimulationService().positionStream.listen((pos) {
       if (selectedRoute != null && selectedRoute!.claveruta == 'SIM_PACORA') {
         _updateUnitPosition(pos['lat'].toString(), pos['lon'].toString(), economico: "SIM-01");
       }
    });
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
          'tipo_ruta': 'EXT',
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
        urlParam: _urlService.getUrlAnnouncements(),
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
    
    // Initial tracking update
    if (_unit != null && _stops.isNotEmpty) {
      final unitLat = double.tryParse(_unit!.lat) ?? 0.0;
      final unitLon = double.tryParse(_unit!.lon) ?? 0.0;
      _updateTrackingIndex(unitLat, unitLon);
    }
    
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
      
      
      try {
        print("DEBUG - Starting socket tracking...");
        _startSocketTracking();
      } catch (e) {
        print("ERROR - Failed to start socket tracking (non-critical): $e");
      }
      
      print("DEBUG - selectRoute completed. Notifying listeners...");
      notifyListeners();
      
      // Call the callback after everything is loaded
      if (onRouteLoaded != null) {
        print("📍 Centering map on route with ${_stops.length} stops");
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
      print("🔗 Tracking unit ${_unit!.economico} (deviceId: ${_unit!.idplataformagps})");
      _socketService.setDeviceIds([_unit!.idplataformagps!]);
    } else {
      print("⚠️  No device ID available for tracking");
    }
    
    await _socketService.connect();
    
    _socketSubscription = _socketService.positionStream?.listen((packet) {
      try {
        final lat = packet['lat'] ?? packet['latitude'] ?? packet['latitud'];
        final lon = packet['lon'] ?? packet['longitude'] ?? packet['longitud'];
        final deviceId = packet['deviceId'];
        
        // CRITICAL: Only update if this packet is for OUR unit
        if (_unit != null && _unit!.idplataformagps != null) {
          final unitDeviceId = int.tryParse(_unit!.idplataformagps!);
          final packetDeviceId = deviceId is int ? deviceId : int.tryParse(deviceId?.toString() ?? '');
          
          if (packetDeviceId != unitDeviceId) {
            // This position is for a different bus, ignore it
            return;
          }
        }
        
        if (lat != null && lon != null) {
          final double latVal = double.tryParse(lat.toString()) ?? 0.0;
          final double lonVal = double.tryParse(lon.toString()) ?? 0.0;
          
          _updateUnitPosition(lat.toString(), lon.toString());
          
          // Trigger tracking update
          _updateTrackingIndex(latVal, lonVal);
        }
      } catch (e) {
        print("❌ Socket error: $e");
      }
    });
  }

  void _stopSocketTracking() {
    _socketSubscription?.cancel();
    _socketService.disconnect();
  }

  void _updateUnitPosition(String lat, String lon, {String? economico}) {
    if (_unit != null || economico != null) {
      final String finalEconomico = economico ?? _unit?.economico ?? '---';
      final double newLat = double.tryParse(lat) ?? 0.0;
      final double newLon = double.tryParse(lon) ?? 0.0;
      
      double newHeading = _unit?.heading ?? 0.0;
      
      // Calculate bearing if we have a previous valid position
      if (_unit != null) {
         final double oldLat = double.tryParse(_unit!.lat) ?? 0.0;
         final double oldLon = double.tryParse(_unit!.lon) ?? 0.0;
         
         if (oldLat != 0.0 && oldLon != 0.0 && newLat != 0.0 && newLon != 0.0) {
            final double distance = Geolocator.distanceBetween(oldLat, oldLon, newLat, newLon);
            
            // Only update heading if moved more than 2 meters to avoid jitter
            if (distance > 2.0) {
               double bearing = Geolocator.bearingBetween(oldLat, oldLon, newLat, newLon);
               newHeading = (bearing + 360) % 360; // Normalize
            }
         }
      }

      print("🚌 $finalEconomico: $lat, $lon | Heading: $newHeading");
      _unit = UnitData(
        economico: finalEconomico,
        lat: lat,
        lon: lon,
        claveruta: _selectedRoute?.claveruta ?? _unit?.claveruta ?? '',
        idplataformagps: _unit?.idplataformagps ?? '',
        heading: newHeading, // Store calculated heading
      );

      // Trigger tracking update on static position set
      _updateTrackingIndex(newLat, newLon);

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
          final economico = lastPos['economico']?.toString() ?? lastPos['unit']?.toString();
          final double latVal = double.tryParse(lat.toString()) ?? 0.0;
          final double lonVal = double.tryParse(lon.toString()) ?? 0.0;
          
          _updateUnitPosition(lat.toString(), lon.toString(), economico: economico);
          
          // Trigger tracking update on last position fetch
          _updateTrackingIndex(latVal, lonVal);
          
          print("DEBUG - Last position updated: $lat, $lon (Unit: $economico)");
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

      if (claveruta == 'SIM_PACORA') {
        // Mock stops for Pacora with pseudo-coordinates for simulation
        _stops = [
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'C.C. La Doña (Inicio)', horario: '06:00', estatus: 'A tiempo', hora_parada: '06:00', latitud: 9.071852, longitud: -79.370503, numero_parada: 1),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Megamall', horario: '06:15', estatus: 'A tiempo', hora_parada: '06:15', latitud: 9.068222, longitud: -79.385202, numero_parada: 2),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Plaza Tocumen', horario: '06:30', estatus: 'A tiempo', hora_parada: '06:30', latitud: 9.055877, longitud: -79.431252, numero_parada: 3),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Metro Mall', horario: '06:45', estatus: 'A tiempo', hora_parada: '06:45', latitud: 9.050519, longitud: -79.453303, numero_parada: 4),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Plaza Carolina', horario: '07:00', estatus: 'A tiempo', hora_parada: '07:00', latitud: 9.020583, longitud: -79.489370, numero_parada: 5),
          StopData(claveruta: 'SIM_PACORA', nombre_parada: 'Vía España (Final)', horario: '07:15', estatus: 'A tiempo', hora_parada: '07:15', latitud: 8.986617, longitud: -79.529844, numero_parada: 6),
        ];
      } else if (response != null && (response.respuesta == 'existe' || response.respuesta == 'correcto')) {
      // Filter unique stops by numero_parada to avoid duplication if API returns same stops multiple times
      final Map<int, StopData> uniqueStopsMap = {};
      for (var stop in response.datos) {
        if (!uniqueStopsMap.containsKey(stop.numero_parada)) {
          uniqueStopsMap[stop.numero_parada] = stop;
        }
      }
      
      _stops = uniqueStopsMap.values.toList();
      // Sort stops by numero_parada to ensure tracking logic works
      _stops.sort((a, b) => a.numero_parada.compareTo(b.numero_parada));
      print("DEBUG - fetchStops SUCCESS: Loaded ${_stops.length} stops (filtered from ${response.datos.length})");
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
    if (t.contains('DIARIO') || t.contains('TODOS') || t.contains('LUN-DOM') || t.isEmpty) return 'every_day';
    if (t.contains('L-V') || t.contains('LUN-VIE') || t.contains('LUNES A VIERNES')) return 'monday_friday';
    if (t.contains('SAB') || t.contains('SÁB') || t.contains('SABADO') || t.contains('SÁBADO')) return 'saturdays';
    if (t.contains('DOM') || t.contains('DOMINGO')) return 'sunday';
    return 'specific_schedule';
  }

  String getActiveDaysForRoute(RouteData route) {
    // Prefer dia_ruta field, fallback to tipo_ruta
    final dayInfo = route.dia_ruta ?? route.tipo_ruta;
    return getActiveDays(dayInfo);
  }

  /// Returns formatted time for TRANSPORTEPP domain only:
  /// - ENTRADA → hora_fin
  /// - SALIDA  → tipo_ruta (turno) + 10 min
  /// Returns null for all other companies (caller should fall back to localized tipo_ruta).
  String? formatRouteTime(RouteData route) {
    // Only apply custom logic for transportepp domain
    final clave = (_session.companyClave ?? '').toLowerCase();
    if (!clave.contains('transportepp')) return null;

    final tramo = route.tramo.toUpperCase();

    // ENTRADA: show the end time (hora_fin)
    if (tramo.contains('ENTRADA')) {
      final fin = route.hora_fin;
      if (fin != null && fin.isNotEmpty) return fin;
    }

    // SALIDA (or fallback): show turno time + 10 minutes
    final turno = route.tipo_ruta;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(turno);
    if (match != null) {
      int h = int.parse(match.group(1)!);
      int m = int.parse(match.group(2)!);
      final total = m + 10;
      h = h + total ~/ 60;
      m = total % 60;
      h = h % 24;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    return route.tipo_ruta;
  }

  bool isRouteActiveNow(RouteData route) => _isRouteInTime(route);

  void reset() {
    _stopSocketTracking();
    _roadPoints = [];
    _routes = [];
    _stops = [];
    _unit = null;
    _selectedRoute = null;
    _filterOption = 'filter_all';
    _searchQuery = '';
    _bulletins = [];
    _regulations = [];
    _manuals = [];
    _isLoadingFlyers = false;
    _selectedUserStop = null;
    _currentUnitStopIndex = -1;
    _showFilteredStops = false;
    _recentRoutes = [];
    _isLoadingRoutes = false;
    _isLoadingStops = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _simSubscription?.cancel();
    _stopSocketTracking();
    super.dispose();
  }
}
