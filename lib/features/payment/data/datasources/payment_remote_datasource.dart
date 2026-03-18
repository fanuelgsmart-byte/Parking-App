import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/payment/data/models/payment_model.dart';
import 'package:parkflow_manager/features/payment/domain/entities/qr_payment_session.dart';

abstract class PaymentRemoteDataSource {
  Future<QrPaymentSession> fetchQrCode(int sessionId, double amount);
  Future<PaymentModel> confirmDigitalPayment(String transactionRef);
  Future<PaymentModel> submitPayment(Map<String, dynamic> data);
}

@Injectable(as: PaymentRemoteDataSource)
class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<QrPaymentSession> fetchQrCode(int sessionId, double amount) async {
    try {
      final response = await apiClient.post(
        ApiConstants.paymentQr,
        data: {'session_id': sessionId, 'amount': amount},
      );
      final data = response.data as Map<String, dynamic>;
      final qrCodeUrl = data['qr_code_url'] as String?;
      final transactionRef = data['transaction_ref'] as String?;
      if (qrCodeUrl == null || transactionRef == null) {
        throw const ServerException(
          message: 'QR payment response is missing required fields.',
        );
      }
      return QrPaymentSession(
        qrCodeUrl: qrCodeUrl,
        transactionRef: transactionRef,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaymentModel> confirmDigitalPayment(String transactionRef) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.payments}/$transactionRef/status',
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaymentModel> submitPayment(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(
        ApiConstants.payments,
        data: data,
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
