import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartpath_app/screens/summaries_content_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Map<String, dynamic>> contentItems = [];
  String _selectedAmbit = "Àmbit lingüístic";
  String userName = '';
  String userUid = '';
  final int startIndex = 0;

  @override

  void initState() {
    super.initState();
    loadContentFromFirebase();
    loadUserName();
  }

  Future<void> loadContentFromFirebase() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('summaries')
          .get();

      List<Map<String, dynamic>> loadedContent = [];
      for (var doc in querySnapshot.docs) {
        loadedContent.add({
          'docId': doc.id,
          'name': doc['name'],
          'color': Color(doc['color'] as int),
          'ambit': doc['ambit'],
          'isValidated': doc['isValidated'],
          'summary1': doc['summary1'],
          'summary2': doc['summary2'],
          'summary3': doc['summary3'],
          'completedUsers': doc['completedUsers'] ?? [],
        });
      }
      print(loadedContent);

      setState(() {
        contentItems = loadedContent;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el contenido')),
      );
    }
  }
  
  Future<void> loadUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if(user == null || user.uid.isEmpty) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          userName = userDoc.get('name') ?? '';
          userUid = user.uid;
        });

    } catch (e){
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al carregar el nom')),
        );
      }
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
          buildAmbitSelection(),
          buildContentList(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildCustomBottomBar() {
  return Container(
    height: 80,
    color: const Color.fromARGB(125, 117, 0, 128),
    child: Center(
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
  );
}

  Widget buildBackground() {
  return Stack(
    children: [
      Container(
        height: 212,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(60),
          )
        ),
      ),
      Positioned(
        left: 40,
        top: 70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $userName!',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Avui és un bon dia per\naprendre alguna cosa nova!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      Positioned(
        right: 20,
        top: 40,
        child: Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
            child: Image.asset(
              'images/molt_content_transparent.png',
            ),
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
        height: 623,
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

  Widget buildBackground3(){
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        alignment: Alignment.bottomCenter,
        height: 623,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
      )
    );
  }

  Widget buildAmbitSelection() {
  return Padding(
    padding: const EdgeInsets.only(top: 260, left: 20, right: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ambitButton("Àmbit lingüístic"),
        _ambitButton("Àmbit cientifico-tecnològic"),
      ],
    ),
  );
}

  Widget _ambitButton(String ambit) {
    return SizedBox(
      width: 160,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedAmbit = ambit;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedAmbit == ambit ? primaryColor : Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          ambit,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            color: _selectedAmbit == ambit ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> saveInteractionGaps() async {
    DocumentReference docRef = FirebaseFirestore.instance.collection('studentsInteractionGapsExercise').doc(userUid);
    try {
      DocumentSnapshot docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({'name': userName,userUid: []});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la interacción')),
      );
    }
  }

  Future<void> saveInteractionTest() async {
    DocumentReference docRef = FirebaseFirestore.instance.collection('studentsInteractionTestExercise').doc(userUid);
    try {
      DocumentSnapshot docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({'name': userName});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la interacción')),
      );
    }
  }
  
  Widget buildContentList() {
  List<Map<String, dynamic>> filteredContent = contentItems
      .where((item) => item['ambit'] == _selectedAmbit)
      .toList();
  return Padding(
    padding: const EdgeInsets.only(top: 305),
    child: filteredContent.isEmpty
        ? const Center(
            child: Text("No hi ha contingut", 
                style: TextStyle(fontSize: 20, color: Colors.grey)),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(37),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredContent.length,
            itemBuilder: (context, index) {
            final item = filteredContent[index];
            final isCompleted = (item['completedUsers'] as List).contains(userUid);
            return Stack(
              children: [
                ElevatedButton(
                  onPressed: isCompleted ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SummariesContentScreen(
                          docId: item['docId'],
                          name: item['name'],
                          color: item['color'],
                          summaries: [
                            item['summary1'],
                            item['summary2'],
                            item['summary3'],
                          ],
                          startIndex: startIndex,
                          userUid: userUid,
                          userName: userName,
                        ),
                      ),
                    );
                    saveInteractionGaps();
                    saveInteractionTest();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? item['color'].withOpacity(0.3) : item['color'],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        isCompleted ? '${item['name']} completat!' : item['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.check_circle, color: Colors.lightGreen),
                )
              ],
            );
          }
        )
    );
  }
}