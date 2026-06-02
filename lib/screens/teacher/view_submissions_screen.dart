import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ViewSubmissionsScreen extends StatelessWidget {
  final String assignmentId;
  final String assignmentTitle;

  const ViewSubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  Future<void> _openFile(BuildContext context, Map<String, dynamic> data) async {
    final fileUrl = data['fileUrl'] as String?;
    final fileLink = data['fileLink'] as String?;

    if (fileUrl != null && fileUrl.isNotEmpty) {
      // PDF uploadé via Storage
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } 
    else if (fileLink != null && fileLink.isNotEmpty) {
      // Lien Google Drive
      final uri = Uri.parse(fileLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun fichier disponible')),
    );
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A43EC),
        title: Text('Rendus : $assignmentTitle', style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun rendu pour le moment'));
          }

          final submissions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final data = submissions[index].data() as Map<String, dynamic>;
              final submittedAt = data['submittedAt'] as Timestamp?;
              final pdfName = data['pdfName'] as String?;

              final submittedStr = _formatDate(submittedAt);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF4A43EC).withOpacity(0.1),
                        child: Text(
                          (data['firstName'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFF4A43EC), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Classe ${data['classe'] ?? ''} ${data['groupe'] != null ? '• G${data['groupe']}' : ''}',
                              style: const TextStyle(color: Color(0xFF4A43EC), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rendu le $submittedStr',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            if (pdfName != null)
                              Text(
                                '📄 $pdfName',
                                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: () => _openFile(context, data),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Ouvrir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}