import 'package:flutter/material.dart';
import 'dart:ui';

class GlassyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GlassyAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          title: Text(title),
          actions: actions,
          leading: leading,
          centerTitle: centerTitle,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}