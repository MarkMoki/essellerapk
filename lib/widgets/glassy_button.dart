import 'package:flutter/material.dart';
import 'dart:ui';

class GlassyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double blurStrength;
  final double opacity;

  const GlassyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.blurStrength = 10.0,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height ?? 50,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                borderRadius: borderRadius ?? BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}