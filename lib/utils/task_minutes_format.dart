String formatTaskMinutes(int minutes) {
  if (minutes < 60) {
    return '${minutes}m estimated';
  }
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) {
    return '${hours}h estimated';
  }
  return '${hours}h ${remainder}m estimated';
}
