import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ComplexityModifier {
  final String docId;
  final String summary1;
  final String summary2;
  final String summary3;

  ComplexityModifier({
    required this.docId,
    required this.summary1,
    required this.summary2,
    required this.summary3,

  });

  Future<void> saveSummary() async {
    try{
      final List<String> summaries = await Future.wait([
        generateLowCmplexSummary(summary1),
        generateLowCmplexSummary(summary2),
        generateLowCmplexSummary(summary3),
    ]);

    await FirebaseFirestore.instance.collection('lowComplexitySummaries').doc(docId).set({
      'summary1': summaries[0],
      'summary2': summaries[1],
      'summary3': summaries[2],
      'context': 'Resums generats des del document: $docId'
    });

    } catch (e){
      print('Error guardant resums: $e');
      rethrow;
    }
  }

  Future<String> generateLowCmplexSummary(String summary) async {
    String prompt = """
       Si us plau, simplifica la complexitat del següent resum perquè els 
       estudiants el puguin entendre fàcilment. Mantingues les idees clau, 
       però utilitza un llenguatge clar i senzill sense allargar gaire el text.
       Escriu el nou resum en català i no afegeixis cap altre text addicional.

      Resum original:
      $summary
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

  Future<List<String>> loadSummaries() async {
    final doc = await FirebaseFirestore.instance.collection('lowComplexitySummaries').doc(docId).get();
    if (doc.exists) {
      return [
        doc['summary1'],
        doc['summary2'],
        doc['summary3'],
      ];
    } else{
      return [];
    }
  }

}