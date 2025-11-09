import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Settings'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), // Account for app bar
              GlassyContainer(
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.notifications,
                      title: 'Push Notifications',
                      subtitle: 'Receive order updates and promotions',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white30,
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    _buildSettingItem(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Toggle between light and dark themes',
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white30,
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    _buildSettingItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Select your preferred language',
                      trailing: DropdownButton<String>(
                        value: _language,
                        dropdownColor: Colors.black87,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items: ['English', 'Spanish', 'French', 'German']
                            .map((lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _language = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GlassyContainer(
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.person,
                      title: 'Profile Information',
                      subtitle: 'Update your personal details',
                      onTap: () {
                        // Navigate to profile edit screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile edit coming soon')),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24),
                    _buildSettingItem(
                      icon: Icons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () {
                        // Navigate to change password screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Change password coming soon')),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24),
                    _buildSettingItem(
                      icon: Icons.payment,
                      title: 'Payment Methods',
                      subtitle: 'Manage your saved payment options',
                      onTap: () {
                        // Navigate to payment methods screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment methods coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GlassyContainer(
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.help,
                      title: 'Help & FAQ',
                      subtitle: 'Find answers to common questions',
                      onTap: () {
                        Navigator.pushNamed(context, '/help');
                      },
                    ),
                    const Divider(color: Colors.white24),
                    _buildSettingItem(
                      icon: Icons.contact_support,
                      title: 'Contact Support',
                      subtitle: 'Get in touch with our team',
                      onTap: () {
                        // Navigate to contact support screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contact support coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: trailing ??
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white54,
            size: 16,
          ),
      onTap: onTap,
    );
  }
}