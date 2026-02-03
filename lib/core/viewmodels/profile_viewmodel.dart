import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  // Mock User Data
  final String userName = "George Voy";
  final String userEmail = "george@busmen.com";
  final String userId = "123456789";

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  Future<void> deleteUser(BuildContext context) async {
    _isDeleting = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _isDeleting = false;
    notifyListeners();

    if (context.mounted) {
      // Show confirmation or navigate out
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado correctamente')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
