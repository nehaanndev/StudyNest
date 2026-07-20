import 'package:flutter/material.dart';

// Shows a dialog and waits for its exit animation before callers dispose resources.
Future<T?> showManagedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
  );
  final result = await navigator.push<T>(route);
  await route.completed;
  return result;
}
