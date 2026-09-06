import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryCalendar extends StatefulWidget {
  const HistoryCalendar({Key? key}) : super(key: key);

  @override
  State<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<HistoryCalendar> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final List<String> _days = ['Δ', 'Τ', 'Τ', 'Π', 'Π', 'Σ', 'Κ'];

  final List<String> _months = const [
    'Ιανουάριος',
    'Φεβρουάριος',
    'Μάρτιος',
    'Απρίλιος',
    'Μάιος',
    'Ιούνιος',
    'Ιούλιος',
    'Αύγουστος',
    'Σεπτέμβριος',
    'Οκτώβριος',
    'Νοέμβριος',
    'Δεκέμβριος',
  ];

  // Χρώμα ανάλογα με το stressScore (0-10)
  Color _colorForScore(double stressScore) {
    if (stressScore <= 4) {
      return const Color.fromARGB(255, 96, 164, 2);
    } else if (stressScore <= 7) {
      return const Color.fromARGB(255, 222, 192, 0);
    } else {
      return const Color.fromARGB(255, 208, 114, 6);
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Map<String, double> _calculateAverageScorePerDay(
    List<QueryDocumentSnapshot> checkIns,
  ) {
    Map<String, List<double>> autoScoresPerDay =
        {}; // συγκεντρώνουμε τα αυτόματα
    Map<String, List<double>> manualScoresPerDay =
        {}; // και τα χειροκίνητα check-ins ξεχωριστά

    for (final doc in checkIns) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? timestamp = data['timestamp'] as Timestamp?;
      final double? stressScore = (data['stress_score'] as num?)?.toDouble();
      final bool isAuto = data['is_autoSync'] == true;

      if (timestamp == null || stressScore == null) {
        continue;
      }

      final date = timestamp.toDate();
      final dayKey = '${date.year}-${date.month}-${date.day}';

      if (isAuto) {
        if (autoScoresPerDay.containsKey(dayKey)) {
          autoScoresPerDay[dayKey]!.add(stressScore);
        } else {
          autoScoresPerDay[dayKey] = [stressScore];
        }
      } else {
        if (manualScoresPerDay.containsKey(dayKey)) {
          manualScoresPerDay[dayKey]!.add(stressScore);
        } else {
          manualScoresPerDay[dayKey] = [stressScore];
        }
      }
    }

    Set<String> allDays = {};
    allDays.addAll(autoScoresPerDay.keys);
    allDays.addAll(manualScoresPerDay.keys);

    // υπολογίζουμε τον μο για κάθε ημέρα
    Map<String, double> finalAveragePerDay = {};
    for (final dayKey in allDays) {
      final autoList = autoScoresPerDay[dayKey];
      final manualList = manualScoresPerDay[dayKey];

      double? autoAverage;
      if (autoList != null && autoList.isNotEmpty) {
        double sum = 0;
        for (final s in autoList) {
          sum += s;
        }
        autoAverage = sum / autoList.length;
      }

      double? manualAverage;
      if (manualList != null && manualList.isNotEmpty) {
        double sum = 0;
        for (final s in manualList) {
          sum += s;
        }
        manualAverage = sum / manualList.length;
      }

      if (autoAverage != null && manualAverage != null) {
        finalAveragePerDay[dayKey] = (autoAverage + manualAverage) / 2;
      } else if (autoAverage != null) {
        finalAveragePerDay[dayKey] = autoAverage;
      } else if (manualAverage != null) {
        finalAveragePerDay[dayKey] = manualAverage;
      }
    }

    return finalAveragePerDay;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('check_ins')
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, double> averageScorePerDay = {};

        if (snapshot.hasData) {
          averageScorePerDay = _calculateAverageScorePerDay(
            snapshot.data!.docs,
          );
        }

        return Card(
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(
              color: Color.fromARGB(255, 25, 96, 25),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildMonthHeader(),
                const SizedBox(height: 8),
                _buildWeekdayLabels(),
                const SizedBox(height: 4),
                _buildCalendarGrid(averageScorePerDay),
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Γραμμή πάνω πάνω με τα βελάκια και το όνομα του μήνα
  Widget _buildMonthHeader() {
    final monthName = _months[_selectedMonth.month - 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousMonth,
        ),
        Text(
          '$monthName ${_selectedMonth.year}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  // Η γραμμή με τις ημέρες της εβδομάδας (Δ, Τ, Τ, Π, Π, Σ, Κ)
  Widget _buildWeekdayLabels() {
    List<Widget> labelWidgets = [];
    for (final letter in _days) {
      labelWidgets.add(
        Expanded(
          child: Center(
            child: Text(
              letter,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }
    return Row(children: labelWidgets);
  }

  // Το κυρίως πλέγμα με τους αριθμούς ημερών και τα κυκλάκια
  Widget _buildCalendarGrid(Map<String, double> averageScorePerDay) {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final totalDaysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    // Πόσα κενά κουτάκια χρειάζονται πριν την 1η μέρα του μήνα, ώστε η 1η να πέσει στη σωστή στήλη (πχ αν ο μήνας ξεκινάει Τετάρτη, 2 κενά πριν)
    final emptyCellsBeforeFirstDay = firstDayOfMonth.weekday - 1;

    final today = DateTime.now();
    final isViewingCurrentMonth =
        (today.year == _selectedMonth.year) &&
        (today.month == _selectedMonth.month);

    List<Widget> dayCells = [];

    // Προσθέτουμε τα κενά κουτάκια στην αρχή
    for (int i = 0; i < emptyCellsBeforeFirstDay; i++) {
      dayCells.add(const SizedBox());
    }

    // Προσθέτουμε ένα κουτάκι για κάθε ημέρα του μήνα
    for (int day = 1; day <= totalDaysInMonth; day++) {
      final dayKey = '${_selectedMonth.year}-${_selectedMonth.month}-$day';
      final double? averageScore = averageScorePerDay[dayKey];
      final bool isToday = isViewingCurrentMonth && (today.day == day);

      dayCells.add(
        _buildSingleDayCell(
          day: day,
          averageScore: averageScore,
          isToday: isToday,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayCells,
    );
  }

  // Ένα μεμονωμένο κουτάκι ημέρας (αριθμός και βούλα αν υπάρχει score)
  Widget _buildSingleDayCell({
    required int day,
    required double? averageScore,
    required bool isToday,
  }) {
    return Container(
      decoration: isToday
          ? BoxDecoration(
              color: const Color.fromARGB(255, 25, 96, 25),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 3),
          if (averageScore != null)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorForScore(averageScore),
              ),
            )
          else
            const SizedBox(height: 6), // κενός χώρος ίδιο ύψος με τη βούλα
        ],
      ),
    );
  }

  // Υπόμνημα χρωμάτων κάτω από το ημερολόγιο
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(_colorForScore(2), 'Χαμηλό'),
        const SizedBox(width: 16),
        _legendDot(_colorForScore(5.5), 'Μέτριο'),
        const SizedBox(width: 16),
        _legendDot(_colorForScore(9), 'Υψηλό'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
