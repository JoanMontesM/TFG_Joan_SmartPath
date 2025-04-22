import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/screens/gapped_summaries_exercise.dart';
import 'package:smartpath_app/screens/student_home_screen.dart';
import 'package:smartpath_app/screens/TTS_generator.dart';
import 'package:smartpath_app/screens/image_generation.dart';



class SummariesContentScreen extends StatefulWidget {
  final String docId;
  final String name;
  final Color color;
  final List<String> summaries;
  final int startIndex;
  final String userUid;
  final String userName;

  const SummariesContentScreen({
    super.key, 
    required this.docId, 
    required this.name, 
    required this.color,
    required this.summaries,
    required this.startIndex,
    required this.userName,
    required this.userUid,
  });

  @override
  State<SummariesContentScreen> createState() => _SummariesContentScreenState();
}

class _SummariesContentScreenState extends State<SummariesContentScreen> {
  int _selectedIndex = 1;
  int _currentSummaryIndex = 0;
  int _currentLowSummaryIndex = 0;
  
  List<String> images = [];
  bool isLoadingImages = false; 

  List<Map<String, dynamic>> contentItems = [];

  List<List<Map<String, dynamic>>> gapsInfo = [];
  List<String> gappedTexts = [];

  late TTSGenerator ttsGenerator;
  bool ttsIsGenerating = false;
  final AudioPlayer audioPlayer = AudioPlayer();

  late ImageGenerator imageGenerator;


  @override
  void initState() {
    super.initState();
    _currentSummaryIndex = widget.startIndex;
    _currentLowSummaryIndex = widget.startIndex;
    loadLowComplexitySummaries();
    loadGappedSummaries();

    ttsGenerator = TTSGenerator(
      docId: widget.docId, 
      summary1: widget.summaries[0], 
      summary2: widget.summaries[1], 
      summary3: widget.summaries[2],
    );
    imageGenerator = ImageGenerator(
      docId: widget.docId,
      summary1: widget.summaries[0],
      summary2: widget.summaries[1],
      summary3: widget.summaries[2],
    );
  }

  Future<void> loadLowComplexitySummaries() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('lowComplexitySummaries').doc(widget.docId).get();

