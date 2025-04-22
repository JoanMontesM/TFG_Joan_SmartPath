import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/student_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingScreen extends StatefulWidget {
  final String docId;
  final String name;
  final String userUid;
  final String userName;
  final Color color;

  const RatingScreen({
    super.key,
    required this.docId,
    required this.name,
    required this.userName,
    required this.userUid,
    required this.color
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int currentQuestionIndex = 0;
  int? selectedValue;
  List<int?> answers = List.filled(4, null);
  String comment = '';

  final List<String> questionList = [
    'Com et sents després de respondre el test?',
    'Què t’ha semblat el contingut amb diferents formats?',
    'Què t’han semblat els exercicis amb buits?',
    'Que t’ha semblat el test?',
    'T’agradaría afegir un comentari sobre algun aspecte a destacar?',
  ];

  Future<void> saveAnswers() async {
    try{
      final userDoc = FirebaseFirestore.instance.collection('usersRatingAnswers').doc(widget.userUid);

      await userDoc.set({
        'userName': widget.userName,
        widget.name: {
          'question1': answers[0],
          'question2': answers[1],
          'question3': answers[2],
          'question4': answers[3],
          'question5': comment,
        },
      }, SetOptions(merge: true));
    } catch(e){
      print(e);
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
          Align(
            alignment: Alignment(0,-0.1),
            child: buildTimeline(),
          ),
          buildRatingButtons(),
          buildNavigationButtons(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
      
    );
  }

  Widget buildRatingButtons() {
    if (currentQuestionIndex == 4) {
      return Align(
        alignment: Alignment(0, 0.4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            onChanged: (value) => comment = value,
            decoration: InputDecoration(
              hintText: 'Escriu el teu comentari aquí...',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color.fromARGB(99, 117, 0, 128),
                ),
              ),
              filled: true, 
              fillColor: const Color.fromARGB(99, 117, 0, 128),
            ),
            maxLines: 5,
          ),
        ),
      );
    } else{
      return Align(
        alignment: Alignment(0, 0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (index) {
            int value = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedValue = value;
                });
              },
              child: Opacity(
                opacity: selectedValue == value ? 0.4 : 1.0,
                child: Image.asset(
                  'images/rating_$value.png',
                  width: 82.2,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }),
        ),
      );
    }
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
                    if(currentQuestionIndex < 4){
                      answers[currentQuestionIndex] = selectedValue;
                      setState((){
                      currentQuestionIndex++;
                      selectedValue = null;
                    });
                    } else{
                      saveAnswers();
                      returnHomePage();
                    }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                label: Text('Envia', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),  
              ],
            ),
          ),
        );
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

Future<void> returnHomePage() async {
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
                "Moltes gràcies, la teva opinió ens ajuda a crèixer!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'images/rating_4.png',
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
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              minimumSize: const Size(100, 50)
            ),
            child: const Text("Surt al menú principal"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
  if (exit == true) {
    try{
      await FirebaseFirestore.instance.collection('summaries').doc(widget.docId).update({
        'completedUsers': FieldValue.arrayUnion([widget.userUid]),
      });
    } catch (e){
      print(e);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentHomeScreen(),
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
              padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 10),
              child: Text(
                questionList[currentQuestionIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
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