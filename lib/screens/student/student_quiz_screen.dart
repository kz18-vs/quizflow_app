import 'package:flutter/material.dart';

class StudentQuizScreen extends StatelessWidget {
  const StudentQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Étudiant"),
        backgroundColor: const Color(0xFF4A43EC),
      ),
      body: const Center(
        child: Text(
          " Espace Étudiant\n\nFonctionnalité en cours de développement",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}