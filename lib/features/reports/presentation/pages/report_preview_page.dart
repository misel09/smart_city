import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../domain/models/complaint.dart';
import 'package:smart_city/core/config/api_config.dart';

class ReportPreviewPage extends StatelessWidget {
  final Complaint complaint;
  final String? complainantName;

  const ReportPreviewPage({
    super.key,
    required this.complaint,
    this.complainantName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text('Report Preview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0B1224),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (format) => _generatePdf(format),
        canDebug: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        pdfFileName: 'UrbanReport_${_getShortId(complaint.id)}.pdf',
        previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('MMM d, yyyy').format(complaint.timestamp);
    final timeStr = DateFormat('h:mm a').format(complaint.timestamp);

    // Resolve Images
    pw.ImageProvider? beforeImage;
    pw.ImageProvider? afterImage;

    if (complaint.imagePath != null && complaint.imagePath!.isNotEmpty) {
      beforeImage = await _resolveImageProvider(complaint.imagePath!);
    }
    if (complaint.afterImagePath != null && complaint.afterImagePath!.isNotEmpty) {
      afterImage = await _resolveImageProvider(complaint.afterImagePath!);
    }

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
      italic: await PdfGoogleFonts.openSansItalic(),
    );

    // PAGE 1: CASE SUMMARY & STAKEHOLDERS
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(0),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Classic Header with Dark Background
              pw.Container(
                width: double.infinity,
                color: PdfColors.grey900,
                padding: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 32),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SMART CITY',
                            style: pw.TextStyle(
                                fontSize: 28,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white)),
                        pw.Text('INFRASTRUCTURE MANAGEMENT SYSTEM',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey400, letterSpacing: 1.5)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('OFFICIAL REPORT',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ),
                  ],
                ),
              ),
              
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('I. EXECUTIVE SUMMARY'),
                    pw.Row(
                      children: [
                        pw.Expanded(child: _infoRow('Case Reference', '#${_getShortId(complaint.id)}')),
                        pw.Expanded(child: _infoRow('Priority', complaint.priority)),
                      ],
                    ),
                    _infoRow('Issue Title', complaint.title),
                    _infoRow('Classification', complaint.category),
                    pw.Row(
                      children: [
                        pw.Text('Status: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          decoration: pw.BoxDecoration(
                            color: _getStatusColor(complaint.status),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                          child: pw.Text(complaint.statusText.toUpperCase(), style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    
                    _sectionTitle('II. GEOGRAPHICAL CONTEXT'),
                    _infoRow('Site Address', complaint.address),
                    _infoRow('Report Coordinates', '${complaint.location.latitude.toStringAsFixed(6)}, ${complaint.location.longitude.toStringAsFixed(6)}'),
                    _infoRow('Record Date', '$dateStr at $timeStr'),
                    pw.SizedBox(height: 20),
                    
                    _sectionTitle('III. STAKEHOLDERS'),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('REPORTING CITIZEN', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                              pw.Text(complainantName ?? complaint.userName ?? 'Anonymous', style: const pw.TextStyle(fontSize: 11)),
                              pw.Text(complaint.userEmail ?? 'Not provided', style: pw.TextStyle(fontSize: 10, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (complaint.contractorEmail != null)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('ASSIGNED PROFESSIONAL', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                                pw.Text(complaint.contractorName ?? 'Contractor', style: const pw.TextStyle(fontSize: 11)),
                                pw.Text(complaint.contractorEmail!, style: pw.TextStyle(fontSize: 10, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    pw.SizedBox(height: 30),
                    _sectionTitle('IV. DETAILED CASE NARRATIVE'),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 4)),
                      ),
                      child: pw.Text(complaint.description, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.8)),
                    ),
                    
                    if (complaint.afterDescription != null && complaint.afterDescription!.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      _sectionTitle('REPAIR / RESOLUTION NOTES'),
                      pw.Text(complaint.afterDescription!, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                    ],
                  ],
                ),
              ),
              
              pw.Spacer(),
              pw.Container(
                width: double.infinity,
                color: PdfColors.grey100,
                padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('OFFICIAL DOCUMENT | PAGE 1 OF 2', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('VERIFICATION ID: ${complaint.id.toUpperCase()}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // PAGE 2: EVIDENCE & TIMELINE
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(0),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildMiniHeader(complaint),
              
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('V. VISUAL EVIDENCE ARCHIVE (PHOTOS)'),
                    pw.SizedBox(height: 10),
                    if (beforeImage != null || afterImage != null) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (beforeImage != null)
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    color: PdfColors.grey800,
                                    child: pw.Text('INITIAL STATE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Container(
                                    height: 240,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                                    ),
                                    child: pw.Image(beforeImage, fit: pw.BoxFit.cover),
                                  ),
                                ],
                              ),
                            ),
                          if (beforeImage != null && afterImage != null) pw.SizedBox(width: 30),
                          if (afterImage != null)
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    color: PdfColors.grey600,
                                    child: pw.Text('RESOLUTION STATE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Container(
                                    height: 240,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                                    ),
                                    child: pw.Image(afterImage, fit: pw.BoxFit.cover),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ] else
                      pw.Container(
                        height: 150,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(color: PdfColors.grey50, border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed)),
                        child: pw.Text('No photographic evidence was attached to this case.', style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                      ),

                    pw.SizedBox(height: 35),
                    _sectionTitle('VI. INCIDENT LIFECYCLE AUDIT'),
                    pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.5),
                        1: const pw.FlexColumnWidth(4.5),
                        2: const pw.FlexColumnWidth(3),
                      },
                      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _tableHeader('Lifecycle Event'),
                            _tableHeader('Official Timestamp'),
                            _tableHeader('Authorization'),
                          ],
                        ),
                        _timelineRow('Registration', complaint.timestamp, 'Citizen System'),
                        if (complaint.takenAt != null) _timelineRow('Assignment', complaint.takenAt!, 'System Auto'),
                        if (complaint.resolvedAt != null) _timelineRow('Resolution', complaint.resolvedAt!, 'Contractor Node'),
                        if (complaint.reviewedAt != null) _timelineRow('Final Audit', complaint.reviewedAt!, 'Officer Terminal'),
                      ],
                    ),

                    pw.SizedBox(height: 40),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 220,
                              height: 60,
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey300, width: 2),
                              ),
                              child: pw.Center(
                                child: pw.Text('DIGITALLY VERIFIED', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300)),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Container(width: 200, height: 1.5, color: PdfColors.black),
                            pw.SizedBox(height: 5),
                            pw.Text('SMART CITY MANAGEMENT SEAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Authorized Digital Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              pw.Container(
                width: double.infinity,
                color: PdfColors.grey100,
                padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('OFFICIAL DOCUMENT | PAGE 2 OF 2', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('CASE ID REF: ${_getShortId(complaint.id)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildMiniHeader(Complaint complaint) {
    return pw.Container(
      width: double.infinity,
      color: PdfColors.grey900,
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 32),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('SMART CITY INFRASTRUCTURE RECORD', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text('REPORT ID: ${_getShortId(complaint.id)}', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12, top: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 0.8)),
          pw.Container(height: 1, width: 40, color: PdfColors.black, margin: const pw.EdgeInsets.only(top: 2)),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey900)),
          ],
        ),
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
    );
  }

  pw.TableRow _timelineRow(String event, DateTime ts, String auth) {
    final fmt = DateFormat('MMM d, yyyy HH:mm:ss').format(ts);
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(event, style: const pw.TextStyle(fontSize: 9))),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(fmt, style: const pw.TextStyle(fontSize: 9))),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(auth, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
      ],
    );
  }

  PdfColor _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.registered: return PdfColors.orange800;
      case ComplaintStatus.inProgress: return PdfColors.grey800;
      case ComplaintStatus.resolved: return PdfColors.green800;
      case ComplaintStatus.rejected: return PdfColors.red800;
      case ComplaintStatus.reviewed: return PdfColors.black; // Teal -> Black
      default: return PdfColors.grey800;
    }
  }

  Future<pw.ImageProvider?> _resolveImageProvider(String path) async {
    try {
      String fullUrl = path;
      if (!path.startsWith('http')) {
        final baseUrl = ApiConfig.baseUrl;
        final cleanPath = path.startsWith('/') ? path : '/$path';
        fullUrl = baseUrl + cleanPath;
      }

      final res = await http.get(Uri.parse(fullUrl));
      if (res.statusCode == 200) {
        return pw.MemoryImage(res.bodyBytes);
      }
    } catch (e) {
      // ignore errors
    }
    return null; 
  }

  String _getShortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }
}
