import 'package:firebase_core/firebase_core.dart'; // πακέτο firebase_core για αρχικοποίηση του Firebase
import 'firebase_options.dart'; // αρχείο firebase_options.dart που περιέχει τις ρυθμίσεις για το Firebase ανά πλατφόρμα
import 'package:flutter/material.dart'; // πακέτο flutter/material για να χρησιμοποιήσουμε τα widgets
import 'package:wellness_app/home_screen.dart'; // εισάγουμε το αρχείο home_screen.dart που περιέχει την κύρια οθόνη της εφαρμογής

void main() async{
   WidgetsFlutterBinding.ensureInitialized(); // επιβεβαιώνουμε πως το flutter έχει αρχικοποιηθεί
  await Firebase.initializeApp( // αρχικοποιούμε το Firebase με τις ρυθμίσεις που έχουμε στο αρχείο firebase_options.dart
    options: DefaultFirebaseOptions.currentPlatform, // επιλέγουμε τις ρυθμίσεις ανάλογα με την πλατφόρμα που τρέχει η εφαρμογή
  );
  //Ξεκινάμε την εφαρμογή με το HomeScreen ως αρχική οθόνη
  runApp(MaterialApp( 
    debugShowCheckedModeBanner: false,
    home: HomeScreen(), 
  ));
}
