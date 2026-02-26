import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../core/config/api_config.dart';

class ReviewDetailsPage extends StatefulWidget {
  final Complaint complaint;

  const ReviewDetailsPage({
    super.key,
    required this.complaint,
  });

  @override
  State<ReviewDetailsPage> createState() => _ReviewDetailsPageState();
}

class _ReviewDetailsPageState extends State<ReviewDetailsPage> {
  final _commentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(String status) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      await context.read<ComplaintsProvider>().reviewComplaint(
        widget.complaint.id,
        token,
        status,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'Reviewed' ? '✅ Report Approved!' : '❌ Report Rejected.'),
            backgroundColor: status == 'Reviewed' ? Colors.green.shade700 : Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red.shade700),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final dateString = DateFormat('EEEE, MMMM d, yyyy').format(complaint.timestamp);
    final timeString = DateFormat('hh:mm a').format(complaint.timestamp);

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
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateString · $timeString',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5), 
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: complaint.statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: complaint.statusColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: complaint.statusColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: complaint.statusColor, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            complaint.statusText.toUpperCase(),
                            style: TextStyle(
                                color: complaint.statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.05),
              ),

              // ── Body ─────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Before / After images
                      const SizedBox(height: 12), // Give some breathing room from the top
                      const Text('VISUAL EVIDENCE',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          _buildImageCard('Before Resolution', const Color(0xFFEF5350), complaint.imagePath, 'hero_before_${complaint.id}'),
                          const SizedBox(height: 28),
                          _buildImageCard('After Resolution', const Color(0xFF10B981), complaint.afterImagePath, 'hero_after_${complaint.id}'),
                        ],
                      ),
                      const SizedBox(height: 38),

                      if (complaint.status == ComplaintStatus.resolved) ...[

                      // Comment box
                      const Text('YOUR REVIEW COMMENT',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts on the resolution...',
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4FC3F7), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_isSubmitting)
                        const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
                      else
                        // Approve / Reject buttons
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                label: 'Approve',
                                gradient: const [Color(0xFF34D399), Color(0xFF059669)],
                                shadowColor: const Color(0xFF10B981),
                                icon: Icons.verified_rounded,
                                onTap: () => _submitReview('Reviewed'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _actionButton(
                                label: 'Reject',
                                gradient: const [Color(0xFFF87171), Color(0xFFDC2626)],
                                shadowColor: const Color(0xFFEF5350),
                                icon: Icons.cancel_presentation_rounded,
                                onTap: () => _submitReview('Rejected'),
                              ),
                            ),
                          ],
                        ),
                      ] else if (complaint.reviewComment != null && complaint.reviewComment!.isNotEmpty) ...[
                        const Text('REVIEW COMMENT',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            complaint.reviewComment!,
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                          ),
                        ),
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

  void _showFullScreenImage(BuildContext context, String imageUrl, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: tag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCard(String label, Color accent, String? path, String heroTag) {
    final hasImage = path != null && path.isNotEmpty;
    final imageUrl = hasImage ? '${ApiConfig.baseUrl}/${path.replaceAll('\\', '/')}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt_rounded, color: accent, size: 14),
            ),
            const SizedBox(width: 10),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: hasImage ? () => _showFullScreenImage(context, imageUrl, heroTag) : null,
          child: Container(
            width: double.infinity,
            height: 260, // Large, satisfying size
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Hero(
                      tag: heroTag,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),

                  if (!hasImage)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_rounded, color: Colors.white.withOpacity(0.15), size: 48),
                          const SizedBox(height: 12),
                          Text('No Photo Submitted', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  
                  if (hasImage)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    
                  if (hasImage)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            const Text('VIEW FULLSCREEN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required List<Color> gradient,
    required Color shadowColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
