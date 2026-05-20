import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import '../app/study_nest_scope.dart';
import 'study_town_scene.dart';

class MovableDecorScene extends StatefulWidget {
  const MovableDecorScene({
    super.key,
    required this.environmentName,
    required this.focusTitle,
    required this.reward,
    required this.isComplete,
    required this.decorItems,
    required this.decorPositions,
    required this.styleId,
    required this.onDecorMoved,
  });

  final String environmentName;
  final String focusTitle;
  final int reward;
  final bool isComplete;
  final List<StudyDecorItem> decorItems;
  final Map<String, Offset> decorPositions;
  final String styleId;
  final Future<void> Function(String itemId, Offset position) onDecorMoved;

  // Creates local drag state for movable room decor.
  @override
  State<MovableDecorScene> createState() => _MovableDecorSceneState();
}

class _MovableDecorSceneState extends State<MovableDecorScene> {
  final Map<String, Offset> _workingPositions = {};
  String? _draggingItemId;

  // Synchronizes local drag positions when persisted decor positions change.
  @override
  void didUpdateWidget(covariant MovableDecorScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingItemId == null) {
      _workingPositions
        ..clear()
        ..addAll(widget.decorPositions);
    }
  }

  // Builds the room artwork with draggable decor tokens layered on top.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = constraints.maxWidth > 520 ? 430.0 : 410.0;

        return SizedBox(
          height: sceneHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: StudyTownScene(
                  environmentName: widget.environmentName,
                  focusTitle: widget.focusTitle,
                  reward: widget.reward,
                  isComplete: widget.isComplete,
                  onComplete: () {},
                  onEdit: () {},
                  decorItems: const [],
                  styleId: widget.styleId,
                  showFocusPanel: false,
                ),
              ),
              for (final item in widget.decorItems)
                _MovableDecorToken(
                  item: item,
                  position: _positionFor(item.id),
                  sceneSize: Size(constraints.maxWidth, sceneHeight),
                  onMoveStart: () => _draggingItemId = item.id,
                  onMoved: (position) => _moveItem(item.id, position),
                  onMoveEnd: () => _commitItem(item.id),
                ),
            ],
          ),
        );
      },
    );
  }

  // Finds the current local or persisted position for one decor item.
  Offset _positionFor(String itemId) {
    return _workingPositions[itemId] ??
        widget.decorPositions[itemId] ??
        defaultDecorPositionFor(itemId);
  }

  // Updates local drag state while the user moves a decor item.
  void _moveItem(String itemId, Offset position) {
    setState(() {
      _workingPositions[itemId] = position;
    });
  }

  // Persists the final dropped position after a drag gesture.
  Future<void> _commitItem(String itemId) async {
    _draggingItemId = null;
    await widget.onDecorMoved(itemId, _positionFor(itemId));
  }
}

class _MovableDecorToken extends StatelessWidget {
  const _MovableDecorToken({
    required this.item,
    required this.position,
    required this.sceneSize,
    required this.onMoveStart,
    required this.onMoved,
    required this.onMoveEnd,
  });

  final StudyDecorItem item;
  final Offset position;
  final Size sceneSize;
  final VoidCallback onMoveStart;
  final ValueChanged<Offset> onMoved;
  final VoidCallback onMoveEnd;

  // Builds a draggable decor chip at a normalized room position.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    const tokenSize = 48.0;
    final left = position.dx * sceneSize.width - tokenSize / 2;
    final top = position.dy * sceneSize.height - tokenSize / 2;

    return Positioned(
      left: left,
      top: top,
      width: tokenSize,
      height: tokenSize,
      child: GestureDetector(
        onPanStart: (_) => onMoveStart(),
        onPanUpdate: (details) => _handleDrag(details.delta),
        onPanEnd: (_) => onMoveEnd(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.accent.withValues(alpha: 0.58)),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(item.icon, color: theme.primary, size: 26),
        ),
      ),
    );
  }

  // Converts a drag delta into a clipped normalized room position.
  void _handleDrag(Offset delta) {
    final next = Offset(
      position.dx + delta.dx / sceneSize.width,
      position.dy + delta.dy / sceneSize.height,
    );
    onMoved(
      Offset(
        next.dx.clamp(0.08, 0.92).toDouble(),
        next.dy.clamp(0.12, 0.88).toDouble(),
      ),
    );
  }
}
