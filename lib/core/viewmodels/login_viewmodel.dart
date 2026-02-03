import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  String _currentLanguage = 'ES';
  String get currentLanguage => _currentLanguage;

  final Map<String, Map<String, String>> _localizedValues = {
    'ES': {
      'user_label': 'USUARIO',
      'pass_label': 'CONTRASEÑA',
      'remember_me': 'Mantener sesión iniciada',
      'login_btn': 'INICIAR SESION',
    },
    'EN': {
      'user_label': 'USERNAME',
      'pass_label': 'PASSWORD',
      'remember_me': 'Stay logged in',
      'login_btn': 'LOG IN',
    },
  };

  String getString(String key) => _localizedValues[_currentLanguage]?[key] ?? key;

  void toggleRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == 'ES' ? 'EN' : 'ES';
    notifyListeners();
  }

  void login(VoidCallback onLoginSuccess) {
    final user = userController.text;
    final password = passwordController.text;
    
    // For now, meramente diseño as requested.
    debugPrint('Iniciando sesión con Usuario: $user, Idioma: $_currentLanguage');
    
    // Simulate successful login and navigate
    onLoginSuccess();
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
