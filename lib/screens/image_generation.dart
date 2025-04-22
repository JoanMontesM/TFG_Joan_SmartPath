import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;



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

  Future<void> saveImage(int summaryIndex) async {
    summaryIndex = summaryIndex + 1;
    String summary = '';

    if (summaryIndex == 1){
      summary = summary1;
    } else if (summaryIndex == 2) {
      summary = summary2;
    } else if (summaryIndex == 3) {
        summary = summary3;
    }

    try {
      final image = await generateImage(summary);
      final response = await http.get(Uri.parse(image));
      
      if(response.statusCode == 200){
        Uint8List imageBytes = response.bodyBytes;
        final ref = firebase_storage.FirebaseStorage.instance.ref().child('generated_images').child(docId).child('image_summary$summaryIndex.png');

        await ref.putData(imageBytes, firebase_storage.SettableMetadata(contentType: 'image/png'));
        final downloadUrl = await ref.getDownloadURL();
        
        await FirebaseFirestore.instance.collection('images').doc(docId).set({'image1_summary$summaryIndex': downloadUrl, 'context': 'Imatges generades des del document: $docId'}, SetOptions(merge:true));
      }
      
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
        doc['image1_summary1'] as String,
        doc['image1_summary2'] as String,
        doc['image1_summary3'] as String,
      ];
    } else {
      return [];
    }
  }

  Future<String> makeDeepSeekApiRequest(String summary) async {
    String prompt = 
    """
      Analyze the provided text and generate an English image prompt for Imagen-3 (Replicate) that:  
      1. **Contains no text/labels** - Concepts must be visually self-explanatory.  
      2. **Targets high school students** - Use vibrant colors, simple shapes, and clear visuals.  
      3. **Suggested style** - Low levels high school book ilustration.  
      4. **Focus** - Visually represent the text's core concept in an intuitive way.   

      Text to analyze:  
      $summary 

      Respond ONLY with the Replicate-ready prompt.  
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
        print(data);
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