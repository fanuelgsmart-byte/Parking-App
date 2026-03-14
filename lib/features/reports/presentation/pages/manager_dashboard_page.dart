import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/services/pdf_report_service.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
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
            const SnackBar(
              content: Text('Generate a report first before exporting'),
            ),
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
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // In production, use open_file or share_plus to open the PDF
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Manage Employees',
            onPressed: () => context.goNamed('employee-management'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => _exportCurrentReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _RevenueTab(),
          _OccupancyTab(),
          _EmployeeTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Revenue',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Occupancy',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Employees',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Revenue Tab ────────────────────────────

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
          icon: Icons.attach_money,
          title: 'Revenue Reports',
          subtitle: 'Select a date range to generate a revenue report',
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Revenue',
                  value: '\$${report.totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Sessions',
                  value: report.totalSessions.toString(),
                  icon: Icons.directions_car,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Cash',
                  value: '\$${report.cashRevenue.toStringAsFixed(2)}',
                  icon: Icons.money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Digital',
                  value: '\$${report.digitalRevenue.toStringAsFixed(2)}',
                  icon: Icons.qr_code,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Revenue Trend Chart
          Text(
            'Daily Revenue Trend',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: report.dailyBreakdown.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: report.dailyBreakdown
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.revenue,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(child: Text('No data available')),
          ),
          const SizedBox(height: 24),
          // Revenue by Vehicle Size
          Text(
            'Revenue by Vehicle Size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: report.revenueByVehicleSize.isNotEmpty
                ? PieChart(
                    PieChartData(
                      sections: _buildPieSections(
                        report.revenueByVehicleSize,
                      ),
                      centerSpaceRadius: 40,
                    ),
                  )
                : const Center(child: Text('No data available')),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> sizeRevenue) {
    final colors = [Colors.blue, Colors.orange, Colors.red];
    var i = 0;
    return sizeRevenue.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

// ──────────────────────────── Occupancy Tab ────────────────────────────

class _OccupancyTab extends StatelessWidget {
  const _OccupancyTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state is OccupancyReportLoaded) {
          return _OccupancyContent(report: state.report);
        }
        return _EmptyReportPrompt(
          icon: Icons.bar_chart,
          title: 'Occupancy Analytics',
          subtitle: 'Generate occupancy analytics for your lot',
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Avg Occupancy',
                  value: '${report.averageOccupancy.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Peak',
                  value: '${report.peakOccupancy.toStringAsFixed(1)}%',
                  icon: Icons.show_chart,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Avg Duration',
            value:
                '${report.averageDuration.inHours}h ${report.averageDuration.inMinutes.remainder(60)}m',
            icon: Icons.timer,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 24),
          Text(
            'Hourly Traffic Distribution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: report.hourlyBreakdown
                    .map(
                      (h) => BarChartGroupData(
                        x: h.hour,
                        barRods: [
                          BarChartRodData(
                            toY: h.vehicleCount.toDouble(),
                            color: colorScheme.primary,
                            width: 8,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 4 == 0) {
                          return Text(
                            '${value.toInt()}:00',
                            style: const TextStyle(fontSize: 10),
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

// ──────────────────────────── Employee Tab ────────────────────────────

class _EmployeeTab extends StatelessWidget {
  const _EmployeeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state is EmployeePerformanceLoaded) {
          return _EmployeeContent(data: state.data);
        }
        return _EmptyReportPrompt(
          icon: Icons.people,
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
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final employee = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                (employee['employee_name'] as String? ?? '?')
                    .substring(0, 1)
                    .toUpperCase(),
              ),
            ),
            title: Text(employee['employee_name'] as String? ?? 'Unknown'),
            subtitle:
                Text('ID: ${employee['employee_id'] as String? ?? 'N/A'}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${employee['sessions_processed'] ?? 0}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'sessions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────── Shared Widgets ────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.analytics),
            label: const Text('Generate Report'),
          ),
        ],
      ),
    );
  }
}
