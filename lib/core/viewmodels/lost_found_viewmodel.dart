import 'package:flutter/material.dart';

class LostFoundViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  String? _selectedRoute;
  String? get selectedRoute => _selectedRoute;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  final List<String> availableRoutes = [
    "Ruta A - Centro",
    "Ruta B - Norte", 
    "Ruta C - Sur"
  ];

  void setRoute(String? route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> submitReport(BuildContext context) async {
    if (nameController.text.isEmpty || 
        phoneController.text.isEmpty || 
        descriptionController.text.isEmpty || 
        _selectedRoute == null || 
        _selectedDate == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor complete todos los campos')),
        );
      }
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
        const SnackBar(content: Text('Reporte enviado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
