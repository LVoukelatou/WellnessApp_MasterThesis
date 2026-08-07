// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigationBar.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;
  bool _setCustomGoals = false;
  bool _stepsManuallyChanged = false; // flag για να ξέρουμε αν ο χρήστης έχει αλλάξει χειροκίνητα το slider των βημάτων

  String _activityLevel = 'Καθιστική εργασία';

  double _stepsGoal = 7000; // αρχικό, ίδιο με το default της "Καθιστικής εργασίας"
  double _sleepGoal = 8;
  double _hrGoal = 70;
  double _hrvGoal = 50;

  // Επιστρέφει το προτεινόμενο στόχο βημάτων ανάλογα με το activity level
  double _suggestedSteps(String level) {
  switch (level) {
    case 'Καθιστική εργασία':
      return 7000;
    case 'Ενεργή/σωματική εργασία':
      return 10000;
    default:
      return 9000; // ενδιάμεσο, μεταξύ 7000-10000 εύρους
  }
}

  void _onActivityChanged(String val) {
    setState(() {
      _activityLevel = val;
      // Ενημερώνουμε την πρόταση αν ο χρήστης δεν έχει ήδη αλλάξει χειροκίνητα το slider
      if (!_stepsManuallyChanged) {
        _stepsGoal = _suggestedSteps(val);
      }
    });
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'activity_level': _activityLevel,
        'goals': {
          'steps': _stepsGoal.round(),
          'sleep_hours': _setCustomGoals ? _sleepGoal : 8.0,
          'heart_rate': _setCustomGoals ? _hrGoal.round() : 70,
          'hrv': _setCustomGoals ? _hrvGoal.round() : 50,
        },
        'onboarding_completed': true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RootNavigation()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Σφάλμα: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _slider(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()} $unit', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(value: value, min: min, max: max, onChanged: onChanged,
            activeColor: const Color.fromARGB(255, 25, 96, 25)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(title: const Text('Ας φτιάξουμε το προφίλ σου'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Η κίνηση εκτός δουλειάς βοηθά στη διαχείριση του άγχους. Πες μας λίγα λόγια για να προσαρμόσουμε τους στόχους σου.',
                  style: TextStyle(fontWeight: FontWeight.w400)),
              const SizedBox(height: 12),
              const Text('Πώς θα περιέγραφες τη σωματική σου δραστηριότητα;',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              RadioListTile<String>(
                title: const Text('Κυρίως χαλάρωση/καθιστική ζωή στον ελεύθερο χρόνο μου'),
                value: 'Καθιστική εργασία',
                groupValue: _activityLevel,
                activeColor: const Color.fromARGB(255, 25, 96, 25),
                onChanged: (val) => _onActivityChanged(val!),
              ),
              RadioListTile<String>(
                title: const Text('Μέτρια δραστηριότητα (περπάτημα, ελαφριά άσκηση)'),
                value: 'Μέτρια δραστηριότητα',
                groupValue: _activityLevel,
                activeColor: const Color.fromARGB(255, 25, 96, 25),
                onChanged: (val) => _onActivityChanged(val!),
              ),
              RadioListTile<String>(
                title: const Text('Ενεργός τρόπος ζωής (τακτική άσκηση/γυμναστήριο)'),
                value: 'Ενεργή/σωματική εργασία',
                groupValue: _activityLevel,
                activeColor: const Color.fromARGB(255, 25, 96, 25),
                onChanged: (val) => _onActivityChanged(val!),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Πρόταση στον χρήστη για τον στόχο βημάτων ανάλογα με το activity level
              Text(
                'Προτεινόμενος στόχος βημάτων για την μείωση του εργασιακού άγχους: ${_stepsGoal.round()}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color.fromARGB(255, 25, 96, 25)),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Θέλω να προσαρμόσω τους στόχους'),
                value: _setCustomGoals,
                activeColor: const Color.fromARGB(255, 25, 96, 25),
                onChanged: (val) => setState(() => _setCustomGoals = val),
              ),

              if (_setCustomGoals) ...[
                _slider('Βήματα', _stepsGoal, 2000, 20000, 'βήματα', (v) {
                  setState(() {
                    _stepsGoal = v;
                    _stepsManuallyChanged = true; // έχει αλλάξει χειροκίνητα το slider των βημάτων
                  });
                }),
                _slider('Ύπνος', _sleepGoal, 4, 10, 'ώρες', (v) => setState(() => _sleepGoal = v)),
                _slider('Καρδιακός ρυθμός', _hrGoal, 50, 100, 'bpm', (v) => setState(() => _hrGoal = v)),
                _slider('HRV', _hrvGoal, 20, 100, 'ms', (v) => setState(() => _hrvGoal = v)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 25, 96, 25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Ολοκλήρωση'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}