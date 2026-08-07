import 'package:flutter/material.dart';
import 'breathing_exercise_screen.dart';
import 'grounding_technique_screen.dart';

class RelaxScreen extends StatelessWidget {
  const RelaxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('Κέντρο Χαλάρωσης'),
        backgroundColor: const Color.fromARGB(255, 25, 96, 25),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Λίγα λεπτά μόνο για εσένα... διάλεξε μια τεχνική για να αποφορτιστείς από το άγχος της δουλειάς.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              _buildToolCard(
                context: context,
                icon: Icons.air,
                title: 'Πάρε μια ανάσα',
                subtitle: 'Λίγα λεπτά ήρεμης αναπνοής, με τον δικό σου ρυθμό',
                screen: const BreathingExerciseScreen(),
              ),
              const SizedBox(height: 12),
              _buildToolCard(
                context: context,
                icon: Icons.visibility_outlined,
                title: 'Γύρνα στο τώρα',
                subtitle: 'Μια απλή άσκηση για να ηρεμήσεις το μυαλό σου',
                screen: const GroundingTechniqueScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: Color.fromARGB(255, 25, 96, 25), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 25, 96, 25),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }
}