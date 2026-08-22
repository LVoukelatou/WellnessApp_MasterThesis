from flask import Flask, request, jsonify
import os
from groq import Groq

from dotenv import load_dotenv
load_dotenv()  # Διαβάζει το .env αρχείο και ορίζει τα environment variables
app = Flask(__name__)
groq_client = Groq(api_key=os.environ.get("GROQ_API_KEY")) # Το key μπήκε ως environment variable
SYSTEM_PROMPT = """Είσαι ένας υποστηρικτικός AI coach που βοηθά εργαζόμενους να διαχειριστούν το εργασιακό άγχος και να προάγουν την ψυχική τους ευεξία. Μιλάς στα Ελληνικά, με ζεστή, μη-κριτική στάση. Δίνεις πρακτικές, σύντομες συμβουλές (τεχνικές αναπνοής, διαχείριση χρόνου, όρια στη δουλειά, mindfulness). ΔΕΝ κάνεις διαγνώσεις και δεν αντικαθιστάς επαγγελματία ψυχολόγο/ψυχίατρο. Στο πρώτο μήνυμα, αν είναι η αρχή της συνομιλίας, ενημέρωσε ξεκάθαρα ότι είσαι AI βοηθός, όχι άνθρωπος ή επαγγελματίας υγείας. Λάβε υπόψη το ελληνικό εργασιακό πλαίσιο (π.χ. ωράριο, εργασιακή κουλτούρα, οικογενειακές υποχρεώσεις) όταν δίνεις συμβουλές. Μην υπόσχεσαι λύσεις ή θεραπεία. Χρησιμοποίησε γλώσσα όπως "μπορεί να βοηθήσει" αντί για "θα λύσει". Σημαντικό: Αν ο χρήστης εκφράσει σκέψεις αυτοτραυματισμού, απόγνωσης ή κρίσης, ΣΤΑΜΑΤΑ τις συμβουλές άγχους και παρότρυνέ τον άμεσα να επικοινωνήσει με τη Γραμμή Ψυχολογικής Υποστήριξης 1018 (δωρεάν, 24/7, Ελλάδα) ή να απευθυνθεί σε ειδικό/επείγοντα."""

@app.route('/analyze_stress', methods=['POST'])
def analyze_stress():
    try:
        data = request.get_json()
        survey = data.get('survey', {}) # Χρησιμοποιούμε {} για να επιστρέψουμε ένα κενό λεξικό αν δεν υπάρχει το κλειδί
        health = data.get('health', {})
        
        v1 = survey.get('v1', 2) # Αν δεν υπάρχει το κλειδί 'v1', επιστρέφουμε μια ασφαλή τιμή
        v2 = survey.get('v2', 2)  
        v3 = survey.get('v3', 2)
        
        steps = health.get('steps', 0) # Αν δεν υπάρχει το κλειδί 'steps', επιστρέφουμε 0
        sleep_hours = health.get('sleep_hours', 0.0) 
        heart_rate = health.get('heart_rate', 70.0)  # Αν δεν υπάρχει το κλειδί 'heart_rate', επιστρέφουμε 70.0 και έτσι στην διαίρεση θα έχουμε 1
        hrv = health.get('hrv', 50.0) # Αν δεν υπάρχει το κλειδί 'hrv', επιστρέφουμε 50.0 και έτσι στην διαίρεση θα έχουμε 1
        steps_goal = data.get('steps_goal', 10000)
        sleep_goal = data.get('sleep_goal', 8.0)
        hr_goal = data.get('hr_goal', 70)
        hrv_goal = data.get('hrv_goal', 50)
        is_morning = data.get('is_morning', True) # Αν δεν υπάρχει το κλειδί 'is_morning', επιστρέφουμε True
        
        # Υπολογισμός του δείκτη στρες
         
        # Τα αποτελέσματα του survey είναι από 1 έως 3, τα πολλαπλασιάζουμε με 2.5 για να τα απλώσουμε σε κλίμακα 1-7.5
        # Τα βήματα και οι ώρες ύπνου μειώνουν τον δείκτη στρες, ενώ ο καρδιακός ρυθμός και η μεταβλητότητα του καρδιακού ρυθμού τον αυξάνουν
        stress_index = (((v1 + v2 + v3) / 3)*2.5) - (steps / steps_goal) - (sleep_hours / sleep_goal) + (heart_rate / hr_goal) - (hrv / hrv_goal)
        health_score = max(0.0, min(10.0, stress_index))  # Περιορίζουμε το αποτέλεσμα σε κλίμακα 0-10
        
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
   
    except Exception as e:
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
            temperature=0.7, # ζητάμε μια πιο δημιουργική απάντηση (0-1 κλιμακα)
            max_tokens=500, # περίπου 350-400 λέξεις
        )
        reply = completion.choices[0].message.content # παίρνουμε την 1η από την λίστα απαντήσεων, το μήνυμά της και το περιεχόμενο κειμένου
        return jsonify({"reply": reply})
    except Exception as e:
        print("Σφάλμα AI Coach:", e)
        return jsonify({"error": str(e)}), 500
    
# Εκκίνηση του Flask 
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)