import os

from dotenv import load_dotenv
from flask import Flask, jsonify, request
from groq import Groq

load_dotenv()  # Διαβάζει το .env αρχείο και ορίζει τα environment variables
app = Flask(__name__)
groq_client = Groq(api_key=os.environ.get("GROQ_API_KEY")) # Το key μπήκε ως environment variable
SYSTEM_PROMPT = """Σημαντικό: Απαντάς αποκλειστικά στα Ελληνικά. Ποτέ μην χρησιμοποιείς λέξεις ή φράσεις από άλλη γλώσσα (αγγλικά, ισπανικά, ή οποιαδήποτε άλλη), ακόμα κι αν σου φαίνονται φυσικές. Αν δεν είσαι σίγουρος/η για μια ελληνική λέξη, χρησιμοποίησε μια πιο απλή εναλλακτική. Είσαι ένας υποστηρικτικός AI coach που βοηθά εργαζόμενους να διαχειριστούν το εργασιακό άγχος και να προάγουν την ψυχική τους ευεξία. Μιλάς με ζεστή, μη-κριτική στάση. Οι απαντήσεις σου πρέπει να είναι σύντομες το πολύ 3-4 προτάσεις. Μην αναπτύσσεις υπερβολικά τις σκέψεις σου. Πάντα ολοκλήρωνε την τελευταία σου πρόταση πλήρως. Δίνεις πρακτικές, σύντομες συμβουλές (τεχνικές αναπνοής, διαχείριση χρόνου, όρια στη δουλειά, mindfulness). Δεν κάνεις διαγνώσεις και δεν αντικαθιστάς επαγγελματία ψυχολόγο/ψυχίατρο. Στο πρώτο μήνυμα, αν είναι η αρχή της συνομιλίας, ενημέρωσε ξεκάθαρα ότι είσαι AI βοηθός, όχι άνθρωπος ή επαγγελματίας υγείας. Λάβε υπόψη το ελληνικό εργασιακό πλαίσιο (π.χ. ωράριο, εργασιακή κουλτούρα, οικογενειακές υποχρεώσεις) όταν δίνεις συμβουλές. Μην υπόσχεσαι λύσεις ή θεραπεία. Χρησιμοποίησε γλώσσα όπως "μπορεί να βοηθήσει" αντί για "θα λύσει". Σημαντικό: Αν ο χρήστης εκφράσει σκέψεις αυτοτραυματισμού, απόγνωσης ή κρίσης, σταμάτα τις συμβουλές άγχους και παρότρυνέ τον άμεσα να επικοινωνήσει με τη Γραμμή Ψυχολογικής Υποστήριξης 1018 (δωρεάν, 24/7, Ελλάδα) ή να απευθυνθεί σε ειδικό/επείγοντα."""

