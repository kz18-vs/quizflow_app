import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String assignmentId;
  final String module;

  const SubmitAssignmentScreen({
    super.key,
    required this.assignmentId,
    required this.module,
  });

  @override
  State<SubmitAssignmentScreen> createState() =>
      _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState
    extends State<SubmitAssignmentScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);

  final _linkCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_linkCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Entrez le lien de votre fichier')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data()!;

      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      final classe = userData['classe'] ?? '';
      final groupe = userData['groupe'] ?? '';

      // ── SAUVEGARDER LE RENDU ──────────────────────────────
      await FirebaseFirestore.instance
          .collection('submissions')
          .add({
        'assignmentId': widget.assignmentId,
        'studentId': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'classe': classe,
        'groupe': groupe,
        'module': widget.module,
        'fileLink': _linkCtrl.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // ── NOTIFIER LE PROF AVEC CLASSE ET GROUPE ────────────
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();
      final teacherId = assignmentDoc.data()?['teacherId'];

      if (teacherId != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'userId': teacherId,
          'title': 'Nouveau rendu reçu',
          'message':
              '$firstName $lastName — Classe $classe, Groupe $groupe a rendu "${widget.module}"',
          'type': 'submission_received',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendu envoyé avec succès ! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Rendre le devoir',
            style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            // Icône
            Icon(Icons.cloud_upload,
                size: 80,
                color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 20),

            // Titre
            Text(
              widget.module,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Instructions
            Text(
              '1. Uploadez votre fichier sur Google Drive\n'
              '2. Cliquez sur "Partager" → "Copier le lien"\n'
              '3. Collez le lien ci-dessous',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 30),

            // Champ lien
            TextFormField(
              controller: _linkCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Lien Google Drive',
                hintText: 'https://drive.google.com/...',
                prefixIcon:
                    const Icon(Icons.link, color: primaryColor),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),

            const Spacer(),

            // Bouton envoyer
            _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor))
                : ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send,
                        color: Colors.white),
                    label: const Text(
                      'Envoyer le rendu',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}