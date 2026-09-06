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

String formatDate(DateTime time) {
  return '${time.day} ${_months[time.month - 1]} ${time.year}';
}

String formatDateTime(DateTime time) {
  return '${formatDate(time)}, ${_two(time.hour)}:${_two(time.minute)}';
}
