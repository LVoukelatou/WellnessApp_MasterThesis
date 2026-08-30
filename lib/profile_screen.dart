import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  int? _pss10BaselineScore;
  int? _pss10FollowupScore;

  bool _isLoading = true;
  bool _isSaving = false;

  double _stepsGoal = 10000;
  double _sleepGoal = 8;
  double _hrGoal = 70;
  double _hrvGoal = 50;

  String get _userEmail => FirebaseAuth.instance.currentUser?.email ?? 'Άγνωστο email';


  @override
  void initState() {
    super.initState();
    _loadUserDataGoals();
  }

  Future<void> _loadUserDataGoals() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    final goals = (doc.data()?['goals'] as Map<String, dynamic>?) ?? {};

    final pss10Baseline = data?['pss_baseline'] as Map<String, dynamic>?;
    final pss10Followup = data?['pss_followup'] as Map<String, dynamic>?;

    setState(() {
      _stepsGoal = (goals['steps'] as num?)?.toDouble() ?? 10000;
      _sleepGoal = (goals['sleep_hours'] as num?)?.toDouble() ?? 8.0;
      _hrGoal = (goals['heart_rate'] as num?)?.toDouble() ?? 70;
      _hrvGoal = (goals['hrv'] as num?)?.toDouble() ?? 50;
      _pss10BaselineScore = (pss10Baseline?['score'] as num?)?.toInt();
      _pss10FollowupScore = (pss10Followup?['score'] as num?)?.toInt(); 
      _isLoading = false;
    });
    }

  Future <void> _saveUserDataGoals() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'goals': {
          'steps': _stepsGoal.round(),
          'sleep_hours': _sleepGoal,
          'heart_rate': _hrGoal.round(),
          'hrv': _hrvGoal.round(),
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Οι στόχοι σου ενημερώθηκαν!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Σφάλμα: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _goalSlider(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()} $unit', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color.fromARGB(255, 25, 96, 25),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _signOut() async {
  await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('Το προφίλ μου'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Κάρτα email
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        side: const BorderSide(color: Color.fromARGB(255, 25, 96, 25), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color.fromARGB(255, 25, 96, 25),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Συνδεδεμένος/η ως', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text(_userEmail, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: _signOut,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.logout, color: Colors.red, size: 16),
                                        SizedBox(width: 4),
                                        Text('Αποσύνδεση', style: TextStyle(color: Colors.red, fontSize: 13)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_pss10BaselineScore != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          side: const BorderSide(color: Color.fromARGB(255, 25, 96, 25), width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Αξιολόγηση Στρες (PSS-10)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Αρχική μέτρηση', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      Text('$_pss10BaselineScore/40', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  if (_pss10FollowupScore != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Μετά από 1 μήνα', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        Text('$_pss10FollowupScore/40', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text('Στόχοι Βιοσημάτων', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Προσάρμοσε τους στόχους σου όποτε θέλεις.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    _goalSlider('Βήματα', _stepsGoal, 2000, 20000, 'βήματα', (v) => setState(() => _stepsGoal = v)),
                    _goalSlider('Ύπνος', _sleepGoal, 4, 10, 'ώρες', (v) => setState(() => _sleepGoal = v)),
                    _goalSlider('Καρδιακός ρυθμός', _hrGoal, 50, 100, 'bpm', (v) => setState(() => _hrGoal = v)),
                    _goalSlider('HRV', _hrvGoal, 20, 100, 'ms', (v) => setState(() => _hrvGoal = v)),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveUserDataGoals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 25, 96, 25),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Αποθήκευση'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    ],
                ),
              ),
            ),
    );
  }
}