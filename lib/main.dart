import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/ui/views/login_view.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/profile_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/lost_found_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/password_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SchedulesViewModel()),
        ChangeNotifierProvider(create: (_) => LostFoundViewModel()),
        ChangeNotifierProvider(create: (_) => PasswordViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Busmen Panama',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C13A2)),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
