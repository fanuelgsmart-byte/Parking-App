import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';
import 'package:parkflow_manager/features/payment/domain/entities/qr_payment_session.dart';
import 'package:parkflow_manager/features/payment/presentation/bloc/checkout_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.sessionId});

  final int sessionId;

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
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            _showSuccessSheet(context, state.payment);
          }
          if (state is CheckoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CheckoutLoading) {
            return const LoadingIndicator(message: 'Loading session...');
          }
          if (state is CheckoutProcessing) {
            return const LoadingIndicator(message: 'Preparing payment...');
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
              qrPaymentSession: state.qrPaymentSession,
              isPolling: state.isPolling,
            );
          }
          if (state is CheckoutError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<CheckoutBloc>()
                  .add(CheckoutLoadSession(sessionId: widget.sessionId)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, Payment payment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _SuccessSheet(
        payment: payment,
        onDone: () {
          Navigator.of(context).pop();
          context.go('/employee');
        },
      ),
    );
  }
}

class _CheckoutReadyView extends StatelessWidget {
  const _CheckoutReadyView({
    required this.session,
    required this.fee,
    required this.ratePerHour,
  });

  final ParkingSession session;
  final double fee;
  final double ratePerHour;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VehicleCard(session: session),
          const SizedBox(height: 14),
          _FeeBreakdownCard(
            session: session,
            fee: fee,
            ratePerHour: ratePerHour,
          ),
          const SizedBox(height: 24),
          _PaymentOptionCard(
            icon: Icons.payments_rounded,
            title: 'Cash Payment',
            subtitle: 'Record cash received and close the session',
            color: AppTheme.successColor,
            onTap: () =>
                context.read<CheckoutBloc>().add(const CheckoutProcessCash()),
          ),
          const SizedBox(height: 10),
          _PaymentOptionCard(
            icon: Icons.qr_code_rounded,
            title: 'Digital Payment',
            subtitle: 'Generate a QR code and wait for confirmation',
            color: AppTheme.primary,
            onTap: () =>
                context.read<CheckoutBloc>().add(const CheckoutRequestQr()),
          ),
        ],
      ),
    );
  }
}

class _QrPaymentView extends StatelessWidget {
  const _QrPaymentView({
    required this.session,
    required this.fee,
    required this.qrPaymentSession,
    required this.isPolling,
  });

  final ParkingSession session;
  final double fee;
  final QrPaymentSession qrPaymentSession;
  final bool isPolling;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Digital Payment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'The app will keep checking for confirmation while this screen stays open.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            '\$${fee.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    qrPaymentSession.qrCodeUrl,
                    height: 220,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 220,
                      width: 220,
                      child: Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 140),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reference: ${qrPaymentSession.transactionRef}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _VehicleCard(session: session),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                context.read<CheckoutBloc>().add(
                      CheckoutPollDigitalStatus(
                        transactionRef: qrPaymentSession.transactionRef,
                      ),
                    );
              },
              icon: Icon(isPolling ? Icons.sync_rounded : Icons.refresh_rounded),
              label: Text(
                isPolling ? 'Refresh Payment Status' : 'Check Payment Status',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context
                .read<CheckoutBloc>()
                .add(CheckoutLoadSession(sessionId: session.id)),
            child: const Text('Cancel Digital Payment'),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.session});

  final ParkingSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.vehicle.licensePlate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                ),
                Text(
                  '${session.vehicle.color} • ${session.vehicle.size.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Spot ${session.spotNumber}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeBreakdownCard extends StatelessWidget {
  const _FeeBreakdownCard({
    required this.session,
    required this.fee,
    required this.ratePerHour,
  });

  final ParkingSession session;
  final double fee;
  final double ratePerHour;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _FeeRow(label: 'Entry Time', value: session.entryTime.toString(), dark: true),
          _FeeRow(label: 'Duration', value: session.formattedDuration, dark: true),
          _FeeRow(
            label: 'Rate',
            value: '\$${ratePerHour.toStringAsFixed(2)}/hr',
            dark: true,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Due',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${fee.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value, this.dark = false});

  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dark
                  ? Colors.white60
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: dark ? Colors.white : null,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({required this.payment, required this.onDone});

  final Payment payment;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.successColor,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Successful!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${payment.amount.toStringAsFixed(2)} collected via ${payment.method.displayName}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

