import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerItem {
  final int id;
  DateTime startTime;
  bool isActive;
  Timer? timer;
  Duration get elapsed => DateTime.now().difference(startTime);

  TimerItem(this.id, this.startTime, this.isActive);
}

class TimerService extends ChangeNotifier {
  final List<TimerItem> _timers = [];
  int _nextId = 0;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  TimerService() {
    _initNotifications();
  }

  List<TimerItem> get timers => _timers;

  String formatDuration(Duration d) {
    return "${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s";
  }

  void _initNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    _notificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );
  }

  void startNewTimer() {
    final newTimer = TimerItem(_nextId++, DateTime.now(), true);

    newTimer.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNotification(newTimer);
      notifyListeners();
    });

    _timers.add(newTimer);
    _showNotification(newTimer);
    notifyListeners();
  }

  void stopTimer(int id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    timer.timer?.cancel();
    timer.isActive = false;
    _cancelNotification(id);
    notifyListeners();
  }

  void deleteTimer(int id) {
    _timers.removeWhere((t) => t.id == id);
    _cancelNotification(id);
    notifyListeners();
  }

  Future<void> _showNotification(TimerItem timer) async {
    await _notificationsPlugin.show(
      timer.id,
      'Timer ${timer.id + 1}',
      'Elapsed: ${formatDuration(timer.elapsed)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screen_time_channel',
          'Screen Time Tracker',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          visibility: NotificationVisibility.public,
          onlyAlertOnce: true,
          playSound: false,
        ),
      ),
    );
  }

  Future<void> _updateNotification(TimerItem timer) async {
    if (!timer.isActive) return;

    await _notificationsPlugin.show(
      timer.id,
      'Timer ${timer.id + 1}',
      'Elapsed: ${formatDuration(timer.elapsed)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screen_time_channel',
          'Screen Time Tracker',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          playSound: false,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.timer?.cancel();
      _cancelNotification(timer.id);
    }
    super.dispose();
  }
}