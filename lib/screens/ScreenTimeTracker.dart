import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class ScreenTimeTracker extends StatefulWidget {
  const ScreenTimeTracker({Key? key}) : super(key: key);

  @override
  _ScreenTimeTrackerState createState() => _ScreenTimeTrackerState();
}

class _ScreenTimeTrackerState extends State<ScreenTimeTracker> with WidgetsBindingObserver {
  Duration _screenTime = Duration.zero;
  Timer? _timer;
  late SharedPreferences _prefs;
  final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _initNotifications();
    await AndroidAlarmManager.initialize();
    _startTracking();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  void _startTracking() async {
    final storedTime = _prefs.getInt('start_time');
    final startTime = storedTime != null
        ? DateTime.fromMillisecondsSinceEpoch(storedTime)
        : DateTime.now();

    await _prefs.setInt('start_time', startTime.millisecondsSinceEpoch);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _screenTime = DateTime.now().difference(startTime));
    });

    await AndroidAlarmManager.periodic(
      const Duration(seconds: 1),
      0,
      _updateNotification,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _updateNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final startTime = prefs.getInt('start_time');
    if (startTime == null) return;

    final duration = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(startTime)
    );

    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    await notificationsPlugin.show(
      0,
      'Screen Time Tracker',
      'Elapsed: ${_formatDuration(duration)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screen_time_channel',
          'Screen Time Tracker',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    return "${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s";
  }

  @override
  void dispose() {
    _timer?.cancel();
    AndroidAlarmManager.cancel(0);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _updateNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Time Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 50),
            const SizedBox(height: 20),
            Text('Screen Time:', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              _formatDuration(_screenTime),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}