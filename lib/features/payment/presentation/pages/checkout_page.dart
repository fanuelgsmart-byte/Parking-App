import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';
import 'package:parkflow_manager/features/payment/presentation/bloc/checkout_bloc.dart';

class CheckoutPage extends StatefulWidget {
  final int sessionId;

  const CheckoutPage({super.key, required this.sessionId});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<CheckoutBloc>()
        .add(CheckoutLoadSession(sessionId: widget.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            _showSuccessDialog(context, state.payment);
          }
          if (state is CheckoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CheckoutLoading) {
            return const LoadingIndicator(message: 'Loading session...');
          }
          if (state is CheckoutProcessing) {
            return const LoadingIndicator(message: 'Processing payment...');
          }
          if (state is CheckoutReady) {
            return _CheckoutReadyView(
              session: state.session,
              fee: state.fee,
              ratePerHour: state.ratePerHour,
            );
          }
          if (state is CheckoutQrGenerated) {
            return _QrPaymentView(
              session: state.session,
              fee: state.fee,
              qrCodeUrl: state.qrCodeUrl,
            );
          }
          if (state is CheckoutError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<CheckoutBloc>().add(
                          CheckoutLoadSession(sessionId: widget.sessionId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Method: ${payment.method.displayName}'),
            if (payment.transactionRef != null)
              Text('Ref: ${payment.transactionRef}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/employee');
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutReadyView extends StatelessWidget {
  final ParkingSession session;
  final double fee;
  final double ratePerHour;

  const _CheckoutReadyView({
    required this.session,
    required this.fee,
    required this.ratePerHour,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vehicle Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'License Plate',
                    value: session.vehicle.licensePlate,
                  ),
                  _DetailRow(
                    label: 'Size',
                    value: session.vehicle.size.displayName,
                  ),
                  _DetailRow(label: 'Color', value: session.vehicle.color),
                  _DetailRow(
                    label: 'Spot',
                    value: session.spotNumber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Fee Calculation Card
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Duration',
                    value: session.formattedDuration,
                  ),
                  _DetailRow(
                    label: 'Rate',
                    value: '\$${ratePerHour.toStringAsFixed(2)}/hr',
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Fee',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${fee.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Payment buttons
          FilledButton.icon(
            onPressed: () {
              context
                  .read<CheckoutBloc>()
                  .add(const CheckoutProcessCash());
            },
            icon: const Icon(Icons.money),
            label: const Text('Cash Payment'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context
                  .read<CheckoutBloc>()
                  .add(const CheckoutRequestQr());
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('Digital Payment (QR)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPaymentView extends StatelessWidget {
  final ParkingSession session;
  final double fee;
  final String qrCodeUrl;

  const _QrPaymentView({
    required this.session,
    required this.fee,
    required this.qrCodeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scan to Pay',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '\$${fee.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 24),
          // QR Code placeholder - will show actual QR from qrCodeUrl
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2, size: 120),
                  const SizedBox(height: 8),
                  Text(
                    'QR Code loaded from payment provider',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Show this QR code to the customer to scan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // In production, this would poll or use a webhook
              context.read<CheckoutBloc>().add(
                    const CheckoutConfirmDigital(
                        transactionRef: 'pending_confirmation'),
                  );
            },
            child: const Text('Confirm Payment Received'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<CheckoutBloc>().add(
                    CheckoutLoadSession(
                        sessionId: session.id),
                  );
            },
            child: const Text('Cancel & Go Back'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
