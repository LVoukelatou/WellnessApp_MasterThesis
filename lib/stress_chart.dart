import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StressChart extends StatelessWidget {
  const StressChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Color.fromARGB(255, 25, 96, 25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),  
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Η εβδομάδα σου με μια ματιά', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200, // Ύψος του γραφήματος
            child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('check_ins')
            .where( 'timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)))) //Φιλτράρουμε τα check-ins των τελευταίων 7 ημερών
            .orderBy('timestamp', descending: false) //Χρονική σειρά από παλιότερα σε νεότερα
            .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) { 
                // Εμφάνιση loading indicator ενώ φορτώνουν τα δεδομένα
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                // Εμφάνιση μηνύματος αν δεν υπάρχουν δεδομένα
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Ανακάλυψε τον ρυθμό σου!', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 6, 37, 8))),
                    const SizedBox(height: 8),
                    const Text('Ακόμα δεν έχουμε αρκετά δεδομένα. Κάνε Check-in ή σύνδεσε το αγαπημένο σου smartwatch για να ξεκλειδώσεις τις πρώτες σου συμβουλές.', style: TextStyle(fontSize: 14, color: Colors.grey))
                  ],
                ));
              }
              final docs = snapshot.data!.docs; //επιλογή των εγγράφων από το snapshot
              List<FlSpot> spots = []; //Λίστα για τα σημεία του γραφήματος
              for (int i = 0; i < docs.length; i++) {
                final data = docs[i].data() as Map<String, dynamic>; //Λήψη των δεδομένων του εγγράφου ως Map
                final double stressLevel = (data['stress_score'] as num?)?.toDouble() ?? 0.0; //Λήψη της τιμής του stress_score και μετατροπή σε double. Αν δεν υπάρχει, βάουμε 0.0
                spots.add(FlSpot(i.toDouble(), stressLevel)); //Προσθήκη του σημείου στο γράφημα με x = index και y = stressLevel
              }
              return LineChart(
                LineChartData(
                  minY: 0, //Ελάχιστη τιμή στον άξονα y
                  maxY: 10, //Μέγιστη τιμή στον άξονα y
                  borderData: FlBorderData(
                    show: false,
                    //border: Border.all(color: Color.fromARGB(255, 59, 205, 59), width: 1),
                  ),
                  gridData: FlGridData(show: false), //βγαζουμε το πλέγμα
                  titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 2, 
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (value, meta) { //φτιάχνουμε τις ετικέτες ημέρας+ώρας στον άξονα x, σε 2 γραμμές
                          int index = value.toInt();
                          if (index >= 0 && index < docs.length) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final Timestamp? timeSt = data['timestamp'] as Timestamp?; 
                            if (timeSt != null) {
                              final date = timeSt.toDate();

                              const shortDayNames = ['Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα', 'Κυ'];
                              final dayName = shortDayNames[date.weekday - 1];
                              final formattedTime = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dayName,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          return const Text(' ');
                        },
                      ),
                    ),
                  ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color.fromARGB(255, 25, 96, 25),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                        );
  },
          ),
      ),],
      )));
  }
                }
                
