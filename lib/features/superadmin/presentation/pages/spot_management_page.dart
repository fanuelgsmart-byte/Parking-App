import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class SpotManagementPage extends StatelessWidget {
  const SpotManagementPage({super.key, required this.lotId, required this.lotName});
  final String lotId;
  final String lotName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Spots — $lotName'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.tealGradient)),
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
                  return const Padding(padding: EdgeInsets.only(top: 100), child: LoadingIndicator(message: 'Loading spots...'));
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: ErrorDisplay(message: state.message, onRetry: () => context.read<SuperadminCubit>().loadSpots(lotId)),
                  );
                }
                if (state is SuperadminSpotsLoaded) {
                  return _SpotGrid(spots: state.spots, lotId: lotId);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSpotSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSpotSheet(BuildContext context) {
    final cubit = context.read<SuperadminCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpotFormSheet(
        onSave: (number, size, row, col) => cubit.createSpot(lotId, spotNumber: number, size: size, row: row, col: col),
      ),
    );
  }
}

class _SpotGrid extends StatelessWidget {
  const _SpotGrid({required this.spots, required this.lotId});
  final List<SpotDetail> spots;
  final String lotId;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(child: Text('No spots yet. Tap + to add spots.')),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: spots.length,
      itemBuilder: (context, i) {
        final spot = spots[i];
        final isOccupied = spot.status == 'occupied';
        return GestureDetector(
          onLongPress: () => _showSpotOptions(context, spot),
          child: Container(
            decoration: BoxDecoration(
              color: isOccupied ? AppTheme.spotOccupied.withValues(alpha: 0.15) : AppTheme.spotAvailable.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isOccupied ? AppTheme.spotOccupied : AppTheme.spotAvailable),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(spot.spotNumber, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(spot.size[0].toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpotOptions(BuildContext context, SpotDetail spot) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('Edit ${spot.spotNumber}'),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(context, spot);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.errorColor),
              title: Text('Delete ${spot.spotNumber}', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                context.read<SuperadminCubit>().deleteSpot(lotId, spot.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, SpotDetail spot) {
    final cubit = context.read<SuperadminCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpotFormSheet(
        initialNumber: spot.spotNumber,
        initialSize: spot.size,
        initialRow: spot.row,
        initialCol: spot.col,
        onSave: (number, size, row, col) => cubit.updateSpot(lotId, spot.id, spotNumber: number, size: size, row: row, col: col),
      ),
    );
  }
}

class _SpotFormSheet extends StatefulWidget {
  const _SpotFormSheet({this.initialNumber, this.initialSize, this.initialRow, this.initialCol, required this.onSave});
  final String? initialNumber;
  final String? initialSize;
  final int? initialRow;
  final int? initialCol;
  final void Function(String number, String size, int? row, int? col) onSave;

  @override
  State<_SpotFormSheet> createState() => _SpotFormSheetState();
}

class _SpotFormSheetState extends State<_SpotFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _rowCtrl;
  late final TextEditingController _colCtrl;
  late String _size;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(text: widget.initialNumber);
    _rowCtrl = TextEditingController(text: widget.initialRow?.toString());
    _colCtrl = TextEditingController(text: widget.initialCol?.toString());
    _size = widget.initialSize ?? 'medium';
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _rowCtrl.dispose();
    _colCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialNumber != null;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Spot' : 'Add Spot', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(labelText: 'Spot Number (e.g. A1)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _size,
                decoration: const InputDecoration(labelText: 'Size'),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Small')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'large', child: Text('Large')),
                ],
                onChanged: (v) => setState(() => _size = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _rowCtrl, decoration: const InputDecoration(labelText: 'Row'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _colCtrl, decoration: const InputDecoration(labelText: 'Col'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    widget.onSave(
                      _numberCtrl.text.trim(),
                      _size,
                      int.tryParse(_rowCtrl.text),
                      int.tryParse(_colCtrl.text),
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
