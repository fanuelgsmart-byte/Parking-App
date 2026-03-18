import 'package:equatable/equatable.dart';

class ReportPayload<T> extends Equatable {
  const ReportPayload({
    required this.data,
    required this.isStale,
    this.cachedAt,
  });

  final T data;
  final bool isStale;
  final DateTime? cachedAt;

  @override
  List<Object?> get props => [data, isStale, cachedAt];
}
