import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/services/pdf_report_service.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/stat_card.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';
import 'package:parkflow_manager/features/reports/presentation/bloc/reports_cubit.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  int _selectedIndex = 0;
  final PdfReportService _pdfService = PdfReportService();

  Future<void> _exportCurrentReport(BuildContext context) async {
    final state = context.read<ReportsCubit>().state;
    String? filePath;
    try {
      if (state is RevenueReportLoaded) {
        filePath = await _pdfService.generateRevenueReport(state.report);
      } else if (state is OccupancyReportLoaded) {
        filePath = await _pdfService.generateOccupancyReport(state.report);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Generate a report first')),
          );
        }
        return;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
      return;
    }

    if (filePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF exported: ${filePath.split('/').last}'),
          action: SnackBarAction(label: 'Open', onPressed: () {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: const Text(
                'Manager Dashboard',
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
              IconButton(
                icon: const Icon(Icons.people_alt_rounded, color: Colors.white),
                tooltip: 'Manage Employees',
                onPressed: () => context.goNamed('employee-management'),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                tooltip: 'Export PDF',
                onPressed: () => _exportCurrentReport(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Sign Out',
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // ── Tab bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Revenue',
                    icon: Icons.attach_money_rounded,
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Occupancy',
                    icon: Icons.bar_chart_rounded,
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Employees',
                    icon: Icons.people_rounded,
                    selected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  _RevenueTab(),
                  _OccupancyTab(),
                  _EmployeeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Tab Button ─────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── Revenue Tab ────────────────────────────────────

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state is ReportsLoading) {
          return const LoadingIndicator(message: 'Loading revenue data...');
        }
        if (state is ReportsError) {
          return ErrorDisplay(message: state.message);
        }
        if (state is RevenueReportLoaded) {
          return _RevenueContent(report: state.report);
        }
        return _EmptyReportPrompt(
          icon: Icons.attach_money_rounded,
          title: 'Revenue Reports',
          subtitle: 'Generate a revenue report for the last 30 days',
          onGenerate: () {
            final now = DateTime.now();
            context.read<ReportsCubit>().loadRevenueReport(
                  lotId: 'default',
                  startDate: now.subtract(const Duration(days: 30)),
                  endDate: now,
                );
          },
        );
      },
    );
  }
}

class _RevenueContent extends StatelessWidget {
  final RevenueReport report;

  const _RevenueContent({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '\$${report.totalRevenue.toStringAsFixed(0)}',
                  label: 'Total Revenue',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: AppTheme.primaryGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: report.totalSessions.toString(),
                  label: 'Total Sessions',
                  icon: Icons.directions_car_rounded,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '\$${report.cashRevenue.toStringAsFixed(0)}',
                  label: 'Cash',
                  icon: Icons.payments_rounded,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '\$${report.digitalRevenue.toStringAsFixed(0)}',
                  label: 'Digital',
                  icon: Icons.qr_code_rounded,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Trend Chart ──────────────────────────────────────
          _SectionTitle('Daily Revenue Trend'),
          const SizedBox(height: 12),
          _ChartCard(
            child: report.dailyBreakdown.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) => Text(
                              '\$${v.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: report.dailyBreakdown
                              .asMap()
                              .entries
                              .map((e) =>
                                  FlSpot(e.key.toDouble(), e.value.revenue))
                              .toList(),
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.15),
                                AppTheme.primary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const _ChartEmpty(),
          ),
          const SizedBox(height: 24),

          // ── Pie Chart ────────────────────────────────────────
          _SectionTitle('Revenue by Vehicle Size'),
          const SizedBox(height: 12),
          _ChartCard(
            height: 180,
            child: report.revenueByVehicleSize.isNotEmpty
                ? Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(
                                report.revenueByVehicleSize),
                            centerSpaceRadius: 36,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PieLegend(
                          data: report.revenueByVehicleSize,
                        ),
                      ),
                    ],
                  )
                : const _ChartEmpty(),
          ),
        ],
      ),
    );
  }

  static const _pieColors = [
    AppTheme.primary,
    AppTheme.successColor,
    AppTheme.warningColor,
  ];

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    var i = 0;
    return data.entries.map((entry) {
      final color = _pieColors[i % _pieColors.length];
      i++;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 48,
        title: '',
      );
    }).toList();
  }
}

