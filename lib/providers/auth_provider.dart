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
    final response = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', _user!.id)
        .single();
    _role = response['role'];
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
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
    }
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}