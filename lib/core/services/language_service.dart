import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'ES';
  String get currentLanguage => _currentLanguage;

  final Map<String, Map<String, String>> _localizedValues = {
    'ES': {
      // Login
      'user_label': 'USUARIO',
      'pass_label': 'CONTRASEÑA',
      'remember_me': 'Mantener sesión iniciada',
      'login_btn': 'INICIAR SESION',
      'new_user_company': 'Compañia',
      'welcome': 'Entrando...',

      // Drawer
      'driver_role': 'Conductor',
      'profile': 'Perfil',
      'schedules': 'Horarios',
      'monitoring_center': 'Centro de Monitoreo',
      'lost_found': 'Objetos Perdidos',
      'password': 'Contraseña',
      'information': 'Información',
      'announcements': 'Comunicados',
      'announcements_found': 'No hay comunicados disponibles en este momento.',
      'regulations': 'Reglamentación',
      'manual': 'Manual',
      'logout': 'Cerrar Sesión',
      
      // Map
      'normal': 'Normal',
      'satellite': 'Satelital',
      'hybrid': 'Híbrido',
      
      // Bottom UI
      'route_not_selected': 'Ruta no seleccionada',
      'select_route': 'SELECCIONAR RUTA',

      // Profile
      'delete_user': 'ELIMINAR USUARIO',
      'user_code': 'Código de Usuario',
      'deleted_success': 'Usuario eliminado correctamente',

      // Schedules
      'on_time': 'A tiempo',
      'delayed': 'Retrasado',

      // Lost & Found
      'report_lost_object': 'Reportar Objeto Perdido',
      'report_msg': 'Complete el formulario con los detalles del objeto.',
      'user_name_label': 'Nombre de Usuario',
      'user_name_hint': 'Ingrese su nombre',
      'phone_label': 'Teléfono de Contacto',
      'phone_hint': 'Ingrese su teléfono',
      'route_label': 'Ruta',
      'route_hint': 'Seleccione la ruta',
      'date_label': 'Fecha del Incidente',
      'date_hint': 'Seleccione la fecha',
      'description_label': 'Descripción del Objeto',
      'description_hint': 'Describa el objeto detalladamente',
      'send_report': 'ENVIAR REPORTE',
      'fill_all_fields': 'Por favor complete todos los campos',
      'report_sent': 'Reporte enviado correctamente',

      // Password
      'change_password': 'Cambiar Contraseña',
      'password_msg': 'Asegúrese de usar una contraseña segura que recuerde.',
      'new_password_label': 'Nueva Contraseña',
      'new_password_hint': 'Ingrese su nueva contraseña',
      'change_password_btn': 'CAMBIAR CONTRASEÑA',
      'enter_new_password': 'Ingrese una contraseña nueva',
      'password_updated': 'Contraseña actualizada correctamente',

      // Login Extras
      'register': 'Registrarse',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'create_account': 'Crear Cuenta',
      'recover_access': 'Recuperar Acceso',
      'name_label': 'Nombre',
      'email_label': 'Correo',
      'user_n_label': 'Usuario', // To avoid conflict with user_label if needed, or reuse
      'register_btn': 'REGISTRAR',
      'send_btn': 'ENVIAR',
      'cancel_btn': 'CANCELAR',
      'back_btn': 'REGRESAR',
      'register_success': 'Usuario registrado correctamente',
      'register_error': 'Usuario no se registrado correctamente',
      'recovery_sent': 'Correo de recuperación enviado',
      'recovery_sent_error': 'Correo de recuperación fallo en el envío',
      'no_profile': 'SIN PERFIL',
      'error_domine':'Correo inválido',
      'error_user':'Usuario inválido',
    },
    'EN': {
      // Login
      'user_label': 'USERNAME',
      'pass_label': 'PASSWORD',
      'remember_me': 'Stay logged in',
      'login_btn': 'LOG IN',
      'new_user_company': 'Company',
      'welcome': 'Signing in…',
      
      // Drawer
      'driver_role': 'Driver',
      'profile': 'Profile',
      'schedules': 'Schedules',
      'monitoring_center': 'Monitoring Center',
      'lost_found': 'Lost & Found',
      'password': 'Password',
      'information': 'Information',
      'announcements': 'Announcements',
      'announcements_found': 'There are no announcements available at this time',
      'regulations': 'Regulations',
      'manual': 'Manual',
      'logout': 'Log Out',
      
      // Map
      'normal': 'Normal',
      'satellite': 'Satellite',
      'hybrid': 'Hybrid',
      
      // Bottom UI
      'route_not_selected': 'Route not selected',
      'select_route': 'SELECT ROUTE',

       // Profile
      'delete_user': 'DELETE USER',
      'user_code': 'User Code',
      'deleted_success': 'User deleted successfully',

      // Schedules
      'on_time': 'On Time',
      'delayed': 'Delayed',

      // Lost & Found
      'report_lost_object': 'Report Lost Item',
      'report_msg': 'Fill out the form with item details.',
      'user_name_label': 'Username',
      'user_name_hint': 'Enter your name',
      'phone_label': 'Contact Phone',
      'phone_hint': 'Enter your phone',
      'route_label': 'Route',
      'route_hint': 'Select route',
      'date_label': 'Incident Date',
      'date_hint': 'Select date',
      'description_label': 'Item Description',
      'description_hint': 'Describe the item in detail',
      'send_report': 'SEND REPORT',
      'fill_all_fields': 'Please fill all fields',
      'report_sent': 'Report sent successfully',

      // Password
      'change_password': 'Change Password',
      'password_msg': 'Make sure to use a secure password you remember.',
      'new_password_label': 'New Password',
      'new_password_hint': 'Enter your new password',
      'change_password_btn': 'CHANGE PASSWORD',
      'enter_new_password': 'Enter a new password',
      'password_updated': 'Password updated successfully',

      // Login Extras
      'register': 'Register',
      'forgot_password': 'Forgot password?',
      'create_account': 'Create Account',
      'recover_access': 'Recover Access',
      'name_label': 'Name',
      'email_label': 'Email',
      'user_n_label': 'Username',
      'register_btn': 'REGISTER',
      'send_btn': 'SEND',
      'cancel_btn': 'CANCEL',
      'back_btn': 'GO BACK',
      'register_success': 'User registered successfully',
      'register_error': 'User registration failed',
      'recovery_sent': 'Recovery email sent',
      'recovery_sent_error': 'Failed to send recovery email',
      'no_profile': 'NO PROFILE',
      'error_domine':'Please enter a valid email address',
      'error_user':'Invalid User',
    },
  };

  String getString(String key) => _localizedValues[_currentLanguage]?[key] ?? key;

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
}
