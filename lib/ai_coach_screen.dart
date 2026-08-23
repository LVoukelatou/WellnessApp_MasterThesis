import 'package:flutter/material.dart';
import 'ai_coach_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser}); 
}

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({Key? key}) : super(key: key);

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _service = AiCoachService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickReplies = [
    'Νιώθω αγχωμένη/ος σήμερα',
    'Χρειάζομαι tips για διάλειμμα',
    'Πώς να θέσω όρια στη δουλειά;',
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();
    final history = _buildRecentHistory();

    // στέλνουμε το μήνυμα στο service και περιμένουμε την απάντηση
    try {
      final reply = await _service.sendMessage(text, history);
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Συγγνώμη, υπήρξε πρόβλημα σύνδεσης. Δοκίμασε ξανά.',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  } 
  // φτιάχνουμε το ιστορικό με τα τελευταία 10 μηνύματα για το context πλην του πιο πρόσφατου (αυτό στέλνεται ξεχωριστά ως τρέχον μήνυμα)
      List<Map<String, String>> _buildRecentHistory() {

    // αφαιρούμε το τελευταίο μήνυμα από τη λίστα
    List<ChatMessage> messagesWithoutLast = [];
    for (int i = 0; i < _messages.length - 1; i++) {
      messagesWithoutLast.add(_messages[i]);
    }

    // κρατάμε τα τελευταία 10
    List<ChatMessage> lastTenMessages = [];
    int startIndex = messagesWithoutLast.length > 10 ? messagesWithoutLast.length - 10 : 0;
    for (int i = startIndex; i < messagesWithoutLast.length; i++) {
      lastTenMessages.add(messagesWithoutLast[i]);
    }

    // τα μετατρέπουμε σε μορφή που καταλαβαίνει το Groq
    List<Map<String, String>> history = [];
    for (final message in lastTenMessages) {
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    return history;
  }  
  // Scroll στο τέλος του chat όταν έρχεται νέο μήνυμα
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 215),
      appBar: AppBar(
        title: const Text('AI Coach'),
        backgroundColor: const Color.fromARGB(255, 25, 96, 25),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Γεια! Πώς νιώθεις σήμερα;',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? const Color.fromARGB(255, 25, 96, 25)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: message.isUser ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Γρήγορες απαντήσεις
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var reply in _quickReplies)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(reply),
                      backgroundColor: Colors.white,
                      onPressed: _isLoading ? null : () => _sendMessage(reply),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ελεύθερο πεδίο για να γράψει ο χρήστης
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Γράψε κάτι...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 25, 96, 25),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}