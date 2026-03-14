import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';

/// Generates PDF reports for revenue and occupancy data.
class PdfReportService {
  /// Generate a revenue report PDF and return its file path.
  Future<String> generateRevenueReport(RevenueReport report) async {
    final pdf = pw.Document();

    final dateRange =
        '${_fmt(report.startDate)} – ${_fmt(report.endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Revenue Report', dateRange),
        footer: _buildFooter,
        build: (context) => [
          _buildSummarySection(report),
          pw.SizedBox(height: 16),
          _buildDailyTable(report.dailyBreakdown),
          if (report.revenueByVehicleSize.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSizeBreakdown(report.revenueByVehicleSize),
          ],
        ],
      ),
    );

    return _savePdf(pdf, 'revenue_report_${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Generate an occupancy report PDF and return its file path.
  Future<String> generateOccupancyReport(OccupancyReport report) async {
    final pdf = pw.Document();

    final dateRange =
        '${_fmt(report.startDate)} – ${_fmt(report.endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Occupancy Report', dateRange),
        footer: _buildFooter,
        build: (context) => [
          _buildOccupancySummary(report),
          pw.SizedBox(height: 16),
          _buildHourlyTable(report.hourlyBreakdown),
        ],
      ),
    );

    return _savePdf(pdf, 'occupancy_report_${DateTime.now().millisecondsSinceEpoch}');
  }

  // ──────────────────────── Private helpers ────────────────────────

  pw.Widget _buildHeader(String title, String dateRange) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ParkFlow Manager',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                title,
                style: const pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Text(dateRange, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${_fmt(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(RevenueReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _kpi('Total Revenue', '\$${report.totalRevenue.toStringAsFixed(2)}'),
          _kpi('Sessions', report.totalSessions.toString()),
          _kpi('Cash', '\$${report.cashRevenue.toStringAsFixed(2)}'),
          _kpi('Digital', '\$${report.digitalRevenue.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  pw.Widget _buildOccupancySummary(OccupancyReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _kpi('Avg Occupancy',
              '${report.averageOccupancy.toStringAsFixed(1)}%'),
          _kpi('Peak', '${report.peakOccupancy.toStringAsFixed(1)}%'),
          _kpi(
            'Avg Duration',
            '${report.averageDuration.inHours}h ${report.averageDuration.inMinutes.remainder(60)}m',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDailyTable(List<DailyRevenue> days) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Sessions', 'Revenue'],
      data: days
          .map((d) => [
                _fmt(d.date),
                d.sessionCount.toString(),
                '\$${d.revenue.toStringAsFixed(2)}',
              ])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  pw.Widget _buildHourlyTable(List<HourlyOccupancy> hours) {
    return pw.TableHelper.fromTextArray(
      headers: ['Hour', 'Vehicles', 'Occupancy %'],
      data: hours
          .map((h) => [
                '${h.hour.toString().padLeft(2, '0')}:00',
                h.vehicleCount.toString(),
                '${h.occupancyPercentage.toStringAsFixed(1)}%',
              ])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  pw.Widget _buildSizeBreakdown(Map<String, double> sizeRevenue) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Revenue by Vehicle Size',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Size', 'Revenue'],
          data: sizeRevenue.entries
              .map((e) => [e.key, '\$${e.value.toStringAsFixed(2)}'])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        ),
      ],
    );
  }

  pw.Widget _kpi(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 13,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  Future<String> _savePdf(pw.Document pdf, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
