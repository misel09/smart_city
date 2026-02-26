import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/api_config.dart';
import '../../../reports/domain/models/complaint.dart';
import '../providers/complaints_provider.dart';
import '../widgets/status_timeline.dart';
import '../../../home/presentation/pages/review_details_page.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final Complaint complaint;

  const ComplaintDetailsPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

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
            children: [
              // ── AppBar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white70, size: 18),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Task Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // balance
                  ],
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status chip
                      Text(
                        widget.complaint.title,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.complaint.statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: widget.complaint.statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          widget.complaint.statusText,
                          style: TextStyle(
                              color: widget.complaint.statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Priority & Due Date ────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: widget.complaint.priority == 'Urgent' 
                                    ? Colors.red.withOpacity(0.15)
                                    : widget.complaint.priority == 'High'
                                        ? Colors.orange.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: widget.complaint.priority == 'Urgent' 
                                        ? Colors.red.withOpacity(0.5)
                                        : widget.complaint.priority == 'High'
                                            ? Colors.orange.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Priority', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.complaint.priority,
                                    style: TextStyle(
                                      color: widget.complaint.priority == 'Urgent' || widget.complaint.priority == 'High'
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ]
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Due By', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.complaint.dueDate != null 
                                      ? '${dateFormat.format(widget.complaint.dueDate!)}'
                                      : 'Not Set',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ]
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Reporter Details (Contractors only) ─────────────────
                      // Removed Complained By Details (Only meant for Contractors)

                      // ── Contractor Details (citizens only, when In Progress or beyond) ──
                      if (widget.complaint.status != ComplaintStatus.registered &&
                          widget.complaint.contractorEmail != null) ...[
                        _sectionLabel('Assigned Contractor'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.10),
                                const Color(0xFF10B981).withOpacity(0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.35)),
                                    ),
                                    child: const Icon(Icons.handyman_rounded,
                                        color: Color(0xFF10B981), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.complaint.contractorName ?? 'Assigned Contractor',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text('Contractor',
                                            style: TextStyle(
                                                color: Color(0xFF10B981), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: Colors.white10, height: 1),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.email_rounded,
                                    color: Colors.white54, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.complaint.contractorEmail!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ),
                              ]),
                              if (widget.complaint.contractorMobile != null &&
                                  widget.complaint.contractorMobile!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  const Icon(Icons.phone_rounded,
                                      color: Colors.white54, size: 16),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.complaint.contractorMobile!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],


                      // ── Section label helper
                      ...[
                        _sectionLabel('Visual Evidence'),
                        const SizedBox(height: 12),
                        // Image
                        Container(
                          height: 230,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _buildImage(widget.complaint.imagePath),
                          ),
                        ),
                        const SizedBox(height: 28),

                        _sectionLabel('Description'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            widget.complaint.description,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Contractor Evidence (if resolved) ─────────────────
                        if (widget.complaint.afterImagePath != null && widget.complaint.afterImagePath!.isNotEmpty) ...[
                          _sectionLabel('Contractor\'s Evidence'),
                          const SizedBox(height: 12),
                          Container(
                            height: 230,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: _buildImage(widget.complaint.afterImagePath),
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          if (widget.complaint.afterDescription != null && widget.complaint.afterDescription!.isNotEmpty) ...[
                            _sectionLabel('Contractor\'s Notes'),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.1)),
                              ),
                              child: Text(
                                widget.complaint.afterDescription!,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    height: 1.6),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ],

                        _sectionLabel('Status Updates'),
                        const SizedBox(height: 12),
                        ..._buildDynamicTimeline(widget.complaint, dateFormat, timeFormat, isCitizen: true),
                        const SizedBox(height: 28),

                        // Location card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4FC3F7)
                                      .withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    color: Color(0xFF4FC3F7), size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.complaint.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${dateFormat.format(widget.complaint.timestamp)}, ${timeFormat.format(widget.complaint.timestamp)}',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // ── Review Button ──────────────────────────────────────
                        if (widget.complaint.status == ComplaintStatus.resolved) ...[
                          const SizedBox(height: 32),
                          Container(
                            height: 54,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF34D399), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewDetailsPage(complaint: widget.complaint),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.rate_review_rounded, size: 20, color: Colors.white),
                              label: const Text(
                                'Review Resolution',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1),
      );

  Widget _buildImage(String? path) {
    if (path == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.white24),
            SizedBox(height: 8),
            Text('No Image', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    if (path.startsWith('http')) {
      return CachedNetworkImage(
          imageUrl: path,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator(color: Colors.white38)),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white38, size: 48));
    }
    if (path.startsWith('uploads/')) {
      return CachedNetworkImage(
          imageUrl: '${ApiConfig.baseUrl}/$path',
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator(color: Colors.white38)),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white38, size: 48));
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _timelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isEnd,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.18), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isEnd)
                Expanded(
                  child: Container(
                      width: 2,
                      color: Colors.white.withOpacity(0.12)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicTimeline(Complaint c, DateFormat dateFormat, DateFormat timeFormat, {required bool isCitizen}) {
    List<Map<String, dynamic>> events = [];

    events.add({
      'time': c.timestamp,
      'icon': Icons.check_circle_rounded,
      'color': const Color(0xFF10B981),
      'title': 'Reported on ${dateFormat.format(c.timestamp)} at ${timeFormat.format(c.timestamp)}',
      'subtitle': isCitizen ? 'We have received your report.' : 'Report received by Smart City.',
    });

    if (c.takenAt != null) {
      events.add({
        'time': c.takenAt!,
        'icon': Icons.sync_rounded,
        'color': const Color(0xFF4FC3F7),
        'title': 'Under Review on ${dateFormat.format(c.takenAt!)} at ${timeFormat.format(c.takenAt!)}',
        'subtitle': 'A contractor has been assigned.',
      });
    }

    if (c.resolvedAt != null) {
      events.add({
        'time': c.resolvedAt!,
        'icon': Icons.handyman_rounded,
        'color': Colors.orange,
        'title': 'Resolved on ${dateFormat.format(c.resolvedAt!)} at ${timeFormat.format(c.resolvedAt!)}',
        'subtitle': 'Contractor has finished the work.',
      });
    }

    if (c.reviewedAt != null) {
      bool rejectedEvent = c.status == ComplaintStatus.rejected || (c.reviewComment != null && c.reviewComment!.isNotEmpty);
      // If the task was rejected and then re-resolved, label it as 'Rejected' based on reviewComment presence
      bool wasRejected = c.reviewComment != null && c.reviewComment!.isNotEmpty;
      events.add({
        'time': c.reviewedAt!,
        'icon': (rejectedEvent || wasRejected) ? Icons.cancel_rounded : Icons.verified_rounded,
        'color': (rejectedEvent || wasRejected) ? Colors.red : Colors.teal,
        'title': '${(rejectedEvent || wasRejected) ? "Rejected" : "Reviewed"} on ${dateFormat.format(c.reviewedAt!)} at ${timeFormat.format(c.reviewedAt!)}',
        'subtitle': (rejectedEvent || wasRejected) ? 'Work was rejected.' : 'Work was verified and approved.',
      });
    }

    events.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    return List.generate(events.length, (index) {
      final e = events[index];
      return _timelineItem(
        icon: e['icon'] as IconData,
        color: e['color'] as Color,
        title: e['title'] as String,
        subtitle: e['subtitle'] as String,
        isEnd: index == events.length - 1,
      );
    });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2744),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this report? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(
                    color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        try {
          await context.read<ComplaintsProvider>().deleteComplaint(widget.complaint.id, token);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report deleted')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: $e'),
                  backgroundColor: Colors.red));
          }
        }
      }
    }
  }
}
