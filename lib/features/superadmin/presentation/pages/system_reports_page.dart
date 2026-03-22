import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/stat_card.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class SystemReportsPage extends StatefulWidget {
  const SystemReportsPage({super.key});

  @override
  State<SystemReportsPage> createState() => _SystemReportsPageState();
}

class _SystemReportsPageState extends State<SystemReportsPage> {
  int _selectedTab = 0; // 0 = revenue, 1 = occupancy

  @override
  void initState() {
    super.initState();
    _loadRevenue();
  }

  void _loadRevenue() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    context.read<SuperadminCubit>().loadRevenueReport(start, now);
  }

  void _loadOccupancy() {
    context.read<SuperadminCubit>().loadOccupancyReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('System Reports'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Revenue'), icon: Icon(Icons.attach_money)),
                  ButtonSegment(value: 1, label: Text('Occupancy'), icon: Icon(Icons.grid_view)),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (s) {
                  setState(() => _selectedTab = s.first);
                  if (_selectedTab == 0) _loadRevenue();
                  if (_selectedTab == 1) _loadOccupancy();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<SuperadminCubit, SuperadminState>(
              builder: (context, state) {
                if (state is SuperadminLoading) {
                  return const Padding(padding: EdgeInsets.only(top: 60), child: LoadingIndicator());
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: ErrorDisplay(message: state.message, onRetry: _selectedTab == 0 ? _loadRevenue : _loadOccupancy),
                  );
                }
                if (state is SuperadminRevenueLoaded) {
                  return _RevenueContent(report: state.report);
                }
                if (state is SuperadminOccupancyLoaded) {
                  return _OccupancyContent(report: state.report);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueContent extends StatelessWidget {
  const _RevenueContent({required this.report});
  final CrossLotRevenueReport report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '\$${report.grandTotalRevenue.toStringAsFixed(2)}',
                  label: 'Total Revenue',
                  icon: Icons.attach_money,
                  gradient: AppTheme.primaryGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${report.grandTotalSessions}',
                  label: 'Total Sessions',
                  icon: Icons.directions_car,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (report.perLot.isEmpty)
            const Text('No revenue data for selected period.')
          else
            ...report.perLot.map((lot) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(lot.lotName),
                    subtitle: Text('${lot.totalSessions} sessions'),
                    trailing: Text(
                      '\$${lot.totalRevenue.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.successColor),
                    ),
                  ),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OccupancyContent extends StatelessWidget {
  const _OccupancyContent({required this.report});
  final CrossLotOccupancyReport report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${report.overallRate.toStringAsFixed(1)}%',
                  label: 'Overall Occupancy',
                  icon: Icons.grid_view,
                  gradient: AppTheme.tealGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${report.totalOccupied}/${report.totalSpots}',
                  label: 'Spots Used',
                  icon: Icons.local_parking,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...report.perLot.map((lot) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(lot.lotName),
                  subtitle: LinearProgressIndicator(
                    value: lot.totalSpots > 0 ? lot.occupiedSpots / lot.totalSpots : 0,
                    backgroundColor: AppTheme.spotAvailable.withValues(alpha: 0.2),
                    color: lot.occupancyRate > 80 ? AppTheme.spotOccupied : AppTheme.spotAvailable,
                  ),
                  trailing: Text(
                    '${lot.occupancyRate.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
