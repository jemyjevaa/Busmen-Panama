import 'package:flutter/material.dart';

class PasswordViewModel extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _obscureText = true;
  bool get obscureText => _obscureText;

  void toggleVisibility() {
    _obscureText = !_obscureText;
    notifyListeners();
  }

  Future<void> changePassword(BuildContext context) async {
    if (newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese una contraseña nueva')),
      );
      return;
    }

    _isSubmitting = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _isSubmitting = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    super.dispose();
  }
}
