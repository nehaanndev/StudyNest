const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

// Formats a date as a compact weekday and month label.
String compactDate(DateTime date) {
  return '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';
}

// Formats a date as a short day label for week selectors.
String shortWeekday(DateTime date) {
  return _weekdays[date.weekday - 1];
}

// Formats the day number for compact calendar chips.
String dayNumber(DateTime date) {
  return date.day.toString();
}

// Formats a clock time in a readable 12-hour style.
String clockTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

// Formats an event range using only the start and end times.
String timeRange(DateTime startsAt, DateTime endsAt) {
  return '${clockTime(startsAt)} - ${clockTime(endsAt)}';
}

// Reports whether two dates are on the same calendar day.
bool isSameCalendarDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
