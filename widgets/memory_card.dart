import 'dart:math' as math;
import 'package:flutter/material.dart';

class MemoryCard extends StatefulWidget {
  final bool isFlipped;
  final bool isMatched;
  final Widget faceDown;
  final Widget faceUp;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.isFlipped,
    required this.isMatched,
    required this.faceDown,
    required this.faceUp,
    required this.onTap,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  bool get _shouldFlip => widget.isFlipped || widget.isMatched;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: _shouldFlip ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFlip = oldWidget.isFlipped || oldWidget.isMatched;
    if (_shouldFlip != oldFlip) {
      _shouldFlip ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final angle = _ctrl.value * math.pi;
          final showBack = angle < math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showBack
                ? widget.faceDown
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.faceUp,
                  ),
          );
        },
      ),
    );
  }
}