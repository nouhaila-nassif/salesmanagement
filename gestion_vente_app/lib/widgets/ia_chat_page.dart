import 'dart:io' show File; // Mobile uniquement
import 'dart:typed_data'; // Pour Uint8List sur Web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../services/GeminiService.dart';

class AskAIScreen extends StatefulWidget {
  const AskAIScreen({super.key});

  @override
  State<AskAIScreen> createState() => _AskAIScreenState();
}

class _AskAIScreenState extends State<AskAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  File? selectedAudioFile; // Mobile
  Uint8List? webAudioBytes; // Web
  String? webFileName; // Nom du fichier audio sur Web

  bool isRecording = false;
  bool isLoading = false;
  String response = "";

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initRecorder();
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _recorder.closeRecorder();
    }
    _controller.dispose();
    super.dispose();
  }

  /// ▶️ Enregistrement audio (mobile uniquement)
  Future<void> _startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enregistrement audio non pris en charge sur le Web.")),
      );
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone non autorisé.")),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/recorded_audio.wav';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );

    setState(() {
      isRecording = true;
      selectedAudioFile = null;
    });
  }

  /// ⏹️ Arrêt enregistrement (mobile uniquement)
  Future<void> _stopRecording() async {
    if (kIsWeb) return;
    final filePath = await _recorder.stopRecorder();
    if (filePath != null) {
      setState(() {
        isRecording = false;
        selectedAudioFile = File(filePath);
      });
    }
  }

  /// 🎵 Sélectionner un fichier audio
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      if (kIsWeb) {
        setState(() {
          webAudioBytes = result.files.single.bytes;
          webFileName = result.files.single.name;
        });
      } else if (result.files.single.path != null) {
        setState(() {
          selectedAudioFile = File(result.files.single.path!);
        });
      }
    }
  }

  /// 🤖 Envoyer la requête à l'IA
  Future<void> _sendToIA() async {
    final question = _controller.text.trim();

    if (question.isEmpty && selectedAudioFile == null && webAudioBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entrez une question ou ajoutez un audio.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      response = "";
    });

    try {
    final result = await GeminiService.askGemini(
  query: question.isNotEmpty ? question : null,
  audioFile: kIsWeb ? null : selectedAudioFile,
  webAudioBytes: kIsWeb ? webAudioBytes : null,
  webFileName: kIsWeb ? webFileName : null,
);


      setState(() => response = result);
    } catch (e) {
      setState(() => response = "Erreur : ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant IA"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Pose ta question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: kIsWeb
                      ? null
                      : (isRecording ? _stopRecording : _startRecording),
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  label: Text(kIsWeb
                      ? "Indispo Web"
                      : isRecording
                          ? "Stop"
                          : "Enregistrer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.red : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickAudioFile,
                  icon: const Icon(Icons.audiotrack),
                  label: const Text("Fichier audio"),
                ),
              ],
            ),

            if (!kIsWeb && selectedAudioFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Audio sélectionné : ${selectedAudioFile!.path.split('/').last}",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),

            if (kIsWeb && webAudioBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Fichier sélectionné (Web) : $webFileName",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isLoading ? null : _sendToIA,
              icon: const Icon(Icons.send),
              label: const Text("Envoyer"),
            ),

            const SizedBox(height: 20),

            if (isLoading) const Center(child: CircularProgressIndicator()),

            if (response.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    "💬 Réponse IA :\n$response",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
