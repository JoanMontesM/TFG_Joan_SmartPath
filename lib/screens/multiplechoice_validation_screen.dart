import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/teacher_home_screen.dart';

class MultiplechoiceValidationScreen extends StatefulWidget {
  final String docId;

  const MultiplechoiceValidationScreen({required this.docId});

  @override
  State<MultiplechoiceValidationScreen> createState() => _MultiplechoiceValidationScreenState();
}

class _MultiplechoiceValidationScreenState extends State<MultiplechoiceValidationScreen> {
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _questionsData = {};

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final doc = await FirebaseFirestore.instance
        .collection('multipleChoice')
        .doc(widget.docId)
        .get();

    if (doc.exists) {
      setState(() => _questionsData = doc.data()!);
    }
  }

  void navigateQuestion(int direction) {
    final newIndex = _currentQuestionIndex + direction;
    if (newIndex >= 0 && newIndex < 5) {
      setState(() => _currentQuestionIndex = newIndex);
      saveChanges();
    }
  }

  void updateQuestion(String newText) {
    setState(() {
      _questionsData['question${_currentQuestionIndex + 1}']['question'] = newText;
    });
  }

  void updateOption(int optionIndex, String newValue) {
    setState(() {
      final questionKey = 'question${_currentQuestionIndex + 1}';
      final question = _questionsData[questionKey];
      question['options'][optionIndex] = newValue;
      
      if (question['correctAnswer'] == question['options'][optionIndex]) {
        question['correctAnswer'] = newValue;
      }
    });
  }

  Future<void> saveChanges() async {
    await FirebaseFirestore.instance
        .collection('multipleChoice')
        .doc(widget.docId)
        .update(_questionsData);
  }

  @override
  Widget build(BuildContext context) {
    if (_questionsData.isEmpty) return const Center(child: CircularProgressIndicator());

    return Scaffold(
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
              child: buildQuestionPage(),
            ),
          ),
          buildNavigationButtons(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget buildQuestionPage() {
    final questionKey = 'question${_currentQuestionIndex + 1}';
    final currentQuestion = _questionsData[questionKey];
    final options = (currentQuestion['options'] as List<dynamic>).cast<String>();

    return Column(
      children: [
        TextFormField(
          key: Key('question_$_currentQuestionIndex'),
          initialValue: currentQuestion['question'],
          onChanged: updateQuestion,
          style: const TextStyle(fontSize: 20, height: 1.7, color: Colors.black87),
          maxLines: 3,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: options.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final optionLetter = String.fromCharCode('A'.codeUnitAt(0) + index);
              final isCorrect = optionLetter == currentQuestion['correctAnswer'];

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: Key('option_${_currentQuestionIndex}_$index'),
                        initialValue: entry.value,
                        onChanged: (value) => updateOption(index, value),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isCorrect ? const Color.fromARGB(81, 76, 175, 79) : Colors.grey[200],
                        ),
                      ),
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
              onPressed: _currentQuestionIndex > 0 ? () => navigateQuestion(-1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Anterior', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentQuestionIndex < 4) {
                  navigateQuestion(1);
                } else {
                  handleFinalize();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: Icon(
                _currentQuestionIndex == 4 ? Icons.done : Icons.arrow_forward,
                color: Colors.white,
              ),
              label: Text(
                _currentQuestionIndex == 4 ? 'Finalitzar' : 'Següent',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleFinalize() async {
    await saveChanges();
    if (mounted) {
      showCompletionDialog();
    }
  }

  Future<void> showCompletionDialog() async {
    await showDialog(
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
                  "Validació completada!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'images/Molt content.png',
                  height: 270,
                  width: 270,
                ),
                const SizedBox(height: 10),
                const Text(
                  "La validació s'ha realitzat correctament. Vols sortir al menú principal?",
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: const Size(100, 50),
              ),
              child: const Text("Tornar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 10),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: const Size(100, 50),
              ),
              child: const Text("Sortir"),
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => TeacherHomeScreen())),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> loadMultipleChoice() async {
    final doc = await FirebaseFirestore.instance.collection('multipleChoice').doc(widget.docId).get();
    if (!doc.exists) return [];

    List<Map<String, dynamic>> questions = [];

    for (int i = 1; i <= 5; i++){
      final questionKey = 'question$i';
      if (doc.data()!.containsKey(questionKey)) {
        questions.add({
          'question': doc[questionKey]['question'],
          'options': List<String>.from(doc[questionKey]['options']),
          'correctAnswer': doc[questionKey]['correctAnswer'],
        });
      }
    }
    return questions;
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