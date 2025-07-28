import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html; // pour MediaRecorder JS

import '../services/GeminiService.dart';

class AskAIScreen extends StatefulWidget {
  const AskAIScreen({super.key});

  @override
  State<AskAIScreen> createState() => _AskAIScreenState();
}

class _AskAIScreenState extends State<AskAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  MediaStream? _localStream;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _chunks = [];

  File? selectedAudioFile;
  Uint8List? webAudioBytes;
  String? webFileName;

  bool isRecording = false;
  bool isLoading = false;
  bool isTyping = false;
  String transcription = "";
  String iaResponse = "";

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initRecorder();
    }
    _messages.add(_ChatMessage(
      sender: "IA",
      message: "Bonjour ! Comment puis-je vous aider aujourd'hui ?",
      timestamp: DateTime.now(),
      isAI: true,
    ));
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
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Fonction utilitaire pour obtenir le MediaStream JS natif
 dynamic _getNativeMediaStream(MediaStream stream) {
  // Essaie d'abord 'jsStream' (flutter_webrtc Web)
  return js_util.getProperty(stream, 'jsStream') ??
         js_util.getProperty(stream, 'mediaStream') ??
         js_util.getProperty(stream, 'nativeStream') ??
         stream;
}

  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        // Enregistrement Web via flutter_webrtc + MediaRecorder JS
        final mediaConstraints = {'audio': true, 'video': false};

        _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

        _chunks = [];

        final jsStream = _getNativeMediaStream(_localStream!);
_mediaRecorder = html.MediaRecorder(jsStream);


        _mediaRecorder!.addEventListener('dataavailable', (event) {
          final blobEvent = event as html.BlobEvent;
          if (blobEvent.data != null) {
            _chunks.add(blobEvent.data!);
          }
        });

        _mediaRecorder!.start();

        setState(() {
          isRecording = true;
          selectedAudioFile = null;
          webAudioBytes = null;
          webFileName = null;
        });
      } else {
        // Enregistrement mobile avec flutter_sound
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone non autorisé.")),
          );
          return;
        }

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/recorded_audio.aac';

        await _recorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );

        setState(() {
          isRecording = true;
          selectedAudioFile = null;
          webAudioBytes = null;
          webFileName = null;
        });
      }
    } catch (e) {
      print("Erreur démarrage enregistrement : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du démarrage de l'enregistrement.")),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (kIsWeb) {
        if (_mediaRecorder == null) return;

        final completer = Completer<Uint8List>();

        void handleStop(event) {
          final blob = html.Blob(_chunks, 'audio/webm');
          final reader = html.FileReader();

          reader.readAsArrayBuffer(blob);
          reader.onLoadEnd.listen((event) {
            final audioBytes = reader.result as Uint8List;
            completer.complete(audioBytes);
          });
        }

        _mediaRecorder!.addEventListener('stop', handleStop);

        _mediaRecorder!.stop();

        setState(() {
          isRecording = false;
        });

        final audioData = await completer.future;

        setState(() {
          webAudioBytes = audioData;
          webFileName = "recorded_audio.webm";
        });

        _localStream?.getTracks().forEach((track) => track.stop());
        _localStream = null;

        _sendToIA();
      } else {
        final path = await _recorder.stopRecorder();
        setState(() {
          isRecording = false;
          if (path != null) {
            selectedAudioFile = File(path);
          }
        });
        _sendToIA();
      }
    } catch (e) {
      print("Erreur arrêt enregistrement : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'arrêt de l'enregistrement.")),
      );
      setState(() {
        isRecording = false;
      });
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

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
      _sendToIA();
    }
  }

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
      isTyping = true;
      if (question.isNotEmpty) {
        _messages.add(_ChatMessage(
          sender: "Vous",
          message: question,
          timestamp: DateTime.now(),
          isAI: false,
        ));
      }
    });

    _controller.clear();
    _focusNode.unfocus();
    _scrollToBottom();

    try {
      final responseJson = await GeminiService.askGemini(
        query: question.isNotEmpty ? question : null,
        audioFile: kIsWeb ? null : selectedAudioFile,
        webAudioBytes: kIsWeb ? webAudioBytes : null,
        webFileName: kIsWeb ? webFileName : null,
      );

      setState(() {
        transcription = responseJson['transcription'] ?? "";

        if (transcription.isNotEmpty) {
          _messages.add(_ChatMessage(
            sender: "Transcription",
            message: transcription,
            timestamp: DateTime.now(),
            isAI: false,
            isInfo: true,
          ));
        }

        iaResponse = responseJson['result'] ?? "";

        if (iaResponse.isNotEmpty) {
          _messages.add(_ChatMessage(
            sender: "IA",
            message: iaResponse,
            timestamp: DateTime.now(),
            isAI: true,
          ));
        }

        selectedAudioFile = null;
        webAudioBytes = null;
        webFileName = null;
      });
    } catch (e) {
      setState(() {
        iaResponse = "Désolé, une erreur s'est produite. Veuillez réessayer.";
        _messages.add(_ChatMessage(
          sender: "IA",
          message: iaResponse,
          timestamp: DateTime.now(),
          isAI: true,
          isError: true,
        ));
      });
    } finally {
      setState(() {
        isLoading = false;
        isTyping = false;
      });
      _scrollToBottom();
    }
  }

