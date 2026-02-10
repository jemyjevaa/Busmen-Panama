import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/services/models/info_schedules_model.dart';
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/ui/widgets/status_dialog.dart';
import 'package:intl/intl.dart';

class LostFoundViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  RouteData? _selectedRouteModel;
  RouteData? get selectedRouteModel => _selectedRouteModel;

  void setRouteModel(RouteData? route) {
    _selectedRouteModel = route;
    notifyListeners();
  }

  List<RouteData> _availableRoutesModel = [];
  List<RouteData> get availableRoutesModel => _availableRoutesModel;

  void setAvailableRoutes(List<RouteData> routes) {
    _availableRoutesModel = routes;
    notifyListeners();
  }

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Map<String, List<RouteData>> get groupedFilteredRoutes {
    final filtered = _availableRoutesModel.where((route) {
      final name = route.nombre.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    // Grouping by nombre
    final Map<String, List<RouteData>> groups = {};
    for (var route in filtered) {
      if (!groups.containsKey(route.nombre)) {
        groups[route.nombre] = [];
      }
      groups[route.nombre]!.add(route);
    }
    return groups;
  }

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> submitReport(BuildContext context) async {
    if (nameController.text.isEmpty || 
        phoneController.text.isEmpty || 
        descriptionController.text.isEmpty || 
        _selectedRouteModel == null || 
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

    try {
      final urlService = UrlService();
      final requestService = RequestService.instance;
      final session = CacheUserSession();
      final localization = Provider.of<LanguageService>(context, listen: false);

      // 0. Close keyboard
      if (context.mounted) FocusScope.of(context).unfocus();

      // 1. Format Date: dd/MM/yy
      final formattedDate = DateFormat('dd/MM/yy').format(_selectedDate!);
      
      // 2. Concatenation: "No. Telefono: ... Ruta: ... Reportado como: ... Fecha: ..."
      final descripcionConcatenada = 
          "No. Telefono: ${phoneController.text} "
          "Ruta: ${_selectedRouteModel!.nombre} "
          "Reportado como: ${descriptionController.text} "
          "Fecha: $formattedDate";

      // 3. Prepare Multipart Fields
      final Map<String, String> fields = {
        'empresa': session.companyClave ?? "",
        'nombre': nameController.text,
        'descripcion': descripcionConcatenada,
      };

      debugPrint("DEBUG - Submitting Lost Object Info: $fields");

      // 4. Send Request (Multipart as required by binary endpoint)
      final response = await requestService.handlingMultipartRequest(
        urlParam: urlService.getUrlLostObjects(),
        fields: fields,
      );

      debugPrint("DEBUG - Lost objects response: $response");

      _isSubmitting = false;
      notifyListeners();

      if (response != null && response.toLowerCase().contains('correcto')) {
        if (context.mounted) {
          StatusDialog.show(
            context,
            title: '¡Excelente!',
            message: localization.getString('report_sent'),
            type: StatusType.success,
            onDismiss: () => Navigator.pop(context),
          );
        }
      } else {
        if (context.mounted) {
          StatusDialog.show(
            context,
            title: 'Ups...',
            message: localization.getString('error_sending_report'),
            type: StatusType.error,
          );
        }
      }
    } catch (e) {
      debugPrint("ERROR - submitReport: $e");
      _isSubmitting = false;
      notifyListeners();
      
      if (context.mounted) {
        StatusDialog.show(
          context,
          title: 'Error',
          message: e.toString(),
          type: StatusType.error,
        );
      }
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
