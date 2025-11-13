import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserProfile {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<UserProfile> _users = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Check if current user is admin
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      if (profileResponse['role'] != 'admin') {
        throw Exception('Access denied: Admin privileges required');
      }

      // Fetch all users from auth.users and join with profiles
      final authUsersResponse = await _supabase.auth.admin.listUsers();
      final profilesResponse = await _supabase.from('profiles').select();

      final authUsers = authUsersResponse;
      final profiles = profilesResponse;

      final userProfiles = authUsers.map((authUser) {
        final profile = profiles.firstWhere(
          (p) => p['id'] == authUser.id,
          orElse: () => {'id': authUser.id, 'role': 'user', 'created_at': DateTime.now().toIso8601String()},
        );

        return UserProfile(
          id: authUser.id,
          email: authUser.email ?? '',
          role: profile['role'] ?? 'user',
          createdAt: DateTime.tryParse(profile['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();

      // Sort users: admins first, then regular users, newest first
      userProfiles.sort((a, b) {
        if (a.role == 'admin' && b.role != 'admin') return -1;
        if (a.role != 'admin' && b.role == 'admin') return 1;
        return b.createdAt.compareTo(a.createdAt); // Newest first for same role
      });

      if (mounted) {
        setState(() {
          _users = userProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle AuthApiException for expired tokens or insufficient permissions
      if (e.toString().contains('AuthApiException') &&
          (e.toString().contains('token is expired') ||
           e.toString().contains('user not allowed') ||
           e.toString().contains('not_admin'))) {
        try {
          // Attempt to refresh the session
          await _supabase.auth.refreshSession();
          // Retry loading users after refresh
          await _loadUsers();
          return;
        } catch (refreshError) {
          // If refresh fails, show authentication error
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Session expired or insufficient permissions. Please sign in again.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Session expired or insufficient permissions. Please sign in again.'),
                backgroundColor: Colors.redAccent,
                action: SnackBarAction(
                  label: 'Sign In',
                  textColor: Colors.white,
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                    }
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadUsers,
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'role': newRole,
      });

      // If promoting to seller, create seller record with 30-day expiration
      if (newRole == 'seller') {
        final expiresAt = DateTime.now().add(const Duration(days: 30));
        await _supabase.from('sellers').upsert({
          'id': userId,
          'created_by': _supabase.auth.currentUser!.id,
          'expires_at': expiresAt.toIso8601String(),
        });
      } else if (newRole != 'seller') {
        // If changing from seller to another role, remove seller record
        await _supabase.from('sellers').delete().eq('id', userId);
      }

      _loadUsers(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle AuthApiException for expired tokens or insufficient permissions
      if (e.toString().contains('AuthApiException') &&
          (e.toString().contains('token is expired') ||
           e.toString().contains('user not allowed') ||
           e.toString().contains('not_admin'))) {
        try {
          // Attempt to refresh the session
          await _supabase.auth.refreshSession();
          // Retry updating user role after refresh
          await _updateUserRole(userId, newRole);
          return;
        } catch (refreshError) {
          // If refresh fails, show authentication error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired or insufficient permissions. Please sign in again.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Admin - User Management'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
          ),
        ),
        child: LoadingOverlay(
          isLoading: _isLoading,
          loadingMessage: 'Loading users...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Users',
                  message: _errorMessage,
                  onRetry: _loadUsers,
                  icon: Icons.refresh,
                )
              : _users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Users will appear here',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Summary cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total Users',
                                  _users.length.toString(),
                                  Icons.people,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Admins',
                                  _users.where((u) => u.role == 'admin').length.toString(),
                                  Icons.admin_panel_settings,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Users list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                        return GlassyContainer(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.email.isNotEmpty ? user.email : 'User ${user.id.substring(0, 8)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Role: ${user.role.toUpperCase()}',
                                            style: TextStyle(
                                              color: user.role == 'admin' ? Colors.purpleAccent : user.role == 'seller' ? Colors.orangeAccent : Colors.blueAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.role == 'admin' ? Colors.purple : user.role == 'seller' ? Colors.orange : Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.role.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'User ID: ${user.id.substring(0, 8)}...',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Joined: ${_formatDate(user.createdAt)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text(
                                      'Role:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButton<String>(
                                        value: user.role,
                                        dropdownColor: const Color(0xFF16213e),
                                        style: const TextStyle(color: Colors.white),
                                        items: const [
                                          DropdownMenuItem(value: 'user', child: Text('User')),
                                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                          DropdownMenuItem(value: 'seller', child: Text('Seller')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null && value != user.role) {
                                            _updateUserRole(user.id, value);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}