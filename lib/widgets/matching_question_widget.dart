import 'package:flutter/material.dart';

class MatchingQuestionWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(Map<int, int> matches) onAnswered;
  final bool isDisabled;

  const MatchingQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isDisabled = false,
  });

  @override
  State<MatchingQuestionWidget> createState() => _MatchingQuestionWidgetState();
}

class _MatchingQuestionWidgetState extends State<MatchingQuestionWidget> {
  // Index de l'élément gauche sélectionné (-1 = rien sélectionné)
  int _selectedLeft = -1;

  // Map des connexions : leftIndex → rightIndex
  Map<int, int> _matches = {};

  // Ordre mélangé des éléments droits
  late List<int> _shuffledRightIndices;

  @override
  void initState() {
    super.initState();
    final pairs = widget.question['pairs'] as List<dynamic>;
    _shuffledRightIndices = List.generate(pairs.length, (i) => i)..shuffle();
  }

  void _selectLeft(int index) {
    if (widget.isDisabled) return;
    setState(() {
      if (_selectedLeft == index) {
        _selectedLeft = -1; // Désélectionner
      } else {
        _selectedLeft = index;
      }
    });
  }

  void _selectRight(int shuffledIndex) {
    if (widget.isDisabled) return;
    if (_selectedLeft == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez d\'abord un élément à gauche'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final rightIndex = _shuffledRightIndices[shuffledIndex];

    setState(() {
      // Si ce droit était déjà lié à un autre gauche → supprimer l'ancien lien
      _matches.removeWhere((k, v) => v == rightIndex);

      // Si ce gauche avait déjà un lien → le remplacer
      _matches[_selectedLeft] = rightIndex;
      _selectedLeft = -1;
    });

    // Notifier le parent
    widget.onAnswered(_matches);
  }

  void _removeMatch(int leftIndex) {
    if (widget.isDisabled) return;
    setState(() => _matches.remove(leftIndex));
    widget.onAnswered(_matches);
  }

  Color _getLeftColor(int index) {
    if (_selectedLeft == index) return const Color(0xFF4A43EC);
    if (_matches.containsKey(index)) return Colors.green;
    return Colors.blue;
  }

  Color _getRightColor(int shuffledIndex) {
    final rightIndex = _shuffledRightIndices[shuffledIndex];
    if (_matches.values.contains(rightIndex)) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.question['pairs'] as List<dynamic>;
    final totalPairs = pairs.length;
    final matched = _matches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // Progression des connexions
        if (totalPairs > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$matched / $totalPairs reliés',
                style: TextStyle(
                  color: matched == totalPairs ? Colors.green : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (matched == totalPairs)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Toutes les paires reliées !',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalPairs > 0 ? matched / totalPairs : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                matched == totalPairs ? Colors.green : const Color(0xFF4A43EC),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Instructions
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Appuyez sur un élément à gauche puis sur sa correspondance à droite',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Colonnes gauche / droite
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── COLONNE GAUCHE ────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'À relier',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(totalPairs, (index) {
                    final pair = pairs[index] as Map<String, dynamic>;
                    final isSelected = _selectedLeft == index;
                    final isMatched = _matches.containsKey(index);
                    final color = _getLeftColor(index);

                    return GestureDetector(
                      onTap: () => _selectLeft(index),
                      onLongPress: () => _removeMatch(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isMatched
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pair['left'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? color : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.arrow_forward, color: color, size: 16),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── COLONNE DROITE ─────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Correspondances',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(totalPairs, (shuffledIndex) {
                    final rightIndex = _shuffledRightIndices[shuffledIndex];
                    final pair = pairs[rightIndex] as Map<String, dynamic>;
                    final isMatched = _matches.values.contains(rightIndex);

                    // Trouver quel gauche est lié à ce droit
                    final linkedLeftIndex = _matches.entries
                        .where((e) => e.value == rightIndex)
                        .map((e) => e.key)
                        .firstOrNull;

                    final color = isMatched ? Colors.green : Colors.grey;

                    return GestureDetector(
                      onTap: () => _selectRight(shuffledIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? Colors.green.withOpacity(0.1)
                              : _selectedLeft != -1
                                  ? Colors.orange.withOpacity(0.05)
                                  : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMatched
                                ? Colors.green
                                : _selectedLeft != -1
                                    ? Colors.orange.withOpacity(0.5)
                                    : Colors.grey[300]!,
                            width: isMatched ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isMatched && linkedLeftIndex != null)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${linkedLeftIndex + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(Icons.circle_outlined,
                                      size: 14, color: Colors.grey[400]),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pair['right'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isMatched ? Colors.green[800] : Colors.black87,
                                  fontWeight: isMatched ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          'Appui long sur un élément gauche pour supprimer sa connexion',
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}



class MatchingResultWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Map<int, int> studentMatches;

  const MatchingResultWidget({
    super.key,
    required this.question,
    required this.studentMatches,
  });

  @override
  Widget build(BuildContext context) {
    final pairs = question['pairs'] as List<dynamic>;
    int correct = 0;

    for (int i = 0; i < pairs.length; i++) {
      if (studentMatches[i] == i) correct++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Résultat : ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '$correct / ${pairs.length} bonnes liaisons',
              style: TextStyle(
                color: correct == pairs.length ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(pairs.length, (i) {
          final pair = pairs[i] as Map<String, dynamic>;
          final studentRightIndex = studentMatches[i];
          final isCorrect = studentRightIndex == i;
          final studentAnswer = studentRightIndex != null
              ? (pairs[studentRightIndex] as Map<String, dynamic>)['right']
              : 'Pas répondu';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pair['left'],
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ' ${pair['right']}',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      if (!isCorrect)
                        Text(
                          ' Ta réponse : $studentAnswer',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}