import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  User? currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> login(String email, String password) async {
    final response = await AuthService.login(email, password);
    if (response != null && response.user != null) {
      currentUser = response.user;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    currentUser = null;
    notifyListeners();
  }
}
