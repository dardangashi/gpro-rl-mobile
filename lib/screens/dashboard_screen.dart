import 'package:flutter/material.dart';

import '../models/action_config.dart';
import '../state/auth_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.auth, super.key});
  final AuthController auth;

  Future<void> _execute(BuildContext context, String action) async {
    final message = await auth.execute(action);
    if (!context.mounted || auth.status != AuthStatus.authenticated) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _refresh(BuildContext context) async {
    try {
      await auth.refreshSettings();
    } catch (_) {
      if (context.mounted && auth.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurimi nuk mund të rifreskohej.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = auth.settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gpro RL'),
        actions: [
          IconButton(
            onPressed: auth.logout,
            tooltip: 'Dil',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(
              'Përshëndetje, ${auth.user?.firstName ?? ''}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Zgjidhni një veprim',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 42),
            _ActionButton(
              label: 'HAPE',
              loadingLabel: 'Duke hapur...',
              icon: Icons.lock_open_rounded,
              color: const Color(0xFF15803D),
              config: settings?.hape,
              loading: auth.busyAction == 'hape',
              disabled: auth.busyAction != null,
              onPressed: () => _execute(context, 'hape'),
            ),
            const SizedBox(height: 24),
            _ActionButton(
              label: 'MBYLL',
              loadingLabel: 'Duke mbyllur...',
              icon: Icons.lock_rounded,
              color: const Color(0xFFB91C1C),
              config: settings?.mbylle,
              loading: auth.busyAction == 'mbylle',
              disabled: auth.busyAction != null,
              onPressed: () => _execute(context, 'mbylle'),
            ),
            if (settings == null ||
                !settings.hape.configured ||
                !settings.mbylle.configured) ...[
              const SizedBox(height: 24),
              const Text(
                'Një ose më shumë veprime nuk janë konfiguruar. Tërhiqni poshtë për të rifreskuar.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.color,
    required this.config,
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final IconData icon;
  final Color color;
  final ActionConfig? config;
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: FilledButton(
      onPressed: disabled || config?.configured != true ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.35),
        minimumSize: const Size.fromHeight(128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: loading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(loadingLabel, style: const TextStyle(fontSize: 18)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
    ),
  );
}
