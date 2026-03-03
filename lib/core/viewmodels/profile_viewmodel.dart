import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/notifications_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/lost_found_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/password_viewmodel.dart';
import 'package:busmen_panama/ui/views/login_view.dart';

class ProfileViewModel extends ChangeNotifier {
  final _session = CacheUserSession();

  String get userName => _session.userName ?? "Usuario";
  
  List<String> get userEmails {
    if (_session.userEmail == null || _session.userEmail!.isEmpty) return [];
    return _session.userEmail!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String get userId => _session.userIdCli ?? "000000";
  String? get userImage => _session.companyImg;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  Future<void> makeMonitoringCall() async {
    final phone = _session.companyPhone ?? "0000";
    final url = Uri.parse('tel:$phone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> deleteUser(BuildContext context) async {
    _isDeleting = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _isDeleting = false;
    notifyListeners();

    if (context.mounted) {
      // Reset all ViewModels to clear state
      context.read<LoginViewModel>().reset();
      context.read<HomeViewModel>().reset();
      context.read<SchedulesViewModel>().reset();
      context.read<NotificationsViewModel>().reset();
      context.read<LostFoundViewModel>().reset();
      context.read<PasswordViewModel>().reset();

      _session.clear();
      _session.isLogin = false; // Log out on delete for mock
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado correctamente')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }
}