Widget _buildMessageBubble(_ChatMessage message) {
  final isUser = !message.isAI && !message.isInfo;
  final isTranscription = message.sender == "Transcription";
  final isError = message.isError;

  // Détecter si le message contient des éléments de formatage (comme des listes, code, etc.)
  final bool hasFormatting = message.message.contains('\n') || 
                            message.message.contains('*') || 
                            message.message.contains('`');

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser && !isTranscription)
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: const Text(
              "AI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            radius: 16,
          ),
        if (isUser)
          const SizedBox(width: 40),
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isUser ? 0 : 8,
              right: isUser ? 8 : 0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.blueAccent
                  : isTranscription
                      ? Colors.orange.shade100
                      : isError
                          ? Colors.red.shade100
                          : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isError
                  ? Border.all(color: Colors.red.shade300, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && !isTranscription)
                  Text(
                    message.sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                      fontSize: 12,
                    ),
                  ),
                if (isTranscription)
                  Text(
                    "Transcription audio:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 4),
                if (hasFormatting)
                  _buildFormattedMessage(message.message)
                else
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontStyle: isTranscription ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser)
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child: const Icon(Icons.person, size: 16, color: Colors.white),
            radius: 16,
          ),
      ],
    ),
  );
}

Widget _buildFormattedMessage(String text) {
  final lines = text.split('\n');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: lines.map((line) {
      if (line.startsWith('* ') || line.startsWith('- ')) {
        // Élément de liste
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      } else if (line.startsWith('```')) {
        // Bloc de code (simplifié)
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            line.substring(3),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        );
      } else if (line.trim().startsWith('#')) {
        // Titre
        final level = line.split(' ')[0].length;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line.substring(level).trim(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18 - (level * 2).toDouble(),
              color: Colors.deepPurple,
            ),
          ),
        );
      } else {
        // Texte normal
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: const TextStyle(color: Colors.black87),
          ),
        );
      }
    }).toList(),
  );
} void _scrollToBottom() {
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

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedAudioFile != null || webAudioBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                label: Text(
                  kIsWeb ? "Fichier audio prêt" : "Enregistrement prêt",
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: const Icon(Icons.audiotrack, size: 16),
                backgroundColor: Colors.green.shade100,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    selectedAudioFile = null;
                    webAudioBytes = null;
                    webFileName = null;
                  });
                },
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: isRecording ? Colors.red : Colors.blue,
                ),
                onPressed: isRecording ? _stopRecording : _startRecording,
                tooltip: "Enregistrement audio",
              ),
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.blue),
                onPressed: _pickAudioFile,
                tooltip: "Joindre un fichier audio",
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendToIA(),
                  decoration: InputDecoration(
                    hintText: "Tapez votre message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendToIA,
                  tooltip: "Envoyer",
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant IA"),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (isTyping)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    "IA écrit...",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: const EdgeInsets.only(bottom: 8),
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isAI;
  final bool isInfo;
  final bool isError;

  _ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    this.isAI = false,
    this.isInfo = false,
    this.isError = false,
  });
}
