import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../pages/heatmap_view_page.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';

const List<String> _allCategories = [
  'Damaged concrete structures',
  'Damaged Electrical Poles',
  'Damaged Road Signs',
  'Dead Animals / Pollution',
  'Fallen Trees',
  'Garbage',
  'Graffiti',
  'Illegal Parking',
  'Potholes and Road Cracks',
];

class OfficerAnalyticsCharts extends StatefulWidget {
  const OfficerAnalyticsCharts({super.key});

  @override
  State<OfficerAnalyticsCharts> createState() => _OfficerAnalyticsChartsState();
}

class _OfficerAnalyticsChartsState extends State<OfficerAnalyticsCharts> {
  int _touchedStatusPieIndex = -1;
  String _selectedFilterCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        final allComplaints = provider.allComplaints;
        if (allComplaints.isEmpty) return const SizedBox();

        // Apply category filter for Pie + Resolution charts
        final filteredComplaints = _selectedFilterCategory == 'All'
            ? allComplaints
            : allComplaints.where((c) => c.category == _selectedFilterCategory).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Work Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // ── Shared Category Filter ──────────────────────────────────
              _buildCategoryFilter(),
              const SizedBox(height: 20),

              // 1. Overall Status Distribution (Pie)
              _buildStatusPieChart(filteredComplaints),
              const SizedBox(height: 16),

              // 2. Total vs Resolved (Bar)
              _buildTotalVsResolvedChart(filteredComplaints),
              const SizedBox(height: 16),

              // 3. Heatmap
              _buildHeatmapChart(filteredComplaints),
              const SizedBox(height: 16),

              // 4. Top 3 Categories (Bar, full names)
              _buildCategoryBarChart(allComplaints),
              const SizedBox(height: 16),

