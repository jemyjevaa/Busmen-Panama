import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/ui/widgets/status_dialog.dart';
import 'package:busmen_panama/core/services/models/general_options_response.dart';

class PasswordViewModel extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  final RequestService _requestService = RequestService.instance;
  final UrlService _urlService = UrlService();
  final CacheUserSession _session = CacheUserSession();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _obscureText = true;
  bool get obscureText => _obscureText;

  String get currentUser => _session.loginUser ?? _session.userEmail ?? '...';

  void toggleVisibility() {
    _obscureText = !_obscureText;
    notifyListeners();
  }

  Future<void> changePassword(BuildContext context) async {
    final localization = Provider.of<LanguageService>(context, listen: false);
    final password = newPasswordController.text.trim();
    
    if (password.isEmpty) {
      _showStatusDialog(context, localization.getString('enter_new_password'), isError: true);
      return;
    }

    // Capture values before async to avoid context issues
    final email = _session.userEmail;
    final company = _session.companyClave;
    final loginUser = _session.loginUser;
    
    // The identifier used for the API call
    final userIdentifier = loginUser ?? email;

    if (userIdentifier == null || userIdentifier.isEmpty) {
      _showStatusDialog(context, localization.getString('error_user'), isError: true);
      return;
    }

    if (company == null || company.isEmpty) {
      _showStatusDialog(context, 'Error: No company code found.', isError: true);
      return;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      print("DEBUG - Attempting password change for identifier: $userIdentifier (Email: $email)");
      final success = await _changePasswordHandler(password, userIdentifier, company);
      
      _isSubmitting = false;
      notifyListeners();

      if (success) {
        // PERMANENT STORAGE: Update local password to keep auto-login working
        _session.userPassword = password;
        
        if (context.mounted) {
          StatusDialog.show(
            context,
            title: '¡Hecho!',
            message: localization.getString('password_updated'),
            type: StatusType.success,
            onDismiss: () => Navigator.pop(context), 
          );
        }
      } else {
        if (context.mounted) {
          _showStatusDialog(context, localization.getString('error_changing_password'), isError: true);
        }
      }
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      print("ERROR - Exception during changePassword: $e");
      if (context.mounted) {
        _showStatusDialog(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<bool> _changePasswordHandler(String newPassword, String userIdentifier, String company) async {
    final url = _urlService.getUrlChangePassword();

    final params = {
      'usuario': userIdentifier,
      'passwordnuevo': newPassword,
      'clave': newPassword, 
      'empresa': company,
    };

    final customHeaders = {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };

    print("DEBUG - POST to $url with params: $params");

    final responseBody = await _requestService.handlingRequest(
      urlParam: url,
      params: params,
      method: 'POST',
      asJson: false, 
      customHeaders: customHeaders,
    );

    if (responseBody == null) {
      print("ERROR - Response body is null (Request failed)");
      return false;
    }

    print("DEBUG - Raw Response: $responseBody");

    try {
      final decoded = jsonDecode(responseBody);
      final response = GeneralOptionsResponse.fromJson(decoded);
      final isCorrect = response.respuesta.toLowerCase() == 'correcto';
      print("DEBUG - Parsed response: ${response.respuesta} -> isCorrect: $isCorrect");
      return isCorrect;
    } catch (e) {
      print("DEBUG - JSON parsing failed for password change, checking raw body contents...");
      final containsCorrecto = responseBody.toLowerCase().contains('correcto');
      print("DEBUG - Raw body contains 'correcto': $containsCorrecto");
      return containsCorrecto;
    }
  }

  void _showStatusDialog(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    
    StatusDialog.show(
      context,
      title: isError ? 'Ups...' : '¡Hecho!',
      message: message,
      type: isError ? StatusType.error : StatusType.success,
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    super.dispose();
  }
}
