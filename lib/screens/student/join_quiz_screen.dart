import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinQuizScreen extends StatefulWidget {
  const JoinQuizScreen({super.key});

  @override
  State<JoinQuizScreen> createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accessCodeCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _accessCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final accessCode = _accessCodeCtrl.text.trim().toUpperCase();
      final studentId = _auth.currentUser!.uid;

      // Chercher le quiz avec ce code d'accès
      final quizSnapshot = await _firestore
          .collection('quizzes')
          .where('accessCode', isEqualTo: accessCode)
          .limit(1)
          .get();

      if (quizSnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Code d\'accès invalide';
          _loading = false;
        });
        return;
      }

      final quizDoc = quizSnapshot.docs.first;
      final quizId = quizDoc.id;

      // Vérifier si l'étudiant est déjà inscrit
      final existingEnrollment = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('quizId', isEqualTo: quizId)
          .limit(1)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'Vous êtes déjà inscrit à ce quiz';
          _loading = false;
        });
        return;
      }

      // Créer l'inscription
      await _firestore.collection('enrollments').add({
        'studentId': studentId,
        'quizId': quizId,
        'enrolledAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Afficher le succès
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(' Inscription réussie !'),
          content: Text('Vous avez rejoint le quiz : ${quizDoc.data()['title']}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Retour au dashboard
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A43EC),
        title: const Text('Rejoindre un Quiz', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 100, color: const Color(0xFF4A43EC).withOpacity(0.5)),
              const SizedBox(height: 30),
              const Text(
                'Entrez le code fourni par votre professeur',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _accessCodeCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
                decoration: InputDecoration(
                  labelText: 'Code d\'accès',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4A43EC), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le code';
                  }
                  if (value.trim().length != 6) {
                    return 'Le code doit contenir 6 caractères';
                  }
                  return null;
                },
                // IMPORTANT: Pas de sélection automatique
                autofocus: false,
                enableSuggestions: false,
                autocorrect: false,
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _joinQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A43EC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Rejoindre le Quiz',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}