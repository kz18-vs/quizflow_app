import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Connectez-vous'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('completedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Gestion des erreurs
        if (snapshot.hasError) {
          debugPrint('Erreur historique: ${snapshot.error}');
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        // Chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));
        }

        // Aucun résultat
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 15),
                Text("Aucun quiz terminé", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text("Vos résultats apparaîtront ici après chaque quiz", 
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          );
        }

        final results = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index].data() as Map<String, dynamic>;
            final percentage = (data['percentage'] ?? 0.0).toDouble();
            final isPassed = percentage >= 50.0;
            final completedAt = data['completedAt'] as Timestamp?;
            final dateStr = completedAt != null
                ? "${completedAt.toDate().day}/${completedAt.toDate().month}/${completedAt.toDate().year}"
                : 'Date inconnue';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPassed ? Icons.check_circle : Icons.cancel,
                    color: isPassed ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(data['quizTitle'] ?? 'Quiz', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${data['subject'] ?? 'Général'} • $dateStr"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(0)}%",
                    style: TextStyle(fontWeight: FontWeight.bold, color: isPassed ? Colors.green : Colors.orange),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}