      if (docSnapshot.exists){
        setState((){
          contentItems = [{
            'summary1': docSnapshot['summary1'],
            'summary2': docSnapshot['summary2'],
            'summary3': docSnapshot['summary3'],
          }];
        });
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el contenido')),
      );
    }
  }

  Future<void> loadGappedSummaries() async {
  try {    
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('summariesWithGaps').doc(widget.docId).get();
  
    final gappedSummaries = docSnapshot.get('gappedSummaries');

    for (int i = 1; i <= 3; i++) {
      final summaryKey = 'summary$i';
      final summary = gappedSummaries[summaryKey];

      if (summary == null) {
        throw Exception('$summaryKey no trobat');
      }
      
      if (summary is! Map<String, dynamic>) {
        throw Exception('Format incorrecte per $summaryKey');
      }

      final text = summary['text'];
      
      if (text is! String || text.isEmpty) {
        throw Exception('Text invàlid a $summaryKey');
      }
      gappedTexts.add(text);

      final gaps = summary['gaps'];
      
      if (gaps is! List<dynamic>) {
        throw Exception('Format de gaps invàlid a $summaryKey');
      }

      List<Map<String, dynamic>> processedGaps = [];
      for (var gap in gaps) {
        processedGaps.add({
          'correctAnswer': gap['correctAnswer']?.toString() ?? 'DESCONOCIDO',
          'gapId': gap['gapId']?.toString() ?? 'gap-${DateTime.now().millisecondsSinceEpoch}',
          'options': List<String>.from(gap['options']?.map((e) => e.toString()) ?? []),
          'position': (gap['position'] is num) ? (gap['position'] as num).toInt() : 0,
        });
      }
      gapsInfo.add(processedGaps);
    }

  } catch (e) {    
    gappedTexts.clear();
    gapsInfo.clear();
    throw Exception('Error al carregar les dades: ${e.toString()}');
  }
}

  Future<void> navigateSummary(int direction) async {
    setState(() {
      _currentSummaryIndex += direction;
      _currentLowSummaryIndex += direction;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          if(_selectedIndex == 1) buildSummaries(),
          if(_selectedIndex == 2) buildImages(),
          if(_selectedIndex == 3) buildLowComplexity(),
          buildNavigationButtons()
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget buildLowComplexity(){
    String summaryKey = 'summary${_currentLowSummaryIndex + 1}';
    String summaryText = contentItems[0][summaryKey];
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: buildBoldSummary(summaryText),
      ),
    ),
  );
  }

  Widget buildNavigationButtons() {
    if (_selectedIndex == 2) return const SizedBox.shrink();

    if (_selectedIndex == 1){
      return Positioned(
        bottom: 10,
        left: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (gappedTexts.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GappedSummariesExercise(
                        gappedTexts: gappedTexts,
                        gapsInfo: gapsInfo,
                        color: widget.color,
                        name: widget.name,
                        currentIndex: widget.startIndex,
                        summaries: widget.summaries,
                        docId: widget.docId,
                        userUid: widget.userUid,
                        userName: widget.userName,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                label: const Text('Continua', style: TextStyle(color: Colors.white, fontSize: 16)),
              )
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> TTSPlayback() async {
    if (ttsIsGenerating) return;
    try {
      setState(() => ttsIsGenerating = true);
    
      await audioPlayer.stop(); 

      final currentIndex = _currentSummaryIndex + 1;

      final storedAudio = await ttsGenerator.loadTTS(currentIndex);

      audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.assistant,
          )
        )
      );

      if (storedAudio != null) {
        await audioPlayer.setVolume(0.7);
        await audioPlayer.play(BytesSource(storedAudio));
      } 
    } catch (e){
      print(e);
    }
    finally {
      setState(() => ttsIsGenerating = false);
    }
  }

  void usageCounter(String feature) async {
    try{
      await FirebaseFirestore.instance.collection('studentsInteractionGapsExercise').doc(widget.userUid).update({
        feature: FieldValue.increment(1)
      });
    }catch (e){
      print("Error actualitzant el comptador d'ús: $e");
    }
  }

  Widget buildImages() {
    return FutureBuilder<List<String>>(
      future: imageGenerator.loadImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Carregant imatges...',
                  style: TextStyle(fontSize: 18, color: Colors.black87)),
            ],
          ),
        );
      }

      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text('No hi ha imatges generades',
              style: TextStyle(fontSize: 20, color: Colors.black87)),
        );
      }
        final images = snapshot.data!;
        return Container(
          height: 835,
          width: 450,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              alignment: const Alignment(0, 0.3),
              image: NetworkImage(images[_currentSummaryIndex]),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
        child: BottomNavigationBar(
          items: [
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
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.headphones),
                  if(ttsIsGenerating)
                    Positioned(
                      top:0,
                      right:0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ),
                    )
                ],
              ),
              label: ttsIsGenerating ? 'Generant...' : 'Escoltar',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.white,
          backgroundColor: const Color.fromARGB(125, 117, 0, 128),
          elevation: 0,
          onTap: (index) async {
            if (index == 0) {
              exitConfirmationAlert();
              _currentSummaryIndex = 0;
              _currentLowSummaryIndex = 0;
            }
            if (index == 1){
              setState(() => _selectedIndex = index);
            }
            if (index == 2){
              setState(() => _selectedIndex = index);
              usageCounter('usageImages');
            }
            if (index == 3){
              await loadLowComplexitySummaries();
              _selectedIndex = index;
              usageCounter('usageLowComplexity');
            }
            if (index == 4){
              usageCounter('usageTTS');
              await TTSPlayback();
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
                "Si surts del exercici hauràs de tornar a començar",
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => StudentHomeScreen()),
      (Route<dynamic> route) => false,
    );
  }
}

  Widget buildSummaries() {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: buildBoldSummary(widget.summaries[_currentSummaryIndex]),
        ),
      ),
    );
  }

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
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: const TextStyle(fontSize: 22, height: 2, color: Colors.black87),
          children: boldText(text),
        ),
      ),
    );
  }

    Widget buildBackground() {
    return Stack(
      children: [
        Container(
          height: 175,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        Align(
          alignment: Alignment(0, -0.80),
          child: Text(
            widget.name,
            style: TextStyle(
              fontSize: 40,
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
        height: 660,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.color,
        ),
      ),
    );
  }

  Widget buildBackground3() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        alignment: Alignment.bottomCenter,
        height: 660,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
      ),
    );
  }
}