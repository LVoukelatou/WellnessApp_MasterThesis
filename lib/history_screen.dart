import 'package:flutter/material.dart';
import 'stress_chart.dart';
import 'history_calendar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('Ιστορικό'),
        backgroundColor: const Color.fromARGB(255, 25, 96, 25),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: const [
              StressChart(),
              SizedBox(height: 16.0),
              HistoryCalendar(),
            ],
          ),
        ),
      ),
    );
  }
}