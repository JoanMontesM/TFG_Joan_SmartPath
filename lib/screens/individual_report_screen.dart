import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smartpath_app/core/pallet.dart';
import 'package:smartpath_app/screens/teacher_home_screen.dart';


class IndividualReportScreen extends StatefulWidget {
  final String name;
  final String uid;

  const IndividualReportScreen({
    super.key,
    required this.name,
    required this.uid,
  });

  @override
  State<IndividualReportScreen> createState() => _IndividualReportScreenState();
}

class _IndividualReportScreenState extends State<IndividualReportScreen> {
  int currentPage = 0;
  Map<String, Map<String, Map<String, int>>> materialDetails = {};
  List<String> get materialNames => materialDetails.keys.toList();
  int? usageImages;
  int? usageLowComplexity;
  int? usageTTS;
  int? dropouts;

  Map<String, Map<String, int>> testDetails = {};
  List<String> get testContentNames => testDetails.keys.toList();

  Map<String, Map<String,int>> ratingAnswers = {};

  @override
  void initState() {
    super.initState();
    loadGapsInteraction();
    loadTestInteraction();
    loadRatingInteraction();
  }

  Future<void> loadGapsInteraction() async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('studentsInteractionGapsExercise').doc(widget.uid).get();

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = Map.from(doc.data() as Map<String, dynamic>);

      setState(() {
        usageLowComplexity = data['usageLowComplexity']?.toInt() ?? 0;
        usageTTS = data['usageTTS']?.toInt() ?? 0;
        usageImages = data['usageImages']?.toInt() ?? 0;
        dropouts = data['dropouts']?.toInt() ?? 0;
      });

      data.remove('usageLowComplexity');
      data.remove('usageTTS');
      data.remove('usageImages');

      Map<String, Map<String, Map<String, int>>> processedData = {};

      data.forEach((materialName, summaries) {
        if (summaries is Map<String, dynamic>) {
          Map<String, Map<String, int>> materialSummaries = {};

          summaries.forEach((summaryKey, interactions) {
            if (interactions is List && interactions.isNotEmpty) {
              Map<String, dynamic> lastInteraction = interactions.last;
              
              materialSummaries[summaryKey] = {
                'correct': (lastInteraction['correctAnswers'] as int? ?? 0),
                'incorrect': (lastInteraction['incorrectAnswers'] as int? ?? 0),
                'time': (lastInteraction['time'] as int? ?? 0)
              };
            }
          });

          processedData[materialName] = materialSummaries;
        }
      });

      setState(() {
        materialDetails = processedData;
      });
    }

  } catch (e) {
    print('Error al cargar: $e');
  }
}

Future<void> loadTestInteraction() async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('studentsInteractionTestExercise').doc(widget.uid).get();

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = Map.from(doc.data() as Map<String, dynamic>);
      
      Map<String, Map<String, int>> processedData = {};

      data.forEach((contentName, attempts) {
        if (attempts is List && attempts.isNotEmpty) {
          Map<String, dynamic> lastAttempt = attempts.last;
          
          processedData[contentName] = {
            'correct': (lastAttempt['correctAnswers'] as int? ?? 0),
            'incorrect': (lastAttempt['incorrectAnswers'] as int? ?? 0),
            'time': (lastAttempt['time'] as int? ?? 0)
          };
        }
      });
      setState(() {
        testDetails = processedData;
      });
    }
  } catch (e) {
    print('Error al cargar tests: $e');
  }
}

