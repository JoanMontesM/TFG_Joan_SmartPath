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

      await FirebaseFirestore.instance.collection('images').doc(docId).set({
        'image1_summary1': images[0],
        'image1_summary2': images[1],
        'image1_summary3': images[2],
        'context': 'Imatge generada des del resum: $docId',
      });
      
    } catch (e) {
      print('Error guardando imagen: $e');
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
    String prompt = /*"""
      Necesito que analizes el siguiente resumen y generes un prompt en inglés breve pero conciso (No mas de 5 lineas, por tanto evita contenido innecesario),
      para generar imagenes sobre el resumen y así poder ayudar a estudiantes de primero de la ESO a
      estudiar y asimilar los conceptos que se explican en el resumen.

      Evita añadir palabras para identificar que lo que estas escribiendo es un prompt,
      simplemente muestra el texto como se lo pasarias tal cual a una IA de generacion de imagenes.
      
      Además en el prompt asegura que la imagen que se vaya a crear sean sin texto, es decir, que no hayan labels en la imagen.

      Finalmente, como las imágenes se tienen que mostrar en un movil me gustaria que fuesen en formato vertical, con fondo blanco y sin texto!
      $summary
    """*/
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