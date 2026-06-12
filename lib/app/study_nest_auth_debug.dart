import 'dart:developer' as developer;

// Writes temporary auth/data-isolation diagnostics to the debug log.
void logStudyNestAuthDebug(
  String message, {
  String? userId,
  String? ownerUserId,
  String? cacheKey,
  String? source,
}) {
  assert(() {
    final details = <String>[
      if (userId != null) 'uid=$userId',
      if (ownerUserId != null) 'owner=$ownerUserId',
      if (cacheKey != null) 'cacheKey=$cacheKey',
      if (source != null) 'source=$source',
    ];
    final suffix = details.isEmpty ? '' : ' ${details.join(' ')}';
    developer.log('$message$suffix', name: 'StudyNestAuth');
    return true;
  }());
}
