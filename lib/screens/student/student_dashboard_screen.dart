import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:badges/badges.dart' as badges;
import 'student_ai_quiz_screen.dart';
import 'join_quiz_screen.dart';
import 'take_quiz_screen.dart';
import 'history_screen.dart';
import 'student_assignments_screen.dart';
import '../notifications_screen.dart';
import 'gamification_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);

  int _selectedIndex = 0;
  String _firstName = "";
  String _lastName = "";
  bool _loadingProfile = true;

  final List<String> _titles = ["Accueil", "Historique", "Devoirs & TP"];

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _firstName = data?['firstName'] ?? "Étudiant";
            _lastName = data?['lastName'] ?? "";
            _loadingProfile = false;
          });
        }
      } catch (e) {
        setState(() => _loadingProfile = false);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
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
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  // ─── BADGE NOTIFICATIONS ──────────────────────────────────────
  Widget _buildNotificationBadge() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user?.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return badges.Badge(
          showBadge: unread > 0,
          position: badges.BadgePosition.topEnd(top: 0, end: 0),
          badgeContent: Text(
            '$unread',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.redAccent,
            padding: EdgeInsets.all(4),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      const HistoryScreen(),
      const StudentAssignmentsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (_selectedIndex == 0) ...[
              const SizedBox(height: 4),
              _loadingProfile
                  ? const SizedBox(
                      height: 12,
                      width: 150,
                      child: LinearProgressIndicator(
                          color: Colors.white70, minHeight: 2),
                    )
                  : Text(
                      "Bonjour $_firstName $_lastName",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
            ],
          ],
        ),
        elevation: 0,
        // ── BOUTON CLOCHE NOTIFICATIONS ──────────────────────────
        actions: [_buildNotificationBadge()],
      ),
      drawer: Drawer(
        child: Container(
          color: primaryColor,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF3D36D4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: primaryColor),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _loadingProfile ? "Chargement..." : "$_firstName $_lastName",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('Étudiant',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(Icons.home,
                          color: _selectedIndex == 0 ? Colors.white : Colors.white70),
                      title: Text('Accueil',
                          style: TextStyle(
                            color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                            fontWeight: _selectedIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                      onTap: () => _onItemTapped(0),
                    ),
                    ListTile(
                      leading: Icon(Icons.history,
                          color: _selectedIndex == 1 ? Colors.white : Colors.white70),
                      title: Text('Historique',
                          style: TextStyle(
                            color: _selectedIndex == 1 ? Colors.white : Colors.white70,
                            fontWeight: _selectedIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                      onTap: () => _onItemTapped(1),
                    ),
                    ListTile(
                      leading: Icon(Icons.assignment,
                          color: _selectedIndex == 2 ? Colors.white : Colors.white70),
                      title: Text('Devoirs & TP',
                          style: TextStyle(
                            color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                            fontWeight: _selectedIndex == 2
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                      onTap: () => _onItemTapped(2),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    // ── NOTIFICATIONS DANS LE DRAWER ─────────────
                    ListTile(
                      leading: const Icon(Icons.notifications_none,
                          color: Colors.white70),
                      title: const Text('Notifications',
                          style: TextStyle(color: Colors.white70)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white70),
                      title: const Text('Déconnexion',
                          style: TextStyle(color: Colors.white70)),
                      onTap: () {
                        Navigator.pop(context);
                        _logout(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinQuizScreen()),
              ),
              backgroundColor: primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Rejoindre un Quiz",
                  style: TextStyle(color: Colors.white)),
            )
          : const SizedBox.shrink(),
    );
  }

  // ─── PAGE ACCUEIL ─────────────────────────────────────────────
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── BANNIÈRE IA ────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentAIQuizScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A43EC), Color(0xFF7B61FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apprendre avec mon cours',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload ton PDF → l\'IA génère des questions pour toi',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
 GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GamificationScreen())),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mes Récompenses',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Points • Badges • Classement • Streak',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
          // ── TITRE ─────────────────────────────────────────────
          const Text(
            'Mes Quiz disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          //LISTE QCM 
          _buildQuizzesList(),
        ],
      ),
    );
  }

  // LISTE DES QCM
  Widget _buildQuizzesList() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: primaryColor));
        }

        if (!enrollmentSnapshot.hasData ||
            enrollmentSnapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 70, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Aucun quiz disponible",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text("Cliquez sur + et entrez un code",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          );
        }

        final quizIds = enrollmentSnapshot.data!.docs
            .map((e) => (e.data() as Map<String, dynamic>)['quizId'] as String)
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .where(FieldPath.documentId, whereIn: quizIds)
              .snapshots(),
          builder: (context, quizSnapshot) {
            if (!quizSnapshot.hasData || quizSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Aucun quiz trouvé'));
            }

            final quizzes = quizSnapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final doc = quizzes[index];
                final data = doc.data() as Map<String, dynamic>;
                final questions = data['questions'] as List<dynamic>? ?? [];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.quiz, color: primaryColor),
                    ),
                    title: Text(
                      data['title'] ?? 'Sans titre',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${questions.length} Questions • ${data['subject'] ?? 'Général'}",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.grey, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TakeQuizScreen(quizId: doc.id, quizData: data),
                      ),
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