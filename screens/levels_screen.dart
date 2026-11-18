import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';

class LevelsScreen extends StatefulWidget {
  final Category category;
  const LevelsScreen({super.key, required this.category});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  List<int> _stars = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = <int>[];
    for (var i = 0; i < widget.category.levels.length; i++) {
      list.add(await ProgressService.getStars(widget.category.id, i));
    }
    if (mounted) setState(() => _stars = list);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: '${cat.icon}  ${cat.title}',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor:
                          WidgetStateProperty.all(const Color(0xFF6366F1)),
                      trackColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.06)),
                      thumbVisibility: WidgetStateProperty.all(true),
                      trackVisibility: WidgetStateProperty.all(true),
                      radius: const Radius.circular(10),
                      thickness: WidgetStateProperty.all(8),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(10),
                      interactive: true,
                      scrollbarOrientation: ScrollbarOrientation.left,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                        itemCount: cat.levels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (_, i) {
                          final lvl = cat.levels[i];
                          final s = i < _stars.length ? _stars[i] : 0;
                          return _LevelRow(
                            index: i,
                            name: lvl.name,
                            pairCount: lvl.pairs.length,
                            stars: s,
                            color: cat.color,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                    category: cat,
                                    levelIndex: i,
                                  ),
                                ),
                              );
                              _load();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final int index;
  final String name;
  final int pairCount;
  final int stars;
  final Color color;
  final VoidCallback onTap;

  const _LevelRow({
    required this.index,
    required this.name,
    required this.pairCount,
    required this.stars,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$pairCount أزواج • ${pairCount * 2} بطاقة',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF93A2BD),
                    ),
                  ),
                ],
              ),
            ),
            _Stars(stars: stars),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int stars;
  const _Stars({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < stars;
        return Icon(
          Icons.star_rounded,
          size: 18,
          color: on ? const Color(0xFFFBBF24) : const Color(0xFF334155),
        );
      }),
    );
  }
}
