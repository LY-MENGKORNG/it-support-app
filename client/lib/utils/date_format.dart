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

  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 30) return '${diff.inDays}d ago';

  return formatDate(time);
}

/// `30 Aug 2026`
String formatDate(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} ${time.year}';

/// `30 Aug 2026, 14:05`
String formatDateTime(DateTime time) =>
    '${formatDate(time)}, ${_two(time.hour)}:${_two(time.minute)}';
