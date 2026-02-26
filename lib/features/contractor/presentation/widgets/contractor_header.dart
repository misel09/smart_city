import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_city/core/config/api_config.dart';

class ContractorHeader extends StatefulWidget {
  const ContractorHeader({super.key});

  @override
  State<ContractorHeader> createState() => _ContractorHeaderState();
}

class _ContractorHeaderState extends State<ContractorHeader> {
  String _userName = 'Contractor';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        final res = await http.get(
          Uri.parse(ApiConfig.meUrl),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) {
            setState(() {
              _userName = data['username'] ?? 'Contractor';
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('MMM d, yyyy').format(now);
    final timeString = DateFormat('hh:mm a').format(now);

    final String initialChar = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF4FC3F7), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      dateString,
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      timeString,
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Profile Avatar with glowing border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF060D1F),
              radius: 26,
              child: Text(
                initialChar,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
