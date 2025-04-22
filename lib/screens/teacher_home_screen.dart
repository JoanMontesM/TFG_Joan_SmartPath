import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/access_reports_screen.dart';
import 'package:smartpath_app/screens/add_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/screens/summaries_validation_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> contentItems = [];
  int _selectedIndex = 0;
  String _selectedAmbit = "Àmbit lingüístic";
  List<Map<String, dynamic>> students = [];

  @override

  void initState() {
    super.initState();
    loadContentFromFirebase();
    loadStudents();
  }

  Future<void> loadContentFromFirebase() async {
    try {
      QuerySnapshot querySnapshot = await firestore
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
        });
      }

      setState(() {
        contentItems = loadedContent;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el contenido')),
      );
    }
  }

  Future<void> loadStudents() async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    List<Map<String, dynamic>> loadedStudents = [];

    for (var doc in querySnapshot.docs) {
      loadedStudents.add({
        'name': doc.get('name') ?? '',
        'uid': doc.id,
        'group': doc.get('group') ?? ''
      });
    }

    if (mounted) {
      setState(() {
        students = loadedStudents;
      });
    }
    print(loadedStudents);

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar estudiantes')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddContent,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'Contingut',
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
              setState(() => _selectedIndex = index);
            }
            else if (index == 1){
              setState(() => _selectedIndex = index);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AccessReportsScreen(
                    students: students,
                  ),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
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

  Widget buildBackground() {
    return Stack(
      children: [
        Container(
          height: 182,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.80),
            child: const Text(
                "Contingut publicat",
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
        height: 653,
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
        height: 653,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
      )
    );
  }

  Widget buildAmbitSelection() {
  return Padding(
    padding: const EdgeInsets.only(top: 220, left: 20, right: 20),
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
  
  Widget buildContentList() {
  List<Map<String, dynamic>> filteredContent = contentItems
      .where((item) => item['ambit'] == _selectedAmbit)
      .toList();

  return Padding(
    padding: const EdgeInsets.only(top: 280),
    child: filteredContent.isEmpty
        ? const Center(
            child: Text("No hi ha contingut", 
                style: TextStyle(fontSize: 20, color: Colors.grey)),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(37),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredContent.length,
            itemBuilder: (context, index) {
            final item = filteredContent[index];
            return Stack(
              children: [
                ElevatedButton(
                  onPressed: () => navigateToValidation(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item['color'],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!item['isValidated']) unVerifiedBanner(),
              ],
            );
          }
        )
    );
  }

void navigateToValidation(BuildContext context, Map<String, dynamic> contentItem) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SummariesValidationScreen(
        docId: contentItem['docId'],
        name: contentItem['name'],
        ambit: contentItem['ambit'],
        summary1: contentItem['summary1'],
        summary2: contentItem['summary2'],
        summary3: contentItem['summary3'],
        isValidated: contentItem['isValidated'],
      ),
    ),
  ).then((shouldRefresh){
    if (shouldRefresh == true){
      loadContentFromFirebase();
    }
  });
}

Widget unVerifiedBanner() {
  return Positioned.fill(
    child: IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: const Alignment(0,0),
        child: const Text(
          'Pendent de revisió',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}


void _navigateToAddContent() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AddContent()),
  ).then((_) => loadContentFromFirebase());
}
}