import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 

Future<void> sendNotificationToEnrolledStudents({
  required String teacherId,
  required String title,
  required String message,
  required String type,
}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // 1. Trouver tous les QCM de ce prof
    final quizzesSnap = await firestore
        .collection('quizzes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    if (quizzesSnap.docs.isEmpty) return;

    final quizIds = quizzesSnap.docs.map((d) => d.id).toList();

    // 2. Trouver tous les étudiants inscrits à ces QCM
    final Set<String> studentIds = {};

    // Firestore limite whereIn à 10 éléments
    for (int i = 0; i < quizIds.length; i += 10) {
      final chunk = quizIds.sublist(
          i, i + 10 > quizIds.length ? quizIds.length : i + 10);

      final enrollSnap = await firestore
          .collection('enrollments')
          .where('quizId', whereIn: chunk)
          .get();

      for (var doc in enrollSnap.docs) {
        final data = doc.data();
        if (data['studentId'] != null) {
          studentIds.add(data['studentId'] as String);
        }
      }
    }

    // 3. Envoyer la notification à chaque étudiant concerné
    final batch = firestore.batch();
    for (final studentId in studentIds) {
      final ref = firestore.collection('notifications').doc();
      batch.set(ref, {
        'userId': studentId,
        'teacherId': teacherId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  } catch (e) {
    debugPrint('Erreur sendNotificationToEnrolledStudents: $e');
  }
}

// ── ENVOYER NOTIFICATION AU PROF QUAND UN ÉTUDIANT SOUMET ────────
Future<void> sendNotificationToTeacher({
  required String teacherId,
  required String quizTitle,
}) async {
  final firestore = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  try {
    // Récupérer les infos de l'étudiant
    final studentDoc = await firestore.collection('users').doc(uid).get();
    final data = studentDoc.data() ?? {};

    final firstName = data['firstName'] ?? 'Étudiant';
    final lastName = data['lastName'] ?? '';
    final classe = data['classe'] ?? 'N/A';
    final groupe = data['groupe'] ?? 'N/A';

    await firestore.collection('notifications').add({
      'userId': teacherId,
      'title': 'Nouvelle soumission',
      'message': '$firstName $lastName — Classe $classe, Groupe $groupe a soumis "$quizTitle"',
      'type': 'submission_received',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint(' Erreur sendNotificationToTeacher: $e');
  }
}

// ── NOUVEAU : NOTIFIER LE PROF EN CAS DE TRICHE ───────────────
Future<void> sendCheatingAlertToTeacher({
  required String teacherId,
  required String studentId,
  required String quizTitle,
  required String studentName,      // ✅ AJOUTÉ
  required String studentClass,     // ✅ AJOUTÉ
  required String studentGroup,     // ✅ AJOUTÉ
  required int violationCount,
  required bool isExcluded,         // ✅ AJOUTÉ
}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Message adapté selon le nombre de violations
    final message = isExcluded
        ? ' $studentName (Classe $studentClass, Groupe $studentGroup) a été exclu du quiz "$quizTitle" après $violationCount sorties détectées.'
        : ' $studentName (Classe $studentClass, Groupe $studentGroup) a quitté l\'écran du quiz "$quizTitle" ($violationCount fois).';

    await firestore.collection('notifications').add({
      'userId': teacherId,
      'title': isExcluded ? 'Exclusion pour triche' : ' Alerte Anti-Triche',
      'message': message,
      'type': 'cheating_alert',
      'isRead': false,
      'studentId': studentId,
      'quizId': null,
      'violationCount': violationCount,
      'studentClass': studentClass,
      'studentGroup': studentGroup,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint(' Alerte triche envoyée au prof $teacherId');
  } catch (e) {
    debugPrint(' Erreur sendCheatingAlertToTeacher: $e');
  }
}

// ── ANCIENNE FONCTION (compatibilité) ────────────────────────────
Future<void> sendNotification({
  required String userId,
  required String title,
  required String message,
  required String type,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}