@app.route('/analyze_stress', methods=['POST'])
def analyze_stress():
    try:
        data = request.get_json()
        survey = data.get('survey', {}) # Χρησιμοποιούμε {} για να επιστρέψουμε ένα κενό λεξικό αν δεν υπάρχει το κλειδί
        health = data.get('health', {})
        
        v1 = survey.get('v1', 2) # Αν δεν υπάρχει το κλειδί 'v1', επιστρέφουμε μια ασφαλή τιμή
        v2 = survey.get('v2', 2)  
        v3 = survey.get('v3', 2)
        
        steps = health.get('steps') # κενό αν δεν υπάρχει το κλειδί 'steps'
        sleep_hours = health.get('sleep_hours') 
        heart_rate = health.get('heart_rate') 
        hrv = health.get('hrv')
        
        steps_goal = data.get('steps_goal', 10000)
        sleep_goal = data.get('sleep_goal', 8.0)
        hr_goal = data.get('hr_goal', 70)
        hrv_goal = data.get('hrv_goal', 50)
        is_morning = data.get('is_morning', True) # Αν δεν υπάρχει το κλειδί 'is_morning', επιστρέφουμε True
        
        # Υπολογισμός του δείκτη στρες
        
        # Υποκειμενικός δείκτης από τα Check-in ερωτηματολόγια (v1, v2, v3) κανονικοποιημένα σε κλίμακα 0-10
        checkIn_average = (v1 + v2 + v3) / 3
        subjective_score = ((checkIn_average - 1) / 2)*10  # Μετατρέπουμε την κλίμακα 1-3 σε 0-10
        
        # Αντικειμενικός δείκτης από τα δεδομένα υγείας (βήματα, ύπνος, καρδιακός ρυθμός, μεταβλητότητα καρδιακού ρυθμού) κανονικοποιημένα σε κλίμακα 0-10
        objective_parameters = []
        if steps is not None:
            steps_parameter = 1 - min(1, steps / steps_goal) # μειώνουμε τον δείκτη στρες όσο περισσότερα βήματα έχει κάνει ο χρήστης
            objective_parameters.append(steps_parameter)
        
        if sleep_hours is not None:
            sleep_parameters = 1 - min(1, sleep_hours / sleep_goal) # αντίστοιχη μείωση εδώ
            objective_parameters.append(sleep_parameters)
        
        if heart_rate is not None:
            heart_rate_parameter = min(heart_rate / hr_goal, 1.0) # αυξάνουμε τον δείκτη στρες όσο υψηλότερος είναι ο καρδιακός ρυθμός
            objective_parameters.append(heart_rate_parameter)
            
        if hrv is not None:
            hrv_parameter = 1 - min(hrv / hrv_goal, 1.0) # μείωση και εδώ
            objective_parameters.append(hrv_parameter)
        
        if len(objective_parameters) > 0:
            total = 0
            for parameter in objective_parameters:
                total += parameter
            objective_score = (total / len(objective_parameters)) * 10 # κανονικοποιούμε σε κλίμακα 0-10
            
            final_score = (subjective_score + objective_score) / 2 # συνδυάζουμε τους δύο δείκτες με ίσο βάρος
        else:
            final_score = subjective_score # αν δεν υπάρχουν αντικειμενικά δεδομένα, χρησιμοποιούμε μόνο τον υποκειμενικό δείκτη
            
        health_score = max(0.0, min(10.0, final_score)) # πρακτικά αδύνατο αλλά για ασφάλεια που γίνει κάποια μελλοντική αλλαγή στον υπολογισμό, περιορίζουμε το score στο εύρος 0-10

        if is_morning:
            if health_score <= 4:
                insight = "Ξεκινάς τη μέρα σου με υπέροχο vibe! Το σώμα σου είναι ξεκούραστο και οι παλμοί σου ήρεμοι. Κράτα αυτή τη θετική ενέργεια!"
            elif health_score <= 7: 
                insight = "Η μέρα έχει μέτρια πίεση σήμερα... αλλά το πας πολύ καλά. Θυμήσου να πίνεις νερό και να παίρνεις μικρές ανάσες ανάμεσα στις υποχρεώσεις σου."
            else:
                insight = "Φαίνεται πως η μέρα ξεκίνησε με αρκετή πίεση. Μην ξεχνάς... ένα βήμα τη φορά. Αν μπορείς, κάνε ένα 5λεπτο διάλειμμα τώρα αμέσως για να αποφορτιστείς."
        else:
            if health_score <= 4:
                insight = "Η μέρα κλείνει με πολύ όμορφο τρόπο. Το σώμα και το μυαλό βρίσκονται σε κατάσταση ηρεμίας, ιδανική για χαλάρωση και καλό ύπνο."
            elif health_score <= 7:
                insight = "Μια γεμάτη μέρα ολοκληρώθηκε. Ώρα να αφήσεις στην άκρη τις εκκρεμότητες και να χαρίσεις στον εαυτό σου λίγο χρόνο αποφόρτισης."
            else:
                insight = "Η πίεση της ημέρας ήταν έντονη. Δώσε άμεση προτεραιότητα στην αποσυμπίεση... δoκίμασε μερικές βαθιές αναπνοές και αποσυνδέσου από τις οθόνες."
            
        return jsonify({"health_score": round(health_score, 1), "insight": insight}), 200 #επιστρέφουμε το αποτέλεσμα σε μορφή JSON, με το health_score στρογγυλοποιημένο στο πρώτο δεκαδικό ψηφίο
   
    except Exception as e:  # noqa: BLE001
        print("Σφάλμα στον υπολογισμό:", e)
        return jsonify({"error": str(e)}), 400

@app.route('/ai_coach', methods=['POST'])
def ai_coach():
    data = request.json # παίρνουμε το request που έστειλε το flutter
    user_message = data.get('message', '') # παίρνουμε μόνο την τιμή του κλειδιού message και την βάζουμε σε string, το αφήνουμε κενό εάν δεν υπάρχει μήνυμα
    history = data.get('history', [])  # παίρνουμε το history αντίστοιχα σε λίστα

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    messages.extend(history) # λίστα με όλο το ιστορικό συνομιλίας
    messages.append({"role": "user", "content": user_message})

    try:
        completion = groq_client.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=messages, # ολόκληρη την λίστα με το ιστορικό
            temperature=0.5, # ζητάμε μια οχι πολύ απρόβλεπτη/δημιουργική απάντηση (0-1 κλιμακα)
            max_tokens=800, # αρκετά για να μη κόβει απότομα την απάντηση
        )
        reply = completion.choices[0].message.content # παίρνουμε την 1η από την λίστα απαντήσεων, το μήνυμά της και το περιεχόμενο κειμένου
        return jsonify({"reply": reply})
    except Exception as e:  # noqa: BLE001
        print("Σφάλμα AI Coach:", e)
        return jsonify({"error": str(e)}), 500
    
# Εκκίνηση του Flask 
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)