import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../models/action_config.dart';
import '../state/auth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.auth, super.key});
  final AuthController auth;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = GlobalKey<FormState>();
  final _hape = TextEditingController();
  final _mbylle = TextEditingController();
  String _hapeMethod = 'POST';
  String _mbylleMethod = 'POST';
  AdminSettings? _original;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await widget.auth.api.getAdminSettings();
      _original = settings;
      _hape.text = settings.hape.url;
      _mbylle.text = settings.mbylle.url;
      _hapeMethod = settings.hape.method;
      _mbylleMethod = settings.mbylle.method;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Përgjigje e pavlefshme nga serveri.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _original == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final settings = AdminSettings(
      hape: AdminActionConfig(
        url: _hape.text.trim(),
        method: _hapeMethod,
        headers: _original!.hape.headers,
        body: _original!.hape.body,
      ),
      mbylle: AdminActionConfig(
        url: _mbylle.text.trim(),
        method: _mbylleMethod,
        headers: _original!.mbylle.headers,
        body: _original!.mbylle.body,
      ),
    );
    try {
      await widget.auth.api.saveAdminSettings(settings);
      _original = settings;
      await widget.auth.refreshSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurimet u ruajtën me sukses.')),
        );
      }
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Konfigurimet nuk mund të ruhen. Provoni përsëri.';
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _urlValidator(String? value) {
    final uri = Uri.tryParse(value ?? '');
    return uri != null &&
            uri.hasScheme &&
            (uri.scheme == 'http' || uri.scheme == 'https')
        ? null
        : 'Shkruani një URL të vlefshme';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      actions: [
        IconButton(
          onPressed: widget.auth.logout,
          tooltip: 'Dil',
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _original == null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Gabim'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _load,
                  child: const Text('PROVO PËRSËRI'),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Endpoint-et e biznesit',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Këto konfigurime përdoren vetëm nga klientët e biznesit tuaj.',
                  ),
                  const SizedBox(height: 24),
                  _EndpointEditor(
                    label: 'HAPE endpoint',
                    controller: _hape,
                    method: _hapeMethod,
                    onMethodChanged: (value) =>
                        setState(() => _hapeMethod = value),
                    validator: _urlValidator,
                  ),
                  const SizedBox(height: 24),
                  _EndpointEditor(
                    label: 'MBYLL endpoint',
                    controller: _mbylle,
                    method: _mbylleMethod,
                    onMethodChanged: (value) =>
                        setState(() => _mbylleMethod = value),
                    validator: _urlValidator,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('RUAJ KONFIGURIMET'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _EndpointEditor extends StatelessWidget {
  const _EndpointEditor({
    required this.label,
    required this.controller,
    required this.method,
    required this.onMethodChanged,
    required this.validator,
  });
  final String label;
  final TextEditingController controller;
  final String method;
  final ValueChanged<String> onMethodChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'GET', label: Text('GET')),
              ButtonSegment(value: 'POST', label: Text('POST')),
            ],
            selected: {method},
            onSelectionChanged: (values) => onMethodChanged(values.first),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com/api/action',
            ),
            keyboardType: TextInputType.url,
            validator: validator,
          ),
        ],
      ),
    ),
  );
}
