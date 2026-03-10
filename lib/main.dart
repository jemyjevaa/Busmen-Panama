import 'package:busmen_panama/ui/views/home_view.dart';
import 'package:busmen_panama/ui/views/operator_home_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/ui/views/login_view.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/profile_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/lost_found_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/password_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/notifications_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/operator_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/core/services/simulation_service.dart';

import 'app_globals.dart';
import 'core/services/cache_user_session.dart';
import 'core/services/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheUserSession().init();
  try {
    await SocketService().initOneSignal();
  } catch (e) {
    debugPrint("OneSignal initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SchedulesViewModel()),
        ChangeNotifierProvider(create: (_) => LostFoundViewModel()),
        ChangeNotifierProvider(create: (_) => PasswordViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ChangeNotifierProvider(create: (_) => OperatorViewModel()),
        ChangeNotifierProvider(create: (_) => SimulationService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Busmen Panama',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C13A2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C13A2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: CacheUserSession().isLogin 
          ? (CacheUserSession().isOperatorMode ? const OperatorHomeView() : const HomeView()) 
          : const LoginView(),
      routes: {
        '/operator_home': (context) => const OperatorHomeView(),
        '/home': (context) => const HomeView(),
      },
    );
  }
}
