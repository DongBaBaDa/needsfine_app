import 'package:flutter/material.dart';

class DraggableFloatingActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Offset initialOffset;
  final VoidCallback? onDragEnd;
  final String heroTag;
  final double? parentHeight; // New parameter

  const DraggableFloatingActionButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.initialOffset = const Offset(300, 400),
    this.onDragEnd,
    required this.heroTag,
    this.parentHeight,
  });

  @override
  State<DraggableFloatingActionButton> createState() => _DraggableFloatingActionButtonState();
}

class _DraggableFloatingActionButtonState extends State<DraggableFloatingActionButton> {
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
  }

  @override
  void didUpdateWidget(DraggableFloatingActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initialOffset changed (e.g. screen resize), update _offset
    // But only if it's significantly different to avoid resetting small drags if any
    if (widget.initialOffset != oldWidget.initialOffset) {
       _offset = widget.initialOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final screenSize = MediaQuery.of(context).size;
            final padding = MediaQuery.of(context).padding;
            
            double dx = _offset.dx + details.delta.dx;
            double dy = _offset.dy + details.delta.dy;

            // Boundaries
            double minX = padding.left;
            double maxX = screenSize.width - padding.right - 56;
            double minY = padding.top; 
            
            // Use parent height if available, otherwise screen height (fallback)
            double heightLimit = widget.parentHeight ?? screenSize.height;
            double maxY = heightLimit - 56 - padding.bottom; // 56 is FAB size

            if (dx < minX) dx = minX;
            if (dx > maxX) dx = maxX;
            if (dy < 0) dy = 0; 
            if (dy > maxY) dy = maxY;

            _offset = Offset(dx, dy);
          });
        },
        onPanEnd: (_) => widget.onDragEnd?.call(),
        child: FloatingActionButton(
          heroTag: widget.heroTag,
          onPressed: widget.onPressed,
          backgroundColor: const Color(0xFFC87CFF),
          foregroundColor: Colors.white,
          elevation: 4,
          child: widget.child,
        ),
      ),
    );
  }
}
