import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ImageGenerator {
  final String docId;
  final String summary1;
  final String summary2;
  final String summary3;
  bool isLoading = false;

  ImageGenerator({
    required this.docId,
    required this.summary1,
    required this.summary2,
    required this.summary3,

  });

  Future<void> saveImage() async {
    try {
      final List<String> images = await Future.wait([
        generateImage(summary1),
        generateImage(summary2),
        generateImage(summary3),
      ]);
      
      // Convertir URL en base64, emmagatzemar en base de dades
      // Per a la visualitzacio convertir base64 en URL i mostrar

      await FirebaseFirestore.instance.collection('images').doc(docId).set({
        'image1_summary1': images[0],
        'image1_summary2': images[1],
        'image1_summary3': images[2],
        'context': 'Imatges generades des del document: $docId',
      });
      
    } catch (e) {
      print('Error guardant imatges: $e');
      rethrow;
    }
  }


   Future<String> generateImage(String summary) async {
    final String _apiUrl = 'https://api.replicate.com/v1/models/google/imagen-3/predictions';
    final apiToken = dotenv.env['REPLICATE_KEY'];
    try {
      final String deepSeekPrompt = await makeDeepSeekApiRequest(summary);
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
          'Prefer': 'wait'
        },
        body: jsonEncode({
          'input': {
            'prompt': deepSeekPrompt,
            'negative_prompt': 'low quality, blurry',
            'width': 720,
            'height': 1280,
            'num_outputs': 1,
          }
        }),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result['output'] as String;
      }
      
      throw Exception('API Error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Image generation failed: ${e.toString()}');
    }
  }

  Future<List<String>> loadImage() async {
    final doc = await FirebaseFirestore.instance.collection('images').doc(docId).get();
    if (doc.exists) {
      return [
        doc['image1_summary1'],
        doc['image1_summary2'],
        doc['image1_summary3'],
      ];
    } else{
      return [];
    }
  }

  Future<String> makeDeepSeekApiRequest(String summary) async {
    String prompt = 
    """
      Analyze this summary and create an English image generation prompt that:
      - Is concise (max 5 lines)
      - Contains no meta-commentary or explanations
      - Specifies vertical composition
      - Uses white background
      - Excludes all text/labels
      - Focuses on key educational elements
  
      Summary: $summary
  
      Respond ONLY with the raw image prompt to use, nothing else.
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
}