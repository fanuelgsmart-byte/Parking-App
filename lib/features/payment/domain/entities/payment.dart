import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required int id,
    required int sessionId,
    required double amount,
    required PaymentMethod method,
    required PaymentStatus status,
    String? transactionRef,
    DateTime? paidAt,
    required bool isSynced,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}

enum PaymentMethod {
  cash,
  digital;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.digital:
        return 'Digital (QR)';
    }
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
}
