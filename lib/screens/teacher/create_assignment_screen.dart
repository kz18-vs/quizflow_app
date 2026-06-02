import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends State<CreateAssignmentScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);

  final _titleCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  DateTime? _deadline;
  bool _loading = false;

  // ─── CHOISIR DATE LIMITE ─────────────────────────────
  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ─── PUBLIER ─────────────────────────────────────────
  Future<void> _publish() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _moduleCtrl.text.trim().isEmpty ||
        _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Titre, module et date limite sont obligatoires',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance
          .collection('assignments')
          .add({
        'teacherId': user.uid,
        'title': _titleCtrl.text.trim(),
        'module': _moduleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'fileLink': _linkCtrl.text.trim(),
        'deadline': Timestamp.fromDate(_deadline!),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ TP publié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _moduleCtrl.dispose();
    _descriptionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Publier un TP/TD',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration:
                  _inputDeco('Titre du TP', Icons.title),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _moduleCtrl,
              decoration:
                  _inputDeco('Module / Matière', Icons.book),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: _inputDeco(
                'Description (optionnel)',
                Icons.description,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _linkCtrl,
              decoration: _inputDeco(
                'Lien Google Drive (optionnel)',
                Icons.link,
              ),
            ),
            const SizedBox(height: 16),

            // Date limite
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'Choisir une date limite *'
                            : 'Date limite : ${DateFormat('dd/MM/yyyy HH:mm').format(_deadline!)}',
                        style: TextStyle(
                          color: _deadline != null
                              ? Colors.black87
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Publier le TP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}