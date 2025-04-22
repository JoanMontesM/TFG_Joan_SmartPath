import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/student_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/screens/rating_screen.dart';


class TestSummariesExercise extends StatefulWidget {
  final String name;
  final Color color;
  final String docId;
  final String userUid;
  final String userName;
  final List<String> questionStatements;
  final List<Map<String, dynamic>> optionsList;

  const TestSummariesExercise({
    super.key,
    required this.name,
    required this.color,
    required this.docId,
    required this.userName,
    required this.userUid,
    required this.optionsList,
    required this.questionStatements
  });

  @override
  State<TestSummariesExercise> createState() => _TestSummariesExerciseState();
}

class _TestSummariesExerciseState extends State<TestSummariesExercise> {
  
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  bool hasCheckedAnswers = false;
  bool isAnswerCorrect = false;
  String? correctAnswer;
  int correctAnswersCount = 0;
  int incorrectAnswersCount = 0;
  late DateTime startTime;
  Duration time = Duration.zero;


  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
  }

  

  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          buildMultipleChoice(),
          buildNavigationButtons(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
      
    );
  }

  Widget buildMultipleChoice() {
  final options = widget.optionsList[currentQuestionIndex]['options'] as List<String>;
  final currentCorrectAnswer = widget.optionsList[currentQuestionIndex]['correctAnswer'] as String;

  return Align(
    alignment: Alignment(0, 0.45),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildTimeline(),
            const SizedBox(height: 20),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              Color backgroundColor = primaryColor;
              final optionLetter = String.fromCharCode(65 + index);

              if(hasCheckedAnswers) {
                if(optionLetter == currentCorrectAnswer) {
                  backgroundColor = Colors.green.shade300;
                }
                else if (index == selectedOptionIndex){
                  backgroundColor = Colors.red.shade300;
                }
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: (index == selectedOptionIndex && !hasCheckedAnswers) ? const Color.fromARGB(149, 117, 0, 128) : backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if(!hasCheckedAnswers){
                          setState(() => selectedOptionIndex = index);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

void checkAnswer() {
    if (selectedOptionIndex == null) return;
    
    final correctAnswer = widget.optionsList[currentQuestionIndex]['correctAnswer'];
    final selectedLetter = String.fromCharCode(65 + selectedOptionIndex!);
    final isCorrect = selectedLetter == correctAnswer;

    setState(() {
      hasCheckedAnswers = true;
      time = DateTime.now().difference(startTime);
      
      if (isCorrect) {
        correctAnswersCount++;
      } else {
        incorrectAnswersCount++;
      }
    });
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
                  if(hasCheckedAnswers){
                    if(currentQuestionIndex < 4){
                      setState((){
                      currentQuestionIndex++;
                      selectedOptionIndex = null;
                      hasCheckedAnswers = false;
                    });
                    } else{
                      updateUserAnswers();
                      endExercises();
                    }
                    
                  } else{
                    checkAnswer();
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

Future<void> endExercises() async {
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
                "Enhorabona! Has finalitzat el test amb èxit",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'images/Molt content.png',
                height: 230,
                width: 230,
              ),
              const SizedBox(height: 10),
              const Text(
                "A continuació, hauràs de fer una breu valoració sobre l'activitat realitzada",
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
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              minimumSize: const Size(100, 50)
            ),
            child: const Text("Valora l'activitat"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
  if (exit == true) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RatingScreen(
          docId: widget.docId,
          name: widget.name,
          userName: widget.userName,
          userUid: widget.userUid,
          color: widget.color,
        ),
      ),
    );
  }
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

void updateUserAnswers() async {
    final totalTime = DateTime.now().difference(startTime);

    final data = {
      'correctAnswers': correctAnswersCount,
      'incorrectAnswers': incorrectAnswersCount,
      'time': totalTime.inSeconds,
    };

    try {
      await FirebaseFirestore.instance.collection('studentsInteractionTestExercise').doc(widget.userUid).update({
        widget.name: FieldValue.arrayUnion([data])});

    } catch (e) {
      print("Error al actualitzar l'interacció: $e");
    }
  }

  void updateUserInteraction() async {  
    try {
      await FirebaseFirestore.instance.collection('studentsInteractionTestExercise').doc(widget.userUid).update({
        'dropouts': FieldValue.increment(1)
      });
    } catch (e) {
      print("Error al actualitzar l'interacció: $e");
    }
  }

Widget buildTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final progress = (currentQuestionIndex / 4);

          return Stack(
            children: [
              Container(
                height: 8,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: totalWidth * progress,
                height: 8,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final isActive = index <= currentQuestionIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: index == currentQuestionIndex ? 30 : 20,
                    height: index == currentQuestionIndex ? 30 : 20,
                    decoration: BoxDecoration(
                      color: isActive ? widget.color : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildBackground() {
    String displayText = widget.questionStatements[currentQuestionIndex];

    if (hasCheckedAnswers && selectedOptionIndex != null) {
      final correctAnswer = widget.optionsList[currentQuestionIndex]['correctAnswer'];
      final selectedLetter = String.fromCharCode(65 + selectedOptionIndex!);
      final isCorrect = selectedLetter == correctAnswer;

      if (isCorrect) {
        displayText = "Enhorabona! Resposta correcta.";
      } 
    }
    return Stack(
      children: [
        Container(
          height: 315,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        Positioned.fill(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 55.0),
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: calculateFontSize(),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

double calculateFontSize() {  
  final text = widget.questionStatements[currentQuestionIndex];
  final length = text.length;
  
  if (length <= 50) return 40;
  if (length <= 100) return 34;
  if (length <= 150) return 32;
  if (length <= 250) return 30;
  if (length <= 300) return 28;
  return 24;
}

  Widget buildBackground2() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 520,
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
        height: 520,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
      ),
    );
  }

}