import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../constants/categories.dart';
import '../services/local_storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  bool _isLoading = true;

  double _totalSpentThisMonth = 0;
  String _highestCategory = 'N/A';
  int _daysLeft = 0;

  Map<String, double> _categorySpentMap = {};
  List<double> _last7DaysSpent = List.filled(7, 0.0);
  double _maxDailySpent = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final expenses = await _storageService.getExpenses();
    final now = DateTime.now();

    // Days in Month Left
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    _daysLeft = daysInMonth - now.day;

    // Monthly Distribution & Summary
    double totalSpent = 0;
    Map<String, double> catSpent = {};

    for (var e in expenses) {
      if (e.date.month == now.month && e.date.year == now.year) {
        totalSpent += e.amount;
        catSpent[e.category] = (catSpent[e.category] ?? 0) + e.amount;
      }
    }

    String maxCat = 'N/A';
    double maxAmt = 0;
    catSpent.forEach((k, v) {
      if (v > maxAmt) {
        maxAmt = v;
        maxCat = k;
      }
    });

    // Last 7 Days (Bar Chart Data)
    List<double> weeklyTotals = List.filled(7, 0.0);
    for (var e in expenses) {
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(e.date.year, e.date.month, e.date.day))
          .inDays;
      if (difference >= 0 && difference < 7) {
        weeklyTotals[6 - difference] += e.amount;
      }
    }
    
    double maxDaily = 0;
    for (var val in weeklyTotals) {
      if (val > maxDaily) maxDaily = val;
    }

    setState(() {
      _totalSpentThisMonth = totalSpent;
      _categorySpentMap = catSpent;
      _highestCategory = maxCat;
      _last7DaysSpent = weeklyTotals;
      _maxDailySpent = maxDaily == 0 ? 100 : maxDaily; // avoid 0 denominator
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Summary Cards ---
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('Total Spent', '\$${_totalSpentThisMonth.toStringAsFixed(0)}', Colors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSummaryCard('Highest', _highestCategory, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSummaryCard('Days Left', '$_daysLeft', Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- Pie Chart (Category Distribution) ---
                    const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: _categorySpentMap.isEmpty 
                        ? const Center(child: Text('No data for this month'))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _getPieChartSections(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (_categorySpentMap.isNotEmpty) _buildLegend(),

                    const SizedBox(height: 48),

                    // --- Bar Chart (Last 7 Days) ---
                    const Text('Last 7 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _maxDailySpent * 1.2, // Give Headroom
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: _getBottomTitles,
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false), // Clean look
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: _getBarGroups(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color iconColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    return _categorySpentMap.entries.map((entry) {
      final catMeta = AppCategories.defaultCategories.firstWhere(
        (c) => c.name == entry.key,
        orElse: () => AppCategories.defaultCategories.last,
      );
      final percent = (_totalSpentThisMonth == 0) ? 0.0 : (entry.value / _totalSpentThisMonth) * 100;

      return PieChartSectionData(
        color: catMeta.color,
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _categorySpentMap.entries.map((entry) {
        final catMeta = AppCategories.defaultCategories.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => AppCategories.defaultCategories.last,
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: catMeta.color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${entry.key} (\$${entry.value.toStringAsFixed(0)})', style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: _last7DaysSpent[i],
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _maxDailySpent * 1.2,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - value.toInt()));
    final text = DateFormat('E').format(date); // Mon, Tue, etc...
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }
}
