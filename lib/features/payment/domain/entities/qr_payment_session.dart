import 'package:equatable/equatable.dart';

class QrPaymentSession extends Equatable {
  const QrPaymentSession({
    required this.qrCodeUrl,
    required this.transactionRef,
  });

  final String qrCodeUrl;
  final String transactionRef;

  @override
  List<Object?> get props => [qrCodeUrl, transactionRef];
}
