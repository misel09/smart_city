import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import 'review_details_page.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && mounted) {
      context.read<ComplaintsProvider>().fetchComplaints(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintsProvider>(context);
    final myComplaints = provider.myComplaints;

    final pendingReviews = myComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
    final completedReviews = myComplaints.where((c) => 
      c.status == ComplaintStatus.reviewed || c.status == ComplaintStatus.rejected
    ).toList();

    return Scaffold(
      body: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.fact_check_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Resolved reports awaiting your review',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Tab Bar ──────────────────────────────────────────────
              _buildTabBar(),

              // ── List ─────────────────────────────────────────────────
              Expanded(
                child: provider.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReviewList(pendingReviews, 'PENDING YOUR REVIEW', 'No pending reviews.'),
                        _buildReviewList(completedReviews, 'REVIEW COMPLETED', 'No completed reviews.'),
                      ],
                    ),
              ),
            ],
          ),
        ),
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
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFF4FC3F7).withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: const Color(0xFF4FC3F7).withOpacity(0.5), width: 1),
        ),
        labelColor: const Color(0xFF4FC3F7),
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<Complaint> reviews, String label, String emptyMsg) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: reviews.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 10),
            child: _sectionLabel(label),
          );
        }
        final c = reviews[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _reviewCard(
            context: context,
            complaint: c,
            navigable: true,
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _reviewCard({
    required BuildContext context,
    required Complaint complaint,
    bool navigable = true,
  }) {
    Color statusColor;
    IconData leadingIcon;
    Color leadingColor;

    if (complaint.status == ComplaintStatus.resolved) {
      statusColor = const Color(0xFF4FC3F7);
      leadingIcon = Icons.check_circle_rounded;
      leadingColor = const Color(0xFF10B981);
    } else if (complaint.status == ComplaintStatus.reviewed) {
      statusColor = const Color(0xFF10B981); // Green for approved
      leadingIcon = Icons.verified_rounded;
      leadingColor = const Color(0xFF4FC3F7);
    } else {
      statusColor = const Color(0xFFEF5350); // Red for rejected
      leadingIcon = Icons.cancel_rounded;
      leadingColor = const Color(0xFFEF5350);
    }

    return GestureDetector(
      onTap: navigable
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReviewDetailsPage(complaint: complaint),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(leadingIcon, color: leadingColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(complaint.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(complaint.category,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(complaint.statusText.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            if (navigable) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white38, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
