import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── MODÈLE BADGE ─────────────────────────────────────────────────
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String condition;
  final int conditionValue;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.condition,
    required this.conditionValue,
  });
}

class GamificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static const List<Badge> allBadges = [
    Badge(id: 'first_points', name: 'Premier pas',
        description: 'Gagner tes premiers points', emoji: '⭐',
        condition: 'points', conditionValue: 1),
    Badge(id: 'bronze', name: 'Bronze',
        description: 'Atteindre 100 points', emoji: '🥉',
        condition: 'points', conditionValue: 100),
    Badge(id: 'silver', name: 'Argent',
        description: 'Atteindre 500 points', emoji: '🥈',
        condition: 'points', conditionValue: 500),
    Badge(id: 'gold', name: 'Or',
        description: 'Atteindre 1000 points', emoji: '🥇',
        condition: 'points', conditionValue: 1000),
    Badge(id: 'diamond', name: 'Diamant',
        description: 'Atteindre 5000 points', emoji: '💎',
        condition: 'points', conditionValue: 5000),
    Badge(id: 'perfect', name: 'Parfait !',
        description: 'Obtenir 100% dans un QCM', emoji: '🎯',
        condition: 'perfect', conditionValue: 1),
    Badge(id: 'perfectx5', name: 'Maître',
        description: 'Obtenir 100% dans 5 QCM', emoji: '🏆',
        condition: 'perfect', conditionValue: 5),
    Badge(id: 'streak3', name: 'En feu',
        description: '3 jours consécutifs', emoji: '🔥',
        condition: 'streak', conditionValue: 3),
    Badge(id: 'streak7', name: 'Semaine parfaite',
        description: '7 jours consécutifs', emoji: '📅',
        condition: 'streak', conditionValue: 7),
    Badge(id: 'streak30', name: 'Mois de feu',
        description: '30 jours consécutifs', emoji: '🌟',
        condition: 'streak', conditionValue: 30),
    Badge(id: 'quiz10', name: 'Actif',
        description: 'Compléter 10 quiz', emoji: '📚',
        condition: 'quizzes', conditionValue: 10),
    Badge(id: 'quiz50', name: 'Expert',
        description: 'Compléter 50 quiz', emoji: '🎓',
        condition: 'quizzes', conditionValue: 50),
  ];

  // ── CALCULER POINTS ──────────────────────────────────────────
  static int calculatePoints(double percentage, int totalQuestions) {
    int basePoints =
        (percentage / 100 * totalQuestions * 10).round();
    if (percentage == 100) basePoints += 50;
    else if (percentage >= 80) basePoints += 20;
    else if (percentage >= 60) basePoints += 10;
    return basePoints;
  }

  // ── METTRE À JOUR APRÈS UN QUIZ ──────────────────────────────
  static Future<Map<String, dynamic>> updateAfterQuiz({
    required double percentage,
    required int score,
    required int total,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    // Récupérer classe et groupe de l'étudiant
    final userDoc =
        await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final classe = userData['classe'] ?? 'N/A';
    final groupe = userData['groupe'] ?? 'N/A';
    final firstName = userData['firstName'] ?? 'Étudiant';
    final lastName = userData['lastName'] ?? '';

    final userRef = _firestore.collection('gamification').doc(uid);
    final doc = await userRef.get();
    final data = doc.exists ? doc.data()! : {};

    final currentPoints = (data['points'] ?? 0) as int;
    final currentStreak = (data['streak'] ?? 0) as int;
    final currentPerfects = (data['perfects'] ?? 0) as int;
    final currentQuizzes = (data['quizzesCompleted'] ?? 0) as int;
    final currentBadges = List<String>.from(data['badges'] ?? []);
    final lastQuizDate = data['lastQuizDate'] as Timestamp?;

    // ── STREAK ────────────────────────────────────────────────
    int newStreak = currentStreak;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastQuizDate != null) {
      final lastDate = lastQuizDate.toDate();
      final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        newStreak = currentStreak;
      } else if (diff == 1) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final earnedPoints = calculatePoints(percentage, total);
    final newPoints = currentPoints + earnedPoints;
    final newPerfects =
        percentage == 100 ? currentPerfects + 1 : currentPerfects;
    final newQuizzes = currentQuizzes + 1;

    // ── BADGES ────────────────────────────────────────────────
    final newlyUnlocked = <Badge>[];
    for (final badge in allBadges) {
      if (currentBadges.contains(badge.id)) continue;
      bool unlocked = false;
      switch (badge.condition) {
        case 'points':
          unlocked = newPoints >= badge.conditionValue;
          break;
        case 'streak':
          unlocked = newStreak >= badge.conditionValue;
          break;
        case 'perfect':
          unlocked = newPerfects >= badge.conditionValue;
          break;
        case 'quizzes':
          unlocked = newQuizzes >= badge.conditionValue;
          break;
      }
      if (unlocked) {
        newlyUnlocked.add(badge);
        currentBadges.add(badge.id);
      }
    }

    // ── SAUVEGARDER ───────────────────────────────────────────
    await userRef.set({
      'userId': uid,
      'points': newPoints,
      'streak': newStreak,
      'perfects': newPerfects,
      'quizzesCompleted': newQuizzes,
      'badges': currentBadges,
      'classe': classe,
      'groupe': groupe,
      'lastQuizDate': Timestamp.now(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ── CLASSEMENT GLOBAL + PAR CLASSE ────────────────────────
    await _updateLeaderboard(
        uid, newPoints, newStreak, classe, groupe,
        '$firstName $lastName');

    return {
      'earnedPoints': earnedPoints,
      'totalPoints': newPoints,
      'streak': newStreak,
      'newBadges': newlyUnlocked,
    };
  }

  // ── METTRE À JOUR LE CLASSEMENT ──────────────────────────────
  static Future<void> _updateLeaderboard(
    String uid,
    int points,
    int streak,
    String classe,
    String groupe,
    String name,
  ) async {
    try {
      // Classement global
      await _firestore.collection('leaderboard').doc(uid).set({
        'userId': uid,
        'name': name,
        'points': points,
        'streak': streak,
        'classe': classe,
        'groupe': groupe,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Classement par classe
      await _firestore
          .collection('leaderboard_classe')
          .doc('${classe}_$uid')
          .set({
        'userId': uid,
        'name': name,
        'points': points,
        'streak': streak,
        'classe': classe,
        'groupe': groupe,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore
    }
  }

  // ── CLASSEMENT GLOBAL TOP 10 ─────────────────────────────────
  static Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _firestore
        .collection('leaderboard')
        .orderBy('points', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ── CLASSEMENT PAR CLASSE ─────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> getLeaderboardByClasse(
      String classe) {
    return _firestore
        .collection('leaderboard_classe')
        .where('classe', isEqualTo: classe)
        .orderBy('points', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ── STATS UTILISATEUR ────────────────────────────────────────
  static Future<Map<String, dynamic>> getUserStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final doc =
        await _firestore.collection('gamification').doc(uid).get();
    return doc.exists ? doc.data()! : {};
  }

  static Badge? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}