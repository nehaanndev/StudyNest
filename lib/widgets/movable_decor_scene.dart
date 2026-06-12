import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import 'study_decor_layer.dart';
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
                  decorPositions: const {},
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

  // Records the final dropped position from a token drag.
  void _moveItem(String itemId, Offset position) {
    _workingPositions[itemId] = position;
  }

  // Persists the final dropped position after a drag gesture.
  Future<void> _commitItem(String itemId) async {
    _draggingItemId = null;
    // Trigger a rebuild so the token moves to its final slot.
    setState(() {});
    await widget.onDecorMoved(itemId, _positionFor(itemId));
  }
}

// Stateful token so only the dragged sprite repaints — not the whole scene.
class _MovableDecorToken extends StatefulWidget {
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

  @override
  State<_MovableDecorToken> createState() => _MovableDecorTokenState();
}

class _MovableDecorTokenState extends State<_MovableDecorToken> {
  late Offset _localPosition = widget.position;
  static const double _minimumTouchTarget = 92;

  @override
  void didUpdateWidget(covariant _MovableDecorToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Accept parent position updates when not mid-drag.
    if (!_dragging) _localPosition = widget.position;
  }

  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final spriteSize = (widget.sceneSize.width * widget.item.baseScale * 1.14)
        .clamp(58.0, 124.0);
    final touchSize = (spriteSize + 28).clamp(_minimumTouchTarget, 148.0);
    final left = _localPosition.dx * widget.sceneSize.width - touchSize / 2;
    final top = _localPosition.dy * widget.sceneSize.height - touchSize / 2;

    return Positioned(
      left: left,
      top: top,
      width: touchSize,
      height: touchSize,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {
          setState(() => _dragging = true);
          widget.onMoveStart();
        },
        onPanUpdate: (details) => _handleDrag(details.delta),
        onPanEnd: (_) {
          setState(() => _dragging = false);
          widget.onMoved(_localPosition);
          widget.onMoveEnd();
        },
        onPanCancel: () {
          setState(() => _dragging = false);
          widget.onMoveEnd();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _dragging
                ? widget.item.rarity.color.withValues(alpha: 0.16)
                : Colors.transparent,
            border: Border.all(
              color: _dragging
                  ? widget.item.rarity.color.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: StudyDecorPreview(
            item: widget.item,
            size: spriteSize,
            backgroundColor: Colors.transparent,
            paddingFactor: 0,
          ),
        ),
      ),
    );
  }

  // Applies one drag delta while keeping the item inside its room zone.
  void _handleDrag(Offset delta) {
    setState(() {
      final next = Offset(
        _localPosition.dx + delta.dx / widget.sceneSize.width,
        _localPosition.dy + delta.dy / widget.sceneSize.height,
      );
      _localPosition = widget.item.zone.clampPosition(next);
    });
  }
}
