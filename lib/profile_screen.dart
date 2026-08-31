import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _isSigningOut = false; 
  bool _isDeleting = false;
  bool _googleSignInInitialized = false;

  double _stepsGoal = 10000;
  double _sleepGoal = 8;
  double _hrGoal = 70;
  double _hrvGoal = 50;

  String get _userEmail => FirebaseAuth.instance.currentUser?.email ?? 'Άγνωστο email';

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    }
  }

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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Φαίνεται να έχεις αποσυνδεθεί, δοκίμασε ξανά μετά τη σύνδεση.')),
        );
      }
      return;
    }

  setState(() => _isSaving = true);
  final uid = currentUser.uid;

    try {
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
    setState(() => _isSigningOut = true);
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _confirmAndDeleteAccount() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Διαγραφή λογαριασμού'),
      content: const Text(
        'Αυτή η ενέργεια είναι μόνιμη. Θα διαγραφεί ο λογαριασμός σου και όλα τα δεδομένα σου (ιστορικό check-ins, στόχοι, αξιολογήσεις PSS-10). Δεν μπορεί να αναιρεθεί. Είσαι σίγουρος/η;',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Άκυρο'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Διαγραφή', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    _deleteAccount();
  }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      await _doDelete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Το Firebase θέλει νέα επαλήθευση πριν επιτρέψει διαγραφή
        final reauthenticated = await _reauthenticate();
        if (reauthenticated) {
          try {
            await _doDelete();
          } catch (e2) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Σφάλμα: $e2')));
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Σφάλμα: ${e.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Σφάλμα: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // Διαγράφει πρώτα τα δεδομένα Firestore και μετά τον ίδιο τον λογαριασμό
  Future<void> _doDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Διαγραφή του collection με ενα εν τα check_ins
    final checkIns = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('check_ins').get();
    for (final doc in checkIns.docs) {
      await doc.reference.delete();
    }

    // Διαγραφή του κυρίως document
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    // Διαγραφή του ίδιου του λογαριασμού
    await user.delete();
  }

  // Ζητάει από τον χρήστη να ξαναεπιβεβαιώσει την ταυτότητά του
  Future<bool> _reauthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');

    if (isGoogleUser) {
      // re-authentication μέσω Google
      try {
        await _ensureGoogleSignInInitialized();
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
        await user.reauthenticateWithCredential(credential);
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Η επιβεβαίωση απέτυχε.')));
        }
        return false;
      }
    } else {
      // re-authentication μέσω email/password ζητάμε τον κωδικό ξανά
      final password = await _askForPassword();
      if (password == null || password.isEmpty) return false;

      try {
        final credential = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        return true;
      } on FirebaseAuthException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Λάθος κωδικός.')));
        }
        return false;
      }
    }
  }

  Future<String?> _askForPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Επιβεβαίωση κωδικού'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Κωδικός'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Άκυρο')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Συνέχεια')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('Το προφίλ μου'),
        backgroundColor: const Color.fromARGB(255, 25, 96, 25),
        foregroundColor: Colors.white,
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
                                      children: [
                                        if (_isSigningOut)
                                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                        else
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
                    Center(
                      child: TextButton(
                        onPressed: _isDeleting ? null : _confirmAndDeleteAccount,
                        child: _isDeleting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('Διαγραφή λογαριασμού', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                      ),
                    ),
                    ],
                ),
              ),
            ),
    );
  }
}