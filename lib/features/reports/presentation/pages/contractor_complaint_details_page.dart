import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/api_config.dart';
import '../../../reports/domain/models/complaint.dart';
import '../providers/complaints_provider.dart';
import 'task_resolution_page.dart';
import '../widgets/status_timeline.dart';

class ContractorComplaintDetailsPage extends StatefulWidget {
  final Complaint complaint;

  const ContractorComplaintDetailsPage({super.key, required this.complaint});

  @override
  State<ContractorComplaintDetailsPage> createState() =>
      _ContractorComplaintDetailsPageState();
}

class _ContractorComplaintDetailsPageState
    extends State<ContractorComplaintDetailsPage> {
  bool _isTaking = false;

  // Freshly fetched complainant details (may override the complaint's cached values)
  String? _complainantMobile;
  String? _complainantName;
  bool _isFetchingUser = true;

  // Contractor's own mobile verification state
  bool _isMobileVerified = false;
  String? _contractorEmail;
  bool _isFetchingContractorInfo = true;

  @override
  void initState() {
    super.initState();
    _fetchComplainantInfo();
    _fetchContractorInfo();
  }

  Future<void> _fetchComplainantInfo() async {
    final email = widget.complaint.userEmail;
    if (email == null || email.isEmpty) {
      if (mounted) setState(() => _isFetchingUser = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;
      final res = await http
          .get(
            Uri.parse(ApiConfig.userInfoUrl(email)),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _complainantName = data['username'] as String?;
          _complainantMobile = data['mobile_number'] as String?;
        });
      }
    } catch (_) {
      // Fall back to data already in complaint object
    } finally {
      if (mounted) setState(() => _isFetchingUser = false);
    }
  }

  Future<void> _fetchContractorInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;
      final res = await http
          .get(
            Uri.parse(ApiConfig.meUrl),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final mobile = data['mobile_number'] as String?;
        setState(() {
          _isMobileVerified = mobile != null && mobile.isNotEmpty;
          _contractorEmail = data['email'] as String?;
        });
      }
    } catch (_) {
      // Leave _isMobileVerified as false on error
    } finally {
      if (mounted) setState(() => _isFetchingContractorInfo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final c = widget.complaint;

    print('--- DEBUG ACTION BUTTONS ---');
    print('c.contractorEmail: "${c.contractorEmail}"');
    print('_contractorEmail: "$_contractorEmail"');
    print('c.status: ${c.status}');
    print('c.contractorEmail != null: ${c.contractorEmail != null}');
    if (c.contractorEmail != null && _contractorEmail != null) {
      print('c.contractorEmail matches _contractorEmail: ${c.contractorEmail!.toLowerCase().trim() == _contractorEmail!.toLowerCase().trim()}');
    }
    print('----------------------------');

    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      // ── Fixed bottom action bar ──────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060D1F),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
        child: _isFetchingContractorInfo
            ? Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white38),
                  ),
                ),
              )
            : c.contractorEmail != null && c.contractorEmail!.isNotEmpty
                ? (c.contractorEmail!.toLowerCase().trim() == _contractorEmail?.toLowerCase().trim())
                // ── This contractor's task ─────────────────────────────────
                ? ((c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.reviewed)
                    ? Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Task Completed',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B4DB).withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final resolved = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskResolutionPage(complaint: c),
                              ),
                            );
                            if (resolved == true) {
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 20, color: Colors.white),
                          label: Text(
                            c.status == ComplaintStatus.rejected ? 'Re-complete Task' : 'Complete Task',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                // ── Other contractor's task ────────────────────────────────
                : Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded,
                            color: Colors.grey, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Task Already Claimed',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  )
            // ── Not yet claimed ─────────────────────────────────────────
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning banner if mobile not verified
                  if (!_isFetchingContractorInfo && !_isMobileVerified)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Verify your mobile number in Profile to take tasks.',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Take Task button (disabled if mobile not verified)
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _isMobileVerified
                          ? const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _isMobileVerified
                          ? null
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: _isMobileVerified
                          ? null
                          : Border.all(
                              color: Colors.white.withOpacity(0.12)),
                      boxShadow: _isMobileVerified
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00B4DB)
                                    .withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton.icon(
                      // Null onPressed disables the button
                      onPressed: (_isMobileVerified && !_isTaking)
                          ? _takeTask
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isTaking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white))
                          : Icon(
                              _isMobileVerified
                                  ? Icons.assignment_turned_in_rounded
                                  : Icons.lock_outline_rounded,
                              size: 20,
                              color: _isMobileVerified
                                  ? Colors.white
                                  : Colors.white30),
                      label: Text(
                        _isTaking
                            ? 'Claiming...'
                            : _isMobileVerified
                                ? 'Take This Task'
                                : 'Mobile Not Verified',
                        style: TextStyle(
                          color: _isMobileVerified
                              ? Colors.white
                              : Colors.white30,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
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
              // ── AppBar ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ── Scrollable Body ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Status chip
                      Text(
                        c.title,
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
                          color: c.statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: c.statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          c.statusText,
                          style: TextStyle(
                              color: c.statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Priority & Due Date ───────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _infoCard(
                              label: 'Priority',
                              value: c.priority,
                              color: c.priority == 'Urgent'
                                  ? Colors.red
                                  : c.priority == 'High'
                                      ? Colors.orange
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoCard(
                              label: 'Due By',
                              value: c.dueDate != null
                                  ? dateFormat.format(c.dueDate!)
                                  : 'Not Set',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Complained By Card ────────────────────────────────
                      _sectionLabel('COMPLAINED BY'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4FC3F7).withOpacity(0.12),
                              const Color(0xFF0083B0).withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF4FC3F7).withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar + name row
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF4FC3F7)
                                            .withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: Color(0xFF4FC3F7), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _complainantName ?? c.userName ?? 'Unknown Citizen',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Citizen',
                                        style: TextStyle(
                                            color: Color(0xFF4FC3F7),
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 14),

                            // Email
                            _contactRow(
                              icon: Icons.email_rounded,
                              text: c.userEmail ?? 'No email provided',
                            ),

                            // Mobile — always try fresh value first
                            const SizedBox(height: 10),
                            if (_isFetchingUser)
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded,
                                      color: Colors.white54, size: 16),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 12,
                                    width: 80,
                                    child: LinearProgressIndicator(
                                      color: const Color(0xFF4FC3F7),
                                      backgroundColor: Colors.white12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              )
                            else if ((_complainantMobile ?? c.userMobile) != null &&
                                (_complainantMobile ?? c.userMobile)!.isNotEmpty)
                              _contactRow(
                                icon: Icons.phone_rounded,
                                text: (_complainantMobile ?? c.userMobile)!,
                                isPhone: true,
                              )
                            else
                              _contactRow(
                                icon: Icons.phone_rounded,
                                text: 'Mobile not added by citizen',
                                dimmed: true,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Visual Evidence ────────────────────────────────────
                      _sectionLabel('VISUAL EVIDENCE'),
                      const SizedBox(height: 12),
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
                          child: _buildImage(c.imagePath),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Description ────────────────────────────────────────
                      _sectionLabel('DESCRIPTION'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          c.description,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.reviewed || c.status == ComplaintStatus.rejected) ...[
                        // ── Resolution Evidence ────────────────────────────────
                        _sectionLabel('CONTRACTOR RESOLUTION'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.12),
                                const Color(0xFF0083B0).withOpacity(0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildImage(c.afterImagePath),
                                ),
                              ),
                              if (c.afterDescription != null && c.afterDescription!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10, height: 1),
                                const SizedBox(height: 14),
                                const Text('Logs & Notes:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(
                                  c.afterDescription!,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                                ),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      if (c.status == ComplaintStatus.reviewed || c.status == ComplaintStatus.rejected) ...[
                        _sectionLabel('CITIZEN REVIEW FEEDBACK'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: c.status == ComplaintStatus.reviewed ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF5350).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: c.status == ComplaintStatus.reviewed ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF5350).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(c.status == ComplaintStatus.reviewed ? Icons.verified : Icons.cancel, color: c.status == ComplaintStatus.reviewed ? const Color(0xFF10B981) : const Color(0xFFEF5350), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.status == ComplaintStatus.reviewed ? 'Work was Approved' : 'Work was Rejected',
                                    style: TextStyle(
                                      color: c.status == ComplaintStatus.reviewed ? const Color(0xFF10B981) : const Color(0xFFEF5350),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              if (c.reviewComment != null && c.reviewComment!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  c.reviewComment!,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      _sectionLabel('STATUS UPDATES'),
                      const SizedBox(height: 12),
                      ..._buildDynamicTimeline(c, dateFormat, timeFormat, isCitizen: false),
                      const SizedBox(height: 28),

                      // ── Location Card ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FC3F7).withOpacity(0.15),
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
                                    c.address.isNotEmpty
                                        ? c.address
                                        : 'Location not available',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateFormat.format(c.timestamp)}, ${timeFormat.format(c.timestamp)}',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                       const SizedBox(height: 24),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      );

  Widget _infoCard({
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color != null
            ? color.withOpacity(0.12)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color != null
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color != null ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String text,
    bool isPhone = false,
    bool dimmed = false,
  }) {
    return Row(
      children: [
        Icon(icon,
            color: dimmed ? Colors.white24 : Colors.white54, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: dimmed ? Colors.white30 : Colors.white70,
              fontSize: 13,
              fontStyle:
                  dimmed ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

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
    
    // Normalize path separators for web/network use
    final sanitizedPath = path.replaceAll('\\', '/');

    if (sanitizedPath.startsWith('http')) {
      return CachedNetworkImage(
          imageUrl: sanitizedPath,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white38)),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white38, size: 48));
    }
    if (sanitizedPath.startsWith('uploads/')) {
      return CachedNetworkImage(
          imageUrl: '${ApiConfig.baseUrl}/$sanitizedPath',
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white38)),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white38, size: 48));
    }
    return Image.file(File(sanitizedPath), fit: BoxFit.cover);
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
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),
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
      bool isRejected = c.status == ComplaintStatus.rejected;
      events.add({
        'time': c.reviewedAt!,
        'icon': isRejected ? Icons.cancel_rounded : Icons.verified_rounded,
        'color': isRejected ? Colors.red : Colors.teal,
        'title': isRejected ? 'Rejected on ${dateFormat.format(c.reviewedAt!)} at ${timeFormat.format(c.reviewedAt!)}' : 'Approved on ${dateFormat.format(c.reviewedAt!)} at ${timeFormat.format(c.reviewedAt!)}',
        'subtitle': isRejected ? 'Work was rejected.' : 'Work was verified and approved.',
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

  Future<void> _takeTask() async {
    setState(() => _isTaking = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && mounted) {
        await context
            .read<ComplaintsProvider>()
            .takeComplaint(widget.complaint.id, token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task claimed successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  Future<void> _completeTask() async {
    setState(() => _isTaking = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && mounted) {
        // Assume context.read<ComplaintsProvider>().resolveComplaint(id, token, desc, imagePath) exists
        await context
            .read<ComplaintsProvider>()
            .resolveComplaint(widget.complaint.id, token, "Resolved via quick action", "");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task marked as completed!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }
}
