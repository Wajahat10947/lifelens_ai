
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../ai_chat/data/gemini_service.dart';

class AiLearningScreen extends StatefulWidget {
  const AiLearningScreen({super.key});

  @override
  State<AiLearningScreen> createState() =>
      _AiLearningScreenState();
}

class _AiLearningScreenState extends State<AiLearningScreen> {
  final _gemini = GeminiService();
  final _topicController = TextEditingController();

  static const purple = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22D3EE);

  bool _loading = false;
  bool _showQuiz = false;
  bool _submitted = false;

  String _explanation = '';
  String _error = '';
  String _resultTopic = '';

  List<_QuizQuestion> _questions = [];
  List<int?> _selectedAnswers = [];

  int get _score {
    int total = 0;

    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctIndex) {
        total++;
      }
    }

    return total;
  }

  Future<void> _generate({required bool quiz}) async {
    if (_loading) return;

    final topic = _topicController.text.trim();

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic first.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _showQuiz = quiz;
      _submitted = false;
      _explanation = '';
      _error = '';
      _resultTopic = topic;
      _questions = [];
      _selectedAnswers = [];
    });

    final prompt = quiz
        ? '''
You are LifeLens AI Quiz Generator.

USER TOPIC:
$topic

Create exactly 5 beginner-friendly multiple-choice
questions about this topic.

LANGUAGE RULES:
- Detect the language from USER TOPIC only.
- English input -> English questions and answers.
- Roman Urdu input -> Roman Urdu questions and answers.
- If the topic is only a technical name, use English.

Return ONLY a valid JSON object.
Do not use Markdown, code fences, or extra text.

Use exactly this JSON structure:

{
  "questions": [
    {
      "question": "Question text",
      "options": [
        "First option",
        "Second option",
        "Third option",
        "Fourth option"
      ],
      "correctIndex": 0,
      "explanation": "Brief explanation"
    }
  ]
}

REQUIREMENTS:
- Exactly 5 question objects.
- Exactly 4 options per question.
- Only ONE correct answer per question.
- correctIndex must be an integer from 0 to 3.
- Mix the correct answer positions.
- Questions must be factually accurate.
- Do not reveal answers in the options' wording.
'''
        : '''
You are LifeLens AI Learning Tutor.

USER TOPIC:
$topic

Explain this topic in an engaging, beginner-friendly way.

Structure your response using Markdown:

## What Is It?
## How Does It Work?
## Real-Life Examples
## Key Takeaways
## Practice Activity

LANGUAGE RULES:
- Detect language from USER TOPIC only.
- English input -> English explanation.
- Roman Urdu input -> Roman Urdu explanation.
- If the topic is only a technical name, use English.

Use clear headings, short paragraphs and helpful bullets.
''';

    try {
      final response = await _gemini.askQuestion(prompt);

      if (!mounted) return;

      if (quiz) {
        final parsedQuestions = _parseQuiz(response);

        setState(() {
          _questions = parsedQuestions;
          _selectedAnswers =
              List<int?>.filled(parsedQuestions.length, null);
        });
      } else {
        if (response.trim().isEmpty) {
          throw const FormatException('Empty AI response');
        }

        setState(() {
          _explanation = response.trim();
        });
      }
    } catch (e) {
      debugPrint('AI Learning Error: $e');

      if (!mounted) return;

      final message = e.toString().toLowerCase();

      setState(() {
        if (message.contains('429') ||
            message.contains('quota')) {
          _error =
              'Gemini request limit reached. Please try again later.';
        } else {
          _error = quiz
              ? 'Unable to generate the quiz. Please try again.'
              : 'Unable to explain this topic. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<_QuizQuestion> _parseQuiz(String response) {
    // Handles JSON with or without Markdown code fences.
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');

    if (start < 0 || end <= start) {
      throw const FormatException('Quiz JSON not found');
    }

    final jsonText = response.substring(start, end + 1);
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map) {
      throw const FormatException('Invalid quiz object');
    }

    final rawQuestions = decoded['questions'];

    if (rawQuestions is! List || rawQuestions.length != 5) {
      throw const FormatException('Expected 5 questions');
    }

    return rawQuestions.map((item) {
      return _QuizQuestion.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  void _submitQuiz() {
    if (_selectedAnswers.any((answer) => answer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer all questions before submitting.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitted = true);
  }

  void _tryAgain() {
    setState(() {
      _submitted = false;
      _selectedAnswers =
          List<int?>.filled(_questions.length, null);
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Widget _buildExplanation() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cyan.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.08),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: cyan,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR LEARNING GUIDE',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resultTopic,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: purple.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          MarkdownBody(
            data: _explanation,
            selectable: true,
            styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
              p: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: colors.onSurface,
              ),
              h2: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: purple,
              ),
              listBullet: const TextStyle(color: cyan),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: purple.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: cyan,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'AI-powered learning guide',
                style: TextStyle(
                  color: cyan,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(int questionIndex) {
    final colors = Theme.of(context).colorScheme;
    final question = _questions[questionIndex];
    final selected = _selectedAnswers[questionIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION ${questionIndex + 1} / ${_questions.length}',
            style: const TextStyle(
              color: cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Every question has its own radio group.
          RadioGroup<int>(
            groupValue: selected,
            onChanged: (value) {
              if (_submitted) return;

              setState(() {
                _selectedAnswers[questionIndex] = value;
              });
            },
            child: Column(
              children: List.generate(
                question.options.length,
                (optionIndex) {
                  final isCorrect = _submitted &&
                      optionIndex == question.correctIndex;

                  final isWrong = _submitted &&
                      selected == optionIndex &&
                      optionIndex != question.correctIndex;

                  Color borderColor =
                      colors.outlineVariant;

                  if (isCorrect) {
                    borderColor = Colors.green;
                  } else if (isWrong) {
                    borderColor = Colors.redAccent;
                  } else if (selected == optionIndex) {
                    borderColor = purple;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      color: selected == optionIndex
                          ? purple.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: RadioListTile<int>(
                      value: optionIndex,
                      enabled: !_submitted,
                      activeColor: purple,
                      selected: selected == optionIndex,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      title: Text(
                        question.options[optionIndex],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (_submitted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    selected == question.correctIndex
                        ? 'Correct Answer!'
                        : 'Correct Answer:',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.options[question.correctIndex],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      question.explanation,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final total = _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF49308C),
                Color(0xFF162540),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.quiz_outlined, color: cyan),
                  SizedBox(width: 10),
                  Text(
                    'KNOWLEDGE QUIZ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _resultTopic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _submitted
                    ? 'Quiz completed!'
                    : '$total questions • Choose one answer per question',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              if (_submitted) ...[
                const SizedBox(height: 18),
                Text(
                  '$_score / $total',
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your Score: ${(_score / total * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        for (int i = 0; i < total; i++)
          _buildQuestion(i),

        if (!_submitted)
          FilledButton.icon(
            onPressed: _submitQuiz,
            icon: const Icon(Icons.task_alt),
            label: const Text('Submit Quiz'),
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(17),
            ),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: _tryAgain,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _generate(quiz: true),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate New Quiz'),
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Learning'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Futuristic header
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF39216F),
                      Color(0xFF111C36),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: purple.withValues(alpha: 0.4),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: cyan,
                      size: 55,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'AI Learning Hub',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Explore topics. Learn smarter. Test your skills.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: _topicController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Enter a topic',
                  hintText:
                      'Example: How does Arduino work?',
                  prefixIcon: const Icon(
                    Icons.lightbulb_outline,
                    color: purple,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () => _generate(quiz: false),
                icon: const Icon(Icons.auto_stories),
                label: const Text('Explain Topic'),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _generate(quiz: true),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Generate Quiz'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              if (_loading) ...[
                const SizedBox(height: 25),
                const LinearProgressIndicator(
                  color: cyan,
                ),
                const SizedBox(height: 10),
                Text(
                  _showQuiz
                      ? 'Generating your quiz...'
                      : 'Preparing your explanation...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  _error,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ],

              if (_explanation.isNotEmpty) ...[
                const SizedBox(height: 25),
                _buildExplanation(),
              ],

              if (_questions.isNotEmpty) ...[
                const SizedBox(height: 25),
                _buildQuiz(),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Data model for one multiple-choice question.
class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory _QuizQuestion.fromJson(Map<String, dynamic> json) {
    final question = json['question'] as String;
    final options = List<String>.from(json['options'] as List);
    final correctIndex = json['correctIndex'] as int;
    final explanation =
        (json['explanation'] ?? '').toString();

    if (question.trim().isEmpty ||
        options.length != 4 ||
        options.any((option) => option.trim().isEmpty) ||
        correctIndex < 0 ||
        correctIndex > 3) {
      throw const FormatException('Invalid quiz question');
    }

    return _QuizQuestion(
      question: question,
      options: options,
      correctIndex: correctIndex,
      explanation: explanation,
    );
  }
}
