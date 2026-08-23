import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/card_catalog.dart';
import '../logic/flip_engine.dart';
import '../models/playing_card_model.dart';
import '../services/collection_service.dart';
import '../widgets/tazo_card.dart';

enum Phase { placing, aiming, throwing, aiThrowing, over }

class KapsScreen extends StatefulWidget {
  const KapsScreen({super.key});
  @override
  State<KapsScreen> createState() => _KapsScreenState();
}

class _KapsScreenState extends State<KapsScreen> with TickerProviderStateMixin {
  final FlipEngine _engine = FlipEngine();

  late final AnimationController _powerCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  late final AnimationController _throwCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final AnimationController _dustCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _flipCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  Phase _phase = Phase.placing;
  List<PlayingCardModel> _myDeck = [];
  List<PlayingCardModel> _aiDeck = [];
  final List<PlayingCardModel> _stack = [];
  final List<PlayingCardModel> _won = [];
  bool _throwerIsMe = true;
  bool _fromTop = false;
  double _lockedPower = 0;
  String _msg = 'جهّز نفسك…';
  String? _winner;

  // مواضع نسبية مطابقة لخلفية الحارة (عدّلها لضبط المحاذاة)
  static const _handPos = Offset(0.42, 0.46);   // يدك في الصورة
  static const _oppPos = Offset(0.66, 0.30);    // الخصم الجالس
  static const _targetPos = Offset(0.50, 0.80); // قرص الأرض

  @override
  void initState() {
    super.initState();
    _startMatch();
  }

  @override
  void dispose() {
    _powerCtl.dispose();
    _throwCtl.dispose();
    _dustCtl.dispose();
    _flipCtl.dispose();
    super.dispose();
  }

  void _startMatch() {
    final col = context.read<CollectionService>();
    _myDeck = col.owned.take(5).toList();
    while (_myDeck.length < 5) {
      _myDeck.add(CardCatalog.all.firstWhere((c) => c.rarity == Rarity.common));
    }
    _aiDeck = List.generate(
        5, (_) => CardCatalog.all[Random().nextInt(CardCatalog.all.length)]);
    _stack.clear();
    _won.clear();
    _winner = null;

    _stack.add(_aiDeck.removeAt(0));
    _flipCtl.reset();
    _throwerIsMe = true;
    _phase = Phase.aiming;
    _msg = 'الخصم فرش قرصه… اكبس!';
    setState(() {});
  }

  void _kapsTap() async {
    if (_phase != Phase.aiming) return;
    _lockedPower = _powerCtl.value;
    _fromTop = false;
    setState(() => _phase = Phase.throwing);

    await _throwCtl.forward(from: 0);
    _dustCtl.forward(from: 0);

    final flipped = _engine.resolveKaps(_lockedPower).flippedTarget;
    if (!mounted) return;

    if (flipped) {
      await _flipCtl.forward(from: 0);
      _won.addAll(_stack);
      _stack.clear();
      _msg = 'قلبتها! أخذت الكومة 🔥';
      if (_aiDeck.isEmpty) {
        _end(true);
        return;
      }
      _stack.add(_aiDeck.removeAt(0));
      _flipCtl.reset();
      _phase = Phase.aiming;
      _throwerIsMe = true;
      _msg = 'الخصم فرش قرصاً جديداً… اكبس!';
    } else {
      _stack.add(_myDeck.removeAt(0));
      _msg = 'ما انقلب… قرصك صار بالكومة';
      _phase = Phase.aiThrowing;
      _throwerIsMe = false;
      _aiTurn();
    }
    setState(() {});
  }

