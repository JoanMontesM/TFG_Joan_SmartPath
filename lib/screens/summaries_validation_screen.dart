import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/gaps_validation_screen.dart';
import 'package:http/http.dart' as http;
import 'image_generation.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class SummariesValidationScreen extends StatefulWidget {
  final String docId;
  final String name;
  final String ambit;
  final String summary1;
  final String summary2;
  final String summary3;
  final bool isValidated;

  const SummariesValidationScreen({
    super.key, 
    required this.docId, 
    required this.name, 
    required this.ambit, 
    required this.summary1, 
    required this.summary2, 
    required this.summary3, 
    required this.isValidated,
    });

  @override
  State<SummariesValidationScreen> createState() => _SummariesValidationScreenState();
}

class _SummariesValidationScreenState extends State<SummariesValidationScreen> {
  int _selectedIndex = 1;
  int _currentSummaryIndex = 0;
  int _currentImageIndex = 0;
  final List<TextEditingController> summaries = [];
  late ImageGenerator imageGenerator;
  bool isGenerating = false;

  @override
  void initState(){
    super.initState();
    imageGenerator = ImageGenerator(
      docId: widget.docId,
      summary1: widget.summary1,
      summary2: widget.summary2,
      summary3: widget.summary3,
    );

    summaries.addAll([
      TextEditingController(text: widget.summary1),
      TextEditingController(text: widget.summary2),
      TextEditingController(text: widget.summary3)
    ]);
  }

  @override
  void dispose(){
    summaries.forEach((summary) => summary.dispose());
    super.dispose();
  }

  TextEditingController currentSummary(){
    switch(_currentSummaryIndex){
      case 0: return summaries[0];
      case 1: return summaries[1];
      case 2: return summaries[2];
      default: return summaries[0];
    }
  }

