import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/individual_report_screen.dart';
import 'package:smartpath_app/screens/teacher_home_screen.dart';

class AccessReportsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const AccessReportsScreen({
    super.key,
    required this.students,
  });

  @override
  State<AccessReportsScreen> createState() => _AccessReportsScreenState();
}

class _AccessReportsScreenState extends State<AccessReportsScreen> {
  List<Map<String, dynamic>> contentItems = [];
  String _selectedGroup = "grup1";
  int _selectedIndex = 1;
  List<Map<String, dynamic>> get filteredStudents {
    return widget.students.where((student) => student['group'] == _selectedGroup).toList();
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
          buildGroupSelection(),
          buildUsersList(context),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget buildUsersList(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 280),
    child: filteredStudents.isEmpty
        ? const Center(
            child: Text("No hi ha usuaris en aquest grup",
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
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              
              return Stack(
                children: [
                  ElevatedButton(
                    onPressed: () => {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => IndividualReportScreen(
                            name: student['name'],
                            uid: student['uid'],
                          )
                        )
                      )
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: studentReportsColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          student['name'],
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
                ],
              );
            },
          ),
  );
}

Widget buildGroupSelection() {
  return Padding(
    padding: const EdgeInsets.only(top: 220, left: 20, right: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        groupButton("grup1"),
        groupButton("grup2"),
      ],
    ),
  );
}

Widget groupButton(String group) {
    final groupName = group == "grup1" ? "Grup 1" : "Grup 2";
    
    return SizedBox(
      width: 160,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedGroup = group;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedGroup == group ? primaryColor : Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          groupName,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            color: _selectedGroup == group ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherHomeScreen(),
                ),
              );
            } else {
              setState(() => _selectedIndex = index);
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
                "Informes d'estudiants",
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

}