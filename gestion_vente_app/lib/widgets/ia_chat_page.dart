import 'package:flutter/material.dart';
import '../services/GeminiService.dart';

class IAChatPage extends StatefulWidget {
  const IAChatPage({super.key});

  @override
  _IAChatPageState createState() => _IAChatPageState();
}

class _IAChatPageState extends State<IAChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  void _askQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _isLoading = true;
    });

    _controller.clear();
    FocusScope.of(context).unfocus();

    try {
      final reponse = await GeminiService.askGemini(question);
      setState(() {
        _messages.add(_ChatMessage(text: reponse, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: 'Erreur : ${e.toString()}', isUser: false));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assistant IA")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text("Posez votre question pour commencer la conversation"))
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: message.isUser ? Colors.blueAccent : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _askQuestion(),
                    decoration: InputDecoration(
                      labelText: "Posez votre question",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_controller.text.trim().isEmpty || _isLoading) ? null : _askQuestion,
                  child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
