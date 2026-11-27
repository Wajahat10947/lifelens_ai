import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../ai_chat/data/gemini_service.dart';

class AiFixItScreen extends StatefulWidget {
  const AiFixItScreen({super.key});

  @override
  State<AiFixItScreen> createState() => _AiFixItScreenState();
}

class _AiFixItScreenState extends State<AiFixItScreen> {
  final _gemini = GeminiService();
  final _problemController = TextEditingController();

  bool _loading = false;
  String _solution = '';
  String _error = '';

  Future<void> _findSolution() async {
    if (_loading) return;

    final problem = _problemController.text.trim();

    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your problem first')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _solution = '';
      _error = '';
    });

    final prompt =
        '''
You are LifeLens AI Fix-It Assistant.

User's problem: $problem

Give:
1. Possible causes.
2. Simple and safe troubleshooting steps.
3. Common mistakes to avoid.
4. When professional help is needed.

Reply in the same language as the user's problem.
If the user writes in English, reply in English.
If the user writes in Roman Urdu, reply in Roman Urdu.

Use Markdown headings and numbered steps.

Do not claim a definite diagnosis.
Avoid dangerous electrical, battery,
chemical or mechanical repair instructions.
For dangerous problems, recommend
professional assistance.
''';

    try {
      final response = await _gemini.askQuestion(prompt);

      if (!mounted) return;

      setState(() => _solution = response);
    } catch (e) {
      debugPrint('Fix-It Error: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString().contains('quota') || e.toString().contains('429')
            ? 'Gemini request limit reached. Please try again later.'
            : 'Unable to find a solution. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const orange = Color(0xFFFFA726);
    const purple = Color(0xFF8B5CF6);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Fix-It'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),

              const Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFF392819),
                  child: Icon(
                    Icons.build_circle_outlined,
                    color: orange,
                    size: 50,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Fix Problems Smarter',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Describe your issue and get AI guidance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _problemController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Describe your problem',
                  hintText: 'Example: My phone charges slowly',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _loading ? null : _findSolution,
                icon: const Icon(Icons.handyman_outlined),
                label: Text(_loading ? 'Analyzing...' : 'Find Solution'),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

              if (_loading) ...[
                const SizedBox(height: 24),
                const LinearProgressIndicator(color: orange),
              ],

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(_error, style: const TextStyle(color: Colors.redAccent)),
              ],

              if (_solution.isNotEmpty) ...[
                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: orange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tips_and_updates, color: orange),
                          SizedBox(width: 10),
                          Text(
                            'AI Suggested Solution',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      MarkdownBody(data: _solution, selectable: true),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Text(
                'AI advice can be incorrect. '
                'Avoid unsafe repairs and contact a professional '
                'when needed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
