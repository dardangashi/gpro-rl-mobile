import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/api_exception.dart';
import '../models/user_profile.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({
    required this.api,
    required this.onLogout,
    super.key,
  });
  final ApiClient api;
  final Future<void> Function() onLogout;

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<UserProfile> _customers = [];
  bool _loading = true;
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
      _customers = await widget.api.getCustomers();
    } catch (error) {
      _error = error is ApiException
          ? error.message
          : 'Klientët nuk mund të ngarkohen.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([UserProfile? customer]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CustomerDialog(api: widget.api, customer: customer),
    );
    if (saved == true) await _load();
  }

  Future<void> _toggle(UserProfile customer) async {
    try {
      await widget.api.setCustomerStatus(customer.id, !customer.isActive);
      await _load();
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _delete(UserProfile customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fshi klientin'),
        content: Text('A dëshironi ta fshini ${customer.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANULO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('FSHI'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteCustomer(customer.id);
      await _load();
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Klientët'),
      actions: [
        IconButton(
          onPressed: widget.onLogout,
          tooltip: 'Dil',
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.person_add),
      label: const Text('SHTO'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _load,
                  child: const Text('PROVO PËRSËRI'),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: _customers.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('Nuk ka klientë.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    itemCount: _customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              customer.firstName.characters.first.toUpperCase(),
                            ),
                          ),
                          title: Text(customer.fullName),
                          subtitle: Text(
                            '${customer.username} • ${customer.isActive ? 'Aktiv' : 'Joaktiv'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _edit(customer);
                              if (value == 'status') _toggle(customer);
                              if (value == 'delete') _delete(customer);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edito'),
                              ),
                              PopupMenuItem(
                                value: 'status',
                                child: Text(
                                  customer.isActive ? 'Deaktivizo' : 'Aktivizo',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Fshi'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
  );
}

class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog({required this.api, this.customer});
  final ApiClient api;
  final UserProfile? customer;

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _first = TextEditingController(
    text: widget.customer?.firstName,
  );
  late final TextEditingController _last = TextEditingController(
    text: widget.customer?.lastName,
  );
  late final TextEditingController _username = TextEditingController(
    text: widget.customer?.username,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.customer?.phone,
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.customer?.address,
  );
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'first_name': _first.text.trim(),
      'last_name': _last.text.trim(),
      'username': _username.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
    };
    if (_password.text.isNotEmpty) {
      data['password'] = _password.text;
      data['password_confirmation'] = _password.text;
    }
    try {
      if (widget.customer == null) {
        await widget.api.createCustomer(data);
      } else {
        await widget.api.updateCustomer(widget.customer!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Përgjigje e papritur nga serveri. Provoni përsëri.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.customer == null ? 'Shto klient' : 'Edito klientin'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'Emri *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _last,
                decoration: const InputDecoration(labelText: 'Mbiemri *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.customer == null
                      ? 'Password *'
                      : 'Password i ri (opsional)',
                ),
                validator: (value) {
                  if (widget.customer == null &&
                      (value == null || value.length < 8)) {
                    return 'Minimum 8 karaktere';
                  }
                  if (value != null && value.isNotEmpty && value.length < 8) {
                    return 'Minimum 8 karaktere';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Telefoni'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Adresa'),
                maxLines: 2,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('ANULO'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('RUAJ'),
      ),
    ],
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Fushë e detyrueshme' : null;
}
