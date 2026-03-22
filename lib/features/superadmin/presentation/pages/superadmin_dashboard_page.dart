import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/stat_card.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class SuperadminDashboardPage extends StatelessWidget {
  const SuperadminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('System Dashboard'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => context.go('/login'),
                tooltip: 'Logout',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<SuperadminCubit, SuperadminState>(
              builder: (context, state) {
                if (state is SuperadminLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: LoadingIndicator(message: 'Loading dashboard...'),
                  );
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: ErrorDisplay(
                      message: state.message,
                      onRetry: () => context.read<SuperadminCubit>().loadDashboard(),
                    ),
                  );
                }
                if (state is SuperadminDashboardLoaded) {
                  return _DashboardContent(stats: state.stats);
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats});
  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                value: '${stats.totalLots}',
                label: 'Parking Lots',
                icon: Icons.local_parking_rounded,
                gradient: AppTheme.primaryGradient,
              ),
              StatCard(
                value: '\$${stats.totalRevenueToday.toStringAsFixed(0)}',
                label: "Today's Revenue",
                icon: Icons.attach_money_rounded,
                gradient: AppTheme.tealGradient,
              ),
              StatCard(
                value: '${stats.totalActiveSessions}',
                label: 'Active Sessions',
                icon: Icons.directions_car_rounded,
                color: AppTheme.warningColor,
              ),
              StatCard(
                value: '${stats.occupiedSpots}/${stats.totalSpots}',
                label: 'Spots Occupied',
                icon: Icons.grid_view_rounded,
                color: AppTheme.spotOccupied,
              ),
              StatCard(
                value: '${stats.totalEmployees}',
                label: 'Employees',
                icon: Icons.people_alt_rounded,
                color: AppTheme.primary,
              ),
              StatCard(
                value: '${stats.activeCameras}/${stats.totalCameras}',
                label: 'Active Cameras',
                icon: Icons.videocam_rounded,
                color: AppTheme.successColor,
              ),
              StatCard(
                value: '\$${stats.totalRevenueAllTime.toStringAsFixed(0)}',
                label: 'All-Time Revenue',
                icon: Icons.trending_up_rounded,
                gradient: AppTheme.successGradient,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ..._buildActions(context),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = [
      _ActionItem(icon: Icons.local_parking_rounded, label: 'Manage Lots', route: '/superadmin/lots'),
      _ActionItem(icon: Icons.bar_chart_rounded, label: 'System Reports', route: '/superadmin/reports'),
      _ActionItem(icon: Icons.people_alt_rounded, label: 'All Employees', route: '/superadmin/employees'),
      _ActionItem(icon: Icons.videocam_rounded, label: 'Camera Overview', route: '/superadmin/cameras'),
      _ActionItem(icon: Icons.history_rounded, label: 'Audit Log', route: '/superadmin/audit-log'),
    ];

    return actions.map((a) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(a.icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(a.label),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).cardTheme.color,
        onTap: () => context.go(a.route),
      ),
    )).toList();
  }
}

class _ActionItem {
  const _ActionItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}
