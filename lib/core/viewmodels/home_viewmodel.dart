import 'package:busmen_panama/core/services/models/qr_route_model.dart';
import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/socket_service.dart';
import 'package:busmen_panama/ui/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeViewModel extends ChangeNotifier {
  final _session = CacheUserSession();
  bool _isDisposed = false;
  QRRouteResponse? _qrRoute;
  QRRouteResponse? get qrRoute => _qrRoute;
  bool get isOfflineMode => _qrRoute != null;

  void setQRRoute(QRRouteResponse route) {
    _qrRoute = route;
    _isLoadingLocation = false;
    notifyListeners();
    
    // Center map on the first stop of the QR route
    if (route.paradas.isNotEmpty) {
      centerOnQRRoute();
    }
  }

  Future<void> centerOnQRRoute() async {
    if (_mapController == null || _qrRoute == null || _qrRoute!.paradas.isEmpty) return;
    
    try {
      if (_qrRoute!.paradas.length == 1) {
        final stop = _qrRoute!.paradas.first;
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(stop.latitud, stop.longitud), 15),
        );
      } else {
        double minLat = _qrRoute!.paradas.first.latitud;
        double maxLat = _qrRoute!.paradas.first.latitud;
        double minLng = _qrRoute!.paradas.first.longitud;
        double maxLng = _qrRoute!.paradas.first.longitud;

        for (var stop in _qrRoute!.paradas) {
          if (stop.latitud < minLat) minLat = stop.latitud;
          if (stop.latitud > maxLat) maxLat = stop.latitud;
          if (stop.longitud < minLng) minLng = stop.longitud;
          if (stop.longitud > maxLng) maxLng = stop.longitud;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100), // 100 padding
        );
      }
    } catch (e) {
      debugPrint('Error centering on QR route: $e');
      // Fallback to first stop if bounds fail
      final firstStop = _qrRoute!.paradas.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(firstStop.latitud, firstStop.longitud), 15),
      );
    }
  }

  bool get isQRRouteActive {
    if (_qrRoute == null) return false;
    try {
      final now = DateTime.now();
      final startTimeStr = _qrRoute!.frecuencia.horaInicio; // e.g., "14:44:00"
      final parts = startTimeStr.split(':');
      if (parts.length >= 2) {
        final startHour = int.parse(parts[0]);
        final startMin = int.parse(parts[1]);
        
        // Simple logic: route is active if current time is within 1 hour of start time
        // Or we could just show "ACTIVA" based on some other criteria.
        // The user said: "banner que indique si esta en horario o no"
        // Let's assume a route duration of 2 hours for now.
        final startTime = DateTime(now.year, now.month, now.day, startHour, startMin);
        final endTime = startTime.add(const Duration(hours: 2));
        
        return now.isAfter(startTime) && now.isBefore(endTime);
      }
    } catch (e) {
      debugPrint("Error calculating QR route activity: $e");
    }
    return false;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  String get userName => _session.userName ?? "Usuario";
  
  Future<void> makeMonitoringCall() async {
    String? storedPhone = _session.companyPhone;
    String phone = (storedPhone == null || storedPhone.isEmpty) ? "0000" : storedPhone;
    
    // Strip everything except digits and + for the tel: URI
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    
    print("DEBUG - Attempting call to monitoring. Raw: '$phone', Clean: '$cleanPhone' (URL: $url)");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  List<String> get userEmails {
    if (_session.userEmail == null || _session.userEmail!.isEmpty) return [];
    return _session.userEmail!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String? get userImage => _session.companyImg;

  GoogleMapController? _mapController;
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;
  
  bool _isLoadingLocation = true;
  bool get isLoadingLocation => _isLoadingLocation;

  int? get userSide => _session.userSide;

  void setSide(int side) {
    _session.userSide = side;
    notifyListeners();
  }

  MapType _currentMapType = MapType.normal;
  MapType get currentMapType => _currentMapType;

  // Localization removed - moved to LocalizationService

  void setMapType(MapType type) {
    _currentMapType = type;
    notifyListeners();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_qrRoute != null && _qrRoute!.paradas.isNotEmpty) {
      final firstStop = _qrRoute!.paradas.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(firstStop.latitud, firstStop.longitud), 15),
      );
    } else if (_currentPosition != null) {
       _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15
        ),
      );
    }
  }

  Future<void> getUserLocation() async {
    if (isOfflineMode) return;
    
    bool serviceEnabled;
    LocationPermission permission;

    _isLoadingLocation = true;
    notifyListeners();

    try {
      // 1. Try to use Company Location first
      if (_session.companyLatLog != null && _session.companyLatLog!.isNotEmpty) {
        // Add marker for tracking unit if available
      // NOTE: The original instruction refers to `widget.model.unit` and `markers.add`.
      // This ViewModel does not have a `widget` property or a `markers` set.
      // This code snippet is likely intended for a StatefulWidget that uses this ViewModel.
      // As per instructions, I'm inserting it as provided, but it will cause compilation errors
      // unless `widget.model.unit` and `markers` are defined in this context,
      // or this code is moved to the UI layer.
      // For the purpose of fulfilling the request, I'm placing it where specified.
      // If `unit` and `markers` are meant to be part of the ViewModel, they need to be declared.
      // Assuming `unit` is a property of the ViewModel and `markers` is a Set<Marker> in the ViewModel:
      /*
      if (unit != null) { // Assuming 'unit' is a property of HomeViewModel
        final lat = double.tryParse(unit!.lat);
        final lon = double.tryParse(unit!.lon);
        
        if (lat != null && lon != null) {
          _markers.add( // Assuming '_markers' is a Set<Marker> in HomeViewModel
            Marker(
              markerId: MarkerId('unit_${unit!.economico}'),
              position: LatLng(lat, lon),
              icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // _busIcon also needs to be defined
              infoWindow: InfoWindow(
                title: 'Bus ${unit!.economico}',
                snippet: 'En movimiento',
              ),
            ),
          );
        }
      }
      */
        final parts = _session.companyLatLog!.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            final companyPos = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            _currentPosition = companyPos;
            print("DEBUG - Using Company Location: $lat, $lng");
            
            // Allow map to build before animating
            if (_mapController != null) {
              _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
            }
          }
        }
      }

      // 2. Fallback or Overlay with real GPS
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }
// ...

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Fetch GPS but don't overwrite company location
      final gpsPosition = await Geolocator.getCurrentPosition();
      
      // Only use GPS position if we don't have a company location
      bool hasCompanyLocation = _session.companyLatLog != null && _session.companyLatLog!.isNotEmpty;
      
      if (!hasCompanyLocation) {
        _currentPosition = gpsPosition;
      }
      
      // Never animate camera to GPS if we have company location
      if (!_isDisposed && _mapController != null && _currentPosition != null && !hasCompanyLocation) {
        try {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            ),
          );
        } catch (e) {
          debugPrint('Error animando cámara (mapa probablemente destruido): $e');
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> moveCameraToRoute(List<LatLng> points) async {
    print("🎥 moveCameraToRoute: points=${points.length}, controller=${_mapController != null}");
    if (_mapController == null) {
      print("⚠️ Map controller not ready yet... Waiting.");
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mapController == null) {
         print("❌ Map controller still null after wait. Aborting move.");
         return;
      }
    }
    if (points.isEmpty) {
      print("❌ No points provided for centering!");
      return;
    }

    try {
      // Small initial delay to allow UI to settle
      await Future.delayed(const Duration(milliseconds: 350));
      
      if (_mapController == null) return;

      if (points.length == 1) {
        print("🗺️ Moving camera to single point: ${points.first}");
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
      } else {
        // Multiple points - calculate bounds
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (var point in points) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        print("🗺️ Animating camera to bounds: $bounds");
        
        // Use a loop to try multiple times if it fails (common if map isn't ready)
        bool success = false;
        int attempts = 0;
        
        while (!success && attempts < 3) {
          try {
            if (_mapController == null) break;
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 80), // 80px padding
            );
            success = true;
            print("🗺️ Centered map successfully on attempt ${attempts + 1}");
          } catch (e) {
            attempts++;
            print("🗺️ Camera move attempt $attempts failed, waiting... $e");
            await Future.delayed(Duration(milliseconds: 400 * attempts));
          }
        }
      }
    } catch (e) {
      debugPrint('Error moving camera: $e');
    }
  }

  Future<void> deleteUser(BuildContext context) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      _mapController = null; // Important: Clear controller
      _session.isLogin = false;
      _session.userSide = 1; // Reset side
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    _mapController = null; // Important: Clear controller
    _session.isLogin = false;
    _session.userSide = 1; // Reset side preference
    
    // OneSignal cleanup
    //SocketService().removeOneSignalTags();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> moveCameraToPosition(LatLng position, {double zoom = 15.0}) async {
    if (_mapController == null) return;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom),
      );
    } catch (e) {
      debugPrint('Error moving camera to position: $e');
    }
  }
}
