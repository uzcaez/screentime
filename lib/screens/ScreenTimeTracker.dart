import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerItem {
  final int id;
  DateTime startTime;
  Timer? timer;
  bool isActive;

  TimerItem(this.id, this.startTime, this.isActive);
}

class ScreenTimeTracker extends StatefulWidget {
  const ScreenTimeTracker({Key? key}) : super(key: key);

  @override
  _ScreenTimeTrackerState createState() => _ScreenTimeTrackerState();
}

class _ScreenTimeTrackerState extends State<ScreenTimeTracker> {
  final List<TimerItem> _timers = [];
  int _nextId = 0;
  late SharedPreferences _prefs;
  final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initNotifications();
    _loadSavedTimers();
  }

  void _initNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  void _loadSavedTimers() async {
    // Implement timer persistence loading if needed
  }

  void _startNewTimer() {
    final newTimer = TimerItem(_nextId++, DateTime.now(), true);

    newTimer.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNotification(newTimer);
    });

    setState(() {
      _timers.add(newTimer);
    });

    _showNotification(newTimer);
  }

  void _stopTimer(TimerItem timer) {
    timer.timer?.cancel();
    _cancelNotification(timer.id);

    setState(() {
      timer.isActive = false;
    });
  }

  Future<void> _showNotification(TimerItem timer) async {
    await _notificationsPlugin.show(
      timer.id,
      'Timer ${timer.id + 1}',
      'Elapsed: ${_formatDuration(DateTime.now().difference(timer.startTime))}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screen_time_channel',
          'Screen Time Tracker',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          visibility: NotificationVisibility.public,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  Future<void> _updateNotification(TimerItem timer) async {
    if (!timer.isActive) return;

    final duration = DateTime.now().difference(timer.startTime);

    await _notificationsPlugin.show(
      timer.id,
      'Timer ${timer.id + 1}',
      'Elapsed: ${_formatDuration(duration)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screen_time_channel',
          'Screen Time Tracker',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          visibility: NotificationVisibility.public,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  String _formatDuration(Duration d) {
    return "${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s";
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewTimer,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _timers.length,
        itemBuilder: (context, index) {
          final timer = _timers[index];
          final duration = DateTime.now().difference(timer.startTime);

          return ListTile(
            title: Text('Timer ${timer.id + 1}'),
            subtitle: Text(_formatDuration(duration)),
            trailing: IconButton(
              icon: Icon(timer.isActive ? Icons.stop : Icons.delete),
              onPressed: () => timer.isActive
                  ? _stopTimer(timer)
                  : setState(() => _timers.removeAt(index)),
            ),
          );
        },
      ),
    );
  }
}