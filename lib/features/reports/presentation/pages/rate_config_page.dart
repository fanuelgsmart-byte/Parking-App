import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/di/injection.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: const Text(
                'Rate Configuration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.headerGradient),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  tooltip: 'Add Rate',
                  onPressed: () => _showAddRateSheet(context),
                ),
              ),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_rates.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else ...[
            // ── Info banner ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.infoColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.infoColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing a rate creates a new version. Previous rates are archived.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.infoColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Rate cards ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _RateCard(rate: _rates[index], onEdit: _onEditRate),
                  childCount: _rates.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No rates configured',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create default rates to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _seedDefaultRates,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Create Default Rates'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDefaultRates() async {
    final now = DateTime.now();
    for (final (size, rate) in [
      ('small', 3.0),
      ('medium', 5.0),
      ('large', 8.0),
    ]) {
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

  void _onEditRate(ParkingRateData rate) {
    _showEditRateSheet(context, rate);
  }

  void _showAddRateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRateSheet(
        lotId: widget.lotId,
        database: _database,
        onSaved: _loadRates,
      ),
    );
  }

  void _showEditRateSheet(BuildContext context, ParkingRateData rate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRateSheet(
        rate: rate,
        lotId: widget.lotId,
        database: _database,
        onSaved: _loadRates,
      ),
    );
  }
}

// ──────────────────────────── Rate Card ──────────────────────────────────────

class _RateCard extends StatelessWidget {
  final ParkingRateData rate;
  final void Function(ParkingRateData) onEdit;

  const _RateCard({required this.rate, required this.onEdit});

  static const _sizeData = {
    'small': (
      icon: Icons.two_wheeler_rounded,
      label: 'Small',
      color: AppTheme.successColor,
      desc: 'Motorcycles & compact cars',
    ),
    'medium': (
      icon: Icons.directions_car_rounded,
      label: 'Medium',
      color: AppTheme.primary,
      desc: 'Standard sedans & SUVs',
    ),
    'large': (
      icon: Icons.local_shipping_rounded,
      label: 'Large',
      color: AppTheme.warningColor,
      desc: 'Trucks & large vehicles',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final data = _sizeData[rate.vehicleSize] ??
        (
          icon: Icons.directions_car_rounded,
          label: rate.vehicleSize,
          color: AppTheme.primary,
          desc: '',
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Vehicle type icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 26),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.label} Vehicles',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  data.desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Since ${_fmt(rate.effectiveFrom)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          // Rate badge + edit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '\$${rate.ratePerHour.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: data.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                'per hour',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => onEdit(rate),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ──────────────────────────── Add Rate Sheet ─────────────────────────────────

class _AddRateSheet extends StatefulWidget {
  final String lotId;
  final AppDatabase database;
  final VoidCallback onSaved;

  const _AddRateSheet({
    required this.lotId,
    required this.database,
    required this.onSaved,
  });

  @override
  State<_AddRateSheet> createState() => _AddRateSheetState();
}

class _AddRateSheetState extends State<_AddRateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _rateCtrl = TextEditingController();
  String _selectedSize = 'medium';

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return _Sheet(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Rate',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedSize,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Size',
                  prefixIcon: Icon(Icons.directions_car_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Small')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'large', child: Text('Large')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedSize = val ?? 'medium'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rate per Hour',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.ratePerHour,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Save Rate',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop();

    // Deactivate previous
    await (widget.database.update(widget.database.parkingRates)
          ..where(
            (tbl) =>
                tbl.lotId.equals(widget.lotId) &
                tbl.vehicleSize.equals(_selectedSize) &
                tbl.isActive.equals(true),
          ))
        .write(const ParkingRatesCompanion(isActive: Value(false)));

    await widget.database.into(widget.database.parkingRates).insert(
          ParkingRatesCompanion(
            lotId: Value(widget.lotId),
            vehicleSize: Value(_selectedSize),
            ratePerHour:
                Value(double.parse(_rateCtrl.text.trim())),
            effectiveFrom: Value(DateTime.now()),
          ),
        );

    widget.onSaved();
  }
}

// ──────────────────────────── Edit Rate Sheet ────────────────────────────────

class _EditRateSheet extends StatefulWidget {
  final ParkingRateData rate;
  final String lotId;
  final AppDatabase database;
  final VoidCallback onSaved;

  const _EditRateSheet({
    required this.rate,
    required this.lotId,
    required this.database,
    required this.onSaved,
  });

  @override
  State<_EditRateSheet> createState() => _EditRateSheetState();
}

class _EditRateSheetState extends State<_EditRateSheet> {
  late final TextEditingController _rateCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(
        text: widget.rate.ratePerHour.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final sizeLabel = widget.rate.vehicleSize[0].toUpperCase() +
        widget.rate.vehicleSize.substring(1);
    return _Sheet(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit $sizeLabel Rate',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Current: \$${widget.rate.ratePerHour.toStringAsFixed(2)}/hr',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rateCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Rate per Hour',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: Validators.ratePerHour,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _update,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Update Rate',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop();

    // Deactivate old, create new (audit trail)
    await (widget.database.update(widget.database.parkingRates)
          ..where((tbl) => tbl.id.equals(widget.rate.id)))
        .write(const ParkingRatesCompanion(isActive: Value(false)));

    await widget.database.into(widget.database.parkingRates).insert(
          ParkingRatesCompanion(
            lotId: Value(widget.lotId),
            vehicleSize: Value(widget.rate.vehicleSize),
            ratePerHour:
                Value(double.parse(_rateCtrl.text.trim())),
            effectiveFrom: Value(DateTime.now()),
          ),
        );

    widget.onSaved();
  }
}

// ──────────────────────────── Sheet Container ────────────────────────────────

class _Sheet extends StatelessWidget {
  final Widget child;

  const _Sheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}
