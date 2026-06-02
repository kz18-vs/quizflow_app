import 'package:flutter/material.dart';

// ── WIDGET QUESTION ORDRE DE MOTS (compatible Web) ───────────────
// lib/widgets/word_order_widget.dart

class WordOrderWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(List<String> orderedWords) onAnswered;
  final bool isDisabled;

  const WordOrderWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isDisabled = false,
  });

  @override
  State<WordOrderWidget> createState() => _WordOrderWidgetState();
}

class _WordOrderWidgetState extends State<WordOrderWidget> {
  late List<String> _availableWords;
  late List<String> _placedWords;
  late List<int> _availableIndices;
  late List<int> _placedIndices;

  @override
  void initState() {
    super.initState();
    final shuffled = (widget.question['shuffledWords'] as List<dynamic>)
        .map((w) => w.toString())
        .toList();

    _availableWords = List.from(shuffled);
    _availableIndices = List.generate(shuffled.length, (i) => i);
    _placedWords = [];
    _placedIndices = [];
  }

  void _placeWord(int availableIndex) {
    if (widget.isDisabled) return;
    setState(() {
      _placedWords.add(_availableWords[availableIndex]);
      _placedIndices.add(_availableIndices[availableIndex]);
      _availableWords.removeAt(availableIndex);
      _availableIndices.removeAt(availableIndex);
    });
    widget.onAnswered(List.from(_placedWords));
  }

  void _removeWord(int placedIndex) {
    if (widget.isDisabled) return;
    setState(() {
      _availableWords.add(_placedWords[placedIndex]);
      _availableIndices.add(_placedIndices[placedIndex]);
      _placedWords.removeAt(placedIndex);
      _placedIndices.removeAt(placedIndex);
    });
    widget.onAnswered(List.from(_placedWords));
  }

  void _resetAll() {
    setState(() {
      _availableWords.addAll(_placedWords);
      _availableIndices.addAll(_placedIndices);
      _placedWords.clear();
      _placedIndices.clear();
    });
    widget.onAnswered([]);
  }

  @override
  Widget build(BuildContext context) {
    final correctOrder = (widget.question['correctOrder'] as List)
        .map((w) => w.toString())
        .toList();
    final totalWords = correctOrder.length;
    final placed = _placedWords.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── PROGRESSION ─────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$placed / $totalWords mots placés',
              style: TextStyle(
                color: placed == totalWords ? Colors.green : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (placed == totalWords)
              const Row(children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('Tous les mots placés !',
                    style: TextStyle(color: Colors.green, fontSize: 12)),
              ]),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: totalWords > 0 ? placed / totalWords : 0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              placed == totalWords ? Colors.green : Colors.purple,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),

        // ── INSTRUCTIONS ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app, color: Colors.purple, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Appuyez sur un mot pour le placer. Appuyez sur un mot placé pour le retirer.',
                  style: TextStyle(color: Colors.purple, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── ZONE DE RÉPONSE ─────────────────────────────────────
        const Text(
          'Votre réponse :',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _placedWords.isEmpty
                ? Colors.grey[50]
                : Colors.purple.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _placedWords.isEmpty
                  ? Colors.grey[300]!
                  : Colors.purple.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: _placedWords.isEmpty
              ? Center(
                  child: Text(
                    'Appuyez sur les mots ci-dessous pour les placer ici',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_placedWords.length, (index) {
                    return GestureDetector(
                      onTap: () => _removeWord(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _placedWords[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.close,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 16),

        // ── MOTS DISPONIBLES ────────────────────────────────────
        const Text(
          'Mots disponibles :',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: _availableWords.isEmpty
              ? Center(
                  child: Text(
                    'Tous les mots sont placés ✓',
                    style: TextStyle(color: Colors.green[600], fontSize: 13),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_availableWords.length, (index) {
                    return GestureDetector(
                      onTap: () => _placeWord(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.purple.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _availableWords[index],
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
        ),

        // ── BOUTON EFFACER ──────────────────────────────────────
        if (_placedWords.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _resetAll,
            icon: const Icon(Icons.refresh, color: Colors.grey, size: 16),
            label: const Text('Tout effacer',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ],
      ],
    );
  }
}

// ── WIDGET RÉSULTAT ORDRE DE MOTS ─────────────────────────────────
class WordOrderResultWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final List<String> studentAnswer;

  const WordOrderResultWidget({
    super.key,
    required this.question,
    required this.studentAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final correctOrder = (question['correctOrder'] as List)
        .map((w) => w.toString())
        .toList();

    bool isCorrect = studentAnswer.length == correctOrder.length;
    if (isCorrect) {
      for (int i = 0; i < correctOrder.length; i++) {
        if (studentAnswer[i] != correctOrder[i]) {
          isCorrect = false;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 8),
            Text(
              isCorrect ? 'Correct !' : 'Incorrect',
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isCorrect) ...[
          const Text('Ta réponse :',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: studentAnswer
                .map((w) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(w,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        const Text('Bonne réponse :',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: correctOrder
              .asMap()
              .entries
              .map((e) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.key + 1}. ',
                            style: TextStyle(
                                color: Colors.green[300], fontSize: 11)),
                        Text(e.value,
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}