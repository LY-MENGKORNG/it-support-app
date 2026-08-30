/// How the request list should be ordered.
enum RequestSort {
  newest('newest', 'Newest first'),
  oldest('oldest', 'Oldest first'),
  priority('priority', 'Priority');

  const RequestSort(this.wire, this.label);

  final String wire;
  final String label;
}
