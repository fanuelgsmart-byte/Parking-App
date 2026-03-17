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
      backgroundColor: AppTheme.bgLight,
      body: BlocBuilder<LotMapCubit, LotMapState>(
        builder: (context, state) {
          if (state is LotMapLoading) {
            return const LoadingIndicator(message: 'Loading lot map...');
          }
          if (state is LotMapError) {
            return ErrorDisplay(message: state.message);
          }
          if (state is LotMapLoaded) {
            return _LotMapContent(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LotMapContent extends StatelessWidget {

  const _LotMapContent({required this.state});
  final LotMapLoaded state;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Gradient Header ──────────────────────────────────────
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: const Text(
              'Lot Map',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 48, 20, 0),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Occupancy Banner ──────────────────────────────────────
        SliverToBoxAdapter(
          child: _OccupancyBanner(
            total: state.totalSpots,
            available: state.availableSpots,
          ),
        ),

        // ── Legend ───────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _LegendChip(color: AppTheme.spotAvailable, label: 'Available'),
                SizedBox(width: 8),
                _LegendChip(color: AppTheme.spotOccupied, label: 'Occupied'),
                SizedBox(width: 8),
                _LegendChip(color: AppTheme.spotReserved, label: 'Reserved'),
              ],
            ),
          ),
        ),

        // ── Grid ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SpotTile(spot: state.spots[index]),
              childCount: state.spots.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Occupancy Banner ─────────────────────────────

class _OccupancyBanner extends StatelessWidget {

  const _OccupancyBanner({required this.total, required this.available});
  final int total;
  final int available;

  @override
  Widget build(BuildContext context) {
    final occupied = total - available;
    final pct = total > 0 ? occupied / total : 0.0;
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';

    Color barColor;
    if (pct < 0.6) {
      barColor = AppTheme.successColor;
    } else if (pct < 0.85) {
      barColor = AppTheme.warningColor;
    } else {
      barColor = AppTheme.errorColor;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Occupancy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pctLabel,
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: barColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(
                label: 'Total',
                value: total.toString(),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Available',
                value: available.toString(),
                color: AppTheme.spotAvailable,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Occupied',
                value: occupied.toString(),
                color: AppTheme.spotOccupied,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Legend ────────────────────────────────────────

class _LegendChip extends StatelessWidget {

  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ──────────────────────────── Spot Tile ─────────────────────────────────────

class _SpotTile extends StatelessWidget {

  const _SpotTile({required this.spot});
  final ParkingSpot spot;

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

  IconData get _icon {
    switch (spot.status) {
      case SpotStatus.available:
        return Icons.local_parking_rounded;
      case SpotStatus.occupied:
        return Icons.directions_car_rounded;
      case SpotStatus.reserved:
        return Icons.bookmark_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSpotDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          border: Border.all(color: _color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, color: _color, size: 18),
            const SizedBox(height: 3),
            Text(
              spot.spotNumber,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSpotDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpotDetailSheet(spot: spot, color: _color),
    );
  }
}

// ──────────────────────────── Spot Detail Sheet ──────────────────────────────

class _SpotDetailSheet extends StatelessWidget {

  const _SpotDetailSheet({required this.spot, required this.color});
  final ParkingSpot spot;
  final Color color;

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
          const SizedBox(height: 20),
          // Spot icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              spot.status == SpotStatus.occupied
                  ? Icons.directions_car_rounded
                  : spot.status == SpotStatus.reserved
                      ? Icons.bookmark_rounded
                      : Icons.local_parking_rounded,
              color: color,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Spot ${spot.spotNumber}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              spot.status.displayName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _DetailRow(label: 'Size', value: spot.size.toUpperCase()),
                if (spot.occupyingPlate != null) ...[
                  const Divider(height: 1),
                  _DetailRow(label: 'License Plate', value: spot.occupyingPlate!),
                ],
                if (spot.row != null && spot.col != null) ...[
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Location',
                    value: 'Row ${spot.row}, Col ${spot.col}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {

  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
