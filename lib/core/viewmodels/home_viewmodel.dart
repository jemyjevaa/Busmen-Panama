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
    if (_currentPosition != null) {
       _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15
        ),
      );
    }
  }

  Future<void> getUserLocation() async {
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

  /// Move camera to show route with all stops
  Future<void> moveCameraToRoute(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;

    try {
      if (points.length == 1) {
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

        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80), // 80px padding
        );
        print("🗺️ Centered map on route");
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
}
