import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_spot.dart';
import 'package:parkflow_manager/features/lot_map/domain/repositories/lot_repository.dart';

// ──────────────────────────── State ────────────────────────────

abstract class LotMapState extends Equatable {
  const LotMapState();

  @override
  List<Object?> get props => [];
}

class LotMapInitial extends LotMapState {
  const LotMapInitial();
}

class LotMapLoading extends LotMapState {
  const LotMapLoading();
}

class LotMapLoaded extends LotMapState {
  final List<ParkingSpot> spots;
  final int totalSpots;
  final int availableSpots;

  const LotMapLoaded({
    required this.spots,
    required this.totalSpots,
    required this.availableSpots,
  });

  @override
  List<Object?> get props => [spots, totalSpots, availableSpots];
}

class LotMapError extends LotMapState {
  final String message;

  const LotMapError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────── Cubit ────────────────────────────

@injectable
class LotMapCubit extends Cubit<LotMapState> {
  final LotRepository lotRepository;
  StreamSubscription<List<ParkingSpot>>? _spotsSubscription;

  LotMapCubit({required this.lotRepository}) : super(const LotMapInitial());

  Future<void> loadSpots(String lotId) async {
    emit(const LotMapLoading());
    final result = await lotRepository.getSpots(lotId);
    result.fold(
      (failure) => emit(LotMapError(message: failure.message)),
      (spots) {
        _emitLoaded(spots);
        _watchSpots(lotId);
      },
    );
  }

  void _watchSpots(String lotId) {
    _spotsSubscription?.cancel();
    _spotsSubscription = lotRepository.watchSpots(lotId).listen(
          (spots) => _emitLoaded(spots),
        );
  }

  void _emitLoaded(List<ParkingSpot> spots) {
    final available =
        spots.where((s) => s.status == SpotStatus.available).length;
    emit(LotMapLoaded(
      spots: spots,
      totalSpots: spots.length,
      availableSpots: available,
    ));
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    return super.close();
  }
}
