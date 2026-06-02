import 'package:flutter/material.dart';

// ── DIALOG CRÉATION QUESTION RELIER ──────────────────────────────
// À ajouter dans create_quiz_screen.dart
// Appel : showDialog(context: context, builder: (_) => MatchingDialog(...))

class MatchingDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onAddQuestion;
  const MatchingDialog({super.key, this.question, required this.onAddQuestion});

  @override
  State<MatchingDialog> createState() => _MatchingDialogState();
}

class _MatchingDialogState extends State<MatchingDialog> {
  late TextEditingController _questionCtrl;

  // Liste de paires : [{left: 'mot', right: 'définition'}]
  late List<Map<String, TextEditingController>> _pairs;

  @override
  void initState() {
    super.initState();

    if (widget.question != null) {
      _questionCtrl = TextEditingController(text: widget.question!['text']);
      final pairs = widget.question!['pairs'] as List<dynamic>;
      _pairs = pairs.map((p) => {
        'left': TextEditingController(text: p['left']),
        'right': TextEditingController(text: p['right']),
      }).toList();
    } else {
      _questionCtrl = TextEditingController();
      // 3 paires par défaut
      _pairs = List.generate(3, (_) => {
        'left': TextEditingController(),
        'right': TextEditingController(),
      });
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (var pair in _pairs) {
      pair['left']!.dispose();
      pair['right']!.dispose();
    }
    super.dispose();
  }

  void _addPair() {
    if (_pairs.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 paires')),
      );
      return;
    }
    setState(() => _pairs.add({
      'left': TextEditingController(),
      'right': TextEditingController(),
    }));
  }

  void _removePair(int index) {
    if (_pairs.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 paires requises')),
      );
      return;
    }
    setState(() {
      _pairs[index]['left']!.dispose();
      _pairs[index]['right']!.dispose();
      _pairs.removeAt(index);
    });
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
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.compare_arrows, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            isEditing ? 'Modifier Relier' : 'Nouvelle question Relier',
            style: const TextStyle(fontSize: 16),
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
              const Text(
                'L\'étudiant devra relier chaque élément de gauche à celui de droite.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // Consigne
              TextField(
                controller: _questionCtrl,
                decoration: InputDecoration(
                  labelText: 'Consigne',
                  hintText: 'Ex: Reliez chaque mot à sa définition',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.help_outline, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),

              // En-têtes colonnes
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Colonne gauche',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.compare_arrows, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Colonne droite',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 10),

              // Paires
              ...List.generate(_pairs.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      // Gauche
                      Expanded(
                        child: TextField(
                          controller: _pairs[index]['left'],
                          decoration: InputDecoration(
                            hintText: 'Ex: Photosynthèse',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            prefixText: '${index + 1}. ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, color: Colors.grey, size: 18),
                      const SizedBox(width: 6),
                      // Droite
                      Expanded(
                        child: TextField(
                          controller: _pairs[index]['right'],
                          decoration: InputDecoration(
                            hintText: 'Ex: Processus des plantes',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.green, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Supprimer
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                        onPressed: () => _removePair(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                );
              }),

              // Bouton ajouter paire
              TextButton.icon(
                onPressed: _addPair,
                icon: const Icon(Icons.add, color: Colors.orange, size: 18),
                label: const Text('Ajouter une paire', style: TextStyle(color: Colors.orange)),
              ),
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
            // Validation
            if (_questionCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entrez une consigne')),
              );
              return;
            }
            if (_pairs.any((p) =>
                p['left']!.text.trim().isEmpty || p['right']!.text.trim().isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remplissez toutes les paires')),
              );
              return;
            }

            final pairsData = _pairs.map((p) => {
              'left': p['left']!.text.trim(),
              'right': p['right']!.text.trim(),
            }).toList();

            widget.onAddQuestion({
              'type': 'matching',
              'text': _questionCtrl.text.trim(),
              'pairs': pairsData,
              // Pour compatibilité avec le système existant
              'options': pairsData.map((p) => p['left']).toList(),
              'correctIndex': 0,
            });
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check, size: 18),
          label: Text(widget.question != null ? 'Modifier' : 'Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}