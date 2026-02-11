import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestService {

  String? _sessionCookie;

  // Singleton pattern
  RequestService._privateConstructor();
  static final RequestService instance = RequestService._privateConstructor();

  /// Initialize session cookie for tracking API authentication
  Future<bool> _initSessionCookie() async {
    try {
      //print("DEBUG - Initializing GPS session cookie...");
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we already have a valid cookie
      final existingCookie = prefs.getString('gps_session_cookie');
      if (existingCookie != null && existingCookie.isNotEmpty) {
        _sessionCookie = existingCookie;
        //print("DEBUG - Using existing GPS session cookie");
        return true;
      }

      // Get new session cookie using URLEncoded format (not JSON)
      final response = await http.post(
        Uri.parse('https://rastreobusmenpa.geovoy.com/api/session'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'email=usuariosapp&password=usuarios0904',
      );

      if (response.statusCode == 200) {
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          _sessionCookie = setCookie.split(';')[0]; // Extract cookie value (JSESSIONID=...)
          await prefs.setString('gps_session_cookie', _sessionCookie!);
          //print("DEBUG - GPS session cookie initialized: ${_sessionCookie!.substring(0, 20)}...");
          return true;
        }
      }
      
      // print("ERROR - Failed to get GPS session cookie: ${response.statusCode}");
      return false;
    } catch (e) {
      // print("ERROR - _initSessionCookie: $e");
      return false;
    }
  }

  Future<String?> handlingRequest({
    required String urlParam,
    Map<String, dynamic>? params,
    String method = "GET",
    bool asJson = false,
    Map<String, String>? customHeaders,
  }) async {
    try {
      // Decide base URL
      // bool isNormUrl = urlParam == urlValidateUser ||
      //     urlParam == urlGetRoute ||
      //     urlParam == urlStopInRoute ||
      //     urlParam == urlUnitAsiggned;

      //final base = baseUrlNor; //isNormUrl ? baseUrlNor : baseUrlAdm;
      String fullUrl = urlParam;

      // Check if this is a tracking API request that needs authentication
      final isTrackingApi = fullUrl.contains('rastreobusmenpa.geovoy.com');
      if (isTrackingApi && _sessionCookie == null) {
        await _initSessionCookie();
      }

      http.Response response;
      print("fullUrl => $fullUrl");
      print("params => $params");
      // Agregar parámetros para GET en query string
      if (method.toUpperCase() == 'GET' && params != null && params.isNotEmpty) {
        final uri = Uri.parse(fullUrl).replace(queryParameters: params);
        final headers = isTrackingApi && _sessionCookie != null 
            ? {'Cookie': _sessionCookie!}
            : <String, String>{};
        response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      } else {
        // Construir el body según asJson o form-url-encoded
        dynamic body;
        Map<String, String>? headers;

        if (params != null) {
          if (asJson) {
            body = jsonEncode(params);
            headers = {'Content-Type': 'application/json'};
          } else {
            body = params.map((k, v) => MapEntry(k, v.toString()));
            headers = {'Content-Type': 'application/x-www-form-urlencoded'};
          }
        }

        // Add session cookie for tracking API requests
        if (isTrackingApi && _sessionCookie != null) {
          headers = headers ?? {};
          headers['Cookie'] = _sessionCookie!;
        }

        if (customHeaders != null) {
          headers = headers ?? {};
          headers.addAll(customHeaders);
        }

        Uri uri = Uri.parse(fullUrl);

        switch (method.toUpperCase()) {
          case 'POST':
            response = await http
                .post(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PUT':
            response = await http
                .put(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PATCH':
            response = await http
                .patch(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'DELETE':
            response = await http
                .delete(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          default:
            throw UnsupportedError("HTTP method $method no soportado");
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        print("HTTP error: ${response.statusCode}");
        print("Error body: ${response.body}"); // Add this line
        return null;
      }
    } catch (e) {
      print("Error en handlingRequest: $e");
      return null;
    }
  }

  Future<T?> handlingRequestParsed<T>(
      {required String urlParam,
        Map<String, dynamic>? params,
        String method = "GET",
        bool asJson = false,
        Map<String, String>? customHeaders,
        required T Function(dynamic json) fromJson} ) async {
    final responseString = await handlingRequest(
        urlParam: urlParam, params: params, method: method, asJson: asJson, customHeaders: customHeaders);

    if (responseString == null) return null;

    try {
      final jsonMap = jsonDecode(responseString);
      return fromJson(jsonMap);
    } catch (e) {
      print("Error parseando JSON: $e");
      return null;
    }
  }

  /// Special function for Multipart requests (as required by iOS/Android logic for some endpoints)
  Future<String?> handlingMultipartRequest({
    required String urlParam,
    required Map<String, String> fields,
  }) async {
    try {
      // print("DEBUG - Multipart URL: $urlParam");
      // print("DEBUG - Multipart Fields: $fields");

      var request = http.MultipartRequest('POST', Uri.parse(urlParam));
      request.fields.addAll(fields);

      var streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        print("Multipart error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error in handlingMultipartRequest: $e");
      return null;
    }
  }
}
