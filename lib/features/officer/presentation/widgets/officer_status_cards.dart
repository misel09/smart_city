import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import 'all_complaints_list.dart';

class OfficerStatusCards extends StatelessWidget {
  const OfficerStatusCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        final all = provider.allComplaints;
        
        final registered = all.where((c) => c.status == ComplaintStatus.registered).length;
        final inProgress = all.where((c) => c.status == ComplaintStatus.inProgress).length;
        final resolved = all.where((c) => c.status == ComplaintStatus.resolved).length;
        final reviewed = all.where((c) => c.status == ComplaintStatus.reviewed).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Row(
                children: [
                  _buildPremiumCard(
                    context: context,
                    title: 'New Issues',
                    count: registered.toString(),
                    colors: [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
                    icon: Icons.new_releases_outlined,
                    onTap: () => _navigateToFilteredIssues(context, 1, 'New Issues'),
                  ),
                  const SizedBox(width: 12),
                  _buildPremiumCard(
                    context: context,
                    title: 'In Progress',
                    count: inProgress.toString(),
                    colors: [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
                    icon: Icons.pending_actions_rounded,
                    onTap: () => _navigateToFilteredIssues(context, 2, 'In Progress Issues'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPremiumCard(
                    context: context,
                    title: 'Resolved',
                    count: resolved.toString(),
                    colors: [const Color(0xFF81C784), const Color(0xFF388E3C)],
                    icon: Icons.check_circle_outline_rounded,
                    onTap: () => _navigateToFilteredIssues(context, 3, 'Resolved Issues'),
                  ),
                  const SizedBox(width: 12),
                  _buildPremiumCard(
                    context: context,
                    title: 'Reviewed',
                    count: reviewed.toString(),
                    colors: [const Color(0xFFBA68C8), const Color(0xFF7B1FA2)],
                    icon: Icons.verified_user_outlined,
                    onTap: () => _navigateToFilteredIssues(context, 4, 'Reviewed Issues'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToFilteredIssues(BuildContext context, int tabIndex, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF060D1F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF060D1F),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: AllComplaintsList(initialTabIndex: tabIndex),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required BuildContext context,
    required String title,
    required String count,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors[0], size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
