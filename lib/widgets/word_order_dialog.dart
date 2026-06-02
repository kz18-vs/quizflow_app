import 'package:flutter/material.dart';

// ── DIALOG CRÉATION QUESTION ORDRE DE MOTS ───────────────────────
// À placer dans : lib/widgets/word_order_dialog.dart

class WordOrderDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onAddQuestion;
  const WordOrderDialog({super.key, this.question, required this.onAddQuestion});

  @override
  State<WordOrderDialog> createState() => _WordOrderDialogState();
}

class _WordOrderDialogState extends State<WordOrderDialog> {
  late TextEditingController _questionCtrl;
  late TextEditingController _sentenceCtrl;

  // Prévisualisation des mots mélangés
  List<String> _previewWords = [];

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionCtrl = TextEditingController(text: widget.question!['text']);
      final correctWords = (widget.question!['correctOrder'] as List)
          .map((w) => w.toString())
          .toList();
      _sentenceCtrl = TextEditingController(text: correctWords.join(' '));
      _updatePreview(correctWords.join(' '));
    } else {
      _questionCtrl = TextEditingController();
      _sentenceCtrl = TextEditingController();
    }

    _sentenceCtrl.addListener(() => _updatePreview(_sentenceCtrl.text));
  }

  void _updatePreview(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      final shuffled = List<String>.from(words)..shuffle();
      setState(() => _previewWords = shuffled);
    } else {
      setState(() => _previewWords = []);
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _sentenceCtrl.dispose();
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
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sort, color: Colors.purple, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEditing ? 'Modifier Ordre de mots' : 'Nouvelle question Ordre de mots',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'étudiant devra remettre les mots dans le bon ordre.',
                        style: TextStyle(color: Colors.purple, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Consigne
              TextField(
                controller: _questionCtrl,
                decoration: InputDecoration(
                  labelText: 'Consigne',
                  hintText: 'Ex: Remettez cette formule dans le bon ordre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.help_outline, color: Colors.purple),
                ),
              ),
              const SizedBox(height: 14),

              // Phrase/formule correcte
              TextField(
                controller: _sentenceCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Phrase ou formule dans le bon ordre',
                  hintText: 'Ex: La lumière voyage plus vite que le son',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.text_fields, color: Colors.purple),
                  helperText: 'Tapez la phrase correcte — les mots seront mélangés automatiquement',
                  helperStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),

              // Prévisualisation mots mélangés
              if (_previewWords.isNotEmpty) ...[
                const Text(
                  'Aperçu — ce que l\'étudiant verra :',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _previewWords.map((word) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Text(
                        word,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_previewWords.length} mots détectés',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_questionCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entrez une consigne')),
              );
              return;
            }
            final words = _sentenceCtrl.text.trim()
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .toList();

            if (words.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entrez au moins 2 mots')),
              );
              return;
            }

            // Mélanger les mots pour le stockage
            final shuffled = List<String>.from(words)..shuffle();

            widget.onAddQuestion({
              'type': 'word_order',
              'text': _questionCtrl.text.trim(),
              'correctOrder': words,       // ordre correct
              'shuffledWords': shuffled,   // mots mélangés pour l'étudiant
              // Compatibilité système existant
              'options': words,
              'correctIndex': 0,
            });
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check, size: 18),
          label: Text(isEditing ? 'Modifier' : 'Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}