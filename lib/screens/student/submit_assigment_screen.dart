import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String assignmentId;
  final String module;
  const SubmitAssignmentScreen({super.key, required this.assignmentId, required this.module});
  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}
class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _linkCtrl = TextEditingController();
  bool _loading = false;
  final _auth = FirebaseAuth.instance;

  Future<void> _submit() async {
    if (_linkCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez le lien'))); return; }
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data()!;
      
      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': widget.assignmentId, 'studentId': user.uid,
        'firstName': userData['firstName'] ?? '', 'lastName': userData['lastName'] ?? '',
        'module': widget.module, 'fileLink': _linkCtrl.text.trim(), 'submittedAt': FieldValue.serverTimestamp(),
      });

      // Notification au prof
      final assignDoc = await FirebaseFirestore.instance.collection('assignments').doc(widget.assignmentId).get();
      final teacherId = assignDoc.data()?['teacherId'];
      if (teacherId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId, 'title': 'Nouveau Rendu', 'message': '${userData['firstName']} a rendu le devoir', 'type': 'submission', 'isRead': false, 'createdAt': FieldValue.serverTimestamp()
        });
      }

      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Envoyé !'), backgroundColor: Colors.green)); Navigator.pop(context); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'))); } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.grey[50], appBar: AppBar(backgroundColor: const Color(0xFF4A43EC), title: const Text('Rendre le TP', style: TextStyle(color: Colors.white)), elevation: 0),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 40), Icon(Icons.cloud_upload, size: 80, color: const Color(0xFF4A43EC).withOpacity(0.5)),
        const SizedBox(height: 20), const Text('Collez le lien de votre fichier', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10), Text('1. Uploadez sur Drive\n2. Copiez le lien\n3. Collez ici', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 30), TextFormField(controller: _linkCtrl, decoration: const InputDecoration(labelText: 'Lien', prefixIcon: Icon(Icons.link), border: OutlineInputBorder()), maxLines: 2),
        const Spacer(),
        _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC))) : ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A43EC), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontSize: 16))),
      ])));
  }
}