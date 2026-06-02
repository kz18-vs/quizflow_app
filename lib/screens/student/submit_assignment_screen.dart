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
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _linkCtrl = TextEditingController();
  bool _loading = false;
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final link = _linkCtrl.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un lien Google Drive')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = _auth.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': widget.assignmentId,
        'studentId': user.uid,
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'classe': userData['classe'] ?? '',
        'groupe': userData['groupe'] ?? '',
        'fileLink': link,
        'module': widget.module,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Devoir soumis avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendre le devoir'),
        backgroundColor: const Color(0xFF4A43EC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Icône Cloud
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4A43EC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                size: 80,
                color: Color(0xFF4A43EC),
              ),
            ),

            const SizedBox(height: 24),

            // Titre
            const Text(
              'Base Données',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Instructions
            const Text(
              '1. Uploadez votre fichier sur Google Drive\n'
              '2. Cliquez sur "Partager" → "Copier le lien"\n'
              '3. Collez le lien ci-dessous',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            // Champ de saisie
            TextField(
              controller: _linkCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link, color: Color(0xFF4A43EC)),
                labelText: 'Lien Google Drive',
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A43EC),
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 50),

            // Bouton Envoyer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A43EC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Envoyer le rendu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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