Future<void> loadRatingInteraction() async{
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usersRatingAnswers').doc(widget.uid).get();

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, Map<String, int>> processedData = {};

      data.forEach((contentName, answerData) {
        if (answerData is Map<String, dynamic>) {
          processedData[contentName] = {
            'question1': (answerData['question1'] as int? ?? 0),
            'question2': (answerData['question2'] as int? ?? 0),
            'question3': (answerData['question3'] as int? ?? 0),
            'question4': (answerData['question4'] as int? ?? 0),
          };
        }
      });
      setState(() {
        ratingAnswers = processedData;
      });
    }
    print(ratingAnswers);
  } catch (e){
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
          buildNavigationButtons(),
          if(currentPage == 0) buildSummaryAnswers(),
          if(currentPage == 1) buildGapsComprehension(),
          if(currentPage == 2) buildTestComprehension(),
          if(currentPage == 3) buildDropouts(),
          if(currentPage == 4) buildFavouriteFormat(),
          if(currentPage == 5) buildStudentSatisfaction(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget buildSummaryAnswers() {
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
  int totalTime = 0;
  materialDetails.forEach((_, summaries) {
    summaries.forEach((_, stats) {
      totalTime += stats['time']!;
    });
  });
  testDetails.forEach((_, stats) {
    totalTime += stats['time']!;
  });

  return Positioned(
    top: 250,
    left: 20,
    right: 20,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Contingut respós: ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
             Text(
                materialNames.join(', '),
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                )
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Temps total emprat:',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatTime(totalTime),
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildGapsComprehension() {
  int summary1Correct = 0;
  int summary1Incorrect = 0;
  int summary2Correct = 0;
  int summary2Incorrect = 0;
  int summary3Correct = 0;
  int summary3Incorrect = 0;
  int totalTime = 0;
  int totalCorrect = 0;
  int totalIncorrect = 0;

  materialDetails.forEach((material, summaries) {
    summaries.forEach((summaryKey, stats) {
      switch (summaryKey) {
        case 'summary1':
          summary1Correct += stats['correct']!;
          summary1Incorrect += stats['incorrect']!;
          break;
        case 'summary2':
          summary2Correct += stats['correct']!;
          summary2Incorrect += stats['incorrect']!;
          break;
        case 'summary3':
          summary3Correct += stats['correct']!;
          summary3Incorrect += stats['incorrect']!;
          break;
      }
    });
  });

  materialDetails.forEach((material, summaries) {
    summaries.forEach((summaryKey, stats) {
      totalTime += stats['time']!;
      totalCorrect += stats['correct']!;
      totalIncorrect += stats['incorrect']!;
    });
  });

  double accuracyPercentage = totalCorrect + totalIncorrect > 0 
      ? (totalCorrect / (totalCorrect + totalIncorrect)) * 100
      : 0.0;

  List<ChartData> chartData = [
    ChartData('Resum 1', summary1Correct, summary1Incorrect),
    ChartData('Resum 2', summary2Correct, summary2Incorrect),
    ChartData('Resum 3', summary3Correct, summary3Incorrect),
  ];

  return Positioned(
    top: 200,
    left: 10,
    right: 10,
    bottom: 100,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            'Respostes correctes/incorrectes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: Colors.grey[800], fontSize: 16),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(color: Colors.grey[800], fontSize: 16),
              ),
              series: <StackedColumnSeries<ChartData, String>>[
                StackedColumnSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.correct,
                  name: 'Correctes',
                  color: primaryColor,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
                StackedColumnSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.incorrect,
                  name: 'Incorrectes',
                  color: studentReportsColor,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildTimeStat(totalTime),
              buildAccuracyStat(accuracyPercentage),
            ],
          )
        ],
      ),
    ),
  );
}

Widget buildTestComprehension() {
  int totalCorrect = 0;
  int totalIncorrect = 0;
  int totalTime = 0;

  testDetails.forEach((content, stats) {
    totalCorrect += stats['correct']!;
    totalIncorrect += stats['incorrect']!;
    totalTime += stats['time']!;
  });

  double accuracyPercentage = totalCorrect + totalIncorrect > 0 
      ? (totalCorrect / (totalCorrect + totalIncorrect)) * 100
      : 0.0;

  List<ChartData> chartData = [
    ChartData('Tests', totalCorrect, totalIncorrect),
  ];

  return Positioned(
    top: 200,
    left: 10,
    right: 10,
    bottom: 100,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        children: [
          Text(
            'Respostes correctes/incorrectes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: Colors.grey[800], fontSize: 16),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(color: Colors.grey[800], fontSize: 16),
              ),
              series: <StackedColumnSeries<ChartData, String>>[
                StackedColumnSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.correct,
                  name: 'Correctes',
                  color: primaryColor,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
                StackedColumnSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.incorrect,
                  name: 'Incorrectes',
                  color: studentReportsColor,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildTimeStat(totalTime),
              buildAccuracyStat(accuracyPercentage),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildTimeStat(int totalSeconds) {
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  return Column(
    children: [
      Icon(Icons.timer, color: primaryColor, size: 30),
      const SizedBox(height: 8),
      Text(
        formatTime(totalSeconds),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800]),
      ),
      const SizedBox(height: 4),
      Text(
        'Temps de resposta',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600]),
      ),
    ],
  );
}

Widget buildAccuracyStat(double percentage) {
  return Column(
    children: [
      Icon(Icons.assessment_outlined, color: primaryColor, size: 30),
      const SizedBox(height: 8),
      Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800]),
      ),
      const SizedBox(height: 4),
      Text(
        'Percentatge encert',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600]),
      ),
    ],
  );
}

