import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigationBar.dart';

class Pss10Screen extends StatefulWidget {
  const Pss10Screen({super.key});

  @override
  State<Pss10Screen> createState() => _Pss10ScreenState();
}

class _Pss10ScreenState extends State<Pss10Screen> {
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  final List<int?> _answers = List.filled(10, null);
  final List<String> _questions = [
    'Τον τελευταίο μήνα, πόσο συχνά αναστατωθήκατε επειδή κάτι συνέβη απροσδόκητα;',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε ανίκανος(η) να ελέγξετε τα σημαντικά πράγματα στη ζωή σας;',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε  νευρικός(η) και "αγχωθήκατε";',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε  σιγουριά για την ικανότητα σας να χειριστείτε προσωπικά  προβλήματά;',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε  ότι όλα πήγαιναν όπως τα θέλετε;',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε ότι δεν θα μπορούσατε να αντιμετωπίσετε όλα όσα έπρεπε να κάνετε;',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε ικανός να ελέγξετε διάφορα ερεθίσματα (προκλήσεις) στη ζωή σας;',
    'Τον τελευταίο  μήνα, πόσο συχνά νοιώσατε ότι είστε “κύριος(α)” των καταστάσεων;',
    'Τον τελευταίο  μήνα, πόσο συχνά οργιστήκατε επειδή τα πράγματα ξέφυγαν από τον έλεγχο σας;',
    'Τον τελευταίο  μήνα, πόσο συχνά έχετε νοιώσατε  ότι συσσωρεύτηκαν τόσες δυσκολίες σε σημείο που δεν θα μπορούσατε να τις ξεπεράσετε;',
  ];
  final List<int> _questionsToReverse = [
    3,
    4,
    6,
    7,
  ]; // ερωτήσεις που χρειάζονται αντίστροφη βαθμολόγηση (0->4, 1->3, 2->2, 3->1, 4->0)
  final List<String> _answerLabels = [
    'Ποτέ',
    'Σπάνια',
    'Μερικές φορές',
    'Αρκετά συχνά',
    'Πολύ συχνά',
  ];

  void _setAnswer(int answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (_currentQuestionIndex < 9) {
        setState(() {
          _currentQuestionIndex = _currentQuestionIndex + 1;
        });
      } else {
        _finishPss10();
      }
    });
  }

  // Υπολογισμός του συνολικού σκορ PSS-10
  int _calculateTotalScore() {
    int score = 0;
    for (int i = 0; i < 10; i++) {
      int answerValue = _answers[i]!;
      bool needsReverse = _questionsToReverse.contains(i);
      if (needsReverse) {
        int reversedValue = 4 - answerValue; //κάνουμε την αντιστροφή
        score = score + reversedValue;
      } else {
        score = score + answerValue;
      }
    }
    return score;
  }

  Future<void> _finishPss10() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final totalScore = _calculateTotalScore();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'pss_baseline': {
          'score': totalScore,
          'completed_at': FieldValue.serverTimestamp(),
        },
        'onboarding_completed': true,
      }, SetOptions(merge: true));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Navigationbar()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Κάτι πήγε στραβά, δοκίμασε ξανά σε λίγο. Σφάλμα: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionText = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: Text('Σχεδόν έτοιμοι...'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Αυτές οι 10 σύντομες ερωτήσεις μας βοηθούν να καταλάβουμε καλύτερα πώς νιώθεις γενικά τον τελευταίο καιρό. Απάντησε αυθόρμητα, δεν υπάρχουν σωστές ή λάθος απαντήσεις.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: const Color.fromARGB(255, 223, 215, 215),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ερώτηση ${_currentQuestionIndex + 1} από 10',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 25, 96, 25),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              questionText,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildAnswerButton(0),
                            _buildAnswerButton(1),
                            _buildAnswerButton(2),
                            _buildAnswerButton(3),
                            _buildAnswerButton(4),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(int answerValue) {
    bool isSelected = _answers[_currentQuestionIndex] == answerValue;
    String label = _answerLabels[answerValue];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () => _setAnswer(answerValue),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromARGB(255, 25, 96, 25)
                : Colors.transparent,
            border: Border.all(
              color: const Color.fromARGB(255, 25, 96, 25),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}
