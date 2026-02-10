import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:busmen_panama/core/services/url_service.dart';

class GoogleDirectionsService {
  final UrlService _urlService = UrlService();
  final String _apiKey = "AIzaSyA6WSHJ8R0AMDhhk0e_-Sn0KLEwSB60QKw";

  Future<List<LatLng>> getRoutePolyline(List<LatLng> stops) async {
    if (stops.length < 2) return stops;

    final origin = "${stops.first.latitude},${stops.first.longitude}";
    final destination = "${stops.last.latitude},${stops.last.longitude}";
    
    // Add intermediate stops as waypoints
    String waypoints = "";
    if (stops.length > 2) {
      waypoints = "&waypoints=" + stops.getRange(1, stops.length - 1)
          .map((p) => "${p.latitude},${p.longitude}")
          .join('|');
    }

    final url = "${_urlService.getUrlDirections()}?origin=$origin&destination=$destination$waypoints&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final polylinePoints = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(polylinePoints);
        }
      }
    } catch (e) {
      print("Error in GoogleDirectionsService: $e");
    }
    
    return stops; // Fallback to straight lines
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
