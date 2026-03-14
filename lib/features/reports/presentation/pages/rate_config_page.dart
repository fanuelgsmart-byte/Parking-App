import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/di/injection.dart';
import 'package:parkflow_manager/core/utils/validators.dart';

/// Allows managers to configure per-size hourly parking rates.
class RateConfigPage extends StatefulWidget {
  final String lotId;

  const RateConfigPage({super.key, required this.lotId});

  @override
  State<RateConfigPage> createState() => _RateConfigPageState();
}

class _RateConfigPageState extends State<RateConfigPage> {
  final _database = getIt<AppDatabase>();
  List<ParkingRateData> _rates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final rates = await (_database.select(_database.parkingRates)
          ..where(
            (tbl) =>
                tbl.lotId.equals(widget.lotId) & tbl.isActive.equals(true),
          ))
        .get();
    setState(() {
      _rates = rates;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Configuration')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Rate'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rates.isEmpty
              ? _buildEmptyState()
              : _buildRateList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No rates configured',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _seedDefaultRates(),
            child: const Text('Create Default Rates'),
          ),
        ],
      ),
    );
  }

  Widget _buildRateList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rates.length,
      itemBuilder: (context, index) {
        final rate = _rates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_sizeIcon(rate.vehicleSize)),
            ),
            title: Text(
              '${rate.vehicleSize[0].toUpperCase()}${rate.vehicleSize.substring(1)} vehicles',
            ),
            subtitle: Text(
              'Effective from: ${_fmt(rate.effectiveFrom)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${rate.ratePerHour.toStringAsFixed(2)}/hr',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditRateDialog(context, rate),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seedDefaultRates() async {
    final now = DateTime.now();
    final defaults = [
      ('small', 3.0),
      ('medium', 5.0),
      ('large', 8.0),
    ];

    for (final (size, rate) in defaults) {
      await _database.into(_database.parkingRates).insert(
            ParkingRatesCompanion(
              lotId: Value(widget.lotId),
              vehicleSize: Value(size),
              ratePerHour: Value(rate),
              effectiveFrom: Value(now),
            ),
          );
    }

    await _loadRates();
  }

  void _showAddRateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final rateController = TextEditingController();
    String selectedSize = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Rate'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Size',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'small', child: Text('Small')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'large', child: Text('Large')),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedSize = val ?? 'medium'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Rate per Hour (\$)',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.ratePerHour,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();

                // Deactivate previous rate for this size
                await (_database.update(_database.parkingRates)
                      ..where(
                        (tbl) =>
                            tbl.lotId.equals(widget.lotId) &
                            tbl.vehicleSize.equals(selectedSize) &
                            tbl.isActive.equals(true),
                      ))
                    .write(const ParkingRatesCompanion(
                        isActive: Value(false)));

                await _database.into(_database.parkingRates).insert(
                      ParkingRatesCompanion(
                        lotId: Value(widget.lotId),
                        vehicleSize: Value(selectedSize),
                        ratePerHour:
                            Value(double.parse(rateController.text.trim())),
                        effectiveFrom: Value(DateTime.now()),
                      ),
                    );

                await _loadRates();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRateDialog(BuildContext context, ParkingRateData rate) {
    final formKey = GlobalKey<FormState>();
    final rateController =
        TextEditingController(text: rate.ratePerHour.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${rate.vehicleSize} rate'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: rateController,
            decoration: const InputDecoration(
              labelText: 'Rate per Hour (\$)',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.ratePerHour,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();

              // Deactivate old, create new (audit trail)
              await (_database.update(_database.parkingRates)
                    ..where((tbl) => tbl.id.equals(rate.id)))
                  .write(const ParkingRatesCompanion(
                      isActive: Value(false)));

              await _database.into(_database.parkingRates).insert(
                    ParkingRatesCompanion(
                      lotId: Value(widget.lotId),
                      vehicleSize: Value(rate.vehicleSize),
                      ratePerHour:
                          Value(double.parse(rateController.text.trim())),
                      effectiveFrom: Value(DateTime.now()),
                    ),
                  );

              await _loadRates();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  IconData _sizeIcon(String size) {
    switch (size) {
      case 'small':
        return Icons.two_wheeler;
      case 'large':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
