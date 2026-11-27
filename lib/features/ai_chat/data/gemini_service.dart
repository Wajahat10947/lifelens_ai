import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // Gemini AI model
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
  );

  // TEXT AI
  Future<String> askQuestion(String question) async {
    final response = await _model.generateContent([
      Content.text('''
You are LifeLens AI.

Language rules:
- If the user's actual question is in English,
  reply in English.
- If the user's actual question is in Roman Urdu,
  reply in Roman Urdu using Latin letters.
- If the user's question is in Urdu script,
  reply in Urdu.
- Do not choose the language based on
  English instructions surrounding the question.
- Use clear Markdown formatting.
- Keep answers simple and beginner-friendly.

Request:
$question
'''),
    ]);

    return response.text ?? 'No response received';
  }

  // IMAGE AI
  Future<String> analyzeImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final prompt = TextPart('''
You are LifeLens AI, an intelligent visual assistant.

Analyze this image carefully.

1. Identify the main object.
2. Explain what it is.
3. Explain what it is used for.
4. Describe visible important details.
5. Give useful learning tips.

Respond in simple Roman Urdu.

If the image is unclear, say so.
Do not invent details you cannot see.
Avoid giving unsafe repair instructions.

Format your response using clean Markdown.
Use ## headings for each main section.
Use bullet points for lists.
Keep paragraphs short.
Do not add unnecessary horizontal separators.
''');

    final imagePart = InlineDataPart(mimeType, bytes);

    // Maximum 3 attempts
    const maxAttempts = 1;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('Gemini Vision attempt: $attempt');

        final response = await _model.generateContent([
          Content.multi([prompt, imagePart]),
        ]);

        final answer = response.text?.trim();

        if (answer == null || answer.isEmpty) {
          throw StateError('AI returned no response');
        }

        // Success
        return answer;
      } on FirebaseAIException catch (e) {
        debugPrint('Gemini Error: $e');

        final error = e.toString().toLowerCase();

        // Retry only temporary server errors
        final isServerBusy =
            error.contains('high demand') ||
            error.contains('server error [500]') ||
            error.contains('server error [503]');

        // Other errors should not be retried
        if (!isServerBusy) {
          rethrow;
        }

        // Stop after final attempt
        if (attempt == maxAttempts) {
          throw StateError(
            'AI server abhi busy hai. '
            'Thori dair baad dobara try karo.',
          );
        }

        // Wait 2 seconds, then 4 seconds
        final delay = Duration(seconds: attempt * 2);

        debugPrint(
          'Server busy. Retrying in '
          '${delay.inSeconds} seconds...',
        );

        await Future<void>.delayed(delay);
      }
    }

    throw StateError('AI analysis failed');
  }
}
