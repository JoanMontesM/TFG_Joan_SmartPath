import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class TestGenerator {
  final String docId;
  final String summary1;
  final String summary2;
  final String summary3;

  TestGenerator({
    required this.docId,
    required this.summary1,
    required this.summary2,
    required this.summary3,

  });

  Future<void> saveMultipleChoice() async {
    try{
      final String response = await generateMultipleChoiceQuestions(summary1, summary2, summary3);

    final List<Map<String, dynamic>> questions = parseQuestions(response);

    Map<String, dynamic> firestoreData = {'docId': docId};
    for (int i = 0; i < questions.length; i++) {
      firestoreData['question${i+1}'] = {
        'question': questions[i]['question'],
        'correctAnswer': questions[i]['correctAnswer'],
        'options': questions[i]['options'],
      };
    }

    await FirebaseFirestore.instance.collection('multipleChoice').doc(docId).set(firestoreData);

    } catch (e){
      print('Error guardant resums: $e');
      rethrow;
    }
  }

  Future<String> generateMultipleChoiceQuestions(String summary1, String summary2, String summary3) async {
    String prompt = """
      Genera 5 preguntes tipus test en català basades en els següents tres resums. Cada pregunta ha de tenir 4 opcions, amb només una resposta correcta.
      Assegura't que les preguntes cobreixin conceptes clau dels resums i evita detalls trivials.
      El format de cada pregunta ha de ser el següent:

      Pregunta: [Text de la pregunta]
      Opcions:
      A) [Opció 1]
      B) [Opció 2]
      C) [Opció 3]
      D) [Opció 4]
      Resposta correcta: [Lletra]

      Resums:
      1. $summary1
      2. $summary2
      3. $summary3
    """;

    final apiKey = dotenv.env['DEEPSEEK_KEY']!;
    final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey'
    };
    final body = jsonEncode({
      'model': 'deepseek-reasoner',
      'messages': [{'role': 'user', 'content': prompt}],
      'max_tokens': 1200,
      'encoding': 'utf-8',
    });
    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        }
        throw Exception('No response content available');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('API request failed: $e');
    }
  }

  List<Map<String, dynamic>> parseQuestions(String apiResponse){
    List<Map<String, dynamic>> questions = [];
    List<String> blocks = apiResponse.split('Pregunta: ').where((b) => b.trim().isNotEmpty).toList();

    for (String block in blocks) {
      List<String> lines = block
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty).toList();
      if(lines.isEmpty) continue;

      String questionText = lines[0];
      List<String> options = [];
      String correctAnswer = '';

      bool inOptions = false;
      for (String line in lines.skip(1)){
        if(line.startsWith('Opcions:')) {
          inOptions = true;
          continue;
        }
        if (line.startsWith('Resposta correcta:')) {
          correctAnswer = line.split(': ')[1].trim();
          break;
        }
        if (inOptions && (line.startsWith('A') || line.startsWith('B') || line.startsWith('C') || line.startsWith('D'))) {
          options.add(line.substring(3).trim());
        }
      }
      if(questionText.isNotEmpty && options.length == 4 && correctAnswer.isNotEmpty){
        questions.add({
          'question': questionText,
          'options': options,
          'correctAnswer': correctAnswer,
        });
      }
    }
    return questions.toList();
  }
}