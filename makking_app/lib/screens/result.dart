import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String transcript;

  const ResultScreen({Key? key, required this.transcript}) : super(key: key);

  List<Map<String, String>> formatMessages(String transcript) {
    List<String> lines = transcript.split('\n');
    List<Map<String, String>> formatted = [];
    String? currentSpeaker;

    for (var line in lines) {
      if (line.startsWith('SPEAKER 1')) {
        currentSpeaker = 'right';
      } else if (line.startsWith('SPEAKER 2')) {
        currentSpeaker = 'left';
      } else if (currentSpeaker != null && line.trim().isNotEmpty) {
        formatted.add({'speaker': currentSpeaker, 'text': line.trim()});
      }
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> messages = formatMessages(transcript);

    return Scaffold(
      appBar: AppBar(
        title: Text('화자 분석 결과'),
        backgroundColor: Color.fromARGB(255, 216, 212, 242),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isSpeaker1 = message['speaker'] == 'right';

            return Align(
              alignment:
                  isSpeaker1 ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: isSpeaker1
                      ? Color.fromARGB(255, 179, 186, 232)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  message['text'] ?? '',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
