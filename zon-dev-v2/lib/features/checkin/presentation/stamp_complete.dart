import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';

class StampComplete extends StatelessWidget {
  const StampComplete({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 96, color: kBrandGreen),
              const SizedBox(height: 24),
              const Text(
                'Stamp saved!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your moment has been added to your map.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/map'),
                child: const Text('View on Map'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/feed'),
                child: const Text('Back to Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
