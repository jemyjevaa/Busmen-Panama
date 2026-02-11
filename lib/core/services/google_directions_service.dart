import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:busmen_panama/core/services/url_service.dart';

class GoogleDirectionsService {
  final UrlService _urlService = UrlService();
  final String _apiKey = "AIzaSyA6WSHJ8R0AMDhhk0e_-Sn0KLEwSB60QKw";

  Future<List<LatLng>> getRoutePolyline(List<LatLng> stops) async {
    if (stops.length < 2) return stops;

    List<LatLng> allPolylinePoints = [];
    const int maxWaypointsPerRequest = 20; // Using a safe limit for waypoints

    try {
      for (int i = 0; i < stops.length - 1; i += maxWaypointsPerRequest) {
        int end = (i + maxWaypointsPerRequest < stops.length) 
            ? i + maxWaypointsPerRequest 
            : stops.length - 1;
        
        // If we only have 1 point left, we can't make a segment
        if (i == end) break;

        final segmentPoints = await _fetchRouteSegment(stops.sublist(i, end + 1));
        allPolylinePoints.addAll(segmentPoints);
      }
      
      if (allPolylinePoints.isNotEmpty) {
        return allPolylinePoints;
      }
    } catch (e) {
      print("Error in GoogleDirectionsService (segmentation): $e");
    }
    
    return stops; // Fallback to straight lines
  }

  Future<List<LatLng>> _fetchRouteSegment(List<LatLng> segmentStops) async {
    if (segmentStops.length < 2) return segmentStops;

    final origin = "${segmentStops.first.latitude},${segmentStops.first.longitude}";
    final destination = "${segmentStops.last.latitude},${segmentStops.last.longitude}";
    
    String waypoints = "";
    if (segmentStops.length > 2) {
      waypoints = "&waypoints=" + segmentStops.getRange(1, segmentStops.length - 1)
          .map((p) => "${p.latitude},${p.longitude}")
          .join('|');
    }

    final url = "${_urlService.getUrlDirections()}?origin=$origin&destination=$destination$waypoints&key=$_apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final polylinePoints = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(polylinePoints);
      } else {
        print("Directions API Error (${data['status']}): ${data['error_message'] ?? 'No message'}");
      }
    }
    
    return segmentStops; // Fallback for this segment
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
