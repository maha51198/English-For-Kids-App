import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/progress_service.dart';
import '../services/reading_service.dart';
import '../widgets/memory_card.dart';

class GameScreen extends StatefulWidget {
  final Category category;
  final int levelIndex;
  const GameScreen({
    super.key,
    required this.category,
    required this.levelIndex,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _CardData {
  final int pid;
  final bool isWord;
  final WordPair pair;
  _CardData({required this.pid, required this.isWord, required this.pair});
}

class _GameScreenState extends State<GameScreen> {
  late List<_CardData> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  final List<int> _selected = [];
  int _moves = 0;
  int _matchedCount = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _lock = true;
  bool _started = false;
  bool _showLearn = true;
  bool _soundOn = true;
  WordPair? _toastPair;
  Timer? _toastTimer;
  final ScrollController _boardController = ScrollController();

  Level get _level => widget.category.levels[widget.levelIndex];

  @override
  void initState() {
    super.initState();
    ReadingService.instance.init();
    _initLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _toastTimer?.cancel();
    _boardController.dispose();
    // 🔇 إيقاف كل الأصوات عند مغادرة الشاشة
    ReadingService.instance.stop();
    super.dispose();
  }

  /// 🔇 إيقاف كل الأصوات وإلغاء أي Toast معلّق
  void _stopAllSounds() {
    _toastTimer?.cancel();
    _toastTimer = null;
    ReadingService.instance.stop();
    if (mounted && _toastPair != null) {
      setState(() => _toastPair = null);
    }
  }

  void _initLevel() {
    _timer?.cancel();
    _stopAllSounds();
    final level = _level;
    final cards = <_CardData>[];
    for (var i = 0; i < level.pairs.length; i++) {
      cards.add(_CardData(pid: i, isWord: true, pair: level.pairs[i]));
      cards.add(_CardData(pid: i, isWord: false, pair: level.pairs[i]));
    }
    cards.shuffle(math.Random());
    _cards = cards;
    _flipped = List.filled(cards.length, false);
    _matched = List.filled(cards.length, false);
    _selected.clear();
    _moves = 0;
    _matchedCount = 0;
    _seconds = 0;
    _lock = true;
    _started = false;
    _showLearn = true;
    _toastPair = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  // ═══════════════════════════════════════════════════════
  //  🔥 النطق الفوري عند النقر — بدون صوت عربي
  // ═══════════════════════════════════════════════════════
  void _onCardTap(int i) {
    if (_lock || _flipped[i] || _matched[i]) return;
    if (!_started) {
      _startTimer();
      _started = true;
    }
    HapticFeedback.selectionClick();

    final isFirstCard = _selected.isEmpty;

    setState(() {
      _flipped[i] = true;
      _selected.add(i);
    });

    // ═══ البطاقة الأولى: نطق فوري ═══
    if (isFirstCard) {
      ReadingService.instance.read(_cards[i].pair, mode: ReadMode.normal);
      return;
    }

    // ═══ البطاقة الثانية ═══
    final a = _selected[0];
    final b = _selected[1];
    final ca = _cards[a];
    final cb = _cards[b];
    final isMatch = ca.pid == cb.pid && ca.isWord != cb.isWord;

    setState(() {
      _moves++;
      _lock = true;
    });

    if (isMatch) {
      // ✅ تطابق: نطق الكلمة × 3 للتأكيد
      ReadingService.instance.read(cb.pair, mode: ReadMode.repeat3);

      Future.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        setState(() {
          _matched[a] = true;
          _matched[b] = true;
          _matchedCount++;
          _selected.clear();
          _lock = false;
        });
        HapticFeedback.mediumImpact();
        _showToast(ca.pair);
        if (_matchedCount == _cards.length ~/ 2) {
          // ⏳ ننتظر قليلاً حتى يكتمل النطق قليلاً ثم نُنهي
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) _onWin();
          });
        }
      });
    } else {
      // ❌ لا تطابق: نطق البطاقة الثانية فوراً
      ReadingService.instance.read(cb.pair, mode: ReadMode.normal);

      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 780), () {
        if (!mounted) return;
        setState(() {
          _flipped[a] = false;
          _flipped[b] = false;
          _selected.clear();
          _lock = false;
        });
      });
    }
  }

  void _showToast(WordPair pair) {
    _toastTimer?.cancel();
    setState(() => _toastPair = pair);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toastPair = null);
    });
  }

  // ═══════════════════════════════════════════════════════
  //  🏆 الفوز — إيقاف كل الأصوات قبل النافذة
  // ═══════════════════════════════════════════════════════
  Future<void> _onWin() async {
    _timer?.cancel();

    // 🔇 الأهم: إيقاف كل الأصوات فوراً قبل ظهور النافذة
    _stopAllSounds();

    final pairs = _cards.length ~/ 2;
    int stars = 1;
    if (_moves <= (pairs * 1.5).ceil()) {
      stars = 3;
    } else if (_moves <= (pairs * 2.3).ceil()) {
      stars = 2;
    }
    await ProgressService.setStars(
      widget.category.id,
      widget.levelIndex,
      stars,
    );
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    final isLast = widget.levelIndex >= widget.category.levels.length - 1;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(
        stars: stars,
        moves: _moves,
        seconds: _seconds,
        isLast: isLast,
      ),
    );

    // 🔇 إيقاف احتياطي بعد إغلاق النافذة (لمنع تسرب أي صوت)
    _stopAllSounds();

    if (!mounted) return;
    if (result == 'next') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            category: widget.category,
            levelIndex: widget.levelIndex + 1,
          ),
        ),
      );
    } else if (result == 'retry') {
      setState(_initLevel);
    } else if (result == 'levels') {
      Navigator.pop(context);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  🛑 زر "إنهاء" — إيقاف كل الأصوات
  // ═══════════════════════════════════════════════════════
  Future<void> _confirmEnd() async {
    _timer?.cancel();

    // 🔇 إيقاف كل الأصوات قبل ظهور النافذة
    _stopAllSounds();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141D33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إنهاء الجلسة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'هل تريد الخروج من المستوى الحالي؟ سيتم فقدان تقدمك في هذه الجلسة.',
          style: TextStyle(color: Color(0xFFB0BDD1), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'متابعة اللعب',
              style: TextStyle(color: Color(0xFF93A2BD)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'إنهاء',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      if (_started && _matchedCount < _cards.length ~/ 2) {
        _startTimer();
      }
    }
  }

  void _startGame() {
    setState(() {
      _showLearn = false;
      _lock = false;
    });
    // 🔇 لا يوجد صوت تلقائي — الصوت فقط عند النقر على البطاقات
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ─── Top Bar ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(
                    children: [
                      _iconBtn(Icons.arrow_forward, () {
                        _stopAllSounds();
                        Navigator.pop(context);
                      }),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${cat.icon}  ${_level.name}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _iconBtn(Icons.refresh, () {
                        setState(_initLevel);
                      }),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: _confirmEnd,
                        icon: const Icon(Icons.stop_circle_outlined, size: 16),
                        label: const Text(
                          'إنهاء',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444)
                              .withValues(alpha: 0.15),
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                            side: BorderSide(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── HUD ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _hud('الحركات', '$_moves'),
                      const SizedBox(width: 8),
                      _hud('الأزواج', '$_matchedCount/${_cards.length ~/ 2}'),
                      const SizedBox(width: 8),
                      _hud('الوقت', _fmt(_seconds)),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _soundOn = !_soundOn;
                            ReadingService.instance.setMuted(!_soundOn);
                          });
                        },
                        icon: Icon(
                          _soundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildBoard(cat)),
              ],
            ),
            if (_toastPair != null) _buildToast(),
            if (_showLearn) _buildLearnOverlay(cat),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
    );
  }

  Widget _hud(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8B9AB5)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString()}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _buildBoard(Category cat) {
    final n = _cards.length;
    if (n == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        double bestSize = 0;
        for (var c = 2; c <= n; c++) {
          final r = (n / c).ceil();
          final sw = (constraints.maxWidth - (c - 1) * gap) / c;
          final sh = (constraints.maxHeight - (r - 1) * gap) / r;
          final s = math.min(sw, sh);
          if (s > bestSize) bestSize = s;
        }
        final size = math.min(bestSize, 150.0);

        return Center(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(
                cat.color.withValues(alpha: 0.7),
              ),
              trackColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.05),
              ),
              thumbVisibility: WidgetStateProperty.all(true),
              trackVisibility: WidgetStateProperty.all(true),
              radius: const Radius.circular(10),
              thickness: WidgetStateProperty.all(8),
            ),
            child: Scrollbar(
              controller: _boardController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(10),
              interactive: true,
              scrollbarOrientation: ScrollbarOrientation.left,
              child: SingleChildScrollView(
                controller: _boardController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: List.generate(n, (i) {
                      final c = _cards[i];
                      return SizedBox(
                        width: size,
                        height: size,
                        child: MemoryCard(
                          isFlipped: _flipped[i],
                          isMatched: _matched[i],
                          onTap: () => _onCardTap(i),
                          faceDown: _cardBack(size),
                          faceUp: _cardFront(c, size),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardBack(double size) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D4D86), Color(0xFF222E5A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '?',
        style: TextStyle(
          fontSize: size * 0.33,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.30),
        ),
      ),
    );
  }

  Widget _cardFront(_CardData c, double size) {
    final matched = _matched[_cards.indexOf(c)];
    final bg = matched
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC9F7D8), Color(0xFF7EE2A4)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFD7E1F0)],
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: bg,
        boxShadow: [
          if (matched)
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.55),
              blurRadius: 14,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: _cardContent(c, size),
    );
  }

  Widget _cardContent(_CardData c, double size) {
    if (c.isWord) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            c.pair.en,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ),
      );
    }
    final isEmoji = _isEmoji(c.pair.visual);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        c.pair.visual,
        style: TextStyle(
          fontSize: isEmoji ? size * 0.6 : size * 0.5,
          fontWeight: isEmoji ? FontWeight.normal : FontWeight.w900,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  bool _isEmoji(String s) {
    if (s.isEmpty) return false;
    return s.runes.first > 0x1F000;
  }

  Widget _buildToast() {
    final pair = _toastPair!;
    return Positioned(
      left: 20,
      right: 20,
      bottom: 26,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141D33).withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pair.visual, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    pair.en,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA5F3C4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 16),
                Text(
                  pair.ar,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF93A2BD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearnOverlay(Category cat) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xEE050A19),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141D33),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${cat.icon} تعلّم الكلمات',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'اقرأ الكلمات واستمع لنطقها ثم ابدأ اللعب',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF93A2BD),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: _level.pairs.map((p) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.055),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 34,
                                      child: Text(
                                        p.visual,
                                        style: const TextStyle(fontSize: 22),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          p.en,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      width: 1,
                                      height: 22,
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      p.ar,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF93A2BD),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => ReadingService.instance
                                            .read(p, mode: ReadMode.normal),
                                        icon: const Icon(
                                          Icons.volume_up_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.07),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _startGame,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'ابدأ اللعب 🚀',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══ نافذة الفوز ═══
