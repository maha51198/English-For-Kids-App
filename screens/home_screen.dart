import 'package:flutter/material.dart';
import '../data/vocabulary.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import 'levels_screen.dart';
import 'reading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _progress = {};
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
    final p = await ProgressService.loadAll();
    if (mounted) setState(() => _progress = p);
  }

  int _stars(String catId, int level) {
    final cat = _progress[catId];
    if (cat is! Map) return 0;
    return (cat[level.toString()] as num?)?.toInt() ?? 0;
  }

  int _completedLevels(Category cat) {
    var count = 0;
    for (var i = 0; i < cat.levels.length; i++) {
      if (_stars(cat.id, i) > 0) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(const Color(0xFF6366F1)),
            trackColor:
                WidgetStateProperty.all(Colors.white.withValues(alpha: 0.06)),
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
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ─── Header ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: isWide ? 40 : 26, bottom: 22),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [
                              Color(0xFFA5B4FC),
                              Color(0xFF67E8F9),
                              Color(0xFFF9A8D4),
                            ],
                          ).createShader(r),
                          child: const Text(
                            '🎯 لعبة الذاكرة',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'تعلّم المفردات الإنجليزية باللعب',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Grid ───
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final cat = categories[i];
                        final done = _completedLevels(cat);
                        final total = cat.levels.length;
                        return _CategoryCard(
                          category: cat,
                          completed: done,
                          total: total,
                          onTap: () => _onCategoryTap(cat),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),

                // ─── Footer ───
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'اختر فئة وابدأ رحلتك في التعلّم',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCategoryTap(Category cat) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF141D33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Text(
                    cat.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sheetOption(
                icon: Icons.grid_view_rounded,
                title: 'لعبة الذاكرة',
                subtitle: 'طابق الكلمات مع الصور',
                color: cat.color,
                onTap: () => Navigator.pop(context, 'game'),
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.record_voice_over_rounded,
                title: 'القراءة والاستماع',
                subtitle: 'استمع، تهجّأ، وكرّر الكلمات',
                color: cat.color,
                onTap: () => Navigator.pop(context, 'read'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'game') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LevelsScreen(category: cat)),
      );
      _load();
    } else if (choice == 'read') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReadingScreen(category: cat)),
      );
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final int completed;
  final int total;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(c, const Color(0xFF111A33), 0.72)!,
                const Color(0xFF111A33),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(category.icon, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 6),
                Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  category.sub,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFA8B6D1),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.13),
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed / $total مستوى',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8B9AB5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sheetOption({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF93A2BD),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Color(0xFF93A2BD),
            ),
          ],
        ),
      ),
    ),
  );
}
