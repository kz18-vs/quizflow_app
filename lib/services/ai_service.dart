import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

class AIService {
  static const String _apiKey = 'AIzaSyBloRWk-w3P3pH0tfy14reHCtt_dtyUTGw';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // ─── EXTRAIRE LE TEXTE DU PDF ──────────────────────────────────
  static Future<String> extractTextFromPdfBytes(List<int> bytes) async {
  try {
    final document = PdfDocument(inputBytes: Uint8List.fromList(bytes));
    final extractor = PdfTextExtractor(document);
    String fullText = '';
    for (int i = 0; i < document.pages.count; i++) {
      fullText += extractor.extractText(startPageIndex: i, endPageIndex: i);
      fullText += '\n';
    }
    document.dispose();
    if (fullText.length > 3000) {
      fullText = fullText.substring(0, 3000) + '...';
    }
    return fullText.trim();
  } catch (e) {
    throw Exception('Impossible de lire le PDF : $e');
  }
}

  // ─── GÉNÉRER QCM DEPUIS LE COURS PDF ──────────────────────────
  static Future<List<Map<String, dynamic>>> generateFromCourse({
  required String courseText,
  int numberOfQuestions = 5,
  String difficulty = 'moyen',
}) async {
  final cleanText = courseText.length > 3000
      ? courseText.substring(0, 3000)
      : courseText;

  final prompt =
      'Tu es un professeur expert. Voici un extrait de cours : "$cleanText". '
      'Génère $numberOfQuestions questions QCM niveau $difficulty basées UNIQUEMENT sur ce cours. '
      'Réponds UNIQUEMENT en JSON sans texte avant ou après: '
      '{"questions":[{"text":"Question?","options":["A","B","C","D"],"correctIndex":0,"explanation":"Explication"}]}';

  return await _callGemini(prompt);
}

  // ─── GÉNÉRER QCM DEPUIS UN SUJET (prof) ───────────────────────
  static Future<List<Map<String, dynamic>>> generateQuestions({
  required String subject,
  required String topic,
  int numberOfQuestions = 5,
  String difficulty = 'moyen',
}) async {
  final prompt =
      'Tu es professeur de $subject. '
      'Génère $numberOfQuestions questions QCM niveau $difficulty sur: $topic. '
      'Réponds UNIQUEMENT en JSON sans texte avant ou après: '
      '{"questions":[{"text":"Question?","options":["A","B","C","D"],"correctIndex":0,"explanation":"Explication"}]}';

  return await _callGemini(prompt);
}

  // ─── APPEL API GEMINI (commun) ─────────────────────────────────
 static Future<List<Map<String, dynamic>>> _callGemini(String prompt) async {
  
  final models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    
  ];

  for (final model in models) {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2000,
          },
        }),
      );

      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['candidates'][0]['content']['parts'][0]['text'];

        if (content.contains('```json')) {
          content = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          content = content.split('```')[1].split('```')[0].trim();
        }

        final parsed = jsonDecode(content);
        final questions = parsed['questions'] as List<dynamic>;

        return questions.map((q) => {
          'text': q['text'] as String,
          'options': (q['options'] as List).map((o) => o.toString()).toList(),
          'correctIndex': q['correctIndex'] as int,
          'explanation': q['explanation'] ?? '',
        }).toList();

      } else if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 5));
        continue;
      } else {
        continue;
      }
    } catch (e) {
     
      continue;
    }
  }

  throw Exception('Aucun modèle Gemini disponible. Vérifiez votre clé API.');
}}