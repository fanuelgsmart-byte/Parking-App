import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  final int sessionId;

  const CheckoutPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session #$sessionId',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    // Vehicle info, duration, fee will be populated via BLoC
                    const Text('Loading session details...'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Payment buttons
            FilledButton.icon(
              onPressed: () {
                // Process cash payment
              },
              icon: const Icon(Icons.money),
              label: const Text('Cash Payment'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Generate QR code for digital payment
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Digital Payment (QR)'),
            ),
          ],
        ),
      ),
    );
  }
}
