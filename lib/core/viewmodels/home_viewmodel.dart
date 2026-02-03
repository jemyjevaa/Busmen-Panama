import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeViewModel extends ChangeNotifier {
  GoogleMapController? _mapController;
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;
  
  bool _isLoadingLocation = true;
  bool get isLoadingLocation => _isLoadingLocation;

  MapType _currentMapType = MapType.normal;
  MapType get currentMapType => _currentMapType;

  // Localization
  String _currentLanguage = 'ES';
  String get currentLanguage => _currentLanguage;

  final Map<String, Map<String, String>> _localizedValues = {
    'ES': {
      // Drawer
      'driver_role': 'Conductor',
      'profile': 'Perfil',
      'schedules': 'Horarios',
      'monitoring_center': 'Centro de Monitoreo',
      'lost_found': 'Objetos Perdidos',
      'password': 'Contraseña',
      'information': 'Información',
      'announcements': 'Comunicados',
      'regulations': 'Reglamentación',
      'manual': 'Manual',
      'logout': 'Cerrar Sesión',
      
      // Map
      'normal': 'Normal',
      'satellite': 'Satelital',
      'hybrid': 'Híbrido',
      
      // Bottom UI
      'route_not_selected': 'Ruta no seleccionada',
      'select_route': 'SELECCIONAR RUTA',
    },
    'EN': {
      // Drawer
      'driver_role': 'Driver',
      'profile': 'Profile',
      'schedules': 'Schedules',
      'monitoring_center': 'Monitoring Center',
      'lost_found': 'Lost & Found',
      'password': 'Password',
      'information': 'Information',
      'announcements': 'Announcements',
      'regulations': 'Regulations',
      'manual': 'Manual',
      'logout': 'Log Out',
      
      // Map
      'normal': 'Normal',
      'satellite': 'Satellite',
      'hybrid': 'Hybrid',
      
      // Bottom UI
      'route_not_selected': 'Route not selected',
      'select_route': 'SELECT ROUTE',
    },
  };

  String getString(String key) => _localizedValues[_currentLanguage]?[key] ?? key;

  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  void setMapType(MapType type) {
    _currentMapType = type;
    notifyListeners();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    _isLoadingLocation = true;
    notifyListeners();

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

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

      _currentPosition = await Geolocator.getCurrentPosition();
      
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
