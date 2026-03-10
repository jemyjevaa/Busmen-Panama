import 'dart:async';
import 'package:flutter/material.dart';

class SimulationService extends ChangeNotifier {
  String? _lastArrivalMessage;
  String? get lastArrivalMessage => _lastArrivalMessage;

  // Simulate position flow
  final _positionController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get positionStream => _positionController.stream;

  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  void notifyArrival(String stopName, {String? nextStopName}) {
    if (nextStopName != null) {
      _lastArrivalMessage = "¡En: $stopName! → Próxima: $nextStopName";
    } else {
      _lastArrivalMessage = "¡En: $stopName! (Final de ruta)";
    }
    notifyListeners();
    
    // Auto-clear after 8 seconds
    Timer(const Duration(seconds: 8), () {
      _lastArrivalMessage = null;
      notifyListeners();
    });
  }

  void broadcastPosition(double lat, double lon) {
    _positionController.add({'lat': lat, 'lon': lon});
  }

  void clearMessage() {
    _lastArrivalMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionController.close();
    super.dispose();
  }
}
