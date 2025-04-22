import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/summaries_content_screen.dart';
import 'package:smartpath_app/screens/student_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/screens/test_summaries_exercise.dart';

class GappedSummariesExercise extends StatefulWidget {
  final List<String> gappedTexts;
  final List<List<Map<String, dynamic>>> gapsInfo;
  final String name;
  final Color color;
  final int currentIndex;
  final String docId;
  final List<String> summaries;
  final String userUid;
  final String userName;

  const GappedSummariesExercise({
    super.key,
    required this.gappedTexts,
    required this.gapsInfo,
    required this.name,
    required this.color,
    required this.currentIndex,
    required this.docId,
    required this.summaries,
    required this.userName,
    required this.userUid,
  });

  @override
  State<GappedSummariesExercise> createState() => _GappedSummariesExerciseState();
}

class _GappedSummariesExerciseState extends State<GappedSummariesExercise> {
  Map<String, String?> selectedAnswers = {};
  Map<String, bool?> answerValidity = {};
  late List<List<Map<String, dynamic>>> randomizedGapsInfo;
  bool hasCheckedAnswers = false;

  late DateTime startTime;
  Duration time = Duration.zero;
  int correctAnswers = 0;
  int incorrectAnswers = 0;

  List<String> questionStatements = [];
  List<Map<String, dynamic>> optionsList = [];

  @override
  void initState(){
    super.initState();
    startTime = DateTime.now();
    loadMultipleChoice();

    randomizedGapsInfo = widget.gapsInfo.map((gapList){
      return gapList.map((gap){
        final options = List<String>.from(gap['options']);
        options.shuffle();
        return {
          'gapId': gap['gapId'],
          'correctAnswer': gap['correctAnswer'],
          'options': options,
        };
      }).toList();
    }).toList();
  }

  void updateUserAnswers() async {
    final summaryKey = 'summary${widget.currentIndex+1}';
    final data = {
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'time': time.inSeconds,
    };
    try {
      await FirebaseFirestore.instance.collection('studentsInteractionGapsExercise').doc(widget.userUid).update({
        '${widget.name}.$summaryKey': FieldValue.arrayUnion([data])
      });
    } catch (e) {
      print("Error al actualitzar l'interacció: $e");
    }
  }

  void updateUserInteraction() async {  
    try {
      await FirebaseFirestore.instance.collection('studentsInteractionGapsExercise').doc(widget.userUid).update({
        'dropouts': FieldValue.increment(1)
      });
    } catch (e) {
      print("Error al actualitzar l'interacció: $e");
    }
  }

  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          buildFirstGappedSummary(),
          buildNavigationButtons(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
      
    );
  }

  Widget buildFirstGappedSummary(){
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
          child: buildPlainTextWithGaps(widget.gappedTexts[widget.currentIndex], randomizedGapsInfo[widget.currentIndex]),
        ),
      ),
    );
  }

  Widget buildPlainTextWithGaps(String text, List<Map<String, dynamic>> gaps) {
  final spans = <InlineSpan>[];
  final regex = RegExp(r'\[gap\d+\]');
  final matches = regex.allMatches(text);

  int lastIndex = 0;

  for (final match in matches) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
    }

    final gapId = match.group(0)!.replaceAll(RegExp(r'[\[\]]'), '');
    final gap = gaps.firstWhere((g) => g['gapId'] == gapId, orElse: () => {});

    if (gap.isNotEmpty) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: buildGapDropdown(gap),
        ),
      ));
    } else {
      spans.add(TextSpan(text: match.group(0)!));
    }

    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex)));
  }

  return Text.rich(
    TextSpan(
      style: const TextStyle(fontSize: 22, color: Colors.black87, height: 1.8),
      children: spans,
    ),
    textAlign: TextAlign.justify,
  );
}


  List<Widget> processTextWithGaps(String text, List<Map<String, dynamic>> gaps) {
  List<Widget> widgets = [];
  final regex = RegExp(r'\[gap\d+\]');
  int lastMatchEnd = 0;

  for (final match in regex.allMatches(text)) {
    if (match.start > lastMatchEnd) {
      widgets.add(Text(text.substring(lastMatchEnd, match.start)));
    }

    final gapId = text.substring(match.start + 1, match.end - 1);
    final gap = gaps.firstWhere((g) => g['gapId'] == gapId, orElse: () => {});
    if (gap.isNotEmpty) {
      widgets.add(buildGapDropdown(gap));
    }

    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < text.length) {
    widgets.add(Text(text.substring(lastMatchEnd)));
  }

  return widgets;
}

