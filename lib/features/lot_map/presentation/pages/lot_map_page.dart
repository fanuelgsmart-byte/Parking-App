import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_spot.dart';
import 'package:parkflow_manager/features/lot_map/presentation/bloc/lot_map_cubit.dart';

class LotMapPage extends StatelessWidget {
  const LotMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lot Map'),
      ),
      body: BlocBuilder<LotMapCubit, LotMapState>(
        builder: (context, state) {
          if (state is LotMapLoading) {
            return const LoadingIndicator(message: 'Loading lot map...');
          }
          if (state is LotMapError) {
            return ErrorDisplay(message: state.message);
          }
          if (state is LotMapLoaded) {
            return Column(
              children: [
                _OccupancySummary(
                  total: state.totalSpots,
                  available: state.availableSpots,
                ),
                const SizedBox(height: 8),
                const _Legend(),
                const SizedBox(height: 8),
                Expanded(
                  child: _SpotGrid(spots: state.spots),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OccupancySummary extends StatelessWidget {
  final int total;
  final int available;

  const _OccupancySummary({required this.total, required this.available});

  @override
  Widget build(BuildContext context) {
    final occupied = total - available;
    final percentage =
        total > 0 ? ((occupied / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total', value: total.toString()),
          _StatItem(label: 'Available', value: available.toString()),
          _StatItem(label: 'Occupied', value: occupied.toString()),
          _StatItem(label: 'Usage', value: '$percentage%'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: AppTheme.spotAvailable, label: 'Available'),
          const SizedBox(width: 16),
          _LegendItem(color: AppTheme.spotOccupied, label: 'Occupied'),
          const SizedBox(width: 16),
          _LegendItem(color: AppTheme.spotReserved, label: 'Reserved'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SpotGrid extends StatelessWidget {
  final List<ParkingSpot> spots;

  const _SpotGrid({required this.spots});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        return _SpotTile(spot: spot);
      },
    );
  }
}

class _SpotTile extends StatelessWidget {
  final ParkingSpot spot;

  const _SpotTile({required this.spot});

  Color get _color {
    switch (spot.status) {
      case SpotStatus.available:
        return AppTheme.spotAvailable;
      case SpotStatus.occupied:
        return AppTheme.spotOccupied;
      case SpotStatus.reserved:
        return AppTheme.spotReserved;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        border: Border.all(color: _color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spot.status == SpotStatus.occupied
                  ? Icons.directions_car
                  : Icons.local_parking,
              color: _color,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              spot.spotNumber,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
