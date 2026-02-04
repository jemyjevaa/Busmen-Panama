import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  int _identifiedCompany = 0; // 0: None, 1: Empresa 1, 2: Empresa 2
  int get identifiedCompany => _identifiedCompany;

  LoginViewModel() {
    // Keep listener as backup, but we'll use direct calls for better reliability
    userController.addListener(_onUserChanged);
  }

  void identifyCompany(String val) {
    final trimmed = val.trim();
    int newCompany = 0;

    if (trimmed == '1') {
      newCompany = 1;
    } else if (trimmed == '2') {
      newCompany = 2;
    } else if (trimmed.contains('@')) {
      newCompany = 2;
    }

    if (newCompany != _identifiedCompany) {
      _identifiedCompany = newCompany;
      notifyListeners();
      debugPrint('Compañía identificada: $_identifiedCompany');
    }
  }

  void _onUserChanged() => identifyCompany(userController.text);

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  void login(void Function(int side) onLoginSuccess, BuildContext context) {
    final password = passwordController.text;
    
    // Validate based on company/side
    bool isValid = false;
    if (_identifiedCompany == 1 && password == '1') {
      isValid = true;
    } else if (_identifiedCompany == 2 && (password == '2' || password.isNotEmpty && !_identifiedCompanyIsExplicit)) {
      // In empresa 2, if it's explicitly '2' or for the general email flow we'll allow any non-empty for now
      isValid = true;
    }

    // Explicit check for the user's specific mock case:
    if (_identifiedCompany == 1 && password != '1') isValid = false;
    if (_identifiedCompany == 2 && password != '2' && userController.text == '2') isValid = false;

    if (isValid) {
      debugPrint('Iniciando sesión con Usuario: ${userController.text} para el Lado: $_identifiedCompany');
      onLoginSuccess(_identifiedCompany);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña incorrecta para esta empresa. Use "1" para Side 1 o "2" para Side 2.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _identifiedCompanyIsExplicit => userController.text == '1' || userController.text == '2';

  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController recoveryUserController = TextEditingController();
  final TextEditingController recoveryEmailController = TextEditingController();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  void registerUser(BuildContext context) async {
    if (registerNameController.text.isEmpty || registerEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos')));
      return;
    }
    
    _isProcessing = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario registrado correctamente')));
      registerNameController.clear();
      registerEmailController.clear();
    }
  }

  void recoverPassword(BuildContext context) async {
    if (recoveryUserController.text.isEmpty || recoveryEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos')));
      return;
    }

    _isProcessing = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo de recuperación enviado')));
      recoveryUserController.clear();
      recoveryEmailController.clear();
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    recoveryUserController.dispose();
    recoveryEmailController.dispose();
    super.dispose();
  }
}