              // 5. Lifecycle: all 9 categories on x-axis
              _buildStackedStatusChart(allComplaints),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  //  Shared Category Filter Dropdown
  // --------------------------------------------------------------------------
  Widget _buildCategoryFilter() {
    final options = ['All', ..._allCategories];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: const Color(0xFF0A2744),
          value: _selectedFilterCategory,
          icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF4FC3F7), size: 20),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          items: options.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedFilterCategory = val;
                _touchedStatusPieIndex = -1;
              });
            }
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. Overall Status Pie Chart
  // --------------------------------------------------------------------------
  Widget _buildStatusPieChart(List<Complaint> complaints) {
    final registered = complaints.where((c) => c.status == ComplaintStatus.registered).length;
    final inProgress = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final reviewed = complaints.where((c) => c.status == ComplaintStatus.reviewed).length;
    final rejected = complaints.where((c) => c.status == ComplaintStatus.rejected).length;
    final total = complaints.length;

    if (total == 0) {
      return _buildChartContainer(
        title: 'Issue Status Distribution',
        height: 160,
        child: const Center(child: Text('No data for selected category', style: TextStyle(color: Colors.white54))),
      );
    }

    // All 5 sections always shown — even at 0 they appear as a thin sliver
    final rawSections = [
      (count: registered, color: const Color(0xFF4FC3F7)),
      (count: inProgress, color: const Color(0xFFFFB74D)),
      (count: resolved,   color: const Color(0xFF81C784)),
      (count: reviewed,   color: const Color(0xFFBA68C8)),
      (count: rejected,   color: const Color(0xFFE57373)),
    ];
    final activeSections = rawSections.where((s) => s.count > 0).toList();
    final activeTouchedIdx = _touchedStatusPieIndex;

    return _buildChartContainer(
      title: 'Issue Status Distribution',
      height: 260,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedStatusPieIndex = -1;
                        return;
                      }
                      _touchedStatusPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 38,
                sections: List.generate(activeSections.length, (i) {
                  final s = activeSections[i];
                  return _pieSection(s.count, total, s.color, activeTouchedIdx == i);
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (registered > 0) _legendItem(const Color(0xFF4FC3F7), 'New ($registered)'),
                if (inProgress > 0) _legendItem(const Color(0xFFFFB74D), 'Working ($inProgress)'),
                if (resolved > 0)   _legendItem(const Color(0xFF81C784), 'Solved ($resolved)'),
                if (reviewed > 0)   _legendItem(const Color(0xFFBA68C8), 'Verified ($reviewed)'),
                if (rejected > 0)   _legendItem(const Color(0xFFE57373), 'Rejected ($rejected)'),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. Total vs Resolved Bar Chart
  // --------------------------------------------------------------------------
  Widget _buildTotalVsResolvedChart(List<Complaint> complaints) {
    final total = complaints.length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.reviewed).length;

    if (total == 0) {
      return _buildChartContainer(
        title: 'Resolution Progress',
        height: 160,
        child: const Center(child: Text('No data for selected category', style: TextStyle(color: Colors.white54))),
      );
    }

    return _buildChartContainer(
      title: 'Resolution Progress',
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: total.toDouble() + (total * 0.3),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withOpacity(0.8),
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.2)),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = group.x == 0 ? 'Total Issues' : 'Resolved';
                final count = rod.toY.toInt();
                final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
                return BarTooltipItem(
                  '$label\n$count issues  ($pct%)',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  final count = value == 0 ? total : resolved;
                  final label = value == 0 ? 'Total Issues' : 'Resolved';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: total.toDouble(),
                  color: const Color(0xFF4FC3F7),
                  width: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: resolved.toDouble(),
                  color: const Color(0xFF81C784),
                  width: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. Top 3 Categories Bar Chart — full names, rotated labels
  // --------------------------------------------------------------------------
  Widget _buildCategoryBarChart(List<Complaint> complaints) {
    final Map<String, int> counts = {};
    for (var c in complaints) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) return const SizedBox();

    final maxY = (top3.first.value).toDouble() + 3;

    return _buildChartContainer(
      title: 'Top 3 Categories',
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withOpacity(0.8),
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.2)),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final name = top3[group.x.toInt()].key;
                final count = rod.toY.toInt();
                final pct = complaints.isNotEmpty ? (count / complaints.length * 100).toStringAsFixed(0) : '0';
                return BarTooltipItem(
                  '$name\n$count issues  ($pct%)',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 68,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= top3.length) return const SizedBox();
                  final name = top3[idx].key;
                  final count = top3[idx].value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: SizedBox(
                      width: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(top3.length, (i) {
            final colors = [const Color(0xFF4FC3F7), const Color(0xFFFFB74D), const Color(0xFF81C784)];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: top3[i].value.toDouble(),
                  color: colors[i],
                  width: 36,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. Complaint Density Heatmap
  // --------------------------------------------------------------------------
  Widget _buildHeatmapChart(List<Complaint> complaints) {
    if (complaints.isEmpty) return const SizedBox();

    LatLng center = const LatLng(22.57, 72.93);
    if (complaints.isNotEmpty) {
      center = complaints.first.location;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HeatmapViewPage(complaints: complaints),
          ),
        );
      },
      child: _buildChartContainer(
        title: 'Complaint Density Heatmap',
        height: 250,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IgnorePointer(
            ignoring: true,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartcity.app',
                ),
                MarkerLayer(
                  markers: complaints.map((c) {
                    return Marker(
                      point: c.location,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 15,
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. Lifecycle: all 9 categories on X-axis
  // --------------------------------------------------------------------------
  Widget _buildStackedStatusChart(List<Complaint> complaints) {
    // Build per-category counts
    final data = _allCategories.map((cat) {
      final catItems = complaints.where((c) => c.category == cat);
      final resolved = catItems.where((c) => c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.reviewed).length.toDouble();
      final inProgress = catItems.where((c) => c.status == ComplaintStatus.inProgress).length.toDouble();
      final registered = catItems.where((c) => c.status == ComplaintStatus.registered).length.toDouble();
      return (cat: cat, registered: registered, inProgress: inProgress, resolved: resolved, total: registered + inProgress + resolved);
    }).toList();

    final maxY = data.map((d) => d.total).fold(0.0, (a, b) => a > b ? a : b);

    return _buildChartContainer(
      title: 'Issue Lifecycle by Category',
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 1 : maxY + (maxY * 0.2),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.1)),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = data[group.x.toInt()];
                      return BarTooltipItem(
                        '${d.cat}\n'
                        'New: ${d.registered.toInt()}  Working: ${d.inProgress.toInt()}  Solved: ${d.resolved.toInt()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox();
                        // Short label: first word or abbreviation
                        final words = data[idx].cat.split(' ');
                        final label = words.length >= 2 ? '${words[0][0]}${words[1][0]}' : data[idx].cat.substring(0, 3);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            label.toUpperCase(),
                            style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  final d = data[i];
                  final total = d.total;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total == 0 ? 0 : total,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: total == 0
                            ? []
                            : [
                                BarChartRodStackItem(0, d.resolved, const Color(0xFF81C784)),
                                BarChartRodStackItem(d.resolved, d.resolved + d.inProgress, const Color(0xFFFFB74D)),
                                BarChartRodStackItem(d.resolved + d.inProgress, total, const Color(0xFF4FC3F7)),
                              ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Full name legend scrollable
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final words = _allCategories[i].split(' ');
                final abbr = words.length >= 2 ? '${words[0][0]}${words[1][0]}' : _allCategories[i].substring(0, 3);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Text(abbr.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _allCategories[i],
                      style: const TextStyle(color: Colors.white60, fontSize: 9),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(const Color(0xFF4FC3F7), 'Pending'),
              _legendItem(const Color(0xFFFFB74D), 'Working'),
              _legendItem(const Color(0xFF81C784), 'Resolved'),
            ],
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------
  Widget _buildChartContainer({required String title, required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
      ),
    );
  }

  PieChartSectionData _pieSection(int count, int total, Color color, bool isTouched) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return PieChartSectionData(
      value: count.toDouble(),
      color: isTouched ? color : color.withOpacity(0.85),
      radius: isTouched ? 30 : 20,
      title: isTouched ? '$pct%' : '$count',
      titleStyle: TextStyle(
        color: Colors.white,
        fontSize: isTouched ? 11 : 10,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
      badgeWidget: isTouched ? _buildDetailBadge(count, pct) : null,
      badgePositionPercentageOffset: 1.4,
    );
  }

  Widget _buildDetailBadge(int count, String pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.2)),
          Text('$pct%', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600, height: 1.1)),
        ],
      ),
    );
  }
}
