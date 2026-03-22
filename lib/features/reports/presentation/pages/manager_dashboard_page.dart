import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/network/sync_health_cubit.dart';
import 'package:parkflow_manager/core/services/pdf_report_service.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/reports/presentation/bloc/reports_cubit.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  int _selectedIndex = 0;
  final PdfReportService _pdfService = PdfReportService();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.context.hasLotAccess) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This manager account has no assigned lot. Please contact support.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final lotId = authState.context.requireLotId();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => context.goNamed('camera-management'),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            onPressed: () => context.goNamed('employee-management'),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money_rounded),
            onPressed: () => context.goNamed('rate-config'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _exportCurrentReport,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SyncHealthBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Revenue')),
                ButtonSegment(value: 1, label: Text('Occupancy')),
                ButtonSegment(value: 2, label: Text('Employees')),
              ],
              selected: {_selectedIndex},
              onSelectionChanged: (value) {
                setState(() => _selectedIndex = value.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _loadCurrentReport(context, lotId),
                icon: const Icon(Icons.analytics_rounded),
                label: const Text('Generate Current Report'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, state) {
                if (state is ReportsLoading) {
                  return const LoadingIndicator(message: 'Loading report...');
                }
                if (state is ReportsError) {
                  return ErrorDisplay(message: state.message);
                }
                if (state is RevenueReportLoaded && _selectedIndex == 0) {
                  return _RevenueView(state: state);
                }
                if (state is OccupancyReportLoaded && _selectedIndex == 1) {
                  return _OccupancyView(state: state);
                }
                if (state is EmployeePerformanceLoaded && _selectedIndex == 2) {
                  return _EmployeeView(state: state);
                }
                return const Center(
                  child: Text('Generate a report to see data for this lot.'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _loadCurrentReport(BuildContext context, String lotId) {
    context.read<SyncHealthCubit>().load();
    final now = DateTime.now();
    switch (_selectedIndex) {
      case 0:
        context.read<ReportsCubit>().loadRevenueReport(
              lotId: lotId,
              startDate: now.subtract(const Duration(days: 30)),
              endDate: now,
            );
      case 1:
        context.read<ReportsCubit>().loadOccupancyReport(
              lotId: lotId,
              startDate: now.subtract(const Duration(days: 7)),
              endDate: now,
            );
      case 2:
        context.read<ReportsCubit>().loadEmployeePerformance(
              lotId: lotId,
              startDate: now.subtract(const Duration(days: 30)),
              endDate: now,
            );
    }
  }

  Future<void> _exportCurrentReport() async {
    final state = context.read<ReportsCubit>().state;
    String? filePath;
    if (state is RevenueReportLoaded) {
      filePath = await _pdfService.generateRevenueReport(state.report);
    } else if (state is OccupancyReportLoaded) {
      filePath = await _pdfService.generateOccupancyReport(state.report);
    }
    if (!mounted || filePath == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF exported to ${filePath.split('/').last}')),
    );
  }
}

class _SyncHealthBanner extends StatelessWidget {
  const _SyncHealthBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncHealthCubit, SyncHealthState>(
      builder: (context, state) {
        if (state is SyncHealthLoading) {
          return const SizedBox.shrink();
        }

        if (state is SyncHealthLoaded && state.deadLetterCount == 0) {
          return const SizedBox.shrink();
        }

        if (state is SyncHealthLoaded) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.deadLetterCount} sync records moved to dead-letter queue. Review sync failures before closing the day.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        if (state is SyncHealthError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Unable to load sync health: ${state.message}'),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _RevenueView extends StatelessWidget {
  const _RevenueView({required this.state});

  final RevenueReportLoaded state;

  @override
  Widget build(BuildContext context) {
    final report = state.report;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.isStale) const _StaleBanner(),
        _MetricCard(
          label: 'Total Revenue',
          value: '\$${report.totalRevenue.toStringAsFixed(2)}',
        ),
        _MetricCard(
          label: 'Cash Revenue',
          value: '\$${report.cashRevenue.toStringAsFixed(2)}',
        ),
        _MetricCard(
          label: 'Digital Revenue',
          value: '\$${report.digitalRevenue.toStringAsFixed(2)}',
        ),
        _MetricCard(label: 'Sessions', value: report.totalSessions.toString()),
      ],
    );
  }
}

class _OccupancyView extends StatelessWidget {
  const _OccupancyView({required this.state});

  final OccupancyReportLoaded state;

  @override
  Widget build(BuildContext context) {
    final report = state.report;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.isStale) const _StaleBanner(),
        _MetricCard(
          label: 'Average Occupancy',
          value: '${report.averageOccupancy.toStringAsFixed(1)}%',
        ),
        _MetricCard(
          label: 'Peak Occupancy',
          value: '${report.peakOccupancy.toStringAsFixed(1)}%',
        ),
        _MetricCard(
          label: 'Average Duration',
          value:
              '${report.averageDuration.inHours}h ${report.averageDuration.inMinutes.remainder(60)}m',
        ),
      ],
    );
  }
}

class _EmployeeView extends StatelessWidget {
  const _EmployeeView({required this.state});

  final EmployeePerformanceLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.isStale) const _StaleBanner(),
        for (final employee in state.data)
          Card(
            child: ListTile(
              title: Text(employee['employee_name'] as String? ?? 'Unknown'),
              subtitle: Text('ID: ${employee['employee_id'] ?? 'N/A'}'),
              trailing: Text('${employee['sessions_processed'] ?? 0} sessions'),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Showing cached server report data. Connect to network and refresh for current authoritative metrics.',
      ),
    );
  }
}
