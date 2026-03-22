import 'package:flutter/material.dart';
import '../widgets/officer_analytics_charts.dart';

class OfficerAnalyticsTab extends StatelessWidget {
  const OfficerAnalyticsTab({super.key});

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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA68C8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFFBA68C8), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Data Insights',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    OfficerAnalyticsCharts(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
