import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static const Color primaryColor = Color(0xFF4A43EC);
  static const Color successGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Résultats", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("Mathématiques", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        elevation: 0,
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.menu, color: Colors.white))],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: successGreen, width: 4),
                color: const Color(0xFFE8F5E9),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("4/5", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: successGreen)),
                  Text("80%", style: TextStyle(fontSize: 18, color: successGreen, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Excellent travail !", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 30),
            _buildResultCard("Bonnes réponses", "4", successGreen),
            const SizedBox(height: 12),
            _buildResultCard("Mauvaises réponses", "1", Colors.orange),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Voir les corrections", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "QCM"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Résultats"), 
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}