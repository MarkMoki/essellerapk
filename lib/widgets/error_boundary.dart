import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(Object error, StackTrace stackTrace)? onError;
  final bool enableLogging;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
    this.enableLogging = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  Zone? _errorZone;

  @override
  void initState() {
    super.initState();
    _setupErrorZone();
  }

  void _setupErrorZone() {
    _errorZone = Zone.current.fork(
      specification: ZoneSpecification(
        handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
            Object error, StackTrace stackTrace) {
          _handleError(error, stackTrace);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }

    return _errorZone?.run(() {
      return Builder(
        builder: (context) {
          try {
            return widget.child;
          } catch (error, stackTrace) {
            _handleError(error, stackTrace);
            return widget.errorWidget ?? _buildDefaultErrorWidget();
          }
        },
      );
    }) ?? widget.child;
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (widget.enableLogging) {
      developer.log(
        'Error caught by ErrorBoundary',
        error: error,
        stackTrace: stackTrace,
        name: 'ErrorBoundary',
      );
    }

    setState(() {
      _error = error;
    });

    widget.onError?.call(error, stackTrace);
  }

  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error != null
                    ? 'Error: ${_error.toString().split(':').first}'
                    : 'We encountered an unexpected error. Please try again.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _resetError,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _reportError(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Report Error'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Report Error', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error details have been logged. Would you like to send additional feedback?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${_error?.toString() ?? 'Unknown error'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error reported. Thank you for your feedback!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }
}