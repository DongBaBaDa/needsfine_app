
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:needsfine_app/services/admin_service.dart';
import 'package:needsfine_app/utils/number_utils.dart'; // Ensure this exists or use standard formatting
import 'package:needsfine_app/l10n/app_localizations.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _storeMetrics = [];
  List<Map<String, dynamic>> _growthStats = [];
  
  // Sort state
  int _sortColumnIndex = 1; // Default sort by View Count
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final responses = await Future.wait([
        AdminService.getStoreMetrics(),
        AdminService.getDailyGrowthStats(),
      ]);

      setState(() {
        _storeMetrics = responses[0];
        _growthStats = responses[1];
        _isLoading = false;
        
        // Initial Sort
        _sortData(_sortColumnIndex, _isAscending);
      });
    } catch (e) {
      debugPrint("Error loading admin stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortData(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      
      _storeMetrics.sort((a, b) {
        dynamic aValue;
        dynamic bValue;

        switch (columnIndex) {
          case 0: // Store Name
            aValue = a['store_name'];
            bValue = b['store_name'];
            break;
          case 1: // Views
            aValue = a['total_views'];
            bValue = b['total_views'];
            break;
          case 2: // Reviews
             aValue = a['review_count'];
             bValue = b['review_count'];
             break;
          case 3: // Likes
             aValue = a['total_likes'];
             bValue = b['total_likes'];
             break;
          case 4: // Conversion
             aValue = a['conversion_rate'];
             bValue = b['conversion_rate'];
             break;
          default:
             return 0;
        }

        if (aValue == null) return 1;
        if (bValue == null) return -1;

        return ascending 
            ? aValue.compareTo(bValue) 
            : bValue.compareTo(aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(l10n.adminStatsDashboard, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGrowthChart(l10n),
                  const SizedBox(height: 24),
                  _buildKPIOverview(l10n),
                  const SizedBox(height: 24),
                  _buildStoreTable(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildKPIOverview(AppLocalizations l10n) {
    int totalViews = _storeMetrics.fold(0, (sum, item) => sum + (item['total_views'] as int? ?? 0));
    int totalReviews = _storeMetrics.fold(0, (sum, item) => sum + (item['review_count'] as int? ?? 0));
    int totalStores = _storeMetrics.length;

    return Row(
      children: [
        Expanded(child: _buildKPICard(l10n.totalViews, NumberUtils.format(totalViews), Icons.visibility, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildKPICard(l10n.totalReviews, NumberUtils.format(totalReviews), Icons.rate_review, Colors.purple)),
        const SizedBox(width: 8),
        Expanded(child: _buildKPICard(l10n.registeredStores, "$totalStores", Icons.store, Colors.orange)),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(AppLocalizations l10n) {
    if (_growthStats.isEmpty) return const SizedBox.shrink();

    // Prepare data spots
    List<FlSpot> reviewSpots = [];
    List<FlSpot> userSpots = [];
    
    // Sort logic handled in SQL usually, but verify order by date asc
    // SQL triggers sort ASC.
    
    for (int i = 0; i < _growthStats.length; i++) {
        reviewSpots.add(FlSpot(i.toDouble(), (_growthStats[i]['new_reviews'] as int).toDouble()));
        userSpots.add(FlSpot(i.toDouble(), (_growthStats[i]['new_users'] as int).toDouble()));
    }
    
    // Calculate max Y for scale
    double maxY = 0;
    for (var spot in reviewSpots) if (spot.y > maxY) maxY = spot.y;
    for (var spot in userSpots) if (spot.y > maxY) maxY = spot.y;
    maxY = (maxY * 1.2).ceilToDouble(); // Add 20% padding
    if (maxY < 5) maxY = 5;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dailyGrowthTrend, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < _growthStats.length) {
                             String dateStr = _growthStats[idx]['date'].toString(); 
                             // dateStr might be "2026-02-09T00:00:00.000Z" or similar
                             try {
                                 DateTime dt = DateTime.parse(dateStr);
                                 return Padding(
                                     padding: const EdgeInsets.only(top: 8.0),
                                     child: Text("${dt.month}/${dt.day}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                 );
                             } catch(e) { return const SizedBox(); }
                        }
                        return const SizedBox();
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide left numbers to keep it clean
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_growthStats.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: reviewSpots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: userSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                  ),
                ],
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                                final isReview = spot.barIndex == 0;
                                return LineTooltipItem(
                                    "${isReview ? l10n.newReviews : l10n.newUsers}: ${spot.y.toInt()}",
                                    TextStyle(color: isReview ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold)
                                );
                            }).toList();
                        }
                    )
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(l10n.newReviews, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(l10n.newUsers, style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStoreTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.storePerformance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _isAscending,
              columns: [
                DataColumn(label: Text(l10n.storeName), onSort: _sortData),
                DataColumn(label: Text(l10n.viewCount), numeric: true, onSort: _sortData),
                DataColumn(label: Text(l10n.reviewCount), numeric: true, onSort: _sortData),
                DataColumn(label: Text(l10n.helpful), numeric: true, onSort: _sortData),
                DataColumn(label: Text(l10n.conversionRate), numeric: true, onSort: _sortData),
              ],
              rows: _storeMetrics.map((store) {
                 return DataRow(cells: [
                     DataCell(Text(store['store_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600))),
                     DataCell(Text(NumberUtils.format(store['total_views'] as int? ?? 0))),
                     DataCell(Text(NumberUtils.format(store['review_count'] as int? ?? 0))),
                     DataCell(Text(NumberUtils.format(store['total_likes'] as int? ?? 0))),
                     DataCell(Text("${store['conversion_rate'] ?? 0}%")),
                 ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
