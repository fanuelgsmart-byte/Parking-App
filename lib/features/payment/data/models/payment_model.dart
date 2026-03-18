import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.sessionId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionRef,
    this.paidAt,
    required this.isSynced,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      status: json['status'] as String,
      transactionRef: json['transaction_ref'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      isSynced: json['is_synced'] as bool? ?? true,
    );
  }

  final int id;
  final int sessionId;
  final double amount;
  final String method;
  final String status;
  final String? transactionRef;
  final DateTime? paidAt;
  final bool isSynced;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'amount': amount,
      'method': method,
      'status': status,
      'transaction_ref': transactionRef,
      'paid_at': paidAt?.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  Payment toEntity() {
    return Payment(
      id: id,
      sessionId: sessionId,
      amount: amount,
      method: method == 'cash' ? PaymentMethod.cash : PaymentMethod.digital,
      status: parseStatus(status),
      transactionRef: transactionRef,
      paidAt: paidAt,
      isSynced: isSynced,
    );
  }

  static PaymentStatus parseStatus(String status) {
    switch (status) {
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  static String statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
    }
  }
}
