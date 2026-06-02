import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/ai_service.dart';
import 'dart:typed_data';

class StudentAIQuizScreen extends StatefulWidget {
  const StudentAIQuizScreen({super.key});

  @override
  State<StudentAIQuizScreen> createState() => _StudentAIQuizScreenState();
}

class _StudentAIQuizScreenState extends State<StudentAIQuizScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);

  final _textCtrl = TextEditingController();

  // PDF
  String? _pdfName;
  Uint8List? _pdfBytes;

  // Options
  int _nbQuestions = 5;
  String _difficulty = 'moyen';

  // États
  String _step = 'input'; // input → loading → quiz → result

  // Quiz
  List<Map<String, dynamic>> _questions = [];
  List<int?> _answers = [];
  int _currentIndex = 0;
  int _score = 0;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ─── CHOISIR PDF ──────────────────────────────────────────────
  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible de lire le fichier. Réessayez.'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        setState(() {
          _pdfName = file.name;
          _pdfBytes = bytes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${file.name} chargé !'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ─── GÉNÉRER DEPUIS TEXTE ─────────────────────────────────────
  Future<void> _generateFromText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez coller votre cours')));
      return;
    }
    if (text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texte trop court — minimum 50 caractères')));
      return;
    }
    await _generateWithAI(text);
  }

  // ─── GÉNÉRER DEPUIS PDF ───────────────────────────────────────
  Future<void> _generateFromPDF() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir un fichier PDF')));
      return;
    }
    setState(() => _step = 'loading');
    try {
      final courseText = await AIService.extractTextFromPdfBytes(_pdfBytes!);
      if (courseText.isEmpty) throw Exception('PDF vide ou non lisible');
      await _generateWithAI(courseText);
    } catch (e) {
      setState(() => _step = 'input');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ─── APPEL IA GEMINI ──────────────────────────────────────────
  Future<void> _generateWithAI(String courseText) async {
    setState(() => _step = 'loading');

    try {
      final questions = await AIService.generateFromCourse(
        courseText: courseText,
        numberOfQuestions: _nbQuestions,
        difficulty: _difficulty,
      );

      setState(() {
        _questions = questions;
        _answers = List.filled(questions.length, null);
        _currentIndex = 0;
        _step = 'quiz';
      });
    } catch (e) {
      setState(() => _step = 'input');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur IA : $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ─── RÉPONDRE ─────────────────────────────────────────────────
  void _selectAnswer(int index) {
    setState(() => _answers[_currentIndex] = index);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _calculateScore();
    }
  }

  void _calculateScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['correctIndex']) score++;
    }
    setState(() {
      _score = score;
      _step = 'result';
    });
  }

  void _reset() {
    setState(() {
      _step = 'input';
      _pdfName = null;
      _pdfBytes = null;
      _textCtrl.clear();
      _questions = [];
      _answers = [];
      _currentIndex = 0;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Apprendre avec mon cours', style: TextStyle(color: Colors.white)),
        elevation: 0,
        leading: _step != 'input'
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _reset)
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 'loading':
        return _buildLoading();
      case 'quiz':
        return _buildQuiz();
      case 'result':
        return _buildResult();
      default:
        return _buildInput();
    }
  }

  // ─── INPUT ────────────────────────────────────────────────────
  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bannière
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4A43EC), Color(0xFF7B61FF)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                SizedBox(height: 10),
                Text('Auto-évaluation IA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Importe ton cours et l\'IA génère des questions pour toi !', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ZONE PDF
          GestureDetector(
            onTap: _pickPDF,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pdfBytes != null ? primaryColor : Colors.grey.shade300, width: _pdfBytes != null ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_pdfBytes != null ? Icons.picture_as_pdf : Icons.upload_file, size: 46, color: _pdfBytes != null ? Colors.red : Colors.grey),
                  const SizedBox(height: 10),
                  Text(_pdfBytes != null ? '✅ $_pdfName' : 'Appuyer pour choisir un PDF', style: TextStyle(fontSize: 14, fontWeight: _pdfBytes != null ? FontWeight.bold : FontWeight.normal, color: _pdfBytes != null ? primaryColor : Colors.grey), textAlign: TextAlign.center),
                  if (_pdfBytes != null)
                    TextButton(onPressed: _pickPDF, child: const Text('Changer de fichier')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ZONE TEXTE
          Container(
            height: 150,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
            child: TextField(
              controller: _textCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'OU colle ici le texte de ton cours...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Options
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 14),
                  const Text('Nombre de questions', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [3, 5, 10].map((n) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$n'),
                        selected: _nbQuestions == n,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(color: _nbQuestions == n ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() => _nbQuestions = n),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Difficulté', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'label': 'Facile', 'value': 'facile', 'color': Colors.green},
                      {'label': 'Moyen', 'value': 'moyen', 'color': Colors.orange},
                      {'label': 'Difficile', 'value': 'difficile', 'color': Colors.red},
                    ].map((d) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(d['label'] as String, style: const TextStyle(fontSize: 12)),
                        selected: _difficulty == d['value'],
                        selectedColor: d['color'] as Color,
                        labelStyle: TextStyle(color: _difficulty == d['value'] ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() => _difficulty = d['value'] as String),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              if (_pdfBytes != null) {
                _generateFromPDF();
              } else {
                _generateFromText();
              }
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Générer mon QCM avec l\'IA', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── LOADING ──────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          const SizedBox(height: 24),
          const Text('L\'IA analyse ton cours...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }

  // ─── QUIZ ─────────────────────────────────────────────────────
  Widget _buildQuiz() {
    final question = _questions[_currentIndex];
    final options = question['options'] as List;
    final selectedAnswer = _answers[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_currentIndex + 1} / ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_answers.where((a) => a != null).length} répondues', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(primaryColor), minHeight: 8),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
            child: Text(question['text'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5)),
          ),
          const SizedBox(height: 20),

          ...List.generate(options.length, (index) {
            final isSelected = selectedAnswer == index;
            return GestureDetector(
              onTap: () => _selectAnswer(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? primaryColor : Colors.grey[300]!, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? primaryColor : Colors.grey[100]),
                      child: Center(child: Text(['A', 'B', 'C', 'D'][index], style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(options[index], style: TextStyle(fontSize: 15, color: isSelected ? primaryColor : Colors.black87, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                    if (isSelected) const Icon(Icons.check_circle, color: primaryColor, size: 20),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: selectedAnswer != null ? _nextQuestion : null,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, disabledBackgroundColor: Colors.grey[300], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_currentIndex < _questions.length - 1 ? 'Question suivante →' : 'Voir mes résultats', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── RÉSULTATS ────────────────────────────────────────────────
  Widget _buildResult() {
    final percentage = (_score / _questions.length * 100).round();
    final Color scoreColor = percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red;
    final String message = percentage >= 70 ? '🎉 Excellent travail !' : percentage >= 50 ? '👍 Bon effort, continue !' : '📚 Revois ton cours et réessaie !';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: scoreColor.withValues(alpha: 0.1), border: Border.all(color: scoreColor, width: 4)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$_score/${_questions.length}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scoreColor)),
                        Text('$percentage%', style: TextStyle(color: scoreColor, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Détail des réponses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final isCorrect = _answers[i] == q['correctIndex'];
            final options = q['options'] as List;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(q['text'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isCorrect)
                      Text('❌ Ta réponse : ${_answers[i] != null ? options[_answers[i]!] : "Pas de réponse"}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    Text('✅ Bonne réponse : ${options[q['correctIndex']]}', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                    if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 15),
                            const SizedBox(width: 6),
                            Expanded(child: Text(q['explanation'], style: const TextStyle(color: Colors.blue, fontSize: 12))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _answers = List.filled(_questions.length, null);
                _currentIndex = 0;
                _score = 0;
                _step = 'quiz';
              });
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.upload_file, color: primaryColor),
            label: const Text('Nouveau cours', style: TextStyle(color: primaryColor)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryColor), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}