class _WinDialog extends StatelessWidget {
  final int stars;
  final int moves;
  final int seconds;
  final bool isLast;

  const _WinDialog({
    required this.stars,
    required this.moves,
    required this.seconds,
    required this.isLast,
  });

  String _fmt(int s) =>
      '${(s ~/ 60).toString()}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final emoji = stars == 3 ? '🏆' : (stars == 2 ? '🎉' : '👍');
    final title = stars == 3
        ? 'ممتاز! ذاكرة رائعة'
        : stars == 2
        ? 'أحسنت!'
        : 'أكملت المستوى!';

    return Dialog(
      backgroundColor: const Color(0xFF141D33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 40,
                    color: i < stars
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF334155),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat('الحركات', '$moves'),
                  const SizedBox(width: 14),
                  _stat('الوقت', _fmt(seconds)),
                ],
              ),
              const SizedBox(height: 16),
              if (!isLast)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ReadingService.instance.stop();
                      Navigator.pop(context, 'next');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'المستوى التالي ➜',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ReadingService.instance.stop();
                        Navigator.pop(context, 'retry');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ReadingService.instance.stop();
                        Navigator.pop(context, 'levels');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'المستويات',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    ReadingService.instance.stop();
                    Navigator.pop(context, 'levels');
                  },
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text(
                    'إنهاء والعودة للرئيسية',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: const Color(0xFF93A2BD),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF93A2BD)),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
