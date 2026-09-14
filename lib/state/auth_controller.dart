import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/api_exception.dart';
import '../data/token_store.dart';
import '../models/action_config.dart';
import '../models/user_profile.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({required this.api, required this.tokenStore}) {
    api.onUnauthorized = _expireSession;
  }

  final ApiClient api;
  final TokenStore tokenStore;
  AuthStatus status = AuthStatus.checking;
  UserProfile? user;
  AppSettings? settings;
  String? error;
  String? busyAction;

  Future<void> restoreSession() async {
    final token = await tokenStore.read();
    if (token == null) return _setUnauthenticated();
    try {
      final profile = await api.me();
      if (!profile.isActive) {
        throw const ApiException('Llogaria juaj është joaktive.');
      }
      user = profile;
      settings = await api.getSettings();
      status = AuthStatus.authenticated;
      error = null;
    } catch (_) {
      await tokenStore.clear();
      _setUnauthenticated();
      return;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    error = null;
    notifyListeners();
    try {
      final profile = await api.login(username.trim(), password);
      if (!profile.isActive) {
        throw const ApiException('Llogaria juaj është joaktive.');
      }
      user = profile;
      settings = await api.getSettings();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on TimeoutException {
      error = 'Serveri nuk u përgjigj. Kontrolloni lidhjen.';
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Nuk mund të lidhemi me serverin.';
    }
    await tokenStore.clear();
    notifyListeners();
    return false;
  }

  Future<void> refreshSettings() async {
    settings = await api.getSettings();
    notifyListeners();
  }

  Future<String> execute(String action) async {
    if (busyAction != null) return 'Një veprim është në proces.';
    final config = action == 'hape' ? settings?.hape : settings?.mbylle;
    if (config == null) return 'Konfigurimi nuk është ngarkuar.';
    busyAction = action;
    notifyListeners();
    try {
      await api.execute(config);
      return action == 'hape' ? 'U hap me sukses' : 'U mbyll me sukses';
    } on TimeoutException {
      return 'Koha e pritjes përfundoi. Provoni përsëri.';
    } on ApiException catch (exception) {
      return exception.message;
    } catch (_) {
      return 'Operacioni dështoi';
    } finally {
      busyAction = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } finally {
      _setUnauthenticated();
    }
  }

  Future<void> _expireSession() async {
    _setUnauthenticated(
      message: 'Sesioni ka përfunduar. Identifikohuni përsëri.',
    );
  }

  void _setUnauthenticated({String? message}) {
    user = null;
    settings = null;
    busyAction = null;
    error = message;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
