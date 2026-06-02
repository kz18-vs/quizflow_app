import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gamification_service.dart' as gami;

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF4A43EC);
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  String _myClasse = '';
  bool _loading = true;

  // Toggle classement global / par classe
  bool _showClasseLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await gami.GamificationService.getUserStats();

    // Récupérer la classe de l'étudiant
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String classe = '';
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      classe = userDoc.data()?['classe'] ?? '';
    }

    setState(() {
      _stats = stats;
      _myClasse = classe;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Mes Récompenses',
            style: TextStyle(color: Colors.white)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Profil'),
            Tab(icon: Icon(Icons.military_tech), text: 'Badges'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildBadgesTab(),
                _buildLeaderboardTab(),
              ],
            ),
    );
  }

  // ─── ONGLET PROFIL ────────────────────────────────────────────
  Widget _buildProfileTab() {
    final points = (_stats['points'] ?? 0) as int;
    final streak = (_stats['streak'] ?? 0) as int;
    final quizzes = (_stats['quizzesCompleted'] ?? 0) as int;
    final perfects = (_stats['perfects'] ?? 0) as int;
    final badges = List<String>.from(_stats['badges'] ?? []);
    final classe = _stats['classe'] ?? _myClasse;
    final groupe = _stats['groupe'] ?? '';

    String level;
    Color levelColor;
    double levelProgress;
    int nextLevelPoints;

    if (points < 100) {
      level = 'Débutant';
      levelColor = Colors.grey;
      levelProgress = points / 100;
      nextLevelPoints = 100;
    } else if (points < 500) {
      level = 'Bronze 🥉';
      levelColor = Colors.brown;
      levelProgress = (points - 100) / 400;
      nextLevelPoints = 500;
    } else if (points < 1000) {
      level = 'Argent 🥈';
      levelColor = Colors.blueGrey;
      levelProgress = (points - 500) / 500;
      nextLevelPoints = 1000;
    } else if (points < 5000) {
      level = 'Or 🥇';
      levelColor = Colors.amber;
      levelProgress = (points - 1000) / 4000;
      nextLevelPoints = 5000;
    } else {
      level = 'Diamant 💎';
      levelColor = Colors.blue;
      levelProgress = 1.0;
      nextLevelPoints = 5000;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── CARTE NIVEAU ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, levelColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Classe et groupe
                if (classe.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Classe $classe${groupe.isNotEmpty ? ' — Groupe $groupe' : ''}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                Text(
                  points.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold),
                ),
                const Text('points',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(level,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: levelProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  points >= 5000
                      ? 'Niveau maximum atteint ! 🎉'
                      : '$points / $nextLevelPoints points pour le niveau suivant',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── STATS ─────────────────────────────────────────────
          Row(
            children: [
              _buildStatCard('🔥', '$streak', 'Jours\nconsécutifs',
                  streak >= 3 ? Colors.orange : Colors.grey),
              const SizedBox(width: 12),
              _buildStatCard(
                  '📚', '$quizzes', 'Quiz\ncomplétés', primaryColor),
              const SizedBox(width: 12),
              _buildStatCard(
                  '🎯', '$perfects', 'Score\nparfait', Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('🏅', '${badges.length}',
                  'Badges\nobtenus', Colors.amber),
            ],
          ),
          const SizedBox(height: 20),

          // ── STREAK ────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Streak quotidien',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final isActive = i < streak.clamp(0, 7);
                      return Column(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.orange
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isActive ? '🔥' : '○',
                              style: TextStyle(
                                  fontSize: isActive ? 16 : 14,
                                  color: isActive
                                      ? null
                                      : Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['L', 'M', 'M', 'J', 'V', 'S', 'D'][i],
                          style: TextStyle(
                              fontSize: 11,
                              color: isActive
                                  ? Colors.orange
                                  : Colors.grey),
                        ),
                      ]);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      streak == 0
                          ? 'Complète un quiz aujourd\'hui !'
                          : streak == 1
                              ? 'C\'est parti ! Continue demain 💪'
                              : 'Incroyable ! $streak jours de suite 🔥',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ─── ONGLET BADGES ────────────────────────────────────────────
  Widget _buildBadgesTab() {
    final unlockedBadges =
        List<String>.from(_stats['badges'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('🏅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                '${unlockedBadges.length} / ${gami.GamificationService.allBadges.length} badges débloqués',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount:
                gami.GamificationService.allBadges.length,
            itemBuilder: (context, index) {
              final badge =
                  gami.GamificationService.allBadges[index];
              final isUnlocked =
                  unlockedBadges.contains(badge.id);

              return GestureDetector(
                onTap: () =>
                    _showBadgeDetail(badge, isUnlocked),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked
                          ? Colors.amber
                          : Colors.grey[300]!,
                      width: isUnlocked ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(badge.emoji,
                              style: const TextStyle(
                                  fontSize: 36)),
                          if (!isUnlocked)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey
                                    .withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock,
                                  color: Colors.white,
                                  size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: Text(
                          badge.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? Colors.amber[800]
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(gami.Badge badge, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji,
                style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(badge.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(badge.description,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUnlocked
                    ? '✅ Débloqué !'
                    : '🔒 Non débloqué',
                style: TextStyle(
                    color: isUnlocked
                        ? Colors.green
                        : Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ─── ONGLET CLASSEMENT ────────────────────────────────────────
  Widget _buildLeaderboardTab() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // ── TOGGLE GLOBAL / MA CLASSE ───────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                      () => _showClasseLeaderboard = false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_showClasseLeaderboard
                          ? primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🌍 Global',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_showClasseLeaderboard
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                      () => _showClasseLeaderboard = true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _showClasseLeaderboard
                          ? primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🏫 Ma Classe${_myClasse.isNotEmpty ? ' ($_myClasse)' : ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _showClasseLeaderboard
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── LISTE CLASSEMENT ─────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _showClasseLeaderboard && _myClasse.isNotEmpty
                ? gami.GamificationService.getLeaderboardByClasse(
                    _myClasse)
                : gami.GamificationService.getLeaderboard(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor));
              }

              final leaderboard = snapshot.data ?? [];

              if (leaderboard.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆',
                          style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        _showClasseLeaderboard
                            ? 'Aucun étudiant dans ta classe pour l\'instant'
                            : 'Aucun classement pour l\'instant',
                        style: const TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'Complète des quiz pour apparaître ici !',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = leaderboard[index];
                  final isCurrentUser =
                      entry['userId'] == currentUid;
                  final rank = index + 1;

                  String rankEmoji;
                  Color rankColor;
                  if (rank == 1) {
                    rankEmoji = '🥇';
                    rankColor = Colors.amber;
                  } else if (rank == 2) {
                    rankEmoji = '🥈';
                    rankColor = Colors.blueGrey;
                  } else if (rank == 3) {
                    rankEmoji = '🥉';
                    rankColor = Colors.brown;
                  } else {
                    rankEmoji = '#$rank';
                    rankColor = Colors.grey;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? primaryColor.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentUser
                            ? primaryColor
                            : Colors.grey[200]!,
                        width: isCurrentUser ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                      leading: rank <= 3
                          ? Text(rankEmoji,
                              style:
                                  const TextStyle(fontSize: 28))
                          : Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    rankColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('$rank',
                                    style: TextStyle(
                                        color: rankColor,
                                        fontWeight:
                                            FontWeight.bold)),
                              ),
                            ),
                      title: Row(children: [
                        Text(
                          entry['name'] ?? 'Étudiant',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser
                                  ? primaryColor
                                  : Colors.black87),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Text('Toi',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11)),
                          ),
                        ],
                      ]),
                      subtitle: Row(children: [
                        // Classe et groupe
                        if (entry['classe'] != null &&
                            entry['classe'].toString().isNotEmpty)
                          Text(
                            '${entry['classe']} • ',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11),
                          ),
                        const Text('🔥 '),
                        Text(
                          '${entry['streak'] ?? 0} jours',
                          style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12),
                        ),
                      ]),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry['points'] ?? 0} pts',
                          style: TextStyle(
                            color: rankColor == Colors.grey
                                ? Colors.grey[700]
                                : rankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}