Widget buildGapDropdown(Map<String, dynamic> gap) {
  final String gapId = gap['gapId'];
  final List<String> options = List<String>.from(gap['options']);
  Color borderColor;
  if (answerValidity.containsKey(gapId)) {
    borderColor = answerValidity[gapId]! ? Colors.green : Colors.red;
  } else {
    borderColor = Colors.grey.shade400;
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  decoration: BoxDecoration(
    border: Border.all(color: borderColor, width: 2),
    borderRadius: BorderRadius.circular(4),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      isDense: true,
      value: selectedAnswers[gapId],
      icon: const Icon(Icons.arrow_drop_down, size: 20),
      style: const TextStyle(fontSize: 22, color: Colors.black),
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedAnswers[gapId] = newValue;
        });
      },
    ),
  ),
);
}

  Widget buildNavigationButtons() {
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
                  if(!hasCheckedAnswers){
                    checkAnswers();
                  } else{
                    updateUserAnswers();
                    if (widget.currentIndex + 1 < widget.summaries.length){
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SummariesContentScreen(
                            docId: widget.docId,
                            name: widget.name,
                            color: widget.color,
                            summaries: widget.summaries,
                            startIndex: widget.currentIndex + 1,
                            userName: widget.userName,
                            userUid: widget.userUid,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestSummariesExercise(
                            name: widget.name,
                            docId: widget.docId,
                            color: widget.color,
                            userName: widget.userName,
                            userUid: widget.userUid,
                            questionStatements: questionStatements,
                            optionsList: optionsList,
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                label: Text(hasCheckedAnswers ? 'Continua' : 'Resol', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),  
              ],
            ),
          ),
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

void checkAnswers() {
  final gaps = widget.gapsInfo[widget.currentIndex];

  setState(() {
    answerValidity.clear();

    for (var gap in gaps) {
      final gapId = gap['gapId'];
      final correctAnswer = gap['correctAnswer'];
      final selected = selectedAnswers[gapId];
      answerValidity[gapId] = selected == correctAnswer;
    }
    hasCheckedAnswers = true;
    final correct = answerValidity.values.where((v) => v == true).length;
    correctAnswers = correct;
    incorrectAnswers = answerValidity.length - correct;
    time = DateTime.now().difference(startTime);
  });
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
    updateUserInteraction();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => StudentHomeScreen()),
      (Route<dynamic> route) => false,
    );
  }
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

  Future<void> loadMultipleChoice() async {
    try{
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('multipleChoice').doc(widget.docId).get();

      List<Map<String, dynamic>> loadedOptions = [];
      List<String> loadedQuestions = [];

      for (int i = 1; i <= 5; i++){
        final questionKey = 'question$i';
        Map<String,dynamic>? questionData = docSnapshot.get(questionKey);

        if (questionData == null){
          throw Exception('$questionKey no trobat');
        }

        final questionText = questionData['question'] as String;
        final options = List<String>.from(questionData['options']);
        final correctAnswer = questionData['correctAnswer'] as String;
        
        loadedQuestions.add(questionText);
        loadedOptions.add({
          'options': options,
          'correctAnswer': correctAnswer,
        });
        
      }

      setState(() {
        questionStatements = loadedQuestions;
        optionsList = loadedOptions;
      });

    }catch (e) {    
    questionStatements.clear();
    optionsList.clear();
    throw Exception('Error al carregar les dades: ${e.toString()}');
  }
  }
}