import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/screens/teacher_home_screen.dart';
import 'package:smartpath_app/screens/test_generator.dart';
import 'package:smartpath_app/screens/multiplechoice_validation_screen.dart';



class GapsValidationScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> summariesData;

  const GapsValidationScreen({
    super.key,
    required this.docId,
    required this.summariesData,
  });

  @override
  State<GapsValidationScreen> createState() => _GapsValidationScreenState();
}

class _GapsValidationScreenState extends State<GapsValidationScreen> {
  int _currentSummaryIndex = 0;
  late Map<String, dynamic> summariesWithGapsData;

  @override
  void initState() {
    super.initState();
    summariesWithGapsData = Map.from(widget.summariesData);
  }

  void navigateSummary(int direction) {
    if (_currentSummaryIndex + direction >= 0 && _currentSummaryIndex + direction < 3){
      setState(() => _currentSummaryIndex += direction);
      updateFirestore();
    }
  }

  Future<void> updateFirestore() async {
    final doc = FirebaseFirestore.instance.collection('summariesWithGaps').doc(widget.docId);
    await doc.update({'gappedSummaries': summariesWithGapsData});
  }

  void updateOption(String summaryKey,int gapIndex,int optionIndex,String newValue){
    setState(() {
      final gap = summariesWithGapsData[summaryKey]['gaps'][gapIndex];
      final options = List<String>.from(gap['options']);
      final oldValue = options[optionIndex];

      options[optionIndex] = newValue;
      gap['options'] = options;

      if (gap['correctAnswer'] == oldValue){
        gap['correctAnswer'] = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          Positioned(
            top: 200,
            left: 15,
            right: 15,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: buildSummaryPage(_currentSummaryIndex),
            ),
          ),
          buildNavigationButtons(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget buildSummaryPage(int index){
  final currentSummaryKey = 'summary${index + 1}';
  final currentSummary = summariesWithGapsData[currentSummaryKey];
  final text = currentSummary['text'] as String;
  final gaps = currentSummary['gaps'] as List<dynamic>;

  return Column(
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          height: 1.7,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 30),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: gaps.asMap().entries.map<Widget>((gapEntry) {
            final gapIndex = gapEntry.key;
            final gapData = gapEntry.value as Map<String, dynamic>;
            final gapId = gapData['gapId'];
            final options = (gapData['options'] as List<dynamic>).cast<String>();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[$gapId]:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: options.asMap().entries.map<Widget>((optionEntry) {
                      final optionIndex = optionEntry.key;
                      final option = optionEntry.value;
                      final isCorrect = option == gapData['correctAnswer'];

                      return SizedBox(
                        width: 150,
                        child: TextFormField(
                          key: Key('${currentSummaryKey}_${gapIndex}_$optionIndex'),
                          initialValue: option,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: isCorrect 
                                ? const Color.fromARGB(81, 76, 175, 79)
                                : Colors.grey[200],
                          ),
                          onChanged: (newValue) => updateOption(
                            currentSummaryKey,
                            gapIndex,
                            optionIndex,
                            newValue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
  }
  
  Widget buildNavigationButtons() {
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Anterior', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (_currentSummaryIndex < 2){
                  navigateSummary(1);
                } else{
                  final continuar = await completedValidationGapsAlert();
                  if(continuar == true){
                    final testGenerator = TestGenerator(docId: widget.docId, summary1: widget.summariesData['summary1']['text'], summary2: widget.summariesData['summary2']['text'], summary3: widget.summariesData['summary3']['text']);
                    showDialog(
                      context: context,
                      barrierDismissible: false, 
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      )
                    );

                    try {
                      await testGenerator.saveMultipleChoice();
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => MultiplechoiceValidationScreen(
                            docId: widget.docId,
                          ),
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: primaryColor,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text('Següent', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> completedValidationGapsAlert() async {
    return showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                "Validació dels exercicis amb buits completada!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'images/smartpath_brand.png',
                  height: 270,
                  width: 270,
                ),
                const Text(
                  "Tots els exercicis amb buits han sigut validats correctament! Vols continuar amb la validació dels exercicis tipus test?",
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
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
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
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            ),
          ],
        );      
      }
    ); 
  }

  Widget _buildCustomBottomBar() {
  return Container(
    height: 80,
    color: const Color.fromARGB(125, 117, 0, 128),
    child: Center(
      child: InkWell(
        onTap: exitConfirmationAlert,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_rounded,
              color: primaryColor,
              size: 30,
            ),
            const SizedBox(height: 1),
            Text(
              'Inici',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 17),
          ],
        ),
      ),
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
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => TeacherHomeScreen())),
          ),
        ],
      );
    },
  );
    if (exit == true) {
      Navigator.pop(context);
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