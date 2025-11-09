import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassyAppBar(title: 'Profile'),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassyContainer(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.user?.email ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.isAdmin ? 'Administrator' : 'Customer',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassyContainer(
                child: Column(
                  children: [
                    _buildProfileOption(
                      icon: Icons.shopping_bag,
                      title: 'My Orders',
                      onTap: () {
                        // Navigate to orders screen
                      },
                    ),
                    const Divider(color: Colors.white24),
                    _buildProfileOption(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        // Navigate to settings screen
                      },
                    ),
                    const Divider(color: Colors.white24),
                    _buildProfileOption(
                      icon: Icons.help,
                      title: 'Help & Support',
                      onTap: () {
                        // Navigate to help screen
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GlassyButton(
                onPressed: () {
                  authProvider.signOut();
                },
                width: double.infinity,
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}