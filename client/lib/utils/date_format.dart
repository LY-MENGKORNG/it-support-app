/// Date formatting, without pulling in `intl` for what amounts to two functions.
library;

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// `2 hours ago`, `3 days ago`, `just now`. Falls back to an absolute date past
/// a month, where "37 days ago" stops being easier to read than the date.
String formatRelative(DateTime time) {
  final diff = DateTime.now().difference(time);

  return switch (diff) {
    _ when diff.isNegative || diff.inSeconds < 60 => 'just now',
    _ when diff.inMinutes < 60 => '${diff.inMinutes}m ago',
    _ when diff.inHours < 24 => '${diff.inHours}h ago',
    _ when diff.inDays == 1 => 'yesterday',
    _ when diff.inDays < 30 => '${diff.inDays}d ago',
    _ => formatDate(time),
  };
}

/// `30 Aug 2026`
String formatDate(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} ${time.year}';

/// `30 Aug 2026, 14:05`
String formatDateTime(DateTime time) =>
    '${formatDate(time)}, ${_two(time.hour)}:${_two(time.minute)}';
