import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  String? _role;

  User? get user => _user;
  String? get role => _role;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _role == 'admin';

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      _fetchUserRole();
    }
    _supabase.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      if (_user != null) {
        _fetchUserRole();
      } else {
        _role = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole() async {
    if (_user == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _user!.id)
          .single();
      _role = response['role'];
      notifyListeners();
    } catch (e) {
      // If profile doesn't exist, role remains null (user)
      _role = null;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      // After signup, insert profile with default role 'user'
      if (response.user != null) {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'role': 'user',
        });
      } else {
        throw Exception('Signup failed: Unable to create account');
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Login failed: Invalid credentials');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}