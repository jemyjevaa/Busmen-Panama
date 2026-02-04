import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  void login(VoidCallback onLoginSuccess) {
    final user = userController.text;
    final password = passwordController.text;
    
    // For now, meramente diseño as requested.
    debugPrint('Iniciando sesión con Usuario: $user');
    
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
