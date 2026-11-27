import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../ai_chat/data/gemini_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GeminiService _gemini = GeminiService();

  final TextEditingController _questionController = TextEditingController();

  bool _isListening = false;
  bool _isStarting = false;
  bool _isAsking = false;
  bool _isSpeaking = false;

  String _status = 'Tap microphone to speak';
  String _answer = '';
  String _error = '';

  @override
  void initState() {
    super.initState();

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _tts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');

      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  // 1. Start / Stop microphone
  Future<void> _toggleMic() async {
    if (_isStarting || _isAsking) return;

    if (_speech.isListening) {
      await _speech.stop();

      if (mounted) {
        setState(() {
          _isListening = false;
          _status = 'Microphone stopped';
        });
      }
      return;
    }

    setState(() => _isStarting = true);

    try {
      // Avoid microphone listening to the AI voice
      await _tts.stop();

      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            _isListening = status == 'listening';
            _status = _isListening
                ? 'Listening to your voice...'
                : 'Tap microphone to speak';
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _isListening = false;
            _status = 'Speech error: ${error.errorMsg}';
          });
        },
      );

      if (!mounted) return;

      if (!available) {
        setState(() {
          _status = 'Microphone unavailable or permission denied';
        });
        return;
      }

      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );

      if (mounted) {
        setState(() {
          _isListening = _speech.isListening;
        });
      }
    } catch (e) {
      debugPrint('Speech Error: $e');

      if (mounted) {
        setState(() {
          _status = 'Could not start microphone';
          _isListening = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  // 2. Convert speech into text
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    final words = result.recognizedWords;

    _questionController.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );

    if (result.finalResult) {
      setState(() {
        _isListening = false;
        _status = 'Question ready!';
      });
    }
  }

  // 3. Ask Gemini AI
  Future<void> _askGemini() async {
    if (_isAsking) return;

    final question = _questionController.text.trim();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please speak or type a question')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    await _speech.stop();
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _isAsking = true;
      _isListening = false;
      _isSpeaking = false;
      _answer = '';
      _error = '';
      _status = 'Gemini is thinking...';
    });

    try {
      final result = await _gemini.askQuestion(question);

      if (!mounted) return;

      setState(() {
        _answer = result;
        _status = 'AI answer is ready';
      });
    } catch (e) {
      debugPrint('Voice Gemini Error: $e');

      if (!mounted) return;

      final message = e.toString().toLowerCase();

      setState(() {
        if (message.contains('quota') || message.contains('429')) {
          _error =
              'Gemini request limit reached. '
              'Please try again later.';
        } else {
          _error =
              'Unable to get an AI response. '
              'Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isAsking = false);
      }
    }
  }

  // 4. Speak Gemini answer
  Future<void> _speakAnswer() async {
    if (_answer.isEmpty || _isAsking) return;

    if (_isSpeaking) {
      await _tts.stop();

      if (mounted) {
        setState(() => _isSpeaking = false);
      }
      return;
    }

    // Remove basic Markdown symbols before speaking
    final spokenText = _answer
        .replaceAll(RegExp(r'[#*_`>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    setState(() => _isSpeaking = true);

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      await _tts.speak(spokenText);
    } catch (e) {
      debugPrint('Voice Playback Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play AI voice')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const purple = Color(0xFF8B5CF6);
    const cyan = Color(0xFF22D3EE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Assistant'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    'LifeLens Voice',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Ask anything with your voice',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),

                  const SizedBox(height: 35),

                  // Animated microphone
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: purple.withValues(alpha: 0.13),
                        border: Border.all(
                          color: _isListening ? cyan : purple,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? cyan : purple).withValues(
                              alpha: _isListening ? 0.4 : 0.15,
                            ),
                            blurRadius: _isListening ? 40 : 15,
                            spreadRadius: _isListening ? 8 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.graphic_eq : Icons.mic,
                        size: 70,
                        color: _isListening ? cyan : purple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),

                  const SizedBox(height: 22),

                  // Mic button
                  Center(
                    child: FilledButton.icon(
                      onPressed: _isStarting || _isAsking ? null : _toggleMic,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label: Text(
                        _isListening ? 'Stop Listening' : 'Start Listening',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Question section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: purple.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Question',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _questionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Speak or type here...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Send question to Gemini
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isAsking ? null : _askGemini,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_isAsking ? 'Thinking...' : 'Ask Gemini AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  if (_isAsking) ...[
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(color: cyan),
                  ],

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],

                  // AI response section
                  if (_answer.isNotEmpty) ...[
                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cyan.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology_outlined, color: cyan),
                              SizedBox(width: 10),
                              Text(
                                'AI Response',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          MarkdownBody(data: _answer, selectable: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Speak / Stop voice
                    OutlinedButton.icon(
                      onPressed: _speakAnswer,
                      icon: Icon(
                        _isSpeaking
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                      ),
                      label: Text(
                        _isSpeaking ? 'Stop Speaking' : 'Speak Answer',
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
