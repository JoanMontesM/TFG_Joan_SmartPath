import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class AddContent extends StatefulWidget {
  const AddContent({super.key});

  @override
  State<AddContent> createState() => _AddContentState();
}

class _AddContentState extends State<AddContent> {
  final TextEditingController _contentController = TextEditingController();
  int _selectedIndex = 0;
  Color _selectedColor = primaryColor;
  String? _selectedFilePath;
  PlatformFile? _selectedFile;
  List<String> ambits = ["Àmbit lingüístic", "Àmbit cientifico-tecnològic"];
  String _selectedAmbit = "Àmbit lingüístic";
  bool isLoading = false;

  // Prompt creation
  String createSummaryPrompt(String text) {
    return """
    Basat en el següent text, crea tres resums destinats a estudiants de primer d'ESO per ajudar-los a estudiar i comprendre completament els temes corresponents.
    Tots els resums han d'estar escrits en català i han de ser breus, sense excedir les 150 paraules cadascun.
    A més, en cada resum, destaca en negreta les paraules clau que ajudin a identificar els conceptes més importants.

    Resum 1: Proporciona una explicació general i senzilla del concepte principal que els estudiants han de comprendre.
    Resum 2: Destaca altres temes rellevants presents en el text, complementant l'explicació del concepte principal.
    Resum 3: Recapitula altres temes rellevants del text, destacant aspectes clau que facilitin la comprensió del contingut.
    
    Text per resumir:
    $text

    Format requerit:
    [RESUM_1] Aquí el primer resum [/RESUM_1]
    [RESUM_2] Aquí el segon resum [/RESUM_2]
    [RESUM_3] Aquí el tercer resum [/RESUM_3]
    """;
  }

  // Function to obtain the correct answer format
  List<String> parseSummaries(String apiResponse) {
    try {
      final RegExp regex = RegExp(
        r'\[RESUM_1\](.*?)\[\/RESUM_1\].*?\[RESUM_2\](.*?)\[\/RESUM_2\].*?\[RESUM_3\](.*?)\[\/RESUM_3\]',
        dotAll: true,
      );

      final Match? match = regex.firstMatch(apiResponse);
      if (match == null || match.groupCount < 3) {
        throw Exception('Format de resposta de la API incorrecte');
      }

      return [
        match.group(1)!.trim(),
        match.group(2)!.trim(),
        match.group(3)!.trim(),
      ];
    } catch (e) {
      throw Exception('Error al analitzar els resums: $e');
    }
  }

  // Utility functions
  Future<String> extractTextFromPdf(String filePath) async{
    try{
      PDFDoc doc = await PDFDoc.fromPath(filePath);
      String text = await doc.text;
      return text;
    } catch (e){
      throw Exception('Error al extreure el text del PDF: $e');
    }
  }

  Future<String> makeDeepSeekApiRequest(String prompt) async{
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
      final response = await post(url, headers: headers, body: body);

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

  Future<List<String>> generateSummaries(String pdfText) async{
    try {
      final prompt = createSummaryPrompt(pdfText);
      final response = await makeDeepSeekApiRequest(prompt);
      final summaries = parseSummaries(response);

      return summaries;
    } catch (e){
      throw Exception('Error generant els resums: $e');
    }
  }

  Future<void> saveSummaries({required String name, required Color color, required String ambit, required String summary1, required String summary2, required String summary3}) async{
    setState(() => isLoading = true);
    
    try{
      await FirebaseFirestore.instance.collection('summaries').add({
        'name': name,
        'color': color.value,
        'ambit': ambit,
        'summary1': summary1,
        'summary2': summary2,
        'summary3': summary3,
        'isValidated': false,
        'createdAt': FieldValue.serverTimestamp(),
        'completedUsers': [],
      });
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de base de dades: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error inesperat: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _selectedFilePath = _selectedFile?.path;
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() => _selectedColor = color);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("D'acord"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          _buildFormContent(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'Informes',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.white,
          backgroundColor: const Color.fromARGB(125, 117, 0, 128),
          elevation: 0,
          onTap: (index) {
            if (index == 0) {
              exitConfirmationAlert();
            } else {
              setState(() => _selectedIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            height: 1.2
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            height: 1.2
          ),
          iconSize: 28,
        ),
    );
  }


  Widget _buildFormContent() {
  return Padding(
    padding: const EdgeInsets.only(top: 250.0, left: 20, right: 20, bottom: 80),
    child: ListView(
      children: [
        // Title Input
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Títol del contingut',
            border: OutlineInputBorder(),
            hintText: 'Introdueix el títol del contingut...',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),

        // Ambit Selection
        DropdownButtonFormField<String>(
          value: _selectedAmbit,
          items: ambits.map((String ambit) {
            return DropdownMenuItem(
              value: ambit,
              child: Text(ambit),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAmbit = value!;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Selecciona una categoria',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),

        // Color Picker Button
        ElevatedButton.icon(
          onPressed: _showColorPicker,
          label: const Text('Canviar color'),
          icon: const Icon(Icons.color_lens, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),

        // File Picker Button
        ElevatedButton.icon(
          icon: const Icon(Icons.attach_file, color: primaryColor),
          label: Text(_selectedFile?.name ?? 'Adjuntar arxiu en format PDF'),
          onPressed: _pickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 150),

        // Submit Button
        ElevatedButton(
          onPressed: () async{
            if (_contentController.text.isEmpty){
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Si us plau, introdueix un títol')),
              );
              return;
            }
            if (_selectedFilePath == null){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Si us plau, selecciona un arxiu PDF')),
              );
              return; 
            }

            setState(() => isLoading = true);

            try{
              // Extract PDF text
              final pdfText = await extractTextFromPdf(_selectedFilePath!);

               // Generate summaries
              final summaries = await generateSummaries(pdfText);
              // Store in database
              await saveSummaries(
                name: _contentController.text, 
                color: _selectedColor, 
                ambit: _selectedAmbit, 
                summary1: summaries[0], 
                summary2: summaries[1], 
                summary3: summaries[2],
              );

              // Navigate to the home teacher screen
              if(_contentController.text.isNotEmpty){
                Navigator.pop(context, {
                'name': _contentController.text,
                'color': _selectedColor,
                'ambit': _selectedAmbit,
              });
              }

            } catch(e){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')),
              );
            } finally {
              if (mounted) setState(() => isLoading = false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                'Generar contingut',
                style: TextStyle(fontSize: 18),
              ),
        ),
      ],
    ),
  );
}

Future<void> exitConfirmationAlert() async {
  final bool? exit = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 300,
          height: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Segur que vols sortir?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'images/Avorrit.png',
                height: 270,
                width: 270,
              ),
              const SizedBox(height: 10),
              const Text(
                "Si surts de la pantalla de creació de contingut hauràs de tornar a començar",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
              minimumSize: const Size(100, 50)
            ),
            child: const Text("Torna"),
            onPressed: () => Navigator.of(context).pop(false),
          ),const SizedBox(width: 10),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
              minimumSize: const Size(100, 50)
            ),
            child: const Text("Sortir"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
    if (exit == true) {
      Navigator.pop(context);
    }
  }

  // Add the same background methods from TeacherHomeScreen
  Widget buildBackground() {
    return Stack(
      children: [
        Container(
          height: 185,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        const Align(
          alignment: Alignment(-0.5, -0.80),
          child: Text(
            "Afegir contingut",
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBackground2() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 650,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/smartpath_logo_inverse.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget buildBackground3() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        alignment: Alignment.bottomCenter,
        height: 650,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
      ),
    );
  }
}