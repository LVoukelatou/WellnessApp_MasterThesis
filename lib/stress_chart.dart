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
          Text('Το τελευταίο 24ωρο με μια ματιά', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200, // Ύψος του γραφήματος
            child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('check_ins')
            .where( 'timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))) //Φιλτράρουμε τα check-ins των τελευταίων 24 ωρών
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
                        leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false), //δεν εμφανίζουμε τίτλους στον άξονα y
                      ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) { //φτιάχνουμε τις ετικέτες χρόνου στον άξονα x
                          int index = value.toInt();
                          if (index >= 0 && index < docs.length) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final Timestamp? timeSt = data['timestamp'] as Timestamp?; 
                            if (timeSt != null) {
                              final date = timeSt.toDate();
                              final formattedTime = '${date.hour}:${date.minute.toString().padLeft(2, '0')}'; //Μορφοποίηση της ώρας σε ώρα:λεπτά
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(formattedTime, style: const TextStyle(fontSize: 10  ,color: Colors.grey)),
                              );
                            }
                          }
                          return const Text(' '); //Επιστρέφουμε κενό αν δεν υπάρχει έγκυρη ετικέτα
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
                
