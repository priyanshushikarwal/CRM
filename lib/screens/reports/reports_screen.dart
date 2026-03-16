import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/payment_model.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(revenueReportProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: reportAsync.when(
              data: (data) => _buildReportContent(context, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              SizedBox(height: 4),
              Text(
                'Detailed overview of revenue, payments and business growth',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text('Export Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, Map<String, dynamic> data) {
    final Map<String, double> monthlyData = data['monthlyData'];
    final List<PaymentModel> recentPayments = data['recentPayments'];
    
    // Convert monthlyData to ChartData
    final chartData = monthlyData.entries.map((e) => _ChartData(e.key, e.value)).toList();
    chartData.sort((a, b) => b.month.compareTo(a.month));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              _buildSummaryCard(
                'Grand Total Revenue',
                '₹${NumberFormat('#,##,###', 'en_IN').format(data['totalRevenue'])}',
                Icons.account_balance_wallet_outlined,
                Colors.blue,
              ),
              const SizedBox(width: 24),
              _buildSummaryCard(
                'Expected Revenue (MTD)',
                '₹${NumberFormat('#,##,###', 'en_IN').format(data['monthlyRevenue'])}',
                Icons.calendar_month_outlined,
                Colors.green,
              ),
              const SizedBox(width: 24),
              _buildSummaryCard(
                'Payment Count',
                recentPayments.length.toString(),
                Icons.trending_up_rounded,
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Chart Section
          Container(
            height: 480,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 32),
                Expanded(
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: const CategoryAxis(
                      majorGridLines: MajorGridLines(width: 0),
                      labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    primaryYAxis: NumericAxis(
                      numberFormat: NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN'),
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                      majorGridLines: const MajorGridLines(color: AppTheme.borderColor, dashArray: [5, 5]),
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true, header: 'Revenue'),
                    series: <CartesianSeries>[
                      ColumnSeries<_ChartData, String>(
                        dataSource: chartData.reversed.toList(),
                        xValueMapper: (_ChartData d, _) => d.month,
                        yValueMapper: (_ChartData d, _) => d.revenue,
                        name: 'Revenue',
                        color: AppTheme.primaryColor.withOpacity(0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        animationDuration: 1200,
                      ),
                      SplineSeries<_ChartData, String>(
                        dataSource: chartData.reversed.toList(),
                        xValueMapper: (_ChartData d, _) => d.month,
                        yValueMapper: (_ChartData d, _) => d.revenue,
                        color: AppTheme.primaryColor,
                        width: 4,
                        markerSettings: const MarkerSettings(isVisible: true, shape: DataMarkerType.circle, width: 8, height: 8, color: Colors.white, borderColor: AppTheme.primaryColor, borderWidth: 2),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Recent Payments Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.cardRadius), topRight: Radius.circular(AppTheme.cardRadius)),
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 12),
                      Text('Recent Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                if (recentPayments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(64),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFE2E8F0)),
                          SizedBox(height: 16),
                          Text('No transactions found', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
                        child: const Row(
                          children: [
                            Expanded(flex: 1, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                            Expanded(flex: 2, child: Text('TRANSACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                            Expanded(flex: 1, child: Text('MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                            Expanded(flex: 1, child: Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                            Expanded(flex: 1, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                          ],
                        ),
                      ),
                      ...recentPayments.take(10).map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(DateFormat('dd MMM yyyy').format(p.paymentDate), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                            Expanded(flex: 2, child: Text(p.applicationId.substring(0, 8), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                            Expanded(flex: 1, child: Text(p.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text(p.paymentType.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '₹${NumberFormat('#,##,###', 'en_IN').format(p.amount)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.month, this.revenue);
  final String month;
  final double revenue;
}
