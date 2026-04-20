// lib/features/reports/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_database.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _period = 'Weekly';
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final userId = SupabaseService.userId!;
    final now = DateTime.now();
    final from = _period == 'Daily'
        ? DateTime(now.year, now.month, now.day)
        : _period == 'Weekly'
            ? now.subtract(const Duration(days: 7))
            : now.subtract(const Duration(days: 30));

    final sales = await LocalDatabase.getSalesReport(userId, from, now);
    final products = await LocalDatabase.getTopProducts(userId, from, now);

    setState(() {
      _salesData = sales;
      _topProducts = products;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalRevenue =>
      _salesData.fold(0, (sum, d) => sum + (d['total_sales'] as num? ?? 0));
  int get _totalBills =>
      _salesData.fold(0, (sum, d) => sum + (d['bill_count'] as num? ?? 0).toInt());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['Daily', 'Weekly', 'Monthly'].map((p) {
                final isSelected = _period == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _period = p);
                      _loadData();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(p,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Tabs
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _SalesTab(salesData: _salesData, period: _period),
                      _TopProductsTab(products: _topProducts),
                      _SummaryTab(
                          totalRevenue: _totalRevenue,
                          totalBills: _totalBills,
                          period: _period),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SalesTab extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  final String period;
  const _SalesTab({required this.salesData, required this.period});

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No sales data for this period',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    final maxY = salesData
        .map((d) => (d['total_sales'] as num? ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barGroups: salesData.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (d['total_sales'] as num? ?? 0).toDouble(),
                        gradient: AppTheme.primaryGradient,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= salesData.length) return const Text('');
                        final dateStr = salesData[idx]['sale_date'] as String;
                        final date = DateTime.parse(dateStr);
                        return Text(DateFormat('d/M').format(date),
                            style: const TextStyle(fontSize: 10));
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text(
                        '₹${val.toInt()}',
                        style: const TextStyle(fontSize: 9),
                      ),
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 100,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Day-wise table
          Text('Daily Breakdown',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ...salesData.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('d MMM y').format(
                        DateTime.parse(d['sale_date'] as String)),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
                Text('${d['bill_count']} bills',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight)),
                const SizedBox(width: 12),
                Text(
                  '₹${(d['total_sales'] as num? ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.primary),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _TopProductsTab extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProductsTab({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text('No sales data', style: TextStyle(color: Colors.grey.shade400)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = products[i];
        final revenue = (p['total_revenue'] as num? ?? 0).toDouble();
        final qty = (p['total_quantity'] as num? ?? 0).toInt();
        final maxRevenue = (products.first['total_revenue'] as num? ?? 1).toDouble();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? const Color(0xFFFFD700)
                        : i == 1
                            ? const Color(0xFFC0C0C0)
                            : i == 2
                                ? const Color(0xFFCD7F32)
                                : AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: i < 3 ? Colors.white : AppTheme.primary,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(p['product_name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Text('₹${revenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maxRevenue > 0 ? revenue / maxRevenue : 0,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('$qty units sold',
                  style: TextStyle(fontSize: 11,
                      color: AppTheme.textSecondaryLight)),
            ),
          ]),
        );
      },
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final double totalRevenue;
  final int totalBills;
  final String period;
  const _SummaryTab({
    required this.totalRevenue,
    required this.totalBills,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final avgBillValue = totalBills > 0 ? totalRevenue / totalBills : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryCard(
            title: '$period Revenue',
            value: '₹${totalRevenue.toStringAsFixed(0)}',
            icon: Icons.trending_up_rounded,
            gradient: AppTheme.primaryGradient,
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Total Bills',
            value: '$totalBills',
            icon: Icons.receipt_long_rounded,
            gradient: AppTheme.greenGradient,
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Avg Bill Value',
            value: '₹${avgBillValue.toStringAsFixed(0)}',
            icon: Icons.calculate_rounded,
            gradient: AppTheme.warningGradient,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  const _SummaryCard({
    required this.title, required this.value,
    required this.icon, required this.gradient,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4)),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 13)),
            Text(value, style: const TextStyle(
                color: Colors.white, fontSize: 28,
                fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    ),
  );
}
