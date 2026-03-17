import 'dart:math';

/// Client-side login attempt throttle with exponential backoff.
///
/// After [maxAttempts] consecutive failures, each subsequent attempt
/// is delayed by an exponentially increasing duration (capped at 60s).
/// Resets on successful login.
class LoginThrottle {

  LoginThrottle({this.maxAttempts = 3});
  final int maxAttempts;
  int _failedAttempts = 0;
  DateTime? _lockUntil;

  /// Whether the user is currently locked out.
  bool get isLocked {
    if (_lockUntil == null) return false;
    if (DateTime.now().isAfter(_lockUntil!)) {
      _lockUntil = null;
      return false;
    }
    return true;
  }

  /// Remaining lockout duration. Returns [Duration.zero] if not locked.
  Duration get remainingLockout {
    if (_lockUntil == null) return Duration.zero;
    final remaining = _lockUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Number of failed attempts so far.
  int get failedAttempts => _failedAttempts;

  /// Record a failed login attempt. Returns the lockout duration
  /// if the user is now throttled, or [Duration.zero] if not yet.
  Duration recordFailure() {
    _failedAttempts++;

    if (_failedAttempts >= maxAttempts) {
      // Exponential backoff: 2^(failures - maxAttempts) seconds, capped at 60s
      final exponent = _failedAttempts - maxAttempts;
      final seconds = min(60, pow(2, exponent).toInt());
      final lockDuration = Duration(seconds: seconds);
      _lockUntil = DateTime.now().add(lockDuration);
      return lockDuration;
    }

    return Duration.zero;
  }

  /// Reset the throttle on successful login.
  void reset() {
    _failedAttempts = 0;
    _lockUntil = null;
  }
}
