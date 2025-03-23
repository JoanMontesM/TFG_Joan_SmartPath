import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/screens/teacher_home_screen.dart';


class GapsValidationScreen extends StatefulWidget {
  final String docId;
  final Map<String, String> gappedSummaries;
  final Map<String, dynamic> gapsData;

  const GapsValidationScreen({
    super.key,
    required this.docId,
    required this.gappedSummaries,
    required this.gapsData
  });

  @override
  State<GapsValidationScreen> createState() => _GapsValidationScreenState();
}

class _GapsValidationScreenState extends State<GapsValidationScreen> {
  int _selectedIndex = 0;
  int _currentSummaryIndex = 0;

  List<MapEntry<String, dynamic>> get summaries => [
    MapEntry('summary1', widget.gappedSummaries['summary1']),
    MapEntry('summary2', widget.gappedSummaries['summary2']),
    MapEntry('summary3', widget.gappedSummaries['summary3']),
  ];

  List<MapEntry<String, dynamic>> get gaps => [
    MapEntry('summary1', widget.gapsData['summary1']),
    MapEntry('summary2', widget.gapsData['summary2']),
    MapEntry('summary3', widget.gapsData['summary3']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildBackground3(),
          buildGappedContent(),
          buildNavigationButtons(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }
  
  Widget buildGappedContent() {
    final currentSummary = summaries[_currentSummaryIndex];
    final currentGaps = gaps[_currentSummaryIndex].value;

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
        child: buildEditableContent(currentSummary.value, currentGaps),
      ),
    );
  }

  Widget buildEditableContent(String gappedText, List<dynamic> gaps) {
  final gapRegex = RegExp(r'\[gap\d+\]');
  final textParts = gappedText.split(gapRegex);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 8,
            children: List<Widget>.generate(textParts.length * 2 - 1, (index) {
              if (index.isOdd) {
                final gapIndex = index ~/ 2;
                final gapData = gaps.firstWhere(
                  (gap) => gap['gapId'] == 'gap${gapIndex + 1}'
                );
                return buildIntegratedGapDropdown(gapData);
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    textParts[index ~/ 2],
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                );
              }
            }),
          ),
        ),
      ),
    ),
  );
}

Widget buildAdaptiveGapDropdown(Map<String, dynamic> gapData) {
  final String correctAnswer = gapData['correctAnswer'];
  final List<String> options = List<String>.from(gapData['options']);

  return LayoutBuilder(
    builder: (context, constraints) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: primaryColor.withOpacity(0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true, // Ocupa todo el espacio disponible
            value: correctAnswer,
            iconSize: 20,
            isDense: true,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            itemHeight: null, // Altura dinámica
            items: options.map((String value) {
              final isCorrect = value == correctAnswer;
              return DropdownMenuItem<String>(
                value: value,
                child: Tooltip( // Tooltip para texto largo
                  message: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        if (isCorrect)
                          const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2, // Permite 2 líneas de texto
                            style: TextStyle(
                              color: isCorrect ? Colors.green[800] : Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: null,
          ),
        ),
      );
    },
  );
}

  Widget buildIntegratedGapDropdown(Map<String, dynamic> gapData) {
  final String correctAnswer = gapData['correctAnswer'];
  final List<String> options = List<String>.from(gapData['options']);
  final textStyle = const TextStyle(fontSize: 14);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: primaryColor.withOpacity(0.5)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: correctAnswer,
        iconSize: 20,
        isDense: true,
        style: textStyle,
        dropdownColor: Colors.grey[50],
        items: options.map((String value) {
          final isCorrect = value == correctAnswer;
          return DropdownMenuItem<String>(
            value: value,
            child: IntrinsicWidth(
              child: Row(
                children: [
                  if (isCorrect)
                    const Icon(Icons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCorrect ? Colors.green[800] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (_) {},
      ),
    ),
  );
}

  Widget buildEditableTextSegment(String text, int segmentIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        initialValue: text,
        maxLines: null,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.4,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey[400]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (newValue) {
          //updateGappedText(segmentIndex, newValue),
        },
      ),
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
              style: buttonStyle(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Anterior', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (_currentSummaryIndex < 2) {
                  navigateSummary(1);
                } else {
                  //await saveAllSummaries();
                  
                }
              },
              style: buttonStyle(),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text('Següent', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void navigateSummary(int direction) {
    setState(() => _currentSummaryIndex += direction);
  }

  Future<void> saveAllSummaries() async{
    try {
      await FirebaseFirestore.instance.collection('summariesWithGaps').doc(widget.docId).update({
        'gappedSummaries': widget.gappedSummaries,
        'gapsData': widget.gapsData,
      });
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en guardar: ${e.toString()}'))
      );
    }
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
              icon: Icon(Icons.camera_alt),
              label: 'Imatges',
            )
            
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


