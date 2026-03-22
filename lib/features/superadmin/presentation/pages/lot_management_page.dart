import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class LotManagementPage extends StatelessWidget {
  const LotManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Lot Management'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocConsumer<SuperadminCubit, SuperadminState>(
              listener: (context, state) {
                if (state is SuperadminActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is SuperadminLoading) {
                  return const Padding(padding: EdgeInsets.only(top: 100), child: LoadingIndicator(message: 'Loading lots...'));
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: ErrorDisplay(message: state.message, onRetry: () => context.read<SuperadminCubit>().loadLots()),
                  );
                }
                if (state is SuperadminLotsLoaded) {
                  return _LotList(lots: state.lots);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLotSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLotSheet(BuildContext context) {
    final cubit = context.read<SuperadminCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LotFormSheet(
        onSave: (name, address, tz) => cubit.createLot(name: name, address: address, timezone: tz),
      ),
    );
  }
}

class _LotList extends StatelessWidget {
  const _LotList({required this.lots});
  final List<LotDetail> lots;

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(child: Text('No parking lots yet. Tap + to create one.')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: lots.length,
      itemBuilder: (context, i) => _LotCard(lot: lots[i]),
    );
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.lot});
  final LotDetail lot;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/superadmin/lots/${lot.id}/spots?lotName=${Uri.encodeComponent(lot.name)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(lot.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _showEditSheet(context);
                      if (action == 'delete') _confirmDelete(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (lot.address != null) ...[
                const SizedBox(height: 4),
                Text(lot.address!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _Chip(icon: Icons.grid_view, label: '${lot.spotCount} spots'),
                  const SizedBox(width: 8),
                  _Chip(icon: Icons.people, label: '${lot.employeeCount} staff'),
                  const SizedBox(width: 8),
                  _Chip(icon: Icons.videocam, label: '${lot.cameraCount} cams'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: lot.spotCount > 0 ? lot.occupiedCount / lot.spotCount : 0,
                backgroundColor: AppTheme.spotAvailable.withValues(alpha: 0.2),
                color: lot.occupiedCount / (lot.spotCount > 0 ? lot.spotCount : 1) > 0.8
                    ? AppTheme.spotOccupied
                    : AppTheme.spotAvailable,
              ),
              const SizedBox(height: 4),
              Text(
                '${lot.occupiedCount}/${lot.spotCount} occupied',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final cubit = context.read<SuperadminCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LotFormSheet(
        initialName: lot.name,
        initialAddress: lot.address,
        initialTimezone: lot.timezone,
        onSave: (name, address, tz) => cubit.updateLot(lot.id, name: name, address: address, timezone: tz),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lot'),
        content: Text('Delete "${lot.name}" and all its spots, cameras, and rates? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(context);
              context.read<SuperadminCubit>().deleteLot(lot.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _LotFormSheet extends StatefulWidget {
  const _LotFormSheet({
    this.initialName,
    this.initialAddress,
    this.initialTimezone,
    required this.onSave,
  });

  final String? initialName;
  final String? initialAddress;
  final String? initialTimezone;
  final void Function(String name, String? address, String timezone) onSave;

  @override
  State<_LotFormSheet> createState() => _LotFormSheetState();
}

class _LotFormSheetState extends State<_LotFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _tzCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _addressCtrl = TextEditingController(text: widget.initialAddress);
    _tzCtrl = TextEditingController(text: widget.initialTimezone ?? 'UTC');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Lot' : 'Add Lot', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Lot Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address (optional)')),
              const SizedBox(height: 12),
              TextFormField(controller: _tzCtrl, decoration: const InputDecoration(labelText: 'Timezone')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    widget.onSave(
                      _nameCtrl.text.trim(),
                      _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                      _tzCtrl.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
