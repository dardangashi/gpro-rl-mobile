import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/action_config.dart';
import '../models/user_profile.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.tokenStore,
    http.Client? client,
  }) : baseUri = Uri.parse(baseUrl.replaceFirst(RegExp(r'/$'), '')),
       _client = client ?? http.Client();

  final Uri baseUri;
  final TokenStore tokenStore;
  final http.Client _client;
  Future<void> Function()? onUnauthorized;

  Uri _uri(String path) {
    final relative = Uri.parse(path.replaceFirst(RegExp(r'^/'), ''));

    return baseUri.replace(
      path: '${baseUri.path}/${relative.path}',
      query: relative.hasQuery ? relative.query : null,
    );
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await tokenStore.read();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<UserProfile> login(String username, String password) async {
    final response = await _client
        .post(
          _uri('/auth/login'),
          headers: await _headers(authenticated: false),
          body: jsonEncode({
            'username': username,
            'password': password,
            'device_name': 'mobile-app',
          }),
        )
        .timeout(const Duration(seconds: 15));
    final json = _decode(response);
    await tokenStore.write(json['token'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> me() async {
    final response = await _client
        .get(_uri('/auth/me'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final json = await _handle(response);
    return UserProfile.fromJson((json['data'] ?? json) as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client
          .post(_uri('/auth/logout'), headers: await _headers())
          .timeout(const Duration(seconds: 10));
    } finally {
      await tokenStore.clear();
    }
  }

  Future<AppSettings> getSettings() async {
    final response = await _client
        .get(_uri('/app/settings'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final json = await _handle(response);
    return AppSettings.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> execute(ActionConfig action) async {
    if (!action.configured || action.executeUrl.isEmpty) {
      throw const ApiException('Ky veprim nuk është konfiguruar ende.');
    }
    final response = await _client
        .post(Uri.parse(action.executeUrl), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    await _handle(response);
  }

  Future<List<UserProfile>> getCustomers() async {
    final response = await _client
        .get(_uri('/admin/customers?per_page=100'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final json = await _handle(response);
    return (json['data'] as List<dynamic>)
        .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCustomer(Map<String, dynamic> data) async {
    final response = await _client
        .post(
          _uri('/admin/customers'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    await _handle(response);
  }

  Future<void> updateCustomer(int id, Map<String, dynamic> data) async {
    final response = await _client
        .put(
          _uri('/admin/customers/$id'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    await _handle(response);
  }

  Future<void> deleteCustomer(int id) async {
    final response = await _client
        .delete(_uri('/admin/customers/$id'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    await _handle(response);
  }

  Future<void> setCustomerStatus(int id, bool active) async {
    final operation = active ? 'activate' : 'deactivate';
    final response = await _client
        .patch(
          _uri('/admin/customers/$id/$operation'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    await _handle(response);
  }

  Future<AdminSettings> getAdminSettings() async {
    final response = await _client
        .get(_uri('/admin/settings'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final json = await _handle(response);
    return AdminSettings.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> saveAdminSettings(AdminSettings settings) async {
    final response = await _client
        .put(
          _uri('/admin/settings'),
          headers: await _headers(),
          body: jsonEncode({
            'hape': settings.hape.toJson(),
            'mbylle': settings.mbylle.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 15));
    await _handle(response);
  }

  Future<Map<String, dynamic>> _handle(http.Response response) async {
    if (response.statusCode == 401) {
      await tokenStore.clear();
      await onUnauthorized?.call();
    }
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json = {};
    try {
      if (response.body.isNotEmpty) {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } on FormatException {
      throw ApiException(
        'Përgjigje e pavlefshme nga serveri.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        json['message'] as String? ?? 'Kërkesa dështoi. Provoni përsëri.',
        statusCode: response.statusCode,
      );
    }
    return json;
  }
}
