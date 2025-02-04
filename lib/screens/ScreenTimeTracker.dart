import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/timer_service.dart';

class ScreenTimeTracker extends StatelessWidget {
  const ScreenTimeTracker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: timerService.startNewTimer,
          ),
        ],
      ),
      body: Consumer<TimerService>(
        builder: (context, service, _) {
          return ListView.builder(
            itemCount: service.timers.length,
            itemBuilder: (context, index) {
              final timer = service.timers[index];
              return ListTile(
                title: Text('Timer ${timer.id + 1}'),
                subtitle: Text(service.formatDuration(timer.elapsed)),
                trailing: timer.isActive
                    ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () => service.stopTimer(timer.id),
                )
                    : IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => service.deleteTimer(timer.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}