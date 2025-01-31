import 'package:flutter/material.dart';
import 'dart:async';

class ScreenTimeTracker extends StatefulWidget {
  const ScreenTimeTracker({Key? key}) : super(key: key);

  @override
  _ScreenTimeTrackerState createState() => _ScreenTimeTrackerState();
}

class _ScreenTimeTrackerState extends State<ScreenTimeTracker> {
  Duration _screenTime = Duration.zero;
  Timer? _timer;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _screenTime = DateTime.now().difference(_startTime!);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    return "${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 50),
            const SizedBox(height: 20),
            Text(
              'Screen Time:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              _formatDuration(_screenTime),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}