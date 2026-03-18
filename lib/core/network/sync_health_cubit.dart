import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/network/sync_service.dart';

abstract class SyncHealthState extends Equatable {
  const SyncHealthState();

  @override
  List<Object?> get props => [];
}

class SyncHealthInitial extends SyncHealthState {
  const SyncHealthInitial();
}

class SyncHealthLoading extends SyncHealthState {
  const SyncHealthLoading();
}

class SyncHealthLoaded extends SyncHealthState {
  const SyncHealthLoaded({required this.deadLetterCount});

  final int deadLetterCount;

  @override
  List<Object?> get props => [deadLetterCount];
}

class SyncHealthError extends SyncHealthState {
  const SyncHealthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

@injectable
class SyncHealthCubit extends Cubit<SyncHealthState> {
  SyncHealthCubit({required this.syncService}) : super(const SyncHealthInitial());

  final SyncService syncService;

  Future<void> load() async {
    emit(const SyncHealthLoading());
    try {
      final count = await syncService.deadLetterCount();
      emit(SyncHealthLoaded(deadLetterCount: count));
    } catch (e) {
      emit(SyncHealthError(message: e.toString()));
    }
  }
}
