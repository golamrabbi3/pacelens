import 'package:flutter/material.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recording')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Native high-speed recording is exposed through platform channels. This MVP queries camera capabilities now; full Camera2/AVFoundation recording should be enabled only when the selected device reports stable 60 FPS or higher timestamps.',
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning),
              title: Text('No fallback below 60 FPS'),
              subtitle: Text(
                'PaceLens will not produce a speed estimate from unsupported capture data.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
