import 'package:flutter/material.dart';

class GroundingTechniqueScreen extends StatefulWidget {
  const GroundingTechniqueScreen({Key? key}) : super(key: key);

  @override
  State<GroundingTechniqueScreen> createState() => _GroundingTechniqueScreenState();
}

class _GroundingStep {
  final String number;
  final String instruction;
  final IconData icon;

  const _GroundingStep({required this.number, required this.instruction, required this.icon});
}

class _GroundingTechniqueScreenState extends State<GroundingTechniqueScreen> {
  int _currentStep = 0;

  final List<_GroundingStep> _steps = const [
    _GroundingStep(number: '5', instruction: 'πράγματα που μπορείς να δεις', icon: Icons.visibility),
    _GroundingStep(number: '4', instruction: 'πράγματα που μπορείς να αγγίξεις', icon: Icons.back_hand),
    _GroundingStep(number: '3', instruction: 'πράγματα που μπορείς να ακούσεις', icon: Icons.hearing),
    _GroundingStep(number: '2', instruction: 'πράγματα που μπορείς να μυρίσεις', icon: Icons.air),
    _GroundingStep(number: '1', instruction: 'πράγμα που μπορείς να γευτείς', icon: Icons.restaurant),
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      setState(() => _currentStep = 0); // restart
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('Γύρνα στο τώρα'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Βήμα ${_currentStep + 1} από ${_steps.length}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color.fromARGB(255, 25, 96, 25).withOpacity(0.15),
                        child: Icon(step.icon, size: 50, color: const Color.fromARGB(255, 25, 96, 25)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.number,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 6, 37, 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Πρόσεξε γύρω σου... βρες ${step.number} ${step.instruction}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 25, 96, 25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentStep < _steps.length - 1 ? 'Επόμενο' : 'Ξανά από την αρχή',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}