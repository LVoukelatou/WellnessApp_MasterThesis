import 'dart:async';
import 'package:flutter/material.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

enum BreathPhase { inhale, holdFull, exhale, holdEmpty }

// Η οθόνη για την άσκηση αναπνοής
class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; 
  late Animation<double> _scaleAnimation;

  BreathPhase _currentPhase = BreathPhase.inhale;
  bool _isRunning = false;
  int _completedCycles = 0;
  Timer? _phaseTimer;

  static const int _phaseSeconds = 4; // διάρκεια κάθε φάσης σε δευτερόλεπτα

  final Map<BreathPhase, String> _phaseLabels = {
    BreathPhase.inhale: 'Εισπνοή',
    BreathPhase.holdFull: 'Κράτησε',
    BreathPhase.exhale: 'Εκπνοή',
    BreathPhase.holdEmpty: 'Κράτησε',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // συγχρονίζει το animation με τον ρυθμό ανανέωσης της οθόνης, και το σταματάει αυτόματα όταν η οθόνη δεν είναι ορατή
      duration: const Duration(seconds: _phaseSeconds),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  // Ξεκινάει την άσκηση αναπνοής
  void _startExercise() {
    setState(() {
      _isRunning = true;
      _currentPhase = BreathPhase.inhale;
      _completedCycles = 0;
    });
    _runPhase();
  }
  // Σταματάει την άσκηση αναπνοής
  void _stopExercise() {
    _phaseTimer?.cancel();
    _controller.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _runPhase() {
    if (!_isRunning) return;

    // Ελέγχουμε ποια φάση είναι και ξεκινάμε το animation ανάλογα
    switch (_currentPhase) {
      case BreathPhase.inhale:
        _controller.forward(from: 0.0); // κύκλος μεγαλώνει
        break;
      case BreathPhase.holdFull:
        // παραμένει μεγάλος
        break;
      case BreathPhase.exhale:
        _controller.reverse(from: 1.0); // κύκλος μικραίνει
        break;
      case BreathPhase.holdEmpty:
        // παραμένει μικρός
        break;
    }

    _phaseTimer = Timer(const Duration(seconds: _phaseSeconds), () {
      if (!mounted || !_isRunning) return;
      setState(() {
        _currentPhase = _nextPhase(_currentPhase);
        if (_currentPhase == BreathPhase.inhale) {
          _completedCycles++; // ολοκληρώθηκε ένας κύκλος
        }
      });
      _runPhase();
    });
  }
  // Επιστρέφει την επόμενη φάση της αναπνοής
  BreathPhase _nextPhase(BreathPhase current) {
    switch (current) {
      case BreathPhase.inhale:
        return BreathPhase.holdFull;
      case BreathPhase.holdFull:
        return BreathPhase.exhale;
      case BreathPhase.exhale:
        return BreathPhase.holdEmpty;
      case BreathPhase.holdEmpty:
        return BreathPhase.inhale;
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('Πάρε μια ανάσα'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Ακολούθησε τον κύκλο, με τον δικό σου ρυθμό',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            if (_isRunning)
              Text(
                'Κύκλοι: $_completedCycles',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 250 * _scaleAnimation.value,
                      height: 250 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 25, 96, 25),
                        border: Border.all(
                          color: const Color.fromARGB(255, 25, 96, 25),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isRunning ? _phaseLabels[_currentPhase]! : 'Ξεκίνα',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 6, 37, 8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRunning ? _stopExercise : _startExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Colors.grey.shade700
                        : const Color.fromARGB(255, 25, 96, 25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isRunning ? 'Σταμάτα όποτε θες' : 'Ξεκίνα όταν είσαι έτοιμος/η',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}