class _PieLegend extends StatelessWidget {
  final Map<String, double> data;
  static const _colors = [
    AppTheme.primary,
    AppTheme.successColor,
    AppTheme.warningColor,
  ];

  const _PieLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (i) {
        final e = entries[i];
        final color = _colors[i % _colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${e.key[0].toUpperCase()}${e.key.substring(1)}\n\$${e.value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ──────────────────────────── Occupancy Tab ──────────────────────────────────

class _OccupancyTab extends StatelessWidget {
  const _OccupancyTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state is ReportsLoading) {
          return const LoadingIndicator(message: 'Loading occupancy data...');
        }
        if (state is OccupancyReportLoaded) {
          return _OccupancyContent(report: state.report);
        }
        return _EmptyReportPrompt(
          icon: Icons.bar_chart_rounded,
          title: 'Occupancy Analytics',
          subtitle: 'View traffic patterns for the last 7 days',
          onGenerate: () {
            final now = DateTime.now();
            context.read<ReportsCubit>().loadOccupancyReport(
                  lotId: 'default',
                  startDate: now.subtract(const Duration(days: 7)),
                  endDate: now,
                );
          },
        );
      },
    );
  }
}

class _OccupancyContent extends StatelessWidget {
  final OccupancyReport report;

  const _OccupancyContent({required this.report});

  @override
  Widget build(BuildContext context) {
    final avgDurStr =
        '${report.averageDuration.inHours}h ${report.averageDuration.inMinutes.remainder(60)}m';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${report.averageOccupancy.toStringAsFixed(1)}%',
                  label: 'Avg Occupancy',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${report.peakOccupancy.toStringAsFixed(1)}%',
                  label: 'Peak',
                  icon: Icons.show_chart_rounded,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatCard(
            value: avgDurStr,
            label: 'Average Duration',
            icon: Icons.timer_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 24),
          _SectionTitle('Hourly Traffic Distribution'),
          const SizedBox(height: 12),
          _ChartCard(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: report.hourlyBreakdown
                    .map(
                      (h) => BarChartGroupData(
                        x: h.hour,
                        barRods: [
                          BarChartRodData(
                            toY: h.vehicleCount.toDouble(),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppTheme.primaryDark, AppTheme.primary],
                            ),
                            width: 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 4 == 0) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Employee Tab ────────────────────────────────────

class _EmployeeTab extends StatelessWidget {
  const _EmployeeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state is ReportsLoading) {
          return const LoadingIndicator(message: 'Loading employee data...');
        }
        if (state is EmployeePerformanceLoaded) {
          return _EmployeeContent(data: state.data);
        }
        return _EmptyReportPrompt(
          icon: Icons.people_rounded,
          title: 'Employee Performance',
          subtitle: 'View employee metrics and shift performance',
          onGenerate: () {
            final now = DateTime.now();
            context.read<ReportsCubit>().loadEmployeePerformance(
                  lotId: 'default',
                  startDate: now.subtract(const Duration(days: 30)),
                  endDate: now,
                );
          },
        );
      },
    );
  }
}

class _EmployeeContent extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _EmployeeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No employee data available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final emp = data[index];
        final name = emp['employee_name'] as String? ?? 'Unknown';
        final sessions = emp['sessions_processed'] ?? 0;
        final revenue = (emp['total_revenue'] as num?)?.toDouble() ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'ID: ${emp['employee_id'] as String? ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sessions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                  ),
                  Text(
                    'sessions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (revenue > 0)
                    Text(
                      '\$${revenue.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────── Shared ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  final double height;

  const _ChartCard({required this.child, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No data available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _EmptyReportPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onGenerate;

  const _EmptyReportPrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Icon(icon, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.analytics_rounded),
              label: const Text('Generate Report'),
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
}