  void _aiTurn() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _phase == Phase.over) return;

    _fromTop = true;
    setState(() {});

    await _throwCtl.forward(from: 0);
    _dustCtl.forward(from: 0);

    final flipped =
        _engine.resolveKaps(0.55 + 0.4 * _engine.nextDouble()).flippedTarget;
    if (!mounted) return;

    if (flipped) {
      await _flipCtl.forward(from: 0);
      _stack.clear();
      _msg = 'الخصم قلبها! راحت الكومة 😬';
      if (_myDeck.isEmpty) {
        _end(false);
        return;
      }
      _stack.add(_myDeck.removeAt(0));
      _flipCtl.reset();
      _phase = Phase.aiThrowing;
      _aiTurn();
    } else {
      _stack.add(_aiDeck.removeAt(0));
      _msg = 'ما قلبها… دورك تكبس!';
      _phase = Phase.aiming;
      _throwerIsMe = true;
    }
    setState(() {});
  }

  void _end(bool iWon) {
    _phase = Phase.over;
    _winner = iWon ? 'me' : 'ai';
    final col = context.read<CollectionService>();
    if (iWon) {
      col.addCards(_won, coins: 150 + 25 * _won.length, xp: 60);
    } else {
      col.addCards(const [], coins: 20, xp: 10);
    }
    setState(() {});
  }

  Future<bool> _confirmExit() async {
    if (_phase == Phase.over) return true;
    final keep = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('⚖️ قانون الحارة'),
              content: const Text(
                  'الانسحاب وسط الجولة يعتبر خسارة وتُصادر بطاقتك فوراً للخصم!'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('أكمل اللعب')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('أنسحب 💀')),
              ],
            ));
    return keep ?? false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _phase == Phase.over,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (await _confirmExit()) {
            _end(false);
            if (mounted) Navigator.pop(context);
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              // ===== خلفية الحارة الليلية (اليد + الخصم الجالس) =====
              Positioned.fill(
                child: Image.asset('assets/images/game_bg.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF1A1208))),
              ),
              const DecoratedBox(decoration: BoxDecoration(color: Color(0x22000000))),

              SafeArea(
                child: Column(
                  children: [
                    Expanded(child: _ground()),
                    _messageBar(),
                    _powerBar(),
                    _kapsButton(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              if (_winner != null) _winnerOverlay(),
            ],
          ),
        ),
      );

  Widget _ground() => LayoutBuilder(
        builder: (context, size) {
          final w = size.maxWidth, h = size.maxHeight;
          const disc = 96.0;
          return Stack(
            children: [
              // شارات العدّاد
              Positioned(left: w * 0.05, top: 8, child: _chip('😎 أقراطي: ${_myDeck.length}')),
              Positioned(right: w * 0.05, top: 8, child: _chip('🤖 الخصم: ${_aiDeck.length}')),

              // ===== الكومة/الهدف على الأرض (موضع قرص «كساب» بالصورة) =====
              if (_stack.isNotEmpty)
                Positioned(
                  left: _targetPos.dx * w - disc / 2,
                  top: _targetPos.dy * h - disc / 2,
                  child: AnimatedBuilder(
                    animation: _flipCtl,
                    builder: (_, __) => Stack(
                      children: [
                        for (int i = 0; i < _stack.length; i++)
                          Positioned(
                            left: i * 5.0,
                            top: -i * 7.0,
                            child: TazoCard(
                              card: _stack[i],
                              size: disc,
                              faceUp: i != _stack.length - 1 || _flipCtl.value > .5,
                              angleX: i == _stack.length - 1
                                  ? pi * Curves.easeInOut.transform(_flipCtl.value)
                                  : 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ===== قرصي بين أصابعي (فوق يد الخلفية) =====
              if (_myDeck.isNotEmpty &&
                  (_phase == Phase.aiming || _phase == Phase.placing))
                Positioned(
                  left: _handPos.dx * w - 40,
                  top: _handPos.dy * h - 40,
                  child: TazoCard(card: _myDeck.first, size: 80),
                ),

              // ===== القرص الطائر (قوس رمي + دوران) =====
              if (_phase == Phase.throwing || _phase == Phase.aiThrowing)
                AnimatedBuilder(
                  animation: _throwCtl,
                  builder: (_, __) {
                    final t = Curves.easeIn.transform(_throwCtl.value);
                    final start = _fromTop ? _oppPos : _handPos;
                    final p = Offset.lerp(start, _targetPos, t)!;
                    return Positioned(
                      left: p.dx * w - disc / 2,
                      top: p.dy * h - disc / 2 - 70 * sin(pi * t),
                      child: Transform.rotate(
                        angle: 6 * pi * t,
                        child: TazoCard(
                          card: _throwerIsMe
                              ? (_myDeck.isNotEmpty ? _myDeck.first : _stack.last)
                              : (_aiDeck.isNotEmpty ? _aiDeck.first : _stack.last),
                          size: disc,
                        ),
                      ),
                    );
                  },
                ),

              // ===== غبار الارتطام عند الهدف =====
              AnimatedBuilder(
                animation: _dustCtl,
                builder: (_, __) => _dustCtl.value > 0
                    ? Positioned(
                        left: _targetPos.dx * w - 80,
                        top: _targetPos.dy * h - 60,
                        child: CustomPaint(
                            size: const Size(160, 120),
                            painter: _DustPainter(_dustCtl.value)),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      );

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC1B1208),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x66F3E9D2)),
        ),
        child: Text(s,
            style: const TextStyle(
                color: Color(0xFFF3E9D2), fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _messageBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFEFDDB4), Color(0xFFDCC493)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x99705A33), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Text(_msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF241608), fontSize: 15, fontWeight: FontWeight.w900)),
      );

  Widget _powerBar() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return AnimatedBuilder(
              animation: _powerCtl,
              builder: (_, __) {
                final v = _phase == Phase.aiming ? _powerCtl.value : _lockedPower;
                return Stack(
                  children: [
                    Container(
                        height: 14,
                        decoration: BoxDecoration(
                            color: const Color(0xCC1B1208),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0x66F3E9D2)))),
                    Positioned(
                      left: w * 0.7, top: 2, bottom: 2, width: w * 0.2,
                      child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xAAFFD54F),
                              borderRadius: BorderRadius.circular(5))),
                    ),
                    Positioned(
                      top: -4, left: v * (w - 10),
                      child: Container(
                          width: 10, height: 22,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF3E2412)))),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _kapsButton() => GestureDetector(
        onTap: _phase == Phase.aiming ? _kapsTap : null,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _phase == Phase.aiming
                ? const [Color(0xFFE07A2F), Color(0xFFB4551B)]
                : const [Color(0xFF7A6248), Color(0xFF5C4936)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3E2412), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: const Text('💥 كبس!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFFF6E5))),
        ),
      );

  Widget _winnerOverlay() => Positioned.fill(
        child: Container(
          color: const Color(0xAA000000),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_winner == 'me' ? '🏆 فزت يا كسّاب!' : '💀 خسرت… صودر قرصك',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                        _winner == 'me'
                            ? 'كسبت ${_won.length} قرص + ${150 + 25 * _won.length} عملة'
                            : 'جرب حظك بجولة جديدة',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _startMatch, child: const Text('جولة جديدة 🔁')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// غبار الارتطام
class _DustPainter extends CustomPainter {
  final double v;
  _DustPainter(this.v);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFC9A15F).withOpacity(1 - v);
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final d = 20 + 55 * v;
      c.drawCircle(Offset(s.width / 2 + cos(a) * d, s.height / 2 + sin(a) * d * .5),
          7 * (1 - v), p);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter o) => o.v != v;
}
