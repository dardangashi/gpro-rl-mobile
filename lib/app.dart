import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'state/auth_controller.dart';

class RlgProApp extends StatefulWidget {
  const RlgProApp({required this.auth, super.key});
  final AuthController auth;

  @override
  State<RlgProApp> createState() => _RlgProAppState();
}

class _RlgProAppState extends State<RlgProApp> {
  @override
  void initState() {
    super.initState();
    widget.auth.restoreSession();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gpro RL',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14532D)),
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) => switch (widget.auth.status) {
        AuthStatus.checking => const SplashScreen(),
        AuthStatus.authenticated =>
          widget.auth.user!.isAdmin
              ? AdminHomeScreen(auth: widget.auth)
              : DashboardScreen(auth: widget.auth),
        AuthStatus.unauthenticated => LoginScreen(auth: widget.auth),
      },
    ),
  );
}
