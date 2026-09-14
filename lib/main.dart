import 'package:flutter/material.dart';

import 'app.dart';
import 'data/api_client.dart';
import 'data/token_store.dart';
import 'state/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  final tokenStore = SecureTokenStore();
  final api = ApiClient(baseUrl: baseUrl, tokenStore: tokenStore);
  runApp(
    RlgProApp(
      auth: AuthController(api: api, tokenStore: tokenStore),
    ),
  );
}
