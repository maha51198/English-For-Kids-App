import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/reading_service.dart';

class ReadingScreen extends StatefulWidget {
  final Category category;
  const ReadingScreen({super.key, required this.category});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _reading = ReadingService.instance;
  late List<WordPair> _words;
  int _index = 0;
  bool _showArabic = false;
  ReadMode _mode = ReadMode.normal;
  bool _autoPlaying = false;
  bool _busy = false;
  final ScrollController _wordScrollController = ScrollController();

  /// الأوضاع المتاحة في شاشة القراءة
  static const List<ReadMode> _availableModes = [
    ReadMode.normal,
    ReadMode.slow,
    ReadMode.spelling,
    ReadMode.repeat3,
  ];

  @override
  void initState() {
    super.initState();
    _words = widget.category.levels.expand((l) => l.pairs).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reading.init();
      Future.delayed(const Duration(milliseconds: 300), _playCurrent);
    });
  }

  @override
  void dispose() {
    _autoPlaying = false;
    _reading.stop();
    _wordScrollController.dispose();
    super.dispose();
  }

  WordPair get _current => _words[_index];

  Future<void> _playCurrent() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _reading.read(_current, mode: _mode);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_index < _words.length - 1) {
      setState(() {
        _index++;
        _showArabic = false;
      });
      await _playCurrent();
    }
  }

  Future<void> _prev() async {
    HapticFeedback.selectionClick();
    if (_index > 0) {
      setState(() {
        _index--;
        _showArabic = false;
      });
      await _playCurrent();
    }
  }

  Future<void> _autoPlayAll() async {
    if (_autoPlaying) {
      _autoPlaying = false;
      await _reading.stop();
      setState(() {});
      return;
    }
    _autoPlaying = true;
    setState(() {});
    for (var i = _index; i < _words.length; i++) {
      if (!_autoPlaying || !mounted) break;
      setState(() {
        _index = i;
        _showArabic = false;
      });
      await _reading.read(_words[i], mode: _mode);
      await Future.delayed(
          Duration(milliseconds: _mode == ReadMode.spelling ? 1400 : 900));
    }
    if (mounted) setState(() => _autoPlaying = false);
  }

  void _cycleMode() {
    final next = _availableModes[
        (_availableModes.indexOf(_mode) + 1) % _availableModes.length];
    setState(() => _mode = next);
    _playCurrent();
  }

  String _modeLabel(ReadMode m) {
    switch (m) {
      case ReadMode.normal:
        return 'عادي';
      case ReadMode.slow:
        return 'بطيء';
      case ReadMode.spelling:
        return 'تهجئة';
      case ReadMode.repeat3:
        return 'تكرار ×3';
    }
  }

  IconData _modeIcon(ReadMode m) {
    switch (m) {
      case ReadMode.normal:
        return Icons.play_arrow_rounded;
      case ReadMode.slow:
        return Icons.slow_motion_video_rounded;
      case ReadMode.spelling:
        return Icons.spellcheck_rounded;
      case ReadMode.repeat3:
        return Icons.repeat_rounded;
    }
  }

  Future<void> _confirmEnd() async {
    _autoPlaying = false;
    await ReadingService.instance.stop();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141D33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'إنهاء جلسة القراءة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'هل تريد الخروج من وضع القراءة؟',
          style: TextStyle(color: Color(0xFFB0BDD1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('متابعة',
                style: TextStyle(color: Color(0xFF93A2BD))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('إنهاء',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final w = _current;
    final isEmoji = w.visual.runes.first > 0x1F000;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${cat.icon}  القراءة — ${cat.title}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final m = _reading.isMuted;
                      _reading.setMuted(!m);
                      setState(() {});
                    },
                    icon: Icon(
                      _reading.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: _confirmEnd,
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('إنهاء',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Progress ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'كلمة ${_index + 1} من ${_words.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF93A2BD),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: cat.color.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${w.en.length} أحرف',
                          style: TextStyle(
                            fontSize: 11,
                            color: cat.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / _words.length,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(cat.color),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Word Card ───
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 320;
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: _playCurrent,
                      onDoubleTap: () {
                        setState(() => _showArabic = !_showArabic);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cat.color.withValues(alpha: 0.22),
                              const Color(0xFF141D33),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: cat.color.withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cat.color.withValues(alpha: 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ScrollbarTheme(
                          data: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(
                                cat.color.withValues(alpha: 0.7)),
                            trackColor: WidgetStateProperty.all(
                                Colors.white.withValues(alpha: 0.05)),
                            thumbVisibility: WidgetStateProperty.all(true),
                            trackVisibility: WidgetStateProperty.all(true),
                            radius: const Radius.circular(10),
                            thickness: WidgetStateProperty.all(6),
                          ),
                          child: Scrollbar(
                            controller: _wordScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thickness: 6,
                            radius: const Radius.circular(10),
                            interactive: true,
                            scrollbarOrientation: ScrollbarOrientation.left,
                            child: SingleChildScrollView(
                              controller: _wordScrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // الصورة / الحرف / الرقم
                                    Text(
                                      w.visual,
                                      style: TextStyle(
                                        fontSize: compact
                                            ? (isEmoji ? 70 : 60)
                                            : (isEmoji ? 100 : 84),
                                        fontWeight: isEmoji
                                            ? FontWeight.normal
                                            : FontWeight.w900,
                                      ),
                                    ),

                                    const SizedBox(height: 22),

                                    // الكلمة الأجنبية
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          w.en,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: compact ? 32 : 44,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ✅ مسافة كبيرة قبل الترجمة
                                    const SizedBox(height: 22),

                                    // فاصل أفقي أنيق
                                    Container(
                                      width: 70,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: cat.color.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),

                                    // ✅ مسافة بعد الفاصل
                                    const SizedBox(height: 22),

                                    // الترجمة العربية (نص فقط)
                                    AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      opacity: _showArabic ? 1 : 0.15,
                                      child: Text(
                                        w.ar,
                                        style: TextStyle(
                                          fontSize: compact ? 18 : 22,
                                          color: Colors.white
                                              .withValues(alpha: 0.92),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                    Text(
                                      _showArabic
                                          ? 'اضغط مرتين لإخفاء المعنى'
                                          : 'اضغط مرتين لإظهار المعنى',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
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
                },
              ),
            ),

            // ─── Mode Chip ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _cycleMode,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.055),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Row(
                          children: [
                            Icon(_modeIcon(_mode), size: 20, color: cat.color),
                            const SizedBox(width: 10),
                            const Text(
                              'وضع القراءة:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF93A2BD),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _modeLabel(_mode),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.swap_horiz_rounded,
                                size: 18, color: Color(0xFF93A2BD)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ─── Controls ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  _circleBtn(
                    icon: Icons.skip_previous_rounded,
                    onTap: _prev,
                    disabled: _index == 0,
                  ),
                  const SizedBox(width: 10),
                  _circleBtn(
                    icon: _busy
                        ? Icons.hourglass_top_rounded
                        : Icons.volume_up_rounded,
                    onTap: _playCurrent,
                    primary: true,
                    color: cat.color,
                  ),
                  const SizedBox(width: 10),
                  _circleBtn(
                    icon: _autoPlaying
                        ? Icons.pause_rounded
                        : Icons.play_circle_fill_rounded,
                    onTap: _autoPlayAll,
                    color: _autoPlaying ? Colors.orangeAccent : null,
                  ),
                  const SizedBox(width: 10),
                  _circleBtn(
                    icon: Icons.skip_next_rounded,
                    onTap: _next,
                    disabled: _index >= _words.length - 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
    bool disabled = false,
    Color? color,
  }) {
    final c = color ?? (primary ? const Color(0xFF6366F1) : Colors.white);
    return Expanded(
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Material(
          color: primary
              ? c.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primary
                      ? c.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(icon, color: c, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
