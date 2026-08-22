import 'package:cloud_firestore/cloud_firestore.dart'; // Για την αλληλεπίδραση με το Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Για τα widgets και το UI
import "health_service.dart"; // Για την ανάκτηση δεδομένων υγείας
import 'api_services.dart'; // Για την επικοινωνία με το Flask API
import 'stress_chart.dart'; // Για το γράφημα του επιπέδου στρες
import 'stress_ring.dart'; // Για το κύκλο του επιπέδου στρες

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key); // Constructor για το HomeScreen

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // private state class για το HomeScreen 
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMorning = true; //Ελέγχουμε αν είναι πρωί ή απόγευμα, για να αλλάζει το κείμενο και οι ερωτήσεις ανάλογα
  bool _isCurrentCheckInOK = false; //Ελέγχουμε αν ο χρήστης έχει κάνει check-in σήμερα

  // Αρχικοποίηση των τιμών για τα vibe checks με μια μέση τιμή 2
  int _vibeCheck1 = 2; 
  int _vibeCheck2 = 2;
  int _vibeCheck3 = 2;
  
  // Μεταβλητές για την αποθήκευση των δεδομένων υγείας που θα ανακτηθούν από το Health Connect
  bool _permissionsGranted = false;
  int _actualSteps = 0;
  double _actualHRV = 0.0;
  double _actualHeartRate = 0.0;
  double _actualSleepHours = 0.0;
  
  // Μεταβλητές για την πρόβλεψη του επιπέδου στρες από το Flask API
  bool _isLoading = false;
  double _backendPredictedStress = 0.0; // Η πρόβλεψη του επιπέδου στρες που λαμβάνουμε από το Flask API
  String _backendInsight = ''; // Η ερμηνεία της πρόβλεψης που λαμβάνουμε από το Flask API
  
  //Ημέρες και μήνες στα Ελληνικά και live ώρα για το header της οθόνης
  final List<String> _days = [
    'Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο', 'Κυριακή',
  ];

  final List<String> _months = [
    'Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου', 'Μαΐου', 'Ιουνίου',
    'Ιουλίου', 'Αυγούστου', 'Σεπτεμβρίου', 'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου',
  ];

  String get _dayName => _days[DateTime.now().weekday - 1]; // Λαμβάνουμε το όνομα της ημέρας από τη λίστα days, αφαιρώντας 1 γιατί η μέθοδος weekday επιστρέφει τιμές από 1 (Δευτέρα) έως 7 (Κυριακή) και θέλουμε αντιστοιχία με τον πίνακα που ξεκινάει από το 0
  String get _monthName => _months[DateTime.now().month - 1]; // αντίστοιχα του μήνα
  String get _formattedDate => '$_dayName, ${DateTime.now().day} $_monthName'; // μορφοποιημένη ημερομηνία για το header της οθόνης, π.χ. "Δευτέρα, 1 Ιανουαρίου"


  @override
  void initState() {
    super.initState();
    // Υπολογίζουμε αν είναι πρωί (από τις 5 μέχρι τις 14 γιατί μπορεί κάποιος να ξεκινάει δουλειά αργά) ή απόγευμα μόλις ανοίγει η οθόνη
    _isMorning =  DateTime.now().hour >= 5 && DateTime.now().hour < 14;
    WidgetsBinding.instance.addPostFrameCallback((context) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fetchAndSyncStarting();}); // Καλούμε τη μέθοδο για να ανακτήσουμε τα δεδομένα υγείας και να ενημερώσουμε τις μεταβλητές της οθόνης
    _hasCompletedCurrentCheckIn();
  }


  // Μέθοδος που ανακτά τα δεδομένα υγείας από το HealthService και ενημερώνει τις μεταβλητές της οθόνης
  Future<void> _fetchAndSyncStarting() async {
    try {
      final healthData = await HealthService.fetchHealthData(); // Καλούμε τη μέθοδο fetchHealthData από το HealthService 
      if (!mounted) return; // αν έχει φύγει ο χρήστης από την οθόνη, δεν ενημερώνουμε το state για να αποφύγουμε σφάλματα
      
      setState(() {
        // Ενημερώνουμε τις μεταβλητές με τα δεδομένα που ανακτήθηκαν, αν δεν υπάρχουν δεδομένα, θέτουμε τις τιμές σε 0 ή 0.0
        bool hasPermissions = healthData['permissionsGranted'] == true;
        if (hasPermissions) {
          _permissionsGranted = true;
          _actualSteps = healthData['steps'] ?? 0;
          _actualHRV = healthData['hrv'] ?? 0.0;
          _actualHeartRate = healthData['heartRate'] ?? 0.0;
          _actualSleepHours = healthData['sleepHours'] ?? 0.0;
        } else {
          _permissionsGranted = false;
        } 
      });

      if (_permissionsGranted) {
       final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
        final goals = (userDoc.data()?['goals'] as Map<String, dynamic>?) ?? {};
        final apiService = ApiService();
        final result = await apiService.predictStress(
        isMorning: _isMorning,
        vibeCheck1: 2,
        vibeCheck2: 2,
        vibeCheck3: 2,
        steps: _actualSteps,
        sleepHours: _actualSleepHours,
        heartRate: _actualHeartRate,
        hrv: _actualHRV,
        stepsTarget: (goals['steps'] as num?)?.toDouble() ?? 10000,
        sleepTarget: (goals['sleep_hours'] as num?)?.toDouble() ?? 8.0,
        hrTarget: (goals['heart_rate'] as num?)?.toDouble() ?? 70,
        hrvTarget: (goals['hrv'] as num?)?.toDouble() ?? 50,
      );

      setState(() {
        _backendPredictedStress = (result['health_score'] as num?)?.toDouble() ?? 0.0; // Λαμβάνουμε την πρόβλεψη στρες από το API και την μετατρέπουμε σε double, αν δεν υπάρχει, θέτουμε 0.0
        _backendInsight = result['insight'] ?? ''; // Λαμβάνουμε την ερμηνεία της πρόβλεψης από το API
      });

      await FirebaseFirestore.instance.collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('check_ins')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'is_morning': _isMorning,
        'is_autoSync': true, // Προσθέτουμε ένα πεδίο για να δείξουμε ότι αυτά τα δεδομένα είναι από αυτόματο συγχρονισμό
        'vibe_data': { 'v1':2, 'v2':2, 'v3': 2 },
        'health_data': { 'steps': _actualSteps, 'heart_rate': _actualHeartRate, 'sleep_hours': _actualSleepHours, 'hrv': _actualHRV },
        'stress_score': _backendPredictedStress,
        'insight': _backendInsight,
      });
      debugPrint('Ο αυτόματος συγχρονισμός και ο υπολογισμός του stress score είναι οκ');
          } else {
        debugPrint('Δεν δόθηκαν οι απαραίτητες άδειες πρόσβασης στα δεδομένα υγείας.');
      }
    } catch (e) {
      debugPrint('Σφάλμα κατά την ανάκτηση δεδομένων υγείας: $e');
      setState(() {
        _permissionsGranted = false; // Αν υπάρχει σφάλμα, σημαίνει ότι δεν έχουμε άδεια πρόσβασης
      });
    }
  }
  // Μέθοδος που επεξεργάζεται το check-in, καλεί το Flask API για πρόβλεψη στρες και αποθηκεύει τα δεδομένα στο Firestore
  Future<void> _processCheckIN() async {
    setState(() {
      _isLoading = true; // Ενεργοποιούμε το loading
    });

    try {
      final apiService = ApiService(); // Δημιουργούμε ένα instance του ApiService για να καλέσουμε το Flask API
      final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
      final goals = (userDoc.data()?['goals'] as Map<String, dynamic>?) ?? {};
      final result = await apiService.predictStress(
        isMorning: _isMorning,
        vibeCheck1: _vibeCheck1,
        vibeCheck2: _vibeCheck2,
        vibeCheck3: _vibeCheck3,
        steps: _actualSteps,
        sleepHours: _actualSleepHours,
        heartRate: _actualHeartRate,
        hrv: _actualHRV,
        stepsTarget: (goals['steps'] as num?)?.toDouble() ?? 10000,
        sleepTarget: (goals['sleep_hours'] as num?)?.toDouble() ?? 8.0,
        hrTarget: (goals['heart_rate'] as num?)?.toDouble() ?? 70,
        hrvTarget: (goals['hrv'] as num?)?.toDouble() ?? 50,
    );

      setState(() {
        _backendPredictedStress = (result['health_score'] as num?)?.toDouble() ?? 0.0; // Λαμβάνουμε την πρόβλεψη στρες από το API και την μετατρέπουμε σε double, αν δεν υπάρχει, θέτουμε 0.0
        _backendInsight = result['insight'] ?? ''; // Λαμβάνουμε την ερμηνεία της πρόβλεψης από το API
      });

      await FirebaseFirestore.instance.collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('check_ins')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'is_morning': _isMorning,
        'vibe_data': { 'v1': _vibeCheck1, 'v2': _vibeCheck2, 'v3': _vibeCheck3 },
        'health_data': { 'steps': _actualSteps, 'heart_rate': _actualHeartRate, 'sleep_hours': _actualSleepHours, 'hrv': _actualHRV },
        'stress_score': _backendPredictedStress,
        'insight': _backendInsight,
      });
      if (!mounted) return; // αν έχει φύγει ο χρήστης από την οθόνη, δεν εμφανίζουμε το SnackBar για να αποφύγουμε σφάλματα
      setState(() {
        _isCurrentCheckInOK = true; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Το Check-in αποθηκεύτηκε!')),
      );

    } catch (e) {
      debugPrint('Σφάλμα κατά την επεξεργασία του check-in: $e');
      if (!mounted) return; // αν έχει φύγει ο χρήστης από την οθόνη, δεν εμφανίζουμε το SnackBar για να αποφύγουμε σφάλματα
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Σφάλμα κατά την επεξεργασία του check-in: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Απενεργοποιούμε το loading indicator
      });
    }
  }
  // Μέθοδος που ανανεώνει τα δεδομένα όταν ο χρήστης κάνει pull-to-refresh
  Future<void> _refreshData() async {
    await _fetchAndSyncStarting(); // Ανακτούμε ξανά τα δεδομένα υγείας και ενημερώνουμε τις μεταβλητές της οθόνης
    await _hasCompletedCurrentCheckIn(); // Ελέγχουμε ξανά αν ο χρήστης έχει κάνει check-in για την τρέχουσα περίοδο
    await Future.delayed(const Duration(seconds: 1)); //κάνουμε ένα μικρό delay για να φαίνεται το refresh indicator
  }
  // Μέθοδος που ελέγχει αν ο χρήστης έχει κάνει check-in για την τρέχουσα περίοδο (πρωί ή απόγευμα)
  Future<void> _hasCompletedCurrentCheckIn() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day); // Ξεκινάμε από τις 00:00 της τρέχουσας ημέρας

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('check_ins')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    bool foundCurrentPeriodCheckIn = false;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      bool isManual = data['is_autoSync'] == null || data['is_autoSync'] == false; // Ελέγχουμε αν το check-in είναι χειροκίνητο (manual) ή αυτόματο (autoSync). Αν δεν υπάρχει το πεδίο is_autoSync, θεωρούμε ότι είναι χειροκίνητο.
      if (isManual && data['is_morning'] == _isMorning) // Ελέγχουμε αν το check-in είναι για την τρέχουσα περίοδο (πρωί ή απόγευμα)
      {
        foundCurrentPeriodCheckIn = true;
        break;
      }
    }
      if (mounted) {
        setState(() {
          _isCurrentCheckInOK = foundCurrentPeriodCheckIn;
        });
    }
  }

  // Μέθοδος που επιστρέφει μήνυμα καλωσορίσματος ανάλογα με την ώρα της ημέρας
  String get _dynamicGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Καλημέρα ☀️';
    } else if (hour < 18) {
      return 'Καλό απόγευμα ☕';
    } else {
      return 'Ώρα για χαλάρωση🌙';
    }
  }

  // Μέθοδος που επιστρέφει μήνυμα ενθάρρυνσης για το check-in ανάλογα με την ώρα της ημέρας
  String get _checkInMotivation {
  if (_isMorning) {
    return 'Μια νέα μέρα ξεκινά! Αφιέρωσε 1 λεπτό για να δούμε πώς είναι η ενέργειά σου σήμερα.';
  } else {
    return 'Η μέρα φτάνει στο τέλος της... Ώρα να αφήσεις την πίεση πίσω σου και να κάνεις μια γρήγορη αποτίμηση.';
  }
  }

  // Μέθοδος που εμφανίζει το dialog για το vibe check
  Future<void> _showVibeCheckDialog() async {

    await showDialog(
      context: context,
      barrierDismissible: false, // Αποτρέπουμε το κλείσιμο του dialog με tap έξω από αυτό
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Μέθοδος που δημιουργεί ένα κουτί επιλογής για τις ερωτήσεις του vibe check
            Widget buildChoiceBox({
              required String text,
              required int value,
              required int groupValue,
              required Function(int) onChanged,
            }) {
              final isSelected = value == groupValue;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setDialogState(() => onChanged(value)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Color.fromARGB(255, 6, 37, 8).withValues(alpha: 0.1) : Colors.transparent,
                      border: Border.all(
                        // Γκρι αν δεν είναι επιλεγμένο, πράσινο αν είναι επιλεγμένο
                        color: isSelected ? Color.fromARGB(255, 6, 37, 8) : Colors.grey.shade400,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0), // Στρογγυλεμένες γωνίες
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Color.fromARGB(255, 6, 37, 8) : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }
            // Επιστρέφουμε το AlertDialog με τις ερωτήσεις και τα κουτιά επιλογής
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                _isMorning ? 'Πρωινό Check-in' : 'Απογευματινό Check-in',
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1η ερώτηση ανάλογα με το αν είναι πρωί ή απόγευμα
                    Text(
                      _isMorning 
                        ? '1. Πώς νιώθεις ξεκινώντας τη μέρα σου;' 
                        : '1. Πώς νιώθεις τώρα που τελείωσε ο κύριος όγκος δουλειάς;',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        buildChoiceBox(
                          text: _isMorning ? 'Χαλαρά' : 'Ανακουφισμένα', //αν είναι πρωί, εμφανίζει το πρώτο κείμενο, αν είναι απόγευμα, εμφανίζει το δεύτερο
                          value: 1, groupValue: _vibeCheck1, onChanged: (val) => _vibeCheck1 = val, //παίρνει την τιμή του κουτιού και την αναθέτει στη μεταβλητή _vibeCheck1
                        ),
                        buildChoiceBox(
                          text: _isMorning ? 'Πιεσμένα' : 'Στην τσίτα',
                          value: 2, groupValue: _vibeCheck1, onChanged: (val) => _vibeCheck1 = val,
                        ),
                        buildChoiceBox(
                          text: _isMorning ? 'Αγχωμένα' : 'Είμαι πτώμα',
                          value: 3, groupValue: _vibeCheck1, onChanged: (val) => _vibeCheck1 = val,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 2η ερώτηση ανάλογα με το αν είναι πρωί ή απόγευμα
                    Text(
                      _isMorning 
                        ? '2. Πόσο βαρύ είναι το σημερινό πρόγραμμα;' 
                        : '2. Νιώθεις σωματική ένταση (π.χ. αυχένα/μέση);',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        buildChoiceBox(
                          text: _isMorning ? 'Ελαφρύ' : 'Καθόλου',
                          value: 1, groupValue: _vibeCheck2, onChanged: (val) => _vibeCheck2 = val,
                        ),
                        buildChoiceBox(
                          text: _isMorning ? 'Μέτριο' : 'Λιγάκι',
                          value: 2, groupValue: _vibeCheck2, onChanged: (val) => _vibeCheck2 = val,
                        ),
                        buildChoiceBox(
                          text: _isMorning ? 'Φουλ' : 'Αρκετά',
                          value: 3, groupValue: _vibeCheck2, onChanged: (val) => _vibeCheck2 = val,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 3η ερώτηση ανάλογα με το αν είναι πρωί ή απόγευμα
                    Text(
                      _isMorning 
                        ? '3. Πώς ξύπνησες;' 
                        : '3. Πόσο εύκολο σου είναι να αποσυνδεθείς τώρα;',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        buildChoiceBox(
                          text: _isMorning ? 'Γεμάτος/η ενέργεια' : 'Εύκολο',
                          value: 1, groupValue: _vibeCheck3, onChanged: (val) => _vibeCheck3 = val,
                        ),
                        buildChoiceBox(
                          text: _isMorning ? 'Θέλω καφέ' : 'Το παλεύω',
                          value: 2, groupValue: _vibeCheck3, onChanged: (val) => _vibeCheck3 = val,
                        ),
                        buildChoiceBox(
                          text: _isMorning ? 'Εξαντλημένος/η' : 'Αδύνατον',
                          value: 3, groupValue: _vibeCheck3, onChanged: (val) => _vibeCheck3 = val,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 6, 37, 8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Κλείνει το dialog
                      _processCheckIN(); // Καλεί τη μέθοδο για να επεξεργαστεί το check-in 
                    },
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Αποθήκευση', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formattedDate, 
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Color.fromARGB(255, 6, 37, 8),
              ),
            ),
            Text(
              _dynamicGreeting,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color.fromARGB(255, 6, 37, 8),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (!_isCurrentCheckInOK)
              Card(
                elevation: 0,
                color: Colors.transparent, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 25, 96, 25), 
                    width: 1.5, 
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(width: double.infinity, height: 10),
                      Text(
                        _checkInMotivation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 6, 37, 8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _showVibeCheckDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 25, 96, 25),
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text('Κάνε Check-in'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20), // Λίγο κενό
              
              StressRing(stressScore: _backendPredictedStress),
              //const StressChart(),
              
              const SizedBox(height: 20),

              if (_backendInsight.isNotEmpty)
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(color: Color.fromARGB(255, 25, 96, 25), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Μια μικρή υπενθύμιση 💡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(_backendInsight, style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
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
}