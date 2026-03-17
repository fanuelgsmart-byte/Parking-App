import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/payment/data/models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<String> fetchQrCode(int sessionId, double amount);
  Future<PaymentModel> confirmDigitalPayment(String transactionRef);
  Future<PaymentModel> submitPayment(Map<String, dynamic> data);
}

@Injectable(as: PaymentRemoteDataSource)
class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {

  PaymentRemoteDataSourceImpl({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<String> fetchQrCode(int sessionId, double amount) async {
    try {
      final response = await apiClient.post(
        ApiConstants.paymentQr,
        data: {'session_id': sessionId, 'amount': amount},
      );
      return response.data['qr_code_url'] as String;
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
      return PaymentModel.fromJson(
        response.data as Map<String, dynamic>,
      );
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
      return PaymentModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
