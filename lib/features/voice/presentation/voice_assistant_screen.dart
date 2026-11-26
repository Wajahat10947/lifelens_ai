
import 'package:flutter/material.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Assistant'),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFF8B5CF6),
              child: Icon(
                Icons.mic,
                size: 55,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'LifeLens AI Voice',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Voice assistance coming soon',
            ),
          ],
        ),
      ),
    );
  }
}
