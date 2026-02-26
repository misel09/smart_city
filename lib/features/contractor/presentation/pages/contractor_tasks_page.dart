import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/pages/contractor_complaint_details_page.dart';

class ContractorTasksPage extends StatefulWidget {
  const ContractorTasksPage({super.key});

  @override
  State<ContractorTasksPage> createState() => _ContractorTasksPageState();
}

class _ContractorTasksPageState extends State<ContractorTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF060D1F), Color(0xFF0A2744), Color(0xFF062038)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                   _buildTasksList(context, [ComplaintStatus.inProgress, ComplaintStatus.rejected]),
                  _buildTasksList(context,
                      [ComplaintStatus.resolved, ComplaintStatus.reviewed]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.assignment_rounded,
                color: Color(0xFF4FC3F7), size: 28),
          ),
          const SizedBox(width: 16),
          const Text(
            'My Tasks',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab, // Makes indicator take full width of tab
        dividerColor: Colors.transparent, // Removes the bottom border line of the TabBar
        indicator: BoxDecoration(
          color: const Color(0xFF4FC3F7).withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: const Color(0xFF4FC3F7).withOpacity(0.5), width: 1),
        ),
        labelColor: const Color(0xFF4FC3F7),
        unselectedLabelColor: Colors.white54,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildTasksList(
      BuildContext context, List<ComplaintStatus> statuses) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
        }

        final tasks = provider.takenComplaints
            .where((c) => statuses.contains(c.status))
            .toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 80, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'No tasks found',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _TaskCard(complaint: tasks[index]);
          },
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Complaint complaint;

  const _TaskCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: RawMaterialButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ContractorComplaintDetailsPage(complaint: complaint),
            ),
          );
        },
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: complaint.statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: complaint.statusColor.withOpacity(0.3)),
                        ),
                        child: Icon(
                          _getCategoryIcon(complaint.category),
                          color: complaint.statusColor,
                          size: 24,
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
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complaint.category,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStatusBadge(),
                          const SizedBox(height: 10),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 14),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.08), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: Colors.white.withOpacity(0.4),
                              size: 14),
                          const SizedBox(width: 6),
                          Text(
                            dateFormat.format(complaint.timestamp),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13),
                          ),
                        ],
                      ),
                      if (complaint.dueDate != null)
                        Row(
                          children: [
                            Icon(Icons.assignment_late_rounded,
                                color: Colors.redAccent.withOpacity(0.8),
                                size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Due: ${dateFormat.format(complaint.dueDate!)}',
                              style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: Colors.white.withOpacity(0.4),
                                size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Location Attached',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: complaint.statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: complaint.statusColor.withOpacity(0.3)),
      ),
      child: Text(
        complaint.statusText,
        style: TextStyle(
          color: complaint.statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'roads & traffic':
        return Icons.add_road_rounded;
      case 'waste management':
        return Icons.delete_outline_rounded;
      case 'water & sanitation':
        return Icons.water_drop_rounded;
      case 'electricity':
        return Icons.lightbulb_outline_rounded;
      case 'public safety':
        return Icons.security_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }
}
