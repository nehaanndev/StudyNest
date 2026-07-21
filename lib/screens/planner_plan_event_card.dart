part of 'planner_plan_timeline.dart';

/// Displays an editable event and owns its temporary resize preview.
class _TimelineEventCard extends StatefulWidget {
  const _TimelineEventCard({
    required this.event,
    required this.height,
    required this.minuteHeight,
    required this.snapMinutes,
    required this.visualTheme,
    required this.canResize,
    required this.onTap,
    required this.onResize,
  });

  final PlannerEvent event;
  final double height;
  final double minuteHeight;
  final int snapMinutes;
  final StudyVisualTheme visualTheme;
  final bool canResize;
  final VoidCallback onTap;
  final ValueChanged<DateTime> onResize;

  /// Creates state for the block's in-progress resize delta.
  @override
  State<_TimelineEventCard> createState() => _TimelineEventCardState();
}

class _TimelineEventCardState extends State<_TimelineEventCard> {
  double _resizeDelta = 0;

  /// Resets the visual resize preview when the user grabs the handle.
  void _startResize(DragStartDetails details) {
    setState(() => _resizeDelta = 0);
  }

  /// Extends or contracts the block preview as the handle moves.
  void _updateResize(DragUpdateDetails details) {
    setState(() => _resizeDelta += details.delta.dy);
  }

  /// Snaps and emits the final end time when resizing completes.
  void _finishResize(DragEndDetails details) {
    final minuteDelta = (_resizeDelta / widget.minuteHeight).round();
    final rawEnd = widget.event.endsAt.add(Duration(minutes: minuteDelta));
    final snappedEnd = snapPlannerTime(
      rawEnd,
      intervalMinutes: widget.snapMinutes,
    );
    setState(() => _resizeDelta = 0);
    widget.onResize(snappedEnd);
  }

  /// Adjusts duration by one snap interval for assistive-technology users.
  void _adjustDuration(int direction) {
    widget.onResize(
      widget.event.endsAt.add(
        Duration(minutes: widget.snapMinutes * direction.sign),
      ),
    );
  }

  /// Builds a long-press draggable event with a dedicated resize handle.
  @override
  Widget build(BuildContext context) {
    final color = plannerCategoryColor(widget.event.category);
    final displayHeight = math.max(28.0, widget.height + _resizeDelta);
    final eventSurface = _TimelineEventSurface(
      event: widget.event,
      color: color,
      visualTheme: widget.visualTheme,
      showResizeHandle: widget.canResize,
      onTap: widget.onTap,
      onIncrease: widget.canResize ? () => _adjustDuration(1) : null,
      onDecrease: widget.canResize ? () => _adjustDuration(-1) : null,
      onResizeStart: _startResize,
      onResizeUpdate: _updateResize,
      onResizeEnd: _finishResize,
    );

    return SizedBox(
      height: displayHeight,
      child: LongPressDraggable<PlannerEvent>(
        data: widget.event,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 118,
            height: math.min(displayHeight, 74),
            child: _TimelineEventSurface(
              event: widget.event,
              color: color,
              visualTheme: widget.visualTheme,
              showResizeHandle: false,
              onTap: null,
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.24, child: eventSurface),
        child: eventSurface,
      ),
    );
  }
}

/// Paints the shared event surface used in-place and during dragging.
class _TimelineEventSurface extends StatelessWidget {
  const _TimelineEventSurface({
    required this.event,
    required this.color,
    required this.visualTheme,
    required this.showResizeHandle,
    required this.onTap,
    this.onIncrease,
    this.onDecrease,
    this.onResizeStart,
    this.onResizeUpdate,
    this.onResizeEnd,
  });

  final PlannerEvent event;
  final Color color;
  final StudyVisualTheme visualTheme;
  final bool showResizeHandle;
  final VoidCallback? onTap;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final GestureDragStartCallback? onResizeStart;
  final GestureDragUpdateCallback? onResizeUpdate;
  final GestureDragEndCallback? onResizeEnd;

  /// Builds a readable event card with timing, category color, and resize grip.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label:
          '${event.title}, ${event.category}, '
          '${timeRange(event.startsAt, event.endsAt)}',
      hint: onTap == null
          ? null
          : showResizeHandle
          ? 'Activate to edit. Long press and drag to move. '
                'Swipe up or down to change the duration.'
          : 'Activate to edit. Long press and drag to move.',
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: Material(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.26),
          visualTheme.surfaceAlt,
        ),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 5, 5, 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showTime = constraints.maxHeight >= 24;
                final titleLines = constraints.maxHeight >= 40 ? 2 : 1;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: titleLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: visualTheme.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              height: 1.05,
                            ),
                          ),
                          if (showTime) ...[
                            const SizedBox(height: 2),
                            Text(
                              clockTime(event.startsAt),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: visualTheme.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showResizeHandle)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 12,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: onResizeStart,
                          onVerticalDragUpdate: onResizeUpdate,
                          onVerticalDragEnd: onResizeEnd,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 20,
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
