import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_selector/file_selector.dart';
import 'package:leami_desktop/models/monthly_order.dart';
import 'package:leami_desktop/models/monthly_revenue.dart';
import 'package:provider/provider.dart';
import 'package:leami_desktop/providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  late TextEditingController _fromCtl;
  late TextEditingController _toCtl;

  final ScrollController _chartsCtrl = ScrollController();

  bool get _rangeInvalid => _from.isAfter(_to);
  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    _fromCtl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_from),
    );
    _toCtl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_to));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAll(from: _from, to: _to);
    });
  }

  @override
  void dispose() {
    _fromCtl.dispose();
    _toCtl.dispose();
    _chartsCtrl.dispose();
    super.dispose();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              const Text('Info'),
              const Spacer(),
              IconButton(
                tooltip: 'Zatvori',
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: const Text(
            'Ovdje možeš birati raspon datuma i preuzeti PDF izvještaj. '
            'Grafovi prikazuju broj narudžbi i prihod po mjesecima za odabrani period. '
            'Nije moguće odabrati datum u datepickeru "Od" koji će biti poslije "Do" (i obrnuto). ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('U redu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final oldFrom = _from;
    final oldTo = _to;

    final now = DateTime.now();
    final initial = isFrom ? (_from.isAfter(_to) ? _to : _from) : _to;
    final firstDate = isFrom ? DateTime(2020) : _from;
    final lastDate = isFrom ? (_to.isBefore(now) ? _to : now) : now;

    final picker = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picker == null) return;

    setState(() {
      if (isFrom) {
        _from = picker;
        _fromCtl.text = _fmt(_from);
      } else {
        _to = picker;
        _toCtl.text = _fmt(_to);
      }

      if (_rangeInvalid) {
        _from = oldFrom;
        _to = oldTo;
        _fromCtl.text = _fmt(_from);
        _toCtl.text = _fmt(_to);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nevažeći raspon: "From" ne smije biti poslije "To".',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    });

    await context.read<ReportProvider>().loadAll(from: _from, to: _to);
  }

  Future<void> _downloadPdf() async {
    try {
      final bytes = await context.read<ReportProvider>().downloadReport(
        from: _from,
        to: _to,
      );
      if (bytes.isEmpty) return;

      final name =
          'Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final location = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (location == null) return;

      final file = XFile.fromData(
        bytes,
        name: name,
        mimeType: 'application/pdf',
      );
      await file.saveTo(location.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF preuzet'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poslovni izvještaji')),
      body: Consumer<ReportProvider>(
        builder: (context, rpt, _) {
          if (rpt.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sum = rpt.summary;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromCtl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Od',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _pickDate(true),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _toCtl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Do',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _pickDate(false),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _rangeInvalid ? null : _downloadPdf,
                      child: const Text('Preuzmi PDF'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Info',
                      onPressed: _showInfoDialog,
                      icon: const Icon(Icons.info_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('Broj gostiju'),
                    trailing: Text(sum?.safeTotalUsers.toString() ?? '0'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Broj narudžbi'),
                    trailing: Text(sum?.safeTotalOrders.toString() ?? '0'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Profit'),
                    trailing: Text(
                      sum?.safeTotalRevenue.toStringAsFixed(2) ?? '0.00',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Scrollbar(
                    controller: _chartsCtrl,
                    thumbVisibility: true,
                    interactive: true,
                    child: ListView(
                      controller: _chartsCtrl,
                      children: [
                        const SizedBox(height: 16),
                        _buildOrdersChart(
                          'Broj narudžbi po mjesecima',
                          rpt.ordersByMonth,
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildRevenueChart(
                          'Profit po mjesecima',
                          rpt.revenueByMonth,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersChart(
    String title,
    List<MonthlyOrderData> data,
    Color color,
  ) {
    if (data.isEmpty) {
      return _buildEmptyChart(title);
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.safeCount.toDouble()))
        .toList();

    final maxCount = data
        .map((e) => e.safeCount)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxCount == 0
        ? 10.0
        : (maxCount * 1.3).clamp(1.0, double.infinity);

    return _buildChartCard(
      title: title,
      spots: spots,
      maxY: maxY,
      color: color,
      monthLabels: data.map((e) => e.safeMonth).toList(),
      formatValue: (value) => value.toInt().toString(),
    );
  }

  Widget _buildRevenueChart(
    String title,
    List<MonthlyRevenueData> data,
    Color color,
  ) {
    if (data.isEmpty) {
      return _buildEmptyChart(title);
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.safeRevenue))
        .toList();

    final maxRevenue = data
        .map((e) => e.safeRevenue)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxRevenue == 0
        ? 10.0
        : (maxRevenue * 1.3).clamp(1.0, double.infinity);

    return _buildChartCard(
      title: title,
      spots: spots,
      maxY: maxY,
      color: color,
      monthLabels: data.map((e) => e.safeMonth).toList(),
      formatValue: (value) => value.toStringAsFixed(0),
    );
  }

  Widget _buildChartCard({
    required String title,
    required List<FlSpot> spots,
    required double maxY,
    required Color color,
    required List<DateTime> monthLabels,
    required String Function(double) formatValue,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < monthLabels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat(
                                    'MMM\nyy',
                                  ).format(monthLabels[idx]),
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0 && value >= 0) {
                            return Text(
                              formatValue(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              height: 200,
              child: Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }
}
