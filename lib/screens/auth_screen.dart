import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  final bool isLoginMode;

  const AuthScreen({super.key, required this.role, this.isLoginMode = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color primaryColor = Color(0xFF4A43EC);
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _classeCtrl = TextEditingController();  // ← nouveau
  final _groupeCtrl = TextEditingController();  // ← nouveau

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late bool _isLogin;
  bool _loading = false;
  late String _role;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLoginMode;
    _role = widget.role;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _classeCtrl.dispose();
    _groupeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        if (_passCtrl.text != _confirmCtrl.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Les mots de passe ne correspondent pas')),
          );
          setState(() => _loading = false);
          return;
        }

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

        // ── Données utilisateur avec classe et groupe ──────────
        Map<String, dynamic> userData = {
          'email': _emailCtrl.text.trim(),
          'role': _role,
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Ajouter classe et groupe seulement pour les étudiants
        if (_role == 'etudiant') {
          userData['classe'] = _classeCtrl.text.trim().toUpperCase();
          userData['groupe'] = _groupeCtrl.text.trim().toUpperCase();
        }

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);
      }

      if (!mounted) return;

      final targetRoute =
          _role == 'professeur' ? '/teacher-dashboard' : '/student-dashboard';
      Navigator.of(context)
          .pushNamedAndRemoveUntil(targetRoute, (route) => false);
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().contains('firebase_auth')
          ? e.toString().split('] ').length > 1
              ? e.toString().split('] ')[1]
              : e.toString()
          : 'Une erreur est survenue';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfesseur = _role == 'professeur';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          isProfesseur ? 'Professeur' : 'Étudiant',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              Icon(isProfesseur ? Icons.school : Icons.person,
                  size: 70, color: primaryColor),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Connexion' : 'Inscription',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              const SizedBox(height: 40),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: _inputDecor('Email', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Email requis' : null,
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passCtrl,
                decoration: _inputDecor('Mot de passe', Icons.lock),
                obscureText: true,
                validator: (v) =>
                    v!.length < 6 ? '6 caractères min' : null,
              ),

              // Champs inscription
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration:
                      _inputDecor('Prénom', Icons.person_outline),
                  validator: (v) =>
                      v!.isEmpty ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: _inputDecor('Nom', Icons.person),
                  validator: (v) => v!.isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),

                // ── CLASSE ET GROUPE (étudiant seulement) ──────
                if (_role == 'etudiant') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _classeCtrl,
                          textCapitalization:
                              TextCapitalization.characters,
                          decoration: _inputDecor(
                              'Classe', Icons.class_outlined),
                          validator: (v) =>
                              v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _groupeCtrl,
                          textCapitalization:
                              TextCapitalization.characters,
                          decoration:
                              _inputDecor('Groupe', Icons.group),
                          validator: (v) =>
                              v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ex: Classe = "INFO3"  Groupe = "G2"',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12),
                  ),
                ],
                // ───────────────────────────────────────────────

                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  decoration: _inputDecor(
                      'Confirmer mot de passe', Icons.lock_outline),
                  obscureText: true,
                  validator: (v) =>
                      v != _passCtrl.text ? 'Différent' : null,
                ),
                const SizedBox(height: 16),

                // Rôle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _role,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'etudiant',
                            child: Text('Étudiant')),
                        DropdownMenuItem(
                            value: 'professeur',
                            child: Text('Professeur')),
                      ],
                      onChanged: (value) =>
                          setState(() => _role = value!),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator(
                      color: primaryColor)
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isLogin ? 'Se connecter' : "S'inscrire",
                        style: const TextStyle(
                            fontSize: 17, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () =>
                    setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? "Pas de compte ? S'inscrire"
                      : 'Déjà un compte ? Se connecter',
                  style: TextStyle(
                      color: primaryColor, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}