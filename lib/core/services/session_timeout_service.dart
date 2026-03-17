import 'dart:async';

import 'package:flutter/widgets.dart';

/// Tracks user inactivity and fires a callback when the timeout expires.
///
/// Usage: Wrap the app in [SessionTimeoutListener] widget which calls
/// [onTimeout] (typically triggers AuthLogoutRequested).
class SessionTimeoutService {

  SessionTimeoutService({
    this.timeout = const Duration(minutes: 15),
    required this.onTimeout,
  });
  final Duration timeout;
  final VoidCallback onTimeout;

  Timer? _timer;

  /// Call on every user interaction to reset the timer.
  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeout, _handleTimeout);
  }

  void _handleTimeout() {
    onTimeout();
  }

  /// Start tracking inactivity.
  void start() {
    resetTimer();
  }

  /// Stop tracking and cancel any pending timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Widget that wraps the app to detect user interaction and reset the
/// inactivity timer. Place this directly below MultiBlocProvider.
class SessionTimeoutListener extends StatefulWidget {

  const SessionTimeoutListener({
    super.key,
    required this.child,
    required this.timeoutService,
  });
  final Widget child;
  final SessionTimeoutService timeoutService;

  @override
  State<SessionTimeoutListener> createState() =>
      _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends State<SessionTimeoutListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.timeoutService.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.timeoutService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // User came back — reset the timer
        widget.timeoutService.resetTimer();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App backgrounded — keep timer running; it will fire if the user
        // doesn't return within the timeout window
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.timeoutService.resetTimer(),
      onPointerMove: (_) => widget.timeoutService.resetTimer(),
      child: widget.child,
    );
  }
}