Widget buildDropouts() {
  final int dropoutsCount = dropouts ?? 0;
  return Positioned(
    top: 200,
    left: 20,
    right: 20,
    bottom: 150,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            "Abandonament d'activitats",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: Colors.grey[800], fontSize: 16)),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: Colors.grey[800], fontSize: 14),
                minimum: 0,
                maximum: dropoutsCount + 2.0,
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <ColumnSeries<DropoutData, String>>[
                ColumnSeries<DropoutData, String>(
                  dataSource: [
                    DropoutData('Abandonaments', dropoutsCount)
                  ],
                  xValueMapper: (DropoutData data, _) => data.category,
                  yValueMapper: (DropoutData data, _) => data.count,
                  color: primaryColor,
                  width: 0.3,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildFavouriteFormat() {
  List<FormatUsageData> chartData = [
    FormatUsageData('Baixa complexitat', usageLowComplexity ?? 0, primaryColor),
    FormatUsageData('Imatges', usageImages ?? 0, studentReportsColor),
    FormatUsageData('Text a veu', usageTTS ?? 0, const Color.fromRGBO(99, 11, 87, 1)),
  ];
  int total = chartData.fold(0, (sum, item) => sum + item.value);

  return Positioned(
    top: 200,
    left: 10,
    right: 10,
    bottom: 150,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            'Format preferit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
          ),
          const SizedBox(height: 20),
          Expanded(
        child: total > 0 
            ? SfCircularChart(
                series: <PieSeries<FormatUsageData, String>>[
                  PieSeries<FormatUsageData, String>(
                    dataSource: chartData,
                    xValueMapper: (FormatUsageData data, _) => data.category,
                    yValueMapper: (FormatUsageData data, _) => data.value,
                    pointColorMapper: (FormatUsageData data, _) => data.color,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.inside,
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16),
                        ),
                        explode: true,
                        explodeIndex: 0,
                      )
                    ],
                  )
                : Center(
                    child: Text(
                      'Encara no hi ha dades d\'ús',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600]),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildFormatIndicator(
                'Baixa complexitat', 
                usageLowComplexity ?? 0,
                primaryColor
              ),
              buildFormatIndicator(
                'Imatges', 
                usageImages ?? 0,
                studentReportsColor
              ),
              buildFormatIndicator(
                'Text a veu', 
                usageTTS ?? 0,
                const Color.fromRGBO(99, 11, 87, 1)
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildFormatIndicator(String label, int value, Color color) {
  return Column(
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

Widget buildStudentSatisfaction() {
  final Map<String, double> averages = calculateQuestionAverages(ratingAnswers);
  print(averages);

  final List<String> lineTitles = [
      'Valoració general',
      'Valoració del contingut en diferents formats',
      'Valoració dels exercicis amb buits',
      'Valoració dels exercicis tipus test',
    ];
  return Positioned(
    top: 200,
    left: 50,
    right: 50,
    bottom: 150,
    child: Column(
      children: [
        buildTimeline(lineTitles[0], averages["question1"] ?? 0),
        const SizedBox(height: 30),
        buildTimeline(lineTitles[1], averages["question2"] ?? 0),
        const SizedBox(height: 30),
        buildTimeline(lineTitles[2], averages["question3"] ?? 0),
        const SizedBox(height: 30),
        buildTimeline(lineTitles[3], averages["question4"] ?? 0),
      ],
    )
  );
}

  Widget buildTimeline(String title,double averageRating) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          const circleDiameter = 30.0;
          final spacingBetweenCircles = totalWidth - circleDiameter;
          final segmentWidth = spacingBetweenCircles / 4;
          final fillWidth = (averageRating.clamp(0, 5) - 1) * segmentWidth + (circleDiameter / 2);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: fillWidth,
                height: 12,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final isActive = averageRating >= (index + 1);

                return Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive ? primaryColor : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        );
      },
    ),
    ]
  );
}

Map<String, double> calculateQuestionAverages(Map<String, Map<String, int>> ratingAnswers) {
  final Map<String, List<int>> groupedRatings = {};

  for (final contentRatings in ratingAnswers.values) {
    contentRatings.forEach((question, rating) {
      groupedRatings.putIfAbsent(question, () => []).add(rating);
    });
  }

  final Map<String, double> averages = {};
  groupedRatings.forEach((question, ratings) {
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    averages[question] = avg;
  });

  return averages;
}

Widget buildNavigationButtons() {
  return Positioned(
    bottom: 30,
    left: 30,
    right: 30,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: currentPage == 0 
            ? MainAxisAlignment.center 
            : MainAxisAlignment.spaceBetween,
        children: [
          if(currentPage > 0)
          ElevatedButton(
            onPressed: () {
              setState(() {
                if(currentPage > 0) currentPage--;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Anterior', 
              style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              if(currentPage < 5){
                setState(() {
                  currentPage++;
                });
              } else{
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherHomeScreen(),
                ),
              );
              } 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              currentPage < 5 ? 'Següent' : 'Finalitza', 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16,
                fontWeight: FontWeight.bold
              )),
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
        onTap: () => Navigator.pop(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 1),
            Text(
              'Inici',
              style: TextStyle(
                color: Colors.white,
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

Widget buildBackground() {
    final List<String> pageTitles = [
      'Informe de ${widget.name}',
      'Avaluació de la comprensió de text',
      'Retenció i aplicació de coneixements',
      'Abandonament de les activitats',
      "Preferències de format d'aprenentatge",
      "Satisfacció de l'estudiant"
    ];
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
        Positioned.fill(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Text(
                pageTitles[currentPage],
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

class ChartData {
  final String category;
  final int correct;
  final int incorrect;

  ChartData(this.category, this.correct, this.incorrect);
}

class FormatUsageData {
  final String category;
  final int value;
  final Color color;

  FormatUsageData(this.category, this.value, this.color);
}

class DropoutData {
  final String category;
  final int count;

  DropoutData(this.category, this.count);
}

class QuestionData {
  final String question;
  final double average;

  QuestionData(this.question, this.average);
}
