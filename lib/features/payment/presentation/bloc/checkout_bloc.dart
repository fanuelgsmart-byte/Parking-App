import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';
import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';
import 'package:parkflow_manager/features/payment/domain/repositories/payment_repository.dart';
import 'package:parkflow_manager/features/payment/domain/usecases/calculate_fee.dart';

// ──────────────────────────── Events ────────────────────────────

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutLoadSession extends CheckoutEvent {
  final int sessionId;

  const CheckoutLoadSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class CheckoutProcessCash extends CheckoutEvent {
  const CheckoutProcessCash();
}

class CheckoutRequestQr extends CheckoutEvent {
  const CheckoutRequestQr();
}

class CheckoutConfirmDigital extends CheckoutEvent {
  final String transactionRef;

  const CheckoutConfirmDigital({required this.transactionRef});

  @override
  List<Object?> get props => [transactionRef];
}

// ──────────────────────────── States ────────────────────────────

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
  final ParkingSession session;
  final double fee;
  final double ratePerHour;

  const CheckoutReady({
    required this.session,
    required this.fee,
    required this.ratePerHour,
  });

  @override
  List<Object?> get props => [session, fee, ratePerHour];
}

class CheckoutQrGenerated extends CheckoutState {
  final ParkingSession session;
  final double fee;
  final String qrCodeUrl;

  const CheckoutQrGenerated({
    required this.session,
    required this.fee,
    required this.qrCodeUrl,
  });

  @override
  List<Object?> get props => [session, fee, qrCodeUrl];
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing();
}

class CheckoutSuccess extends CheckoutState {
  final Payment payment;

  const CheckoutSuccess({required this.payment});

  @override
  List<Object?> get props => [payment];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────── BLoC ────────────────────────────

@injectable
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final ParkingSessionRepository sessionRepository;
  final PaymentRepository paymentRepository;
  final CalculateFee calculateFee;

  ParkingSession? _currentSession;
  double _currentFee = 0;
  // Default rate; will be fetched from rate config in production
  final double _ratePerHour = 5.0;

  CheckoutBloc({
    required this.sessionRepository,
    required this.paymentRepository,
    required this.calculateFee,
  }) : super(const CheckoutInitial()) {
    on<CheckoutLoadSession>(_onLoadSession);
    on<CheckoutProcessCash>(_onProcessCash);
    on<CheckoutRequestQr>(_onRequestQr);
    on<CheckoutConfirmDigital>(_onConfirmDigital);
  }

  Future<void> _onLoadSession(
    CheckoutLoadSession event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());
    final result = await sessionRepository.getSessionById(event.sessionId);
    result.fold(
      (failure) => emit(CheckoutError(message: failure.message)),
      (session) {
        _currentSession = session;
        _currentFee = calculateFee(
          session: session,
          ratePerHour: _ratePerHour,
        );
        emit(CheckoutReady(
          session: session,
          fee: _currentFee,
          ratePerHour: _ratePerHour,
        ));
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
        // Complete the session
        await sessionRepository.completeSession(
          _currentSession!.id,
          totalFee: _currentFee,
        );
        emit(CheckoutSuccess(payment: payment));
      },
    );
  }

  Future<void> _onRequestQr(
    CheckoutRequestQr event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) return;

    emit(const CheckoutProcessing());

    final qrResult = await paymentRepository.fetchQrCode(
      _currentSession!.id,
      _currentFee,
    );

    qrResult.fold(
      (failure) => emit(CheckoutError(message: failure.message)),
      (qrUrl) => emit(CheckoutQrGenerated(
        session: _currentSession!,
        fee: _currentFee,
        qrCodeUrl: qrUrl,
      )),
    );
  }

  Future<void> _onConfirmDigital(
    CheckoutConfirmDigital event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) return;

    emit(const CheckoutProcessing());

    final result =
        await paymentRepository.confirmDigitalPayment(event.transactionRef);

    await result.fold(
      (failure) async => emit(CheckoutError(message: failure.message)),
      (payment) async {
        await sessionRepository.completeSession(
          _currentSession!.id,
          totalFee: _currentFee,
        );
        emit(CheckoutSuccess(payment: payment));
      },
    );
  }
}
