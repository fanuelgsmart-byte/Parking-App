import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/reports/domain/entities/parking_rate_config.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/rate_repository.dart';

abstract class RateConfigState extends Equatable {
  const RateConfigState();

  @override
  List<Object?> get props => [];
}

class RateConfigInitial extends RateConfigState {
  const RateConfigInitial();
}

class RateConfigLoading extends RateConfigState {
  const RateConfigLoading();
}

class RateConfigLoaded extends RateConfigState {
  const RateConfigLoaded({required this.rates});

  final List<ParkingRateConfig> rates;

  @override
  List<Object?> get props => [rates];
}

class RateConfigError extends RateConfigState {
  const RateConfigError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

@injectable
class RateConfigCubit extends Cubit<RateConfigState> {
  RateConfigCubit({required this.repository}) : super(const RateConfigInitial());

  final RateRepository repository;
  String? _lotId;

  Future<void> loadRates(String lotId) async {
    _lotId = lotId;
    emit(const RateConfigLoading());
    final result = await repository.getActiveRates(lotId);
    result.fold(
      (failure) => emit(RateConfigError(message: failure.message)),
      (rates) => emit(RateConfigLoaded(rates: rates)),
    );
  }

  Future<void> seedDefaultRates(String lotId) async {
    emit(const RateConfigLoading());
    final result = await repository.seedDefaultRates(lotId);
    await result.fold(
      (failure) async => emit(RateConfigError(message: failure.message)),
      (_) async => loadRates(lotId),
    );
  }

  Future<void> upsertRate({
    required String lotId,
    required VehicleSize vehicleSize,
    required double ratePerHour,
  }) async {
    emit(const RateConfigLoading());
    final result = await repository.upsertRate(lotId, vehicleSize, ratePerHour);
    await result.fold(
      (failure) async => emit(RateConfigError(message: failure.message)),
      (_) async => loadRates(lotId),
    );
  }

  String get currentLotId => _lotId ?? '';
}
