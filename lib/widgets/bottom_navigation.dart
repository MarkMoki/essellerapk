import 'package:flutter/material.dart';
import 'dart:ui';

class GlassyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const GlassyBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final height = isWide ? 90.0 : 80.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isAdmin
                ? [
                    _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                    _buildNavItem(1, Icons.inventory, 'Products'),
                    _buildNavItem(2, Icons.shopping_cart, 'Orders'),
                    _buildNavItem(3, Icons.people, 'Users'),
                  ]
                : [
                    _buildNavItem(0, Icons.home, 'Home'),
                    _buildNavItem(1, Icons.shopping_bag, 'Shop'),
                    _buildNavItem(2, Icons.shopping_cart, 'Cart'),
                    _buildNavItem(3, Icons.person, 'Profile'),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWide = screenWidth > 600;
        final iconSize = isSelected ? (isWide ? 32.0 : 28.0) : (isWide ? 28.0 : 24.0);
        final fontSize = isWide ? 14.0 : 12.0;

        return GestureDetector(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: iconSize,
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}