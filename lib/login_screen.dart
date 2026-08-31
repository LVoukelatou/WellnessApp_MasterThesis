import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
//Firebase Authentication για να ελέγξουμε τα στοιχεία του χρήστη. Αν ο χρήστης δεν έχει λογαριασμό, μπορεί να μεταβεί στην οθόνη εγγραφής (SignUpScreen).
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

// Η μέθοδος _signIn ελέγχει τα στοιχεία του χρήστη με το Firebase Authentication. Αν τα στοιχεία είναι σωστά, ο χρήστης συνδέεται και το StreamBuilder στο main.dart θα εμφανίσει το HomeScreen. Αν τα στοιχεία είναι λάθος, εμφανίζεται μήνυμα σφάλματος.
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(), // Χρησιμοποιούμε το trim() για να αφαιρέσουμε τυχόν κενά πριν και μετά το email
        password: _password.text.trim(), //αντίστοιχα
      );
      
    } on FirebaseAuthException catch (e){
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Δεν βρέθηκε λογαριασμός με αυτό το email.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'Λάθος email ή κωδικός.';
        } else {
          _errorMessage = 'Σφάλμα: ${e.message}';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
Future <void> _resetPassword () async {
  if (_email.text.trim().isEmpty) {
    setState(() {
      _errorMessage = 'Γράψε πρώτα το email σου παραπάνω, για να σου στείλουμε σύνδεσμο επαναφοράς.';
    });
    return;
  }
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Σου στείλαμε email με οδηγίες επαναφοράς κωδικού 📩')));
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      if (e.code == 'user-not-found') {
        _errorMessage = 'Δεν βρέθηκε λογαριασμός με αυτό το email.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Το email δεν φαίνεται έγκυρο.';
      } else {
        _errorMessage = 'Σφάλμα: ${e.message}';
      }
    });
  } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Σύνδεση με τον λογαριασμό Google
  bool _googleSignInInitialized = false;

Future<void> _ensureGoogleSignInInitialized() async {
  if (!_googleSignInInitialized) {
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }
}

Future<void> _signInWithGoogle() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // πρέπει να αρχικοποιηθεί πρώτα μία φορά
    await _ensureGoogleSignInInitialized();

    // ανοίγει το παράθυρο επιλογής λογαριασμού Google
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

    //παίρνουμε το idToken
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // credential με idToken
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // σύνδεση στο Firebase
    await FirebaseAuth.instance.signInWithCredential(credential);

  } on GoogleSignInException catch (e) {
    // Ο χρήστης ακύρωσε ή άλλο σφάλμα Google Sign In
    if (e.code != GoogleSignInExceptionCode.canceled) {
      setState(() {
        _errorMessage = 'Σφάλμα σύνδεσης Google.';
      });
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      _errorMessage = 'Σφάλμα σύνδεσης Google: ${e.message}';
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Κάτι πήγε στραβά. Δοκίμασε ξανά.';
    });
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Καλώς ήρθες',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 6, 37, 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Συνδέσου για να συνεχίσεις',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Κωδικός',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Ξέχασες τον κωδικό;', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 25, 96, 25),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Σύνδεση', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ή', style: TextStyle(color: Colors.grey.shade600)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.asset('assets/google_logo.png', height: 24),
                      label: const Text('Σύνδεση με Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text('Δεν έχεις λογαριασμό; Εγγραφή'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}