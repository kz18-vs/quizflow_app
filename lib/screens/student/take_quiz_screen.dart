import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/matching_question_widget.dart';
import '../../widgets/word_order_widget.dart';
import '../../services/gamification_service.dart';
import '../../widgets/rewards_dialog.dart';
import '../../utils/notification_helper.dart';

class TakeQuizScreen extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;
  const TakeQuizScreen({super.key, required this.quizId, required this.quizData});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen>
    with WidgetsBindingObserver {
  static const Color primaryColor = Color(0xFF4A43EC);

  int _currentQuestionIndex = 0;
  Map<int, int> _answers = {};
  Map<int, Map<int, int>> _matchingAnswers = {};
  Map<int, List<String>> _wordOrderAnswers = {};

  bool _showResults = false;
  int _score = 0;
  int _totalAnswerable = 0;

  // Timer & états
  int _timeLeft = 0;
  Timer? _timer;
  bool _isExamMode = false;
  bool _timeExpired = false;
  bool _isSubmitting = false;

  //  Anti-triche
  int _violationCount = 0;
  final int _maxViolations = 2;
  bool _warningActive = false;
  

  //  Infos pour notifications
  String? _teacherId;
  String _studentName = "Étudiant";
  String _studentClass = "N/A";
  String _studentGroup = "N/A";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _teacherId = widget.quizData['teacherId'];
    _loadStudentInfo();
    
    int limit = widget.quizData['timeLimit'] ?? 0;
    if (limit > 0) {
      _timeLeft = limit * 60;
      _isExamMode = true;
      _startTimer();
    }
  }
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_showResults || _timeExpired) return;

  if (state == AppLifecycleState.paused) {
    _triggerViolation(
      "Vous avez quitté l'application pendant l'examen",
    );
  }

  if (state == AppLifecycleState.inactive) {
    _triggerViolation(
      "Activité suspecte détectée",
    );
  }
}
  // Chargement des infos étudiant pour les notifications
  Future<void> _loadStudentInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          setState(() {
            _studentName = '${data['firstName'] ?? 'Étudiant'} ${data['lastName'] ?? ''}'.trim();
            _studentClass = data['classe'] ?? 'N/A';
            _studentGroup = data['groupe'] ?? 'N/A';
          });
        }
      }
    } catch (e) {
      debugPrint(' Erreur chargement infos: $e');
    }
  }

  //  Détection violation + NOTIFICATION PROF
  void _triggerViolation(String reason) {
    if (_warningActive || _showResults) return;
    _warningActive = true;
    _violationCount++;

    //  NOTIFIER LE PROFESSEUR IMMÉDIATEMENT
    if (_teacherId != null) {
      sendCheatingAlertToTeacher(
        teacherId: _teacherId!,
        studentId: FirebaseAuth.instance.currentUser?.uid ?? '',
        quizTitle: widget.quizData['title'] ?? 'Quiz',
        studentName: _studentName,
        studentClass: _studentClass,
        studentGroup: _studentGroup,
        violationCount: _violationCount,
        isExcluded: _violationCount >= _maxViolations,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(' $reason ($_violationCount/$_maxViolations)'),
        backgroundColor: _violationCount >= _maxViolations ? Colors.redAccent : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );

    if (_violationCount >= _maxViolations) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Trop de violations. Quiz terminé automatiquement.'),
              backgroundColor: Colors.red,
            ),
          );
          _calculateScore();
        }
      });
    }
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _warningActive = false;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_showResults && !_timeExpired) {
        setState(() => _timeLeft--);
      } else if (_timeLeft == 0 && !_showResults && !_timeExpired) {
        _timeExpired = true;
        _timer?.cancel();
        _showTimeExpiredDialog();
      }
    });
  }

  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.timer_off, color: Colors.red),
          SizedBox(width: 10),
          Text(' Temps écoulé !'),
        ]),
        content: const Text('Votre temps est terminé. Cliquez sur "Voir résultats" pour valider.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _calculateScore(); },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Voir résultats', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── NAVIGATION ───────────────────────────────────────────────
  void _nextQuestion() {
    if (_showResults || _timeExpired) return;
    final questions = widget.quizData['questions'] as List;
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _calculateScore();
    }
  }

  bool _currentQuestionAnswered() {
    final questions = widget.quizData['questions'] as List;
    final q = questions[_currentQuestionIndex] as Map<String, dynamic>;
    final type = q['type'] ?? 'qcm';

    if (type == 'matching') {
      final pairs = q['pairs'] as List<dynamic>;
      final matches = _matchingAnswers[_currentQuestionIndex] ?? {};
      return matches.length == pairs.length;
    } else if (type == 'word_order') {
      final correctOrder = q['correctOrder'] as List;
      final words = _wordOrderAnswers[_currentQuestionIndex] ?? [];
      return words.length == correctOrder.length;
    }
    return _answers.containsKey(_currentQuestionIndex);
  }

  // ─── CALCUL SCORE ─────────────────────────────────────────────
  Future<void> _calculateScore() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    int correct = 0;
    int total = 0;
    final questions = widget.quizData['questions'] as List<dynamic>;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      final type = q['type'] ?? 'qcm';

      if (type == 'matching') {
        final pairs = q['pairs'] as List<dynamic>;
        final matches = _matchingAnswers[i] ?? {};
        for (int j = 0; j < pairs.length; j++) {
          total++;
          if (matches[j] == j) correct++;
        }
      } else {
        if (_answers.containsKey(i)) {
          total++;
          if (_answers[i] == q['correctIndex']) correct++;
        }
      }
    }

    _totalAnswerable = total;
    await _saveResultToFirestore(correct, total,
        total > 0 ? (correct / total) * 100 : 0.0);

    setState(() {
      _score = correct;
      _showResults = true;
    });
    _timer?.cancel();

    //  Notifier le professeur de la soumission finale
    try {
      await sendNotificationToTeacher(
        teacherId: widget.quizData['teacherId'],
        quizTitle: widget.quizData['title'] ?? 'Quiz',
      );
    } catch (e) {
      debugPrint('Erreur notification prof: $e');
    }
  }

  Future<void> _saveResultToFirestore(int score, int total, double percentage) async {
  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // ── VÉRIFIER SI CE QCM A DÉJÀ ÉTÉ FAIT ──────────────────
    final alreadyDone = await FirebaseFirestore.instance
        .collection('results')
        .where('studentId', isEqualTo: uid)
        .where('quizId', isEqualTo: widget.quizId)
        .limit(1)
        .get();

    final isFirstTime = alreadyDone.docs.isEmpty;

    // ── SAUVEGARDER LE RÉSULTAT ───────────────────────────────
    await FirebaseFirestore.instance.collection('results').add({
      'studentId': uid,
      'quizId': widget.quizId,
      'quizTitle': widget.quizData['title'] ?? 'Quiz',
      'subject': widget.quizData['subject'] ?? 'Général',
      'score': score,
      'total': total,
      'percentage': percentage,
      'violations': _violationCount,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // ── POINTS SEULEMENT SI 1ère FOIS ────────────────────────
    if (isFirstTime) {
      final rewards = await GamificationService.updateAfterQuiz(
        percentage: percentage,
        score: score,
        total: total,
      );
      if (mounted) showRewardsDialog(context, rewards);
    } else {
      // Afficher un message sans points
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Résultat enregistré — pas de points pour les répétitions'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Erreur sauvegarde: $e');
  }
}

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final questions = widget.quizData['questions'] as List<dynamic>;
    if (_showResults) return _buildResultsScreen();

    final currentQuestion = questions[_currentQuestionIndex] as Map<String, dynamic>;
    final type = currentQuestion['type'] ?? 'qcm';
    final timeColor = _isExamMode && _timeLeft <= 60 ? Colors.red : primaryColor;

    return PopScope(
      canPop: _showResults || _timeExpired || !_isExamMode,
      onPopInvoked: (didPop) {
        if (!didPop && _isExamMode && !_timeExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mode Examen : Navigation arrière bloquée')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(widget.quizData['title'] ?? 'Quiz',
              style: const TextStyle(color: Colors.white)),
          elevation: 0,
          actions: [
            // Indicateur visuel si violations détectées
            if (_violationCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _violationCount >= _maxViolations ? Icons.block : Icons.warning_amber_rounded,
                      color: _violationCount >= _maxViolations ? Colors.red[300] : Colors.orange[300],
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_violationCount',
                      style: TextStyle(
                        color: _violationCount >= _maxViolations ? Colors.red[300] : Colors.orange[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isExamMode)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    _formatTime(_timeLeft),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: timeColor),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_isExamMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: LinearProgressIndicator(
                  value: _timeLeft / (widget.quizData['timeLimit'] * 60),
                  backgroundColor: Colors.grey[300],
                  color: timeColor,
                  minHeight: 6,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} / ${questions.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon(type), size: 12, color: _typeColor(type)),
                        const SizedBox(width: 4),
                        Text(
                          _typeLabel(type),
                          style: TextStyle(
                              fontSize: 11,
                              color: _typeColor(type),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Opacity(
                opacity: _timeExpired ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: _timeExpired,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            currentQuestion['text'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (type == 'matching')
                          MatchingQuestionWidget(
                            question: currentQuestion,
                            isDisabled: _timeExpired,
                            onAnswered: (matches) {
                              setState(() => _matchingAnswers[_currentQuestionIndex] = matches);
                            },
                          )
                        else if (type == 'true_false')
                          _buildTrueFalseOptions(currentQuestion)
                        else if (type == 'word_order')
                          WordOrderWidget(
                            question: currentQuestion,
                            isDisabled: _timeExpired,
                            onAnswered: (words) {
                              setState(() => _wordOrderAnswers[_currentQuestionIndex] = words);
                            },
                          )  
                        else
                          _buildQcmOptions(currentQuestion),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!_isExamMode && _currentQuestionIndex > 0)
                              ElevatedButton.icon(
                                onPressed: () => setState(() => _currentQuestionIndex--),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Précédent'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400]),
                              )
                            else
                              const SizedBox(width: 100),
                            ElevatedButton.icon(
                              onPressed: _currentQuestionAnswered() ? _nextQuestion : null,
                              label: Text(
                                _currentQuestionIndex == questions.length - 1
                                    ? 'Terminer'
                                    : 'Suivant',
                              ),
                              icon: Icon(
                                _currentQuestionIndex == questions.length - 1
                                    ? Icons.check
                                    : Icons.arrow_forward,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── OPTIONS QCM ──────────────────────────────────────────────
  Widget _buildQcmOptions(Map<String, dynamic> question) {
    final options = question['options'] as List<dynamic>;
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value as String;
        final isSelected = _answers[_currentQuestionIndex] == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _answers[_currentQuestionIndex] = index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primaryColor : Colors.grey[100],
                    ),
                    child: Center(
                      child: Text(
                        ['A', 'B', 'C', 'D'][index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(option,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? primaryColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ),
                  if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── OPTIONS VRAI/FAUX ────────────────────────────────────────
  Widget _buildTrueFalseOptions(Map<String, dynamic> question) {
    final selectedIndex = _answers[_currentQuestionIndex];

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _answers[_currentQuestionIndex] = 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: selectedIndex == 0 ? Colors.green : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedIndex == 0 ? Colors.green : Colors.grey[300]!,
                  width: selectedIndex == 0 ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle,
                      color: selectedIndex == 0 ? Colors.white : Colors.grey, size: 40),
                  const SizedBox(height: 10),
                  Text('VRAI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selectedIndex == 0 ? Colors.white : Colors.grey,
                      )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _answers[_currentQuestionIndex] = 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: selectedIndex == 1 ? Colors.red : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedIndex == 1 ? Colors.red : Colors.grey[300]!,
                  width: selectedIndex == 1 ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.cancel,
                      color: selectedIndex == 1 ? Colors.white : Colors.grey, size: 40),
                  const SizedBox(height: 10),
                  Text('FAUX',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selectedIndex == 1 ? Colors.white : Colors.grey,
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── HELPERS TYPE ─────────────────────────────────────────────
  Color _typeColor(String type) {
    switch (type) {
      case 'true_false': return Colors.teal;
      case 'matching': return Colors.orange;
      default: return primaryColor;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'true_false': return Icons.toggle_on;
      case 'matching': return Icons.compare_arrows;
      default: return Icons.quiz;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'true_false': return 'Vrai / Faux';
      case 'matching': return 'Relier';
      default: return 'QCM';
    }
  }

  // ─── ÉCRAN RÉSULTATS ──────────────────────────────────────────
  Widget _buildResultsScreen() {
    final percentage = _totalAnswerable > 0
        ? (_score / _totalAnswerable) * 100
        : 0.0;
    final isPassed = percentage >= 50;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isPassed ? Colors.green : Colors.orange,
        title: Text(
          _timeExpired ? 'Temps écoulé' : (isPassed ? 'Félicitations ! 🎉' : 'Terminé'),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _timeExpired
                    ? Icons.timer_off
                    : (isPassed ? Icons.emoji_events : Icons.check_circle),
                size: 80,
                color: _timeExpired
                    ? Colors.grey
                    : (isPassed ? Colors.amber : Colors.green),
              ),
              const SizedBox(height: 20),
              Text('Votre Score',
                  style: TextStyle(fontSize: 24, color: Colors.grey[600])),
              const SizedBox(height: 10),
              Text('$_score / $_totalAnswerable',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: primaryColor)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              if (_violationCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ' $_violationCount violation(s) détectée(s)',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour à la liste'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}