  String createPrompt(String text) {
    return """
    A partir del següent resum, genera un test amb buits per que estudiants de primer de la ESO puguin estudiar, seguint els següents passos:
    1. Selecciona entre 5 i 7 conceptes clau.
    2. Canvia cada un per [gap1], [gap2], [gap3], etc.
    3. Per cada gap genera:
        - 1 opció correcta
        - 3 opcions incorrectes relacionades amb el context del resum
    
    El resum que has de tenir en compte per generar el contingut requerit es el següent:
    $text

    L'exemple de format requerit de resposta és:
    "gappedText": (Text amb els gaps)
    "gaps": [
      {
        "gapId": "gap1",
        "correctAnswer": "resposta correcta",
        "options": ["resposta correcta", "incorrecta1", "incorrecta2", "incorrecta3"],
        "position": (index numèric (contant des de 0), que indica exactament on està la paraula ubicada abans de ser substituida pel gap)
      }
    ]
    """;
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

  Map<String,dynamic> divideResponse(String apiResponse){
    try{
        final cleanedResponse = apiResponse.replaceAll(RegExp(r'^```json|```$|\n'), '').trim();

        final parsed = jsonDecode(cleanedResponse) as Map<String, dynamic>;
        
        if (!parsed.containsKey('gappedText') || !parsed.containsKey('gaps') || parsed['gaps'] is! List) {
            throw Exception('Estructura de gaps inválida en la respuesta');
        }

        return {
          'gappedText': parsed['gappedText'] as String,
          'gaps': (parsed['gaps'] as List<dynamic>)
        };

    }catch (e){
      throw Exception('Error al dividir la resposta de la API: $e');
    }
  }

  Future<Map<String,dynamic>> generateSummariesWithGaps(String summary) async{
    try {
      final prompt = createPrompt(summary);
      final response = await makeDeepSeekApiRequest(prompt);
      final summaries = divideResponse(response);

      return summaries;
    } catch (e){
      throw Exception('Error generant els resums: $e');
    }
  }

  
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          if(_selectedIndex == 1) buildEditableContent(),
          if(_selectedIndex == 2) buildImages(),
          buildNavigationButtons()
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget buildEditableContent() {
  return Positioned(
    top: 200,
    left: 15,
    right: 15,
    bottom: 80,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: currentController,
        maxLines: null,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontSize: 20,
          height: 1.7,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );
  }

  Future<void> saveChanges() async {
    try{
      await FirebaseFirestore.instance.collection('summaries').doc(widget.docId).update({currentSummaryName: currentController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canvis al resum guardats correctament!'))
      );
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar els canvis'))
      );
    }
  }

  TextEditingController get currentController =>  summaries[_currentSummaryIndex];
  String get currentSummaryName => 'summary${_currentSummaryIndex + 1}';

  Future<void> navigateSummary(int direction) async {
    await saveChanges();
    setState(() => _currentSummaryIndex += direction);
  }

  Widget buildNavigationButtons(){
    if (_selectedIndex == 2) return const SizedBox.shrink();
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _currentSummaryIndex > 0 ? () => navigateSummary(-1):null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white,),
              label: const Text('Anterior', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (_currentSummaryIndex < 2){
                  await navigateSummary(1);
                } else{
                  await saveChanges();
                  completedValidationAlert();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text('Següent', style: TextStyle(color: Colors.white),))
          ],
        ),
      ),
    );
  }


  Widget _buildCustomBottomBar() {
    return Container(
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inici',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'Original',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Imatges',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.keyboard_double_arrow_down_rounded),
              label: 'Complexitat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones),
              label: 'Escoltar',
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
            }
            if (index == 1){
              setState(() => _selectedIndex = index);
            }
            if (index == 2){
              if (_selectedIndex == 2){
                imageGenerator.loadImage().then((images) {
                  if (images.isNotEmpty && mounted) {
                    showRegenerateAlert();
                  }
                });
              } else {
                setState(() => _selectedIndex = index);
              }
            }
            if (index == 3){
              setState(() => _selectedIndex = index);
            }
            if (index == 4){
              setState(() => _selectedIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            height: 1.2,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            height: 1.2,
          ),
          iconSize: 28,
        ),
    );
  }

  Future<void> completedValidationAlert() async {
  final bool? proceed = await showDialog<bool>(
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
                "Validació dels resums completada!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'images/smartpath_brand.png',
                height: 270,
                width: 270,
              ),
              const SizedBox(height: 10),
              const Text(
                "Tots els resums han sigut validats correctament! Vols continuar amb la validació dels exercicis?",
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
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
              minimumSize: const Size(100, 50)
            ),
            child: const Text("Torna"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 10),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
              minimumSize: const Size(100, 50)
            ),
            child: const Text("Continua"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  if (proceed == true) {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('summariesWithGaps')
          .doc(widget.docId)
          .get();

      bool generateNew = true;

      if (docSnapshot.exists) {
        final choice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(20),
            content: SizedBox(
              width: 300,
              height: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ja existeixen resums amb buits per aquest document. Vols regenerar-los o utilitzar els existents?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Image.asset('images/Confus.png',height: 270,width: 270),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(100, 50),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Regenerar"),
              ),
              const SizedBox(width: 10),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(100, 50),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text(" Utilitzar\nexistents"),
              ),
            ],
          ),
        );
        generateNew = choice ?? true;
      }

      if (generateNew) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final List<Future<Map<String, dynamic>>> gapSummaries = [
          generateSummariesWithGaps(widget.summary1),
          generateSummariesWithGaps(widget.summary2),
          generateSummariesWithGaps(widget.summary3),
        ];

        final results = await Future.wait(gapSummaries);
        final summaryWithGaps1 = results[0];
        final summaryWithGaps2 = results[1];
        final summaryWithGaps3 = results[2];

        await saveSummariesWithGaps(
          docId: widget.docId,
          name: widget.name,
          summary1: summaryWithGaps1,
          summary2: summaryWithGaps2,
          summary3: summaryWithGaps3,
        );

        if (context.mounted) Navigator.of(context).pop();

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GapsValidationScreen(
                docId: widget.docId,
                gappedSummaries: {
                  'summary1': summaryWithGaps1['gappedText'],
                  'summary2': summaryWithGaps2['gappedText'],
                  'summary3': summaryWithGaps3['gappedText'],
                },
                gapsData: {
                  'summary1': summaryWithGaps1['gaps'],
                  'summary2': summaryWithGaps2['gaps'],
                  'summary3': summaryWithGaps3['gaps'],
                },
              ),
            ),
          );
        }
      } else {
        final existingData = docSnapshot.data()!;
        final gappedSummaries = existingData['gappedSummaries'];

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GapsValidationScreen(
                docId: widget.docId,
                gappedSummaries: {
                  'summary1': gappedSummaries['summary1']['text'],
                  'summary2': gappedSummaries['summary2']['text'],
                  'summary3': gappedSummaries['summary3']['text'],
                },
                gapsData: {
                  'summary1': gappedSummaries['summary1']['gaps'],
                  'summary2': gappedSummaries['summary2']['gaps'],
                  'summary3': gappedSummaries['summary3']['gaps'],
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }
}

  Future<void> saveImage() async {
    try {
      await imageGenerator.saveImage();
      setState(() => _currentImageIndex = 0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generando imágenes: $e")),
      );
    } finally {
      setState(() => imageGenerator.isLoading = false);
    }
  }
  
  Widget buildImages() {
    return FutureBuilder<List<String>>(
      future: imageGenerator.loadImage(),
      builder: (context, snapshot) {
        if (isGenerating || snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(isGenerating ? 'Generant imatges...' : 'Carregant imatges...',
                style: const TextStyle(fontSize: 18, color: Colors.black87)),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No hi ha imatges generades', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isGenerating ? null : () async {
                    setState(() => isGenerating = true);
                    await saveImage();
                    setState(() => isGenerating = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  ),
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                  label: const Text('Generar Imatges', style: TextStyle(color: Colors.white))
                ),
              ],
            ),
          );
        }
        final images = snapshot.data!;
  return Stack(
        children: [
          Container(
            height: 835,
            width: 450,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                alignment: const Alignment(0, 0.3),
                image: NetworkImage(images[_currentImageIndex]),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentImageIndex = 
                          (_currentImageIndex - 1 + images.length) % images.length;
                      });
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text('Anterior'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {_currentImageIndex = (_currentImageIndex + 1) % images.length;});
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text('Següent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
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
                "Si surts de la pantalla de validació hauràs de tornar a començar",
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

  Future<void> showRegenerateAlert() async {
    final bool? regenerate = await showDialog<bool>(
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
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Vols regenerar les imatges?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'images/Confus.png',
                height: 270,
                width: 270,
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
            child: const Text("Cancel·lar"),
            onPressed: () => Navigator.pop(context, false),
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
            child: const Text("Regenerar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    },
  );
    if (regenerate == true && mounted) {
      setState(() => isGenerating = true);
      try {
        await saveImage();
        setState(() {
          _currentImageIndex = 0;
          isGenerating = false;
        });
      }catch (e){
        if (mounted){
          setState(() => isGenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  Future<void> saveSummariesWithGaps({required String docId,required String name,required Map<String, dynamic> summary1,required Map<String, dynamic> summary2,required Map<String, dynamic> summary3,}) async{
    try{
      final summariesWithGapsData = {
        'name': name,
        'docId': docId,
        'isValidated': false,
        'gappedSummaries':{
          'summary1': {
            'text': summary1['gappedText'],
            'gaps': summary1['gaps'],
          },
          'summary2': {
            'text': summary2['gappedText'],
            'gaps': summary2['gaps'],
          },
          'summary3': {
            'text': summary3['gappedText'],
            'gaps': summary3['gaps'],
          }
        },
      };
      await FirebaseFirestore.instance.collection('summariesWithGaps').doc(docId).set(summariesWithGapsData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contingut guardat correctament!')));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error en guardant els resums amb buits')));
    }
  }

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
          alignment: Alignment(0, -0.80),
          child: Text(
            "Validar contingut",
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


////VISUALITZACIÓ RESUMS AMB FORMAT NEGRETA (UTILITZAR EN LA PANTALLA DELS ESTUDAINTS)
/*
  List<TextSpan> boldText(String text){
    final List<TextSpan> spans = [];
  final parts = text.split('**');
  bool isBold = false;

  for (final part in parts) {
    if (part.isEmpty) continue;
    
    spans.add(TextSpan(
      text: part,
      style: isBold 
          ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
          : const TextStyle(color: Colors.black87),
    ));

    isBold = !isBold;
  }

  return spans;
  }

  Widget buildBoldSummary(String text){
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 20, height: 1.7, color: Colors.black87),
        children: boldText(text),
      ),
    ),
  );
  }
  */