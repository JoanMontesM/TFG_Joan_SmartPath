import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;


class TTSGenerator {
  final String docId;
  final String summary1;
  final String summary2;
  final String summary3;
  bool isLoading = false;

  TTSGenerator({
    required this.docId,
    required this.summary1,
    required this.summary2,
    required this.summary3,

  });

  Future<void> saveTTS(int summaryIndex) async {
    
    String summary = '';

    if (summaryIndex == 1){
      summary = summary1;
    } else if (summaryIndex == 2) {
      summary = summary2;
    } else if (summaryIndex == 3) {
      summary = summary3;
    }

    try {
      final audioBytes = await generateTTS(summary);
      final ref = firebase_storage.FirebaseStorage.instance.ref('generated_TTS/$docId/tts_summary$summaryIndex.mp3');
      await ref.putData(audioBytes, firebase_storage.SettableMetadata(contentType: 'audio/mpeg'));
      
    } catch (e) {
      print('Error guardant els TTS: $e');
      rethrow;
    }
  }
  
Future<Uint8List> generateTTS(String summary) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    const String ttsApiUrl = 'http://10.0.2.2:8000/api/tts'; // Android emulator

    try {
      for (var attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final response = await http.post(
            Uri.parse(ttsApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "voice": "elia",
              "type": "text",
              "text": summary.replaceAll('**','').replaceAll('(','' ).replaceAll(')','' ).replaceAll(':','' ).replaceAll(';','' ),
              "language": "ca-es"
            }),
          );
          
          switch (response.statusCode) {
            case 200:
              return response.bodyBytes;
            case 503:
              await Future.delayed(retryDelay);
              break;
            default:
              throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }
        } on SocketException {
          if (attempt == maxRetries - 1) {
            throw Exception('No s\'ha pogut connectar al servidor TTS');
          }
          await Future.delayed(retryDelay);
        }
      }
      throw Exception('Fallo després de $maxRetries intents');
    } catch (e) {
      throw Exception('Error TTS: ${e.toString()}');
    }
  }


  Future<Uint8List?> loadTTS(int summaryIndex) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('generated_TTS/$docId/tts_summary$summaryIndex.mp3');

      return await ref.getData();
    } catch (e) {
      print('Error cargando TTS $summaryIndex: $e');
      return null;
    }
  }

}