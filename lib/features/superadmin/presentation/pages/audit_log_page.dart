import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/audit_entry.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  String? _entityFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Audit Log'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'All', selected: _entityFilter == null, onTap: () => _applyFilter(null)),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Lots', selected: _entityFilter == 'lot', onTap: () => _applyFilter('lot')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Spots', selected: _entityFilter == 'spot', onTap: () => _applyFilter('spot')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Employees', selected: _entityFilter == 'employee', onTap: () => _applyFilter('employee')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Cameras', selected: _entityFilter == 'camera', onTap: () => _applyFilter('camera')),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<SuperadminCubit, SuperadminState>(
              builder: (context, state) {
                if (state is SuperadminLoading) {
                  return const Padding(padding: EdgeInsets.only(top: 80), child: LoadingIndicator(message: 'Loading audit log...'));
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: ErrorDisplay(message: state.message, onRetry: () => context.read<SuperadminCubit>().loadAuditLog(entityType: _entityFilter)),
                  );
                }
                if (state is SuperadminAuditLogLoaded) {
                  return _AuditList(auditLog: state.auditLog, onPageChange: _loadPage);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter(String? entityType) {
    setState(() => _entityFilter = entityType);
    context.read<SuperadminCubit>().loadAuditLog(entityType: entityType);
  }

  void _loadPage(int page) {
    context.read<SuperadminCubit>().loadAuditLog(page: page, entityType: _entityFilter);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _AuditList extends StatelessWidget {
  const _AuditList({required this.auditLog, required this.onPageChange});
  final PaginatedAuditLog auditLog;
  final void Function(int page) onPageChange;

  @override
  Widget build(BuildContext context) {
    if (auditLog.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text('No audit entries found.')),
      );
    }
    final totalPages = (auditLog.total / auditLog.pageSize).ceil();
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: auditLog.entries.length,
          itemBuilder: (context, i) {
            final entry = auditLog.entries[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: _actionIcon(entry.action),
                title: Text(_formatAction(entry.action), style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.entityType} #${entry.entityId}'),
                    Text(
                      '${entry.actorName ?? 'Unknown'} • ${_formatTime(entry.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: entry.details != null
                    ? IconButton(
                        icon: const Icon(Icons.info_outline, size: 18),
                        onPressed: () => _showDetails(context, entry),
                      )
                    : null,
              ),
            );
          },
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: auditLog.page > 1 ? () => onPageChange(auditLog.page - 1) : null,
                ),
                Text('Page ${auditLog.page} of $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: auditLog.page < totalPages ? () => onPageChange(auditLog.page + 1) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _actionIcon(String action) {
    IconData icon;
    Color color;
    if (action.contains('created')) {
      icon = Icons.add_circle_outline;
      color = AppTheme.successColor;
    } else if (action.contains('updated')) {
      icon = Icons.edit_outlined;
      color = AppTheme.primary;
    } else if (action.contains('deleted') || action.contains('deactivated')) {
      icon = Icons.remove_circle_outline;
      color = AppTheme.errorColor;
    } else {
      icon = Icons.info_outline;
      color = AppTheme.warningColor;
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      radius: 18,
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').replaceFirst(action[0], action[0].toUpperCase());
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showDetails(BuildContext context, AuditEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_formatAction(entry.action)),
        content: SingleChildScrollView(child: Text(entry.details ?? '')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
