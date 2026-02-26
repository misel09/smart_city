import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../pages/report_issue_page.dart';

class ReportIssueHero extends StatelessWidget {
  final String? mobileNumber;

  const ReportIssueHero({super.key, this.mobileNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Center(
        child: InkWell(
          onTap: () async {
            if (mobileNumber == null || mobileNumber!.isEmpty || mobileNumber == 'Not Set') {
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please verify your mobile number in the Profile tab before reporting an issue.'),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              }
              return;
            }

            Map<Permission, PermissionStatus> statuses = await [
              Permission.camera,
              Permission.location,
            ].request();

            final cameraStatus = statuses[Permission.camera];
            final locationStatus = statuses[Permission.location];

            if (cameraStatus!.isPermanentlyDenied || locationStatus!.isPermanentlyDenied) {
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera and Location permissions are required. Please enable them in settings.')),
                );
                openAppSettings();
              }
              return;
            }
            
            if (cameraStatus.isGranted) {
               final picker = ImagePicker();
               final pickedFile = await picker.pickImage(source: ImageSource.camera);
               
               if (pickedFile != null && context.mounted) {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportIssuePage(
                      initialImage: File(pickedFile.path),
                    ),
                  ),
                );
               }
            } else {
               if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permissions are required to report an issue')),
                );
              }
            }
          },

          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], // Vibrant blue gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Report New Issue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
