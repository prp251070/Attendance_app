import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static final _supabase = SupabaseService.supabase;

  static Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      print("Login failed: ${e.message}");
      return null;
    }
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static Future<User?> getCurrentUser() async {
    final response = await _supabase.auth.getUser();
    return response.user;
  }
}
