enum ClockStatus {
  ok,

  /// The device clock is earlier than a time the app has already seen (or
  /// earlier than a code's signed issue time). Access checks must not run
  /// until the clock is corrected.
  behind,
}

class ClockCheck {
  const ClockCheck(this.status, this.lastSeen);

  final ClockStatus status;

  /// The value to persist as the new "latest time seen".
  final DateTime lastSeen;

  bool get isOk => status == ClockStatus.ok;
}

/// Detects a device clock turned back to stretch an expired activation. The
/// app is offline, so the only trusted times are ones it has already observed
/// and the issue times signed into activation codes.
abstract final class ClockGuard {
  /// Small backwards jumps (network time sync, a manual correction of a few
  /// minutes) are normal and must not lock the student out.
  static const tolerance = Duration(hours: 1);

  /// How old a code may be and still re-anchor the clock (see [afterCode]).
  static const resyncWindow = Duration(days: 3);

  /// Run on every app start and resume, then persist [ClockCheck.lastSeen].
  static ClockCheck check({required DateTime now, DateTime? lastSeen}) {
    if (lastSeen != null && now.isBefore(lastSeen.subtract(tolerance))) {
      return ClockCheck(ClockStatus.behind, lastSeen);
    }
    final latest = lastSeen == null || now.isAfter(lastSeen) ? now : lastSeen;
    return ClockCheck(ClockStatus.ok, latest);
  }

  /// Run when a verified code is applied; [issuedAt] is signed by the issuer.
  ///
  /// A recently issued code also vouches for the current clock. That is how a
  /// student recovers after the clock was once set into the future by mistake:
  /// the inflated "latest time seen" is replaced by the correct time.
  static ClockCheck afterCode({
    required DateTime now,
    required DateTime issuedAt,
    DateTime? lastSeen,
  }) {
    if (now.isBefore(issuedAt.subtract(tolerance))) {
      return ClockCheck(ClockStatus.behind, lastSeen ?? issuedAt);
    }
    if (now.difference(issuedAt) <= resyncWindow) {
      return ClockCheck(ClockStatus.ok, now);
    }
    return check(now: now, lastSeen: lastSeen);
  }
}
