import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../../services/ai_service.dart';
import '../../../widgets/matching_dialog.dart';
import '../../../widgets/matching_question_widget.dart';
import '../../../widgets/word_order_dialog.dart';
import '../../../utils/notification_helper.dart';
import 'package:flutter/services.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _aiLoading = false;
  final List<Map<String, dynamic>> _questions = [];
  int _selectedTime = 10;

  String _generateAccessCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // ─── ICÔNE SELON TYPE DE QUESTION ────────────────────────────
  IconData _iconForType(String type) {
    switch (type) {
      case 'true_false':
        return Icons.toggle_on;
      default:
        return Icons.quiz;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'true_false':
        return Colors.teal;
      default:
        return primaryColor;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'true_false':
        return 'Vrai / Faux';
      default:
        return 'QCM';
    }
  }

  // ─── DIALOGUE CHOIX DU TYPE ───────────────────────────────────
  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Type de question', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez le type de question à ajouter',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // QCM
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz, color: primaryColor),
              ),
              title: const Text('QCM', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('4 options, une seule bonne réponse', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => _QuestionDialog(
                    question: null,
                    type: 'qcm',
                    onAddQuestion: (q) => setState(() => _questions.add(q)),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // VRAI / FAUX
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.toggle_on, color: Colors.teal),
              ),
              title: const Text('Vrai / Faux', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Une affirmation, répondre Vrai ou Faux', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => _TrueFalseDialog(
                    question: null,
                    onAddQuestion: (q) => setState(() => _questions.add(q)),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // RELIER
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.orange),
              ),
              title: const Text('Relier', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Relier chaque mot à sa définition', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => MatchingDialog(
                    question: null,
                    onAddQuestion: (q) => setState(() => _questions.add(q)),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // ORDRE DE MOTS
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sort, color: Colors.purple),
              ),
              title: const Text('Ordre de mots', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Remettre les mots dans le bon ordre', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => WordOrderDialog(
                    question: null,
                    onAddQuestion: (q) => setState(() => _questions.add(q)),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _editQuestion(int index) {
    final q = _questions[index];
    final type = q['type'] ?? 'qcm';

    if (type == 'true_false') {
      showDialog(
        context: context,
        builder: (_) => _TrueFalseDialog(
          question: q,
          onAddQuestion: (updated) => setState(() => _questions[index] = updated),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _QuestionDialog(
          question: q,
          type: 'qcm',
          onAddQuestion: (updated) => setState(() => _questions[index] = updated),
        ),
      );
    }
  }

  void _deleteQuestion(int index) => setState(() => _questions.removeAt(index));

  // ─── GÉNÉRATION IA ────────────────────────────────────────────
  void _showAIDialog() {
    final topicCtrl = TextEditingController();
    int nbQuestions = 5;
    String difficulty = 'moyen';

    if (_subjectCtrl.text.isNotEmpty) topicCtrl.text = _subjectCtrl.text;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Générer avec IA', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'L\'IA va créer des questions QCM automatiquement !',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: topicCtrl,
                  decoration: InputDecoration(
                    labelText: 'Sujet précis',
                    hintText: 'Ex: Les dérivées en mathématiques',
                    prefixIcon: const Icon(Icons.topic, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nombre de questions', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [3, 5, 10].map((n) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$n'),
                      selected: nbQuestions == n,
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: nbQuestions == n ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setDialogState(() => nbQuestions = n),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Difficulté', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    {'label': 'Facile', 'value': 'facile', 'color': Colors.green},
                    {'label': 'Moyen', 'value': 'moyen', 'color': Colors.orange},
                    {'label': 'Difficile', 'value': 'difficile', 'color': Colors.red},
                  ].map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(d['label'] as String),
                      selected: difficulty == d['value'],
                      selectedColor: d['color'] as Color,
                      labelStyle: TextStyle(
                        color: difficulty == d['value'] ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setDialogState(() => difficulty = d['value'] as String),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton.icon(
              onPressed: () async {
                if (topicCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un sujet')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _generateWithAI(
                  subject: _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : 'Général',
                  topic: topicCtrl.text.trim(),
                  nbQuestions: nbQuestions,
                  difficulty: difficulty,
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Générer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateWithAI({
    required String subject,
    required String topic,
    required int nbQuestions,
    required String difficulty,
  }) async {
    setState(() => _aiLoading = true);
    try {
      final generated = await AIService.generateQuestions(
        subject: subject,
        topic: topic,
        numberOfQuestions: nbQuestions,
        difficulty: difficulty,
      );
      setState(() {
        // Ajouter le type 'qcm' aux questions générées par l'IA
        _questions.addAll(generated.map((q) => {...q, 'type': 'qcm'}));
        if (_titleCtrl.text.isEmpty) _titleCtrl.text = 'QCM — $topic';
        if (_subjectCtrl.text.isEmpty) _subjectCtrl.text = subject;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${generated.length} questions générées par l\'IA !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ─── SAUVEGARDER ─────────────────────────────────────────────
  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate() || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez le formulaire et ajoutez au moins une question')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final accessCode = _generateAccessCode();

      await _firestore.collection('quizzes').add({
        'title': _titleCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'teacherId': _auth.currentUser!.uid,
        'questions': _questions,
        'accessCode': accessCode,
        'timeLimit': _selectedTime,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ─── NOTIFICATIONS AUX ÉTUDIANTS INSCRITS ──────────────────────
      try {
        await sendNotificationToEnrolledStudents(
          teacherId: _auth.currentUser!.uid,
          title: 'Nouveau QCM disponible',
          message: '${_subjectCtrl.text.trim()} — ${_titleCtrl.text.trim()}',
          type: 'new_quiz',
        );
      } catch (e) {
        debugPrint('Erreur envoi notifications: $e');
        // On continue même si les notifications échouent
      }

      if (!mounted) return;

      showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text(' QCM créé !'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Code d\'accès :'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          accessCode,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
        ),
      ),
      const SizedBox(height: 12),
      // ── BOUTON COPIER ──────────────────────────────────
      ElevatedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: accessCode));
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text(' Code copié !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.copy, size: 18),
        label: const Text('Copier le code'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(ctx, (r) => r.isFirst),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Créer un QCM', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _aiLoading ? null : _showAIDialog,
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            label: const Text('IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── BANNIÈRE IA ──────────────────────────────────────
            GestureDetector(
              onTap: _aiLoading ? null : _showAIDialog,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A43EC), Color(0xFF7B61FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _aiLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('L\'IA génère vos questions...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Générer les questions avec l\'IA',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Entrez un sujet et l\'IA crée les questions automatiquement',
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
              ),
            ),

            // ── FORMULAIRE ───────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre du QCM',
                        prefixIcon: Icon(Icons.title, color: primaryColor),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Matière / Sujet',
                        prefixIcon: Icon(Icons.book, color: primaryColor),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Matière requise' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'Temps limite (minutes)',
                        prefixIcon: Icon(Icons.timer, color: primaryColor),
                        border: OutlineInputBorder(),
                      ),
                      items: [0, 5, 10, 15, 20, 30, 45, 60]
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m == 0 ? 'Illimité' : '$m minutes'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTime = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── LISTE DES QUESTIONS ──────────────────────────────
            if (_questions.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Questions :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                    child: Text('${_questions.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  // Compteurs par type
                  _buildTypeCount('QCM', Icons.quiz, primaryColor),
                  const SizedBox(width: 6),
                  _buildTypeCount('V/F', Icons.toggle_on, Colors.teal),
                ],
              ),
              const SizedBox(height: 12),
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final type = question['type'] ?? 'qcm';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: _colorForType(type),
                      child: Text('${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      question['text'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _colorForType(type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_iconForType(type), size: 12, color: _colorForType(type)),
                              const SizedBox(width: 4),
                              Text(_labelForType(type),
                                  style: TextStyle(fontSize: 11, color: _colorForType(type), fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (type == 'qcm') ...[
                          const SizedBox(width: 8),
                          Text(
                            '✓ ${question['options'][question['correctIndex']]}',
                            style: const TextStyle(color: Colors.green, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (type == 'true_false') ...[
                          const SizedBox(width: 8),
                          Text(
                            '✓ ${question['correctAnswer'] == true ? 'Vrai' : 'Faux'}',
                            style: const TextStyle(color: Colors.green, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _editQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deleteQuestion(index),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],

            // ── BOUTON AJOUTER ───────────────────────────────────
            OutlinedButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add, color: primaryColor),
              label: const Text('Ajouter une question', style: TextStyle(color: primaryColor)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // ── PUBLIER ──────────────────────────────────────────
            _loading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : ElevatedButton.icon(
                    onPressed: _saveQuiz,
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text('Publier le QCM',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCount(String label, IconData icon, Color color) {
    final count = _questions.where((q) {
      if (label == 'QCM') return (q['type'] ?? 'qcm') == 'qcm';
      return (q['type'] ?? 'qcm') == 'true_false';
    }).length;

    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text('$count $label', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── DIALOG QCM ────────────────────────────────────────────────────
class _QuestionDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final String type;
  final Function(Map<String, dynamic>) onAddQuestion;
  const _QuestionDialog({this.question, required this.type, required this.onAddQuestion});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late TextEditingController _questionCtrl;
  late List<TextEditingController> _optionCtrl;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionCtrl = TextEditingController(text: widget.question!['text']);
      _optionCtrl = (widget.question!['options'] as List)
          .map((opt) => TextEditingController(text: opt))
          .toList();
      _correctIndex = widget.question!['correctIndex'];
    } else {
      _questionCtrl = TextEditingController();
      _optionCtrl = List.generate(4, (_) => TextEditingController());
      _correctIndex = 0;
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (var c in _optionCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier la question QCM' : 'Nouvelle question QCM'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _questionCtrl,
            decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('Réponses (cochez la bonne) :'),
          ...List.generate(4, (index) => RadioListTile<int>(
            title: TextField(
              controller: _optionCtrl[index],
              decoration: InputDecoration(
                  labelText: 'Réponse ${index + 1}',
                  border: const OutlineInputBorder()),
            ),
            value: index,
            groupValue: _correctIndex,
            onChanged: (v) => setState(() => _correctIndex = v!),
          )),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_questionCtrl.text.isEmpty || _optionCtrl.any((c) => c.text.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remplissez tous les champs')),
              );
              return;
            }
            widget.onAddQuestion({
              'type': 'qcm',
              'text': _questionCtrl.text,
              'options': _optionCtrl.map((c) => c.text).toList(),
              'correctIndex': _correctIndex,
            });
            Navigator.pop(context);
          },
          child: Text(isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}

// ── DIALOG VRAI / FAUX ────────────────────────────────────────────
class _TrueFalseDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onAddQuestion;
  const _TrueFalseDialog({this.question, required this.onAddQuestion});

  @override
  State<_TrueFalseDialog> createState() => _TrueFalseDialogState();
}

class _TrueFalseDialogState extends State<_TrueFalseDialog> {
  late TextEditingController _statementCtrl;
  bool _correctAnswer = true; // true = Vrai, false = Faux

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _statementCtrl = TextEditingController(text: widget.question!['text']);
      _correctAnswer = widget.question!['correctAnswer'] ?? true;
    } else {
      _statementCtrl = TextEditingController();
      _correctAnswer = true;
    }
  }

  @override
  void dispose() {
    _statementCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.toggle_on, color: Colors.teal),
          ),
          const SizedBox(width: 10),
          Text(isEditing ? 'Modifier Vrai/Faux' : 'Nouvelle question Vrai/Faux'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez une affirmation. L\'étudiant devra dire si elle est vraie ou fausse.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Champ affirmation
            TextField(
              controller: _statementCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Affirmation',
                hintText: 'Ex: La Terre est la troisième planète du système solaire.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.format_quote, color: Colors.teal),
              ),
            ),
            const SizedBox(height: 20),

            // Choisir la bonne réponse
            const Text('La bonne réponse est :', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            const SizedBox(height: 12),

            Row(
              children: [
                // VRAI
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _correctAnswer = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _correctAnswer ? Colors.green : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _correctAnswer ? Colors.green : Colors.grey[300]!,
                          width: _correctAnswer ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _correctAnswer ? Colors.white : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'VRAI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _correctAnswer ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // FAUX
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _correctAnswer = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: !_correctAnswer ? Colors.red : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_correctAnswer ? Colors.red : Colors.grey[300]!,
                          width: !_correctAnswer ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: !_correctAnswer ? Colors.white : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'FAUX',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: !_correctAnswer ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton.icon(
          onPressed: () {
            if (_statementCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez entrer une affirmation')),
              );
              return;
            }
            widget.onAddQuestion({
              'type': 'true_false',
              'text': _statementCtrl.text.trim(),
              'options': ['Vrai', 'Faux'],
              'correctAnswer': _correctAnswer,
              'correctIndex': _correctAnswer ? 0 : 1,
            });
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check, size: 18),
          label: Text(isEditing ? 'Modifier' : 'Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}