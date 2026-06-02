import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'submit_assignment_screen.dart';
import 'package:intl/intl.dart';   // ← Important pour formater les dates

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState
    extends State<StudentAssignmentsScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);

  List<String> _teacherIds = [];
  bool _loadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _loadMyTeachers();
  }

  Future<void> _loadMyTeachers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingTeachers = false);
      return;
    }

    try {
      final enrollSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .get();

      if (enrollSnap.docs.isEmpty) {
        setState(() {
          _teacherIds = [];
          _loadingTeachers = false;
        });
        return;
      }

      final quizIds = enrollSnap.docs
          .map((e) => (e.data())['quizId'] as String)
          .toList();

      final Set<String> teacherIds = {};
      for (int i = 0; i < quizIds.length; i += 10) {
        final chunk = quizIds.sublist(
            i, i + 10 > quizIds.length ? quizIds.length : i + 10);
        final quizSnap = await FirebaseFirestore.instance
            .collection('quizzes')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in quizSnap.docs) {
          final tid = doc.data()['teacherId'];
          if (tid != null) teacherIds.add(tid as String);
        }
      }

      setState(() {
        _teacherIds = teacherIds.toList();
        _loadingTeachers = false;
      });
    } catch (e) {
      setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d\'ouvrir le lien';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_loadingTeachers) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }

    if (_teacherIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun devoir disponible',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Rejoignez un quiz pour voir les devoirs',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('teacherId', whereIn: _teacherIds.take(10).toList())
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Aucun devoir disponible',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final assignments = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final doc = assignments[index];
            final data = doc.data() as Map<String, dynamic>;

            // Formatage de la date limite
            final deadline = data['deadline'] as Timestamp?;
            String deadlineStr = 'Sans date limite';
            bool isLate = false;

            if (deadline != null) {
              final date = deadline.toDate();
              deadlineStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
              isLate = date.isBefore(DateTime.now());
              if (isLate) {
                deadlineStr = '🕒 En retard - $deadlineStr';
              }
            }

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('submissions')
                  .where('assignmentId', isEqualTo: doc.id)
                  .where('studentId', isEqualTo: user?.uid)
                  .limit(1)
                  .get(),
              builder: (context, subSnap) {
                final isSubmitted = subSnap.hasData && subSnap.data!.docs.isNotEmpty;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['title'] ?? 'Sans titre',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isSubmitted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Text(' Rendu', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "${data['module'] ?? 'Module'} • $deadlineStr",
                          style: TextStyle(
                            color: isLate ? Colors.red : Colors.grey[600],
                            fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),

                        if (data['description']?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(data['description'], style: const TextStyle(fontSize: 14)),
                        ],

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openLink(data['fileLink'] ?? ''),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Voir le TP'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isSubmitted
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SubmitAssignmentScreen(
                                              assignmentId: doc.id,
                                              module: data['module'] ?? 'Module',
                                            ),
                                          ),
                                        ),
                                icon: const Icon(Icons.upload_file),
                                label: Text(isSubmitted ? 'Déjà rendu' : 'Rendre'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSubmitted ? Colors.grey : primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}