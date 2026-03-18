import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';
import 'package:parkflow_manager/features/payment/domain/entities/qr_payment_session.dart';

abstract class PaymentRepository {
  Future<Either<Failure, Payment>> processPayment({
    required int sessionId,
    required double amount,
    required PaymentMethod method,
  });

  Future<Either<Failure, QrPaymentSession>> fetchQrCode(
    int sessionId,
    double amount,
  );

  Future<Either<Failure, Payment>> confirmDigitalPayment(String transactionRef);

  Future<Either<Failure, Payment>> recordCashPayment({
    required int sessionId,
    required double amount,
  });

  Future<Either<Failure, List<Payment>>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  );
}
