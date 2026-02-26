import 'package:flutter/material.dart';

class DispatchMapCard extends StatelessWidget {
  const DispatchMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMART DISPATCH MAP',
            style: TextStyle(
              // The "SMART DISPATCH MAP" and "WORK QUEUE" are inside a large white/grey rounded container.
              // So this text "SMART DISPATCH MAP" is actually part of that white sheet.
              // So I should style it as black text on white background.
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage('https://tile.openstreetmap.org/15/9643/12321.png'), // Placeholder
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
             child: Stack(
              children: [
                // Overlay some fake markers or path/route lines could be added here if needed, 
                // but for now just the bg image is fine + the button.
                
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937), // Dark button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Start Next Task'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
