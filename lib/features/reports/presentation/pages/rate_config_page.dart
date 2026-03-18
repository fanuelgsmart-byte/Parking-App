import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/utils/validators.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/reports/domain/entities/parking_rate_config.dart';
import 'package:parkflow_manager/features/reports/presentation/bloc/rate_config_cubit.dart';

class RateConfigPage extends StatelessWidget {
  const RateConfigPage({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Rate Configuration')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRateSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<RateConfigCubit, RateConfigState>(
        listener: (context, state) {
          if (state is RateConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is RateConfigLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RateConfigLoaded && state.rates.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.rates.length,
              itemBuilder: (context, index) {
                final rate = state.rates[index];
                return Card(
                  child: ListTile(
                    title: Text(rate.vehicleSize.displayName),
                    subtitle: Text('Since ${_formatDate(rate.effectiveFrom)}'),
                    trailing: Text(
                      '\$${rate.ratePerHour.toStringAsFixed(2)}/hr',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => _showRateSheet(context, current: rate),
                  ),
                );
              },
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No rates configured yet.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<RateConfigCubit>().seedDefaultRates(lotId),
                  child: const Text('Create Default Rates'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRateSheet(BuildContext context, {ParkingRateConfig? current}) {
    final formKey = GlobalKey<FormState>();
    final rateCtrl = TextEditingController(
      text: current?.ratePerHour.toStringAsFixed(2) ?? '',
    );
    VehicleSize selectedSize = current?.vehicleSize ?? VehicleSize.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current == null ? 'Add Rate' : 'Update Rate',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<VehicleSize>(
                initialValue: selectedSize,
                items: VehicleSize.values
                    .map(
                      (size) => DropdownMenuItem(
                        value: size,
                        child: Text(size.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedSize = value ?? VehicleSize.medium,
                decoration: const InputDecoration(labelText: 'Vehicle Size'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rateCtrl,
                decoration: const InputDecoration(labelText: 'Rate per Hour'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.ratePerHour,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(sheetContext).pop();
                    context.read<RateConfigCubit>().upsertRate(
                          lotId: lotId,
                          vehicleSize: selectedSize,
                          ratePerHour: double.parse(rateCtrl.text.trim()),
                        );
                  },
                  child: Text(current == null ? 'Save Rate' : 'Update Rate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
