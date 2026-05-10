import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TimerState {
  final Duration elapsed;
  final bool isRunning;
  const TimerState({required this.elapsed, required this.isRunning});
  
  TimerState copyWith({Duration? elapsed, bool? isRunning}) =>
    TimerState(elapsed: elapsed ?? this.elapsed, isRunning: isRunning ?? this.isRunning);
}

class SessionTimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _startTime;

  @override
  TimerState build() {
    final box = Hive.box('session_cache');
    final saved = box.get('session_start') as String?;
    if (saved != null) {
      _startTime = DateTime.parse(saved);
      final elapsed = DateTime.now().difference(_startTime!);
      return TimerState(elapsed: elapsed, isRunning: false); // Paused state by default if recovered
    }
    return const TimerState(elapsed: Duration.zero, isRunning: false);
  }

  void start() {
    _startTime ??= DateTime.now().subtract(state.elapsed);
    state = state.copyWith(isRunning: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_startTime!);
      state = state.copyWith(elapsed: elapsed);
    });
    Hive.box('session_cache').put('session_start', _startTime!.toIso8601String());
  }

  void pause() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    _startTime = DateTime.now().subtract(state.elapsed);
    start();
  }

  void reset() {
    _ticker?.cancel();
    _startTime = null;
    state = const TimerState(elapsed: Duration.zero, isRunning: false);
    Hive.box('session_cache').delete('session_start');
  }
}

final sessionTimerNotifierProvider = NotifierProvider<SessionTimerNotifier, TimerState>(() {
  return SessionTimerNotifier();
});