import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';
import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';
import 'package:parkflow_manager/features/payment/domain/entities/qr_payment_session.dart';
import 'package:parkflow_manager/features/payment/domain/repositories/payment_repository.dart';
import 'package:parkflow_manager/features/reports/domain/usecases/get_effective_rate.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutLoadSession extends CheckoutEvent {
  const CheckoutLoadSession({required this.sessionId});

  final int sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class CheckoutProcessCash extends CheckoutEvent {
  const CheckoutProcessCash();
}

class CheckoutRequestQr extends CheckoutEvent {
  const CheckoutRequestQr();
}

class CheckoutPollDigitalStatus extends CheckoutEvent {
  const CheckoutPollDigitalStatus({required this.transactionRef});

  final String transactionRef;

  @override
  List<Object?> get props => [transactionRef];
}

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

class CheckoutReady extends CheckoutState {
  const CheckoutReady({
    required this.session,
    required this.fee,
    required this.ratePerHour,
  });

  final ParkingSession session;
  final double fee;
  final double ratePerHour;

  @override
  List<Object?> get props => [session, fee, ratePerHour];
}

class CheckoutQrGenerated extends CheckoutState {
  const CheckoutQrGenerated({
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
  List<Object?> get props => [session, fee, qrPaymentSession, isPolling];
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing();
}

class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess({required this.payment});

  final Payment payment;

  @override
  List<Object?> get props => [payment];
}

class CheckoutError extends CheckoutState {
  const CheckoutError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

@injectable
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required this.sessionRepository,
    required this.paymentRepository,
    required this.getEffectiveRateUseCase,
  }) : super(const CheckoutInitial()) {
    on<CheckoutLoadSession>(_onLoadSession);
    on<CheckoutProcessCash>(_onProcessCash);
    on<CheckoutRequestQr>(_onRequestQr);
    on<CheckoutPollDigitalStatus>(_onPollDigitalStatus);
  }

  final ParkingSessionRepository sessionRepository;
  final PaymentRepository paymentRepository;
  final GetEffectiveRateUseCase getEffectiveRateUseCase;

  ParkingSession? _currentSession;
  double _currentFee = 0;
  Timer? _paymentPollTimer;
  QrPaymentSession? _currentQrSession;

  Future<void> _onLoadSession(
    CheckoutLoadSession event,
    Emitter<CheckoutState> emit,
  ) async {
    _stopPolling();
    emit(const CheckoutLoading());
    final result = await sessionRepository.getSessionById(event.sessionId);
    await result.fold(
      (failure) async => emit(CheckoutError(message: failure.message)),
      (session) async {
        final rateResult = await getEffectiveRateUseCase(
          GetEffectiveRateParams(
            lotId: session.lotId,
            vehicleSize: session.vehicle.size,
            at: session.entryTime,
          ),
        );
        rateResult.fold(
          (failure) => emit(CheckoutError(message: failure.message)),
          (ratePerHour) {
            _currentSession = session;
            _currentFee = _calculateFee(session: session, ratePerHour: ratePerHour);
            emit(
              CheckoutReady(
                session: session,
                fee: _currentFee,
                ratePerHour: ratePerHour,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onProcessCash(
    CheckoutProcessCash event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) return;

    emit(const CheckoutProcessing());

    final paymentResult = await paymentRepository.processPayment(
      sessionId: _currentSession!.id,
      amount: _currentFee,
      method: PaymentMethod.cash,
    );

    await paymentResult.fold(
      (failure) async => emit(CheckoutError(message: failure.message)),
      (payment) async {
        final completeResult = await sessionRepository.completeSession(
          _currentSession!.id,
          totalFee: _currentFee,
        );
        completeResult.fold(
          (failure) => emit(CheckoutError(message: failure.message)),
          (_) => emit(CheckoutSuccess(payment: payment)),
        );
      },
    );
  }

  Future<void> _onRequestQr(
    CheckoutRequestQr event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) return;

    emit(const CheckoutProcessing());

    final pendingPayment = await paymentRepository.processPayment(
      sessionId: _currentSession!.id,
      amount: _currentFee,
      method: PaymentMethod.digital,
    );
    if (pendingPayment.isLeft) {
      pendingPayment.fold(
        (failure) => emit(CheckoutError(message: failure.message)),
        (_) {},
      );
      return;
    }

    final sessionResult = await sessionRepository.markPaymentPending(
      _currentSession!.id,
    );
    if (sessionResult.isLeft) {
      sessionResult.fold(
        (failure) => emit(CheckoutError(message: failure.message)),
        (_) {},
      );
      return;
    }

    final qrResult = await paymentRepository.fetchQrCode(
      _currentSession!.id,
      _currentFee,
    );

    qrResult.fold(
      (failure) => emit(CheckoutError(message: failure.message)),
      (qrSession) {
        _currentQrSession = qrSession;
        emit(
          CheckoutQrGenerated(
            session: _currentSession!,
            fee: _currentFee,
            qrPaymentSession: qrSession,
            isPolling: true,
          ),
        );
        _startPolling(qrSession.transactionRef);
      },
    );
  }

  Future<void> _onPollDigitalStatus(
    CheckoutPollDigitalStatus event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null || _currentQrSession == null) return;

    final result =
        await paymentRepository.confirmDigitalPayment(event.transactionRef);

    await result.fold(
      (failure) async {
        _stopPolling();
        emit(CheckoutError(message: failure.message));
      },
      (payment) async {
        if (payment.status == PaymentStatus.completed) {
          _stopPolling();
          final completeResult = await sessionRepository.completeSession(
            _currentSession!.id,
            totalFee: _currentFee,
          );
          completeResult.fold(
            (failure) => emit(CheckoutError(message: failure.message)),
            (_) => emit(CheckoutSuccess(payment: payment)),
          );
          return;
        }

        if (payment.status == PaymentStatus.failed) {
          _stopPolling();
          emit(
            const CheckoutError(
              message: 'Digital payment failed. Please try again or use cash.',
            ),
          );
          return;
        }

        emit(
          CheckoutQrGenerated(
            session: _currentSession!,
            fee: _currentFee,
            qrPaymentSession: _currentQrSession!,
            isPolling: true,
          ),
        );
      },
    );
  }

  void _startPolling(String transactionRef) {
    _stopPolling();
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(CheckoutPollDigitalStatus(transactionRef: transactionRef));
    });
  }

  void _stopPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = null;
  }

  double _calculateFee({
    required ParkingSession session,
    required double ratePerHour,
  }) {
    final duration = session.duration;
    final hours = duration.inMinutes / 60.0;
    final chargeableHours = hours < 1.0 ? 1.0 : hours;
    final roundedHours = (chargeableHours * 4).ceil() / 4.0;
    return roundedHours * ratePerHour;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}

