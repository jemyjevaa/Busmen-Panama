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
      
      // Drawer
      'driver_role': 'Conductor',
      'profile': 'Perfil',
      'schedules': 'Horarios',
      'monitoring_center': 'Centro de Monitoreo',
      'lost_found': 'Objetos Perdidos',
      'password': 'Contraseña',
      'information': 'Información',
      'announcements': 'Comunicados',
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
      'options_monitoring': 'Centro de Monitoreo',
      'options_monitoring_btn': 'Llamar a Monitoreo',

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
      'error_sending_report': 'Error al enviar el reporte. Intente de nuevo.',
      'notification': 'Notificación', // Added for notifications

      // Password
      'change_password': 'Cambiar Contraseña',
      'password_msg': 'Asegúrese de usar una contraseña segura que recuerde.',
      'new_password_label': 'Nueva Contraseña',
      'new_password_hint': 'Ingrese su nueva contraseña',
      'change_password_btn': 'CAMBIAR CONTRASEÑA',
      'enter_new_password': 'Ingrese una contraseña nueva',
      'password_updated': 'Contraseña actualizada correctamente',
      'error_changing_password': 'El servidor no pudo procesar el cambio. Verifique sus datos o intente más tarde.',

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
      'recovery_sent': 'Correo de recuperación enviado',
      'no_profile': 'SIN PERFIL',
      'error_domine':'Correo inválido',
      'error_user':'Usuario inválido',
      
      // Tracking (v7)
      'live_tracking': 'RASTREO EN VIVO ACTIVADO',
      'full_route': 'RECORRIDO COMPLETO',
      'select_my_stop': 'SELECCIONAR MI PARADA',
      'active_tracking': 'RASTREO ACTIVO',
      'offline_system': 'SISTEMA FUERA DE HORARIO',
      'offline_msg': 'La ruta no está operando actualmente. Los tiempos mostrados son estimados programados.',
      'my_stop_label': 'MI PARADA',
      'stop_number': 'Parada #',
      'select_stop_desc': 'Selecciona el punto donde abordarás la unidad para darte prioridad.',
    },
    'EN': {
      // Login
      'user_label': 'USERNAME',
      'pass_label': 'PASSWORD',
      'remember_me': 'Stay logged in',
      'login_btn': 'LOG IN',
      
      // Drawer
      'driver_role': 'Driver',
      'profile': 'Profile',
      'schedules': 'Schedules',
      'monitoring_center': 'Monitoring Center',
      'lost_found': 'Lost & Found',
      'password': 'Password',
      'information': 'Information',
      'announcements': 'Announcements',
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
      'options_monitoring': 'Monitoring Center',
      'options_monitoring_btn': 'Call Monitoring',

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
      'error_sending_report': 'Error sending report. Please try again.',

      // Password
      'change_password': 'Change Password',
      'password_msg': 'Make sure to use a secure password you remember.',
      'new_password_label': 'New Password',
      'new_password_hint': 'Enter your new password',
      'change_password_btn': 'CHANGE PASSWORD',
      'enter_new_password': 'Enter a new password',
      'password_updated': 'Password updated successfully',
      'error_changing_password': 'The server could not process the change. Please check your data or try again later.',

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
      'recovery_sent': 'Recovery email sent',
      'no_profile': 'NO PROFILE',
      'error_domine':'Please enter a valid email address',
      'error_user':'Invalid User',
      'notification': 'Notification', // Added for notifications

      // Tracking (v7)
      'live_tracking': 'LIVE TRACKING ACTIVATED',
      'full_route': 'FULL ROUTE',
      'select_my_stop': 'SELECT MY STOP',
      'active_tracking': 'ACTIVE TRACKING',
      'offline_system': 'SYSTEM OUTSIDE HOURS',
      'offline_msg': 'The route is not currently operating. Times shown are scheduled estimates.',
      'my_stop_label': 'MY STOP',
      'stop_number': 'Stop #',
      'select_stop_desc': 'Select the point where you will board the unit to prioritize it.',
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
