import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/pages/complaint_details_page.dart';

class AllComplaintsList extends StatefulWidget {
  final int initialTabIndex;
  const AllComplaintsList({super.key, this.initialTabIndex = 0});

  @override
  State<AllComplaintsList> createState() => _AllComplaintsListState();
}

class _AllComplaintsListState extends State<AllComplaintsList> with SingleTickerProviderStateMixin {
  String _sortField = 'status';
  bool _sortAscending = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        var items = List<Complaint>.from(provider.allComplaints);

        // Sorting Logic
        items.sort((a, b) {
          int cmp = 0;
          switch (_sortField) {
            case 'status':
              cmp = _getStatusWeight(a.status).compareTo(_getStatusWeight(b.status));
              break;
            case 'date':
              cmp = a.timestamp.compareTo(b.timestamp);
              break;
            case 'type':
              cmp = a.category.toLowerCase().compareTo(b.category.toLowerCase());
              break;
            case 'priority':
              cmp = _getPriorityWeight(a.priority).compareTo(_getPriorityWeight(b.priority));
              break;
          }
          return _sortAscending ? cmp : -cmp;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TabBar styling
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorColor: const Color(0xFF4FC3F7),
              indicatorWeight: 3,
              labelColor: const Color(0xFF4FC3F7),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.white.withOpacity(0.05),
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'NEW'),
                Tab(text: 'WORKING'),
                Tab(text: 'SOLVED'),
                Tab(text: 'VERIFIED'),
                Tab(text: 'REJECTED'),
              ],
            ),
            const SizedBox(height: 8),

            // Sorting Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('SORT BY:', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(width: 12),
                  _buildSortChip('Normal', 'status'),
                  _buildSortChip('Date', 'date'),
                  _buildSortChip('Type', 'type'),
                  _buildSortChip('Priority', 'priority'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Use Expanded + TabBarView to show content per tab natively
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65, // Provide height for TabBarView inside SingleChildScrollView block
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildList(items, null),
                  _buildList(items, ComplaintStatus.registered),
                  _buildList(items, ComplaintStatus.inProgress),
                  _buildList(items, ComplaintStatus.resolved),
                  _buildList(items, ComplaintStatus.reviewed),
                  _buildList(items, ComplaintStatus.rejected),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildList(List<Complaint> items, ComplaintStatus? status) {
    var filtered = items;
    if (status != null) {
      filtered = items.where((c) => c.status == status).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${filtered.length} RESULTS',
                style: TextStyle(
                  color: const Color(0xFF4FC3F7).withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (filtered.isEmpty)
          Expanded(child: _buildEmptyState())
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ComplaintListItem(complaint: filtered[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSortChip(String label, String field) {
    final bool isActive = _sortField == field;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = field;
            _sortAscending = true;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4FC3F7).withOpacity(0.12) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? const Color(0xFF4FC3F7).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: const Color(0xFF4FC3F7), size: 12),
            ]
          ],
        ),
      ),
    );
  }

  int _getPriorityWeight(String p) {
    switch (p.toLowerCase()) {
      case 'urgent': return 3;
      case 'high': return 2;
      case 'normal': return 1;
      case 'low': return 0;
      default: return 1;
    }
  }

  int _getStatusWeight(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.registered: return 0;
      case ComplaintStatus.inProgress: return 1;
      case ComplaintStatus.resolved: return 2;
      case ComplaintStatus.reviewed: return 3;
      case ComplaintStatus.rejected: return 4;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, color: Colors.white.withOpacity(0.1), size: 64),
          const SizedBox(height: 16),
          Text(
            'No matching reports found',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _ComplaintListItem extends StatelessWidget {
  final Complaint complaint;

  const _ComplaintListItem({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = complaint.statusColor;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintDetailsPage(complaint: complaint),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconForStatus(complaint.status),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    complaint.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.3), size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          complaint.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    complaint.statusText.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: #${complaint.id.substring(0, complaint.id.length > 5 ? 5 : complaint.id.length)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForStatus(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.registered: return Icons.report_gmailerrorred_rounded;
      case ComplaintStatus.inProgress: return Icons.auto_awesome_motion_rounded;
      case ComplaintStatus.resolved: return Icons.task_alt_rounded;
      case ComplaintStatus.reviewed: return Icons.verified_rounded;
      case ComplaintStatus.rejected: return Icons.block_flipped;
    }
  }
}
