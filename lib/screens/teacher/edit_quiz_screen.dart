import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditQuizScreen extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const EditQuizScreen({
    super.key,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _subjectCtrl;
  final _firestore = FirebaseFirestore.instance;
  
  bool _loading = false;
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.quizData['title'] ?? '');
    _subjectCtrl = TextEditingController(text: widget.quizData['subject'] ?? '');
    _questions = List<Map<String, dynamic>>.from(
      widget.quizData['questions']?.map((q) => Map<String, dynamic>.from(q)) ?? [],
    );
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (ctx) => _QuestionDialog(
        onAddQuestion: (question) {
          setState(() => _questions.add(question));
        },
      ),
    );
  }

  Future<void> _updateQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une question')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _firestore.collection('quizzes').doc(widget.quizId).update({
        'title': _titleCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'questions': _questions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' QCM modifié avec succès !'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A43EC),
        title: const Text('Modifier le QCM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre et Matière
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
                        prefixIcon: Icon(Icons.title, color: Color(0xFF4A43EC)),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Matière / Sujet',
                        prefixIcon: Icon(Icons.book, color: Color(0xFF4A43EC)),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Matière requise' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Liste des questions
            if (_questions.isNotEmpty) ...[
              const Text('Questions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4A43EC),
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(question['text']),
                    subtitle: Text('${question['options'].length} réponses'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _questions.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],

            // Bouton Ajouter une question
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A43EC),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton Mettre à jour
            _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)))
                : ElevatedButton(
                    onPressed: _updateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(' Mettre à jour le QCM', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    showDialog(
      context: context,
      builder: (ctx) => _QuestionDialog(
        existingQuestion: question,
        onAddQuestion: (updatedQuestion) {
          setState(() => _questions[index] = updatedQuestion);
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }
}

// Dialog pour ajouter/modifier une question
class _QuestionDialog extends StatefulWidget {
  final Map<String, dynamic>? existingQuestion;
  final Function(Map<String, dynamic>) onAddQuestion;

  const _QuestionDialog({
    this.existingQuestion,
    required this.onAddQuestion,
  });

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
    _questionCtrl = TextEditingController(
      text: widget.existingQuestion?['text'] ?? '',
    );
    _optionCtrl = List.generate(
      4,
      (i) => TextEditingController(
        text: widget.existingQuestion?['options']?[i] ?? '',
      ),
    );
    _correctIndex = widget.existingQuestion?['correctIndex'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingQuestion == null ? 'Ajouter une question' : 'Modifier la question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Réponses (cochez la bonne):'),
            ...List.generate(4, (index) => RadioListTile<int>(
              title: TextField(
                controller: _optionCtrl[index],
                decoration: InputDecoration(labelText: 'Réponse ${index + 1}', border: const OutlineInputBorder()),
              ),
              value: index,
              groupValue: _correctIndex,
              onChanged: (v) => setState(() => _correctIndex = v!),
            )),
          ],
        ),
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
              'text': _questionCtrl.text,
              'options': _optionCtrl.map((c) => c.text).toList(),
              'correctIndex': _correctIndex,
            });
            Navigator.pop(context);
          },
          child: Text(widget.existingQuestion == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (var ctrl in _optionCtrl) {
      ctrl.dispose();
    }
    super.dispose();
  }
}