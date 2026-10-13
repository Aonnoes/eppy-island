/// Formats a countdown as `H:MM:SS`, or `MM:SS` when under an hour.
/// Negative durations show as `00:00`.
String formatCountdown(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
