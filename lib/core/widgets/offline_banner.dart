import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Colors.orange.shade100,
      content: const Text(
        'You are offline. Changes will sync when connection is restored.',
      ),
      leading: const Icon(Icons.wifi_off, color: Colors.orange),
      actions: [
        TextButton(
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('DISMISS'),
        ),
      ],
    );
  }
}
