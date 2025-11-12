import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  User? _user;
  UserProfile? _userProfile;
  String? _role;
  Timer? _sessionTimer;
  static const Duration _sessionTimeout = Duration(hours: 24); // 24 hour session

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  String? get role => _role;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _role == 'admin';
  bool get isSeller => _role == 'seller';

  Future<bool> get isSellerActive async {
    if (!isSeller) return false;
    final sellerInfo = await getSellerInfo();
    return sellerInfo != null && !sellerInfo.isExpired;
  }

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    // Check current session immediately
    final session = _supabase.auth.currentSession;
    _user = session?.user;

    if (_user != null) {
      _startSessionTimer();
      _fetchUserRole();
    } else {
      // No user logged in, set role to null
      _role = null;
    }

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      if (_user != null) {
        _startSessionTimer();
        _fetchUserRole();
      } else {
        _clearSession();
        notifyListeners();
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      // Session expired, sign out user
      signOut();
    });
  }

  void _clearSession() {
    _user = null;
    _userProfile = null;
    _role = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  Future<void> _fetchUserRole() async {
    if (_user == null) return;

    try {
      // First, ensure profile exists
      await _ensureProfileExists();

      // Fetch role
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _user!.id)
          .single();

      _role = response['role'] ?? 'user';

      // Fetch user profile
      _userProfile = await _userService.getUserProfile(_user!.id);

      // Check seller status if user is a seller
      if (_role == 'seller') {
        final sellerInfo = await getSellerInfo();
        if (sellerInfo == null) {
          // No seller record found, downgrade to user
          await _updateUserRole('user');
          _role = 'user';
        } else if (sellerInfo.isExpired) {
          // Seller expired - keep role but functionality will be restricted
          // Don't change role, let UI handle restrictions
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      // Default to user role on error
      _role = 'user';
      notifyListeners();
      rethrow; // Re-throw to handle verification error
    }
  }

  Future<void> _ensureProfileExists() async {
    try {
      // Try to get existing profile
      await _supabase
          .from('profiles')
          .select('id')
          .eq('id', _user!.id)
          .single();
    } catch (e) {
      // Profile doesn't exist, create it
      await _supabase.from('profiles').insert({
        'id': _user!.id,
        'email': _user!.email,
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _updateUserRole(String newRole) async {
    await _supabase
        .from('profiles')
        .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', _user!.id);
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'email_confirm': true}, // Auto-confirm email
      );
      if (response.user == null) {
        throw Exception('Signup failed: Unable to create account');
      }
      // No email verification required for any role
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
      // Role check will be handled in _fetchUserRole
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      _clearSession();
      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // Will use default redirect URL configured in Supabase
      );
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }


  Future<Seller?> getSellerInfo() async {
    if (_user == null || _role != 'seller') return null;
    try {
      final response = await _supabase
          .from('sellers')
          .select()
          .eq('id', _user!.id)
          .single();
      return Seller.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshSession() async {
    if (_user != null) {
      _startSessionTimer();
      await _fetchUserRole();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', _user!.id);

      // Refresh role if it was updated
      if (updates.containsKey('role')) {
        _role = updates['role'];
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;

    try {
      _userProfile = await _userService.updateUserProfile(_user!.id, updates);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}