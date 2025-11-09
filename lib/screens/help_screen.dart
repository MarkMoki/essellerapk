import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Help & Support'),
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
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildFAQItem(
                question: 'How do I place an order?',
                answer: 'Browse our products, add items to your cart, and proceed to checkout. Follow the payment instructions to complete your order.',
              ),
              _buildFAQItem(
                question: 'What payment methods do you accept?',
                answer: 'We accept major credit cards, debit cards, and digital payment methods like PayPal and Apple Pay.',
              ),
              _buildFAQItem(
                question: 'How can I track my order?',
                answer: 'You can track your order status in the "My Orders" section of your profile. We\'ll also send you email updates.',
              ),
              _buildFAQItem(
                question: 'What is your return policy?',
                answer: 'We offer a 30-day return policy for most items. Items must be in original condition and packaging.',
              ),
              _buildFAQItem(
                question: 'How do I contact customer support?',
                answer: 'You can reach our support team through the "Contact Support" option in Settings, or email us at support@esaller.com.',
              ),
              _buildFAQItem(
                question: 'Can I cancel my order?',
                answer: 'Orders can be cancelled within 24 hours of placement. Please contact support immediately if you need to cancel.',
              ),
              const SizedBox(height: 40),
              const Text(
                'Contact Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GlassyContainer(
                child: const Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.white70),
                      title: Text(
                        'Email Support',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'support@esaller.com',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Divider(color: Colors.white24),
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.white70),
                      title: Text(
                        'Phone Support',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '+1 (555) 123-4567',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Divider(color: Colors.white24),
                    ListTile(
                      leading: Icon(Icons.schedule, color: Colors.white70),
                      title: Text(
                        'Support Hours',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Mon-Fri: 9AM-6PM EST\nSat-Sun: 10AM-4PM EST',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'App Version',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esaller v1.0.0',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return GlassyContainer(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}