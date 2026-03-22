import 'package:equatable/equatable.dart';

class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.actorId,
    this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] as int,
      actorId: json['actor_id'] as int,
      actorName: json['actor_name'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int actorId;
  final String? actorName;
  final String action;
  final String entityType;
  final String entityId;
  final String? details;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, action, entityType, entityId, createdAt];
}

class PaginatedAuditLog extends Equatable {
  const PaginatedAuditLog({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.entries,
  });

  factory PaginatedAuditLog.fromJson(Map<String, dynamic> json) {
    return PaginatedAuditLog(
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      entries: (json['entries'] as List)
          .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int total;
  final int page;
  final int pageSize;
  final List<AuditEntry> entries;

  @override
  List<Object?> get props => [total, page, pageSize, entries];
}
