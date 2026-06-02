import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'create_quiz_screen.dart';
import 'edit_quiz_screen.dart';
import 'teacher_assignments_screen.dart';
import 'create_assignment_screen.dart';
import '../notifications_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  String _firstName = "Professeur";
  String _lastName = "";
  bool _loadingProfile = true;

  final List<String> _titles = ["Accueil", "Statistiques", "Devoirs & TP"];
  final Map<String, String> _studentNameCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfessorProfile();
  }

  Future<void> _loadProfessorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _firstName = data['firstName'] ?? 'Professeur';
          _lastName = data['lastName'] ?? '';
          _loadingProfile = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _deleteQuiz(BuildContext context, String quizId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce QCM ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ QCM supprimé'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  Future<String> _getStudentFullName(String uid) async {
    if (_studentNameCache.containsKey(uid)) return _studentNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final name = '${data['firstName'] ?? 'Étudiant'} ${data['lastName'] ?? ''}'.trim();
        _studentNameCache[uid] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Erreur fetch nom étudiant: $e');
    }
    return 'Étudiant inconnu';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildQuizzesList(),
      _buildStatisticsTab(),
      const TeacherAssignmentsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A43EC),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_selectedIndex], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            if (_selectedIndex == 0) ...[
              const SizedBox(height: 4),
              _loadingProfile
                  ? const SizedBox(height: 12, width: 150, child: LinearProgressIndicator(color: Colors.white70, minHeight: 2))
                  : Text("Bonjour $_firstName $_lastName", style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unread = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return badges.Badge(
                showBadge: unread > 0,
                position: badges.BadgePosition.topEnd(top: 0, end: 0),
                badgeContent: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12)),
                badgeStyle: badges.BadgeStyle(badgeColor: Colors.redAccent, padding: const EdgeInsets.all(4)),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF4A43EC),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF3D36D4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Color(0xFF4A43EC))),
                    const SizedBox(height: 15),
                    Text(_loadingProfile ? "Chargement..." : "$_firstName $_lastName", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Enseignant', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(leading: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.white : Colors.white70), title: Text('Accueil', style: TextStyle(color: _selectedIndex == 0 ? Colors.white : Colors.white70, fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.normal)), onTap: () => _onItemTapped(0)),
                    ListTile(leading: Icon(Icons.bar_chart, color: _selectedIndex == 1 ? Colors.white : Colors.white70), title: Text('Statistiques', style: TextStyle(color: _selectedIndex == 1 ? Colors.white : Colors.white70, fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.normal)), onTap: () => _onItemTapped(1)),
                    ListTile(leading: Icon(Icons.assignment, color: _selectedIndex == 2 ? Colors.white : Colors.white70), title: Text('Devoirs & TP', style: TextStyle(color: _selectedIndex == 2 ? Colors.white : Colors.white70, fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.normal)), onTap: () => _onItemTapped(2)),
                    const Divider(color: Colors.white24, height: 1),
                    ListTile(leading: const Icon(Icons.logout, color: Colors.white70), title: const Text('Déconnexion', style: TextStyle(color: Colors.white70)), onTap: () { Navigator.pop(context); _logout(context); }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex < 2
          ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateQuizScreen())), backgroundColor: const Color(0xFF4A43EC), icon: const Icon(Icons.add, color: Colors.white), label: const Text("Nouveau QCM", style: TextStyle(color: Colors.white)))
          : FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAssignmentScreen())), backgroundColor: const Color(0xFF4A43EC), icon: const Icon(Icons.add, color: Colors.white), label: const Text("Nouveau TP", style: TextStyle(color: Colors.white))),
    );
  }

  // PAGE 1 : LISTE DES QCM
  Widget _buildQuizzesList() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').where('teacherId', isEqualTo: user?.uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]), const SizedBox(height: 20), Text("Aucun QCM pour le moment", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("Cliquez sur + pour créer votre premier quiz", style: TextStyle(color: Colors.grey[400]))]));
        final quizzes = snapshot.data!.docs;
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: quizzes.length, itemBuilder: (context, index) {
          final doc = quizzes[index];
          final data = doc.data() as Map<String, dynamic>;
          final questions = data['questions'] as List<dynamic>? ?? [];
          return Card(elevation: 4, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(contentPadding: const EdgeInsets.all(20), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF4A43EC).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.school, color: Color(0xFF4A43EC))), title: Text(data['title'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: Text("${questions.length} Question${questions.length > 1 ? 's' : ''} • ${data['subject'] ?? 'Général'}", style: TextStyle(color: Colors.grey.shade600))), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteQuiz(context, doc.id)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditQuizScreen(quizId: doc.id, quizData: data)))));
        });
      },
    );
  }

  // PAGE 2 : STATISTIQUES (✅ CORRIGÉ)
  Widget _buildStatisticsTab() {
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('quizzes').where('teacherId', isEqualTo: user?.uid).get(),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));
        final quizDocs = quizSnapshot.data?.docs ?? [];
        if (quizDocs.isEmpty) return const Center(child: Text("Créez des QCM pour voir les statistiques"));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('results').snapshots(),
          builder: (context, resultSnapshot) {
            if (resultSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));
            final allResults = resultSnapshot.data?.docs ?? [];
            final quizIds = quizDocs.map((d) => d.id).toSet();
            final relevantResults = allResults.where((r) => quizIds.contains((r.data() as Map)['quizId'])).toList();

            // ✅ CORRECTION 1 : Participants uniques (Set élimine les doublons)
            final uniqueStudentIds = relevantResults
                .map((r) => (r.data() as Map)['studentId'] as String)
                .toSet();
            final totalParticipants = uniqueStudentIds.length;

            // ✅ CORRECTION 2 : Meilleur score par étudiant pour le taux de réussite
            final bestResults = <String, double>{};
            for (var r in relevantResults) {
              final data = r.data() as Map;
              final uid = data['studentId'] as String;
              final pct = (data['percentage'] ?? 0.0).toDouble();
              if (!bestResults.containsKey(uid) || pct > bestResults[uid]!) {
                bestResults[uid] = pct;
              }
            }
            final passed = bestResults.values.where((pct) => pct >= 50.0).length;
            final rate = totalParticipants > 0 ? (passed / totalParticipants) * 100 : 0.0;

            // Tentatives totales (optionnel - pour affichage)
            final totalAttempts = relevantResults.length;

            Map<String, List<Map<String, dynamic>>> byQuiz = {};
            for (var r in relevantResults) byQuiz.putIfAbsent((r.data() as Map)['quizId'], () => []).add(r.data() as Map<String, dynamic>);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ✅ CORRECTION 3 : Affichage des deux métriques (optionnel)
                _StatCard(title: "Participants Uniques", value: "$totalParticipants", icon: Icons.people, color: Colors.blue),
                const SizedBox(height: 12),
                _StatCard(title: "Tentatives Totales", value: "$totalAttempts", icon: Icons.repeat, color: Colors.purple),
                const SizedBox(height: 12),
                _StatCard(title: "Taux de Réussite", value: "${rate.toStringAsFixed(1)}%", icon: Icons.check_circle, color: Colors.green),
                const SizedBox(height: 24),
                const Text("📈 Analyse détaillée par QCM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...quizDocs.map((qDoc) {
                  final qData = qDoc.data() as Map<String, dynamic>;
                  final qResults = byQuiz[qDoc.id] ?? [];
                  if (qResults.isEmpty) return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(title: Text(qData['title']), subtitle: Text(qData['subject']), trailing: const Text("0 participants")));

                  // ✅ CORRECTION 4 : Grouper par étudiant et garder le meilleur score
                  final bestByStudent = <String, Map<String, dynamic>>{};
                  for (var res in qResults) {
                    final uid = res['studentId'] as String;
                    final pct = (res['percentage'] ?? 0.0).toDouble();
                    if (!bestByStudent.containsKey(uid) || pct > (bestByStudent[uid]?['percentage'] ?? 0.0)) {
                      bestByStudent[uid] = res;
                    }
                  }

                  // Calculs basés sur les meilleurs scores
                  final bestValues = bestByStudent.values.toList();
                  final attempts = qResults.length; // Total tentatives pour info
                  final participants = bestByStudent.length; // Participants uniques
                  final correct = bestValues.where((r) => (r['percentage'] ?? 0.0) >= 50.0).length;
                  final qRate = participants > 0 ? (correct / participants) * 100 : 0.0;
                  final qAvg = bestValues.map((r) => (r['percentage'] ?? 0.0).toDouble()).reduce((a, b) => a + b) / participants;

                  // Question la plus ratée (basée sur les meilleures tentatives)
                  String hardest = "Aucune";
                  Map<int, int> qCorr = {}, qAtt = {};
                  for (var res in bestValues) {
                    final answers = res['answers'] as Map<String, dynamic>? ?? {};
                    for (var e in answers.entries) {
                      final idx = int.tryParse(e.key) ?? -1;
                      if (idx >= 0 && idx < (qData['questions'] as List).length) {
                        qAtt.update(idx, (v) => v + 1, ifAbsent: () => 1);
                        if (e.value == (qData['questions'] as List)[idx]['correctIndex']) qCorr.update(idx, (v) => v + 1, ifAbsent: () => 1);
                      }
                    }
                  }
                  if (qAtt.isNotEmpty) {
                    int minC = 999;
                    for (var e in qAtt.entries) {
                      if ((qCorr[e.key] ?? 0) < minC) {
                        minC = qCorr[e.key] ?? 0;
                        String fullText = ((qData['questions'] as List)[e.key] as Map)['text'].toString();
                        hardest = fullText.length > 30 ? "${fullText.substring(0, 30)}..." : fullText;
                      }
                    }
                  }

                  // ✅ CORRECTION 5 : Top 3 sans doublons (meilleur score par étudiant)
                  final top3Results = bestValues
                      ..sort((a, b) => (b['percentage'] ?? 0.0).compareTo(a['percentage'] ?? 0.0))
                      ..take(3)
                      .toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(qData['title']),
                      subtitle: Text("${qData['subject']} • $participants participants uniques"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Réussite: ${qRate.toStringAsFixed(1)}% (Moy: ${qAvg.toStringAsFixed(1)}%)", style: TextStyle(color: qRate >= 50 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("Question la plus ratée:\n$hardest", style: const TextStyle(fontSize: 13)),
                            const Divider(),
                            const Text("🏆 Top 3 Étudiants (meilleur score)", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchTop3WithNames(top3Results),
                              builder: (ctx, snap) {
                                if (!snap.hasData) return const SizedBox(height: 20, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                                final top3 = snap.data!;
                                return Column(
                                  children: top3.asMap().entries.map((e) {
                                    final student = e.value;
                                    final pct = (student['percentage'] ?? 0.0).toDouble();
                                    final medalColor = e.key == 0 ? Colors.amber : e.key == 1 ? Colors.grey[400] : Colors.brown[300];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(children: [
                                        Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: medalColor, borderRadius: BorderRadius.circular(12)), child: Text("${e.key + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(student['displayName'], style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                                        Text("${pct.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: pct >= 50 ? Colors.green : Colors.orange)),
                                      ]),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ]),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTop3WithNames(List<Map<String, dynamic>> results) async {
    List<Map<String, dynamic>> enriched = [];
    for (var res in results) {
      final uid = res['studentId'] as String;
      final name = await _getStudentFullName(uid);
      enriched.add({...res, 'displayName': name});
    }
    return enriched;
  }
}

// Widget Carte Statistique
class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]))]));
  }
}