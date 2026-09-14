import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import 'customer_management_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({required this.auth, super.key});
  final AuthController auth;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(auth: widget.auth),
            CustomerManagementScreen(
              api: widget.auth.api,
              onLogout: widget.auth.logout,
            ),
            SettingsScreen(auth: widget.auth),
          ],
        ),
      ),
      NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Klientët',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    ],
  );
}
