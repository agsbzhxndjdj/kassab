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

  // ===== متحكمات الأنيميشن =====
  late final AnimationController _powerCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  // مرحلة الرمي الكاملة (تحضير + إطلاق + طيران + ارتطام)
  late final AnimationController _throwCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  // مرحلة القلب الدرامي
  late final AnimationController _flipCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  // اهتزاز الكاميرا
  late final AnimationController _shakeCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  // جسيمات الغبار
  late final AnimationController _dustCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  // احتفال الفوز
  late final AnimationController _winCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  Phase _phase = Phase.placing;
  List<PlayingCardModel> _myDeck = [];
  List<PlayingCardModel> _aiDeck = [];
  final List<_StackCard> _stack = [];
  final List<PlayingCardModel> _won = [];
  bool _throwerIsMe = true;
  double _lockedPower = 0;
  String _msg = 'جهّز نفسك…';
  String? _winner;
  late final List<_DustParticle> _particles;
  final Random _rand = Random();

  // مواضع نسبية
  static const _handStart = Offset(0.38, 0.78);   // اليد في وضع الاستعداد
  static const _handPullBack = Offset(0.25, 0.95); // اليد ترجع للخلف قبل الرمي
  static const _handRelease = Offset(0.42, 0.60);  // اليد تطلق القرص
  static const _oppPos = Offset(0.66, 0.28);
  static const _targetPos = Offset(0.50, 0.55);    // نقطة الارتطام (أعلى قليلاً من الأرض)
  static const _landPos = Offset(0.50, 0.78);      // موضع الكومة النهائي على الأرض

  @override
  void initState() {
    super.initState();
    _particles = List.generate(40, (_) => _DustParticle.random(_rand));
    _startMatch();
  }

  @override
  void dispose() {
    _powerCtl.dispose();
    _throwCtl.dispose();
    _flipCtl.dispose();
    _shakeCtl.dispose();
    _dustCtl.dispose();
    _winCtl.dispose();
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

    _stack.add(_StackCard(_aiDeck.removeAt(0)));
    _throwerIsMe = true;
    _phase = Phase.aiming;
    _msg = 'الخصم فرش قرصه… اكبس!';
    setState(() {});
  }

  void _kapsTap() async {
    if (_phase != Phase.aiming) return;
    _lockedPower = _powerCtl.value;
    setState(() => _phase = Phase.throwing);
    _throwerIsMe = true;
    await _performThrow(fromOpponent: false);
  }

  void _aiTurn() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _phase == Phase.over) return;
    _throwerIsMe = false;
    setState(() => _phase = Phase.aiThrowing);
    await _performThrow(fromOpponent: true);
  }

  /// المشهد السينمائي الكامل: تحضير → إطلاق → طيران → ارتطام → قرار
  Future<void> _performThrow({required bool fromOpponent}) async {
    // 1️⃣ تحضير وإطلاق
    await _throwCtl.forward(from: 0);
    if (!mounted) return;

    // 2️⃣ ارتطام + اهتزاز + غبار
    _shakeCtl.forward(from: 0);
    _dustCtl.forward(from: 0);

    // 3️⃣ حساب النتيجة
    final power = fromOpponent
        ? 0.55 + 0.4 * _engine.nextDouble()
        : _lockedPower;
    final flipped = _engine.resolveKaps(power).flippedTarget;

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    // 4️⃣ قرار القلب
    if (flipped) {
      await _flipCtl.forward(from: 0);
      // نقل الكومة للفائز
      if (fromOpponent) {
        _stack.clear();
        _msg = 'الخصم قلبها! راحت الكومة 😬';
        if (_myDeck.isEmpty) { _end(false); return; }
        _stack.add(_StackCard(_myDeck.removeAt(0)));
        _phase = Phase.aiThrowing;
        _aiTurn();
      } else {
        _won.addAll(_stack.map((e) => e.card));
        _stack.clear();
        await _winCtl.forward(from: 0);
        _msg = 'قلبتها! أخذت الكومة 🔥';
        if (_aiDeck.isEmpty) { _end(true); return; }
        _stack.add(_StackCard(_aiDeck.removeAt(0)));
        _phase = Phase.aiming;
        _msg = 'الخصم فرش قرصاً جديداً… اكبس!';
      }
    } else {
      // البطاقة تُضاف للكومة
      final card = fromOpponent ? _aiDeck.removeAt(0) : _myDeck.removeAt(0);
      _stack.add(_StackCard(card));
      if (fromOpponent) {
        _msg = 'ما قلبها… دورك تكبس!';
        _phase = Phase.aiming;
      } else {
        _msg = 'ما انقلب… قرصك صار بالكومة';
        _phase = Phase.aiThrowing;
        _aiTurn();
      }
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
          body: AnimatedBuilder(
            animation: _shakeCtl,
            builder: (ctx, _) {
              // اهتزاز الكاميرا عند الارتطام
              final shakeT = _shakeCtl.value;
              final dx = (shakeT < 0.5 ? 1 : 1 - (shakeT - 0.5) * 2) *
                  sin(shakeT * 30) * 8;
              final dy = (shakeT < 0.5 ? 1 : 1 - (shakeT - 0.5) * 2) *
                  cos(shakeT * 24) * 6;
              return Transform.translate(
                offset: Offset(dx, dy),
                child: Stack(children: [
                  Positioned.fill(
                    child: Image.asset('assets/images/game_bg.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF1A1208))),
                  ),
                  const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x22000000))),
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
                ]),
              );
            },
          ),
        ),
      );

  Widget _ground() => LayoutBuilder(
        builder: (context, size) {
          final w = size.maxWidth, h = size.maxHeight;
          return Stack(
            children: [
              Positioned(left: w * 0.05, top: 8, child: _chip('😎 ${_myDeck.length}')),
              Positioned(right: w * 0.05, top: 8, child: _chip('🤖 ${_aiDeck.length}')),

              // ===== الكومة على الأرض (مكدسة بتباعد طبيعي) =====
              if (_stack.isNotEmpty)
                Positioned(
                  left: _landPos.dx * w - 50,
                  top: _landPos.dy * h - 50,
                  child: AnimatedBuilder(
                    animation: _flipCtl,
                    builder: (_, __) => Stack(
                      children: [
                        for (int i = 0; i < _stack.length; i++)
                          Positioned(
                            left: i * 3.0 - (_stack.length * 1.5) + _stack[i].offX,
                            top: -i * 2.5 + _stack[i].offY,
                            child: Transform.rotate(
                              angle: _stack[i].rot,
                              child: _flipTarget(i)
                                  ? _flippingDisc(_stack[i].card)
                                  : TazoCard(
                                      card: _stack[i].card,
                                      size: 96,
                                      faceUp: true,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ===== قرصي بين أصابعي (أثناء التصويب) =====
              if (_myDeck.isNotEmpty && _phase == Phase.aiming)
                AnimatedBuilder(
                  animation: _powerCtl,
                  builder: (_, __) {
                    // حركة اهتزاز خفيفة حسب القوة
                    final breath = sin(_powerCtl.value * pi) * 2;
                    return Positioned(
                      left: _handStart.dx * w - 40,
                      top: _handStart.dy * h - 40 + breath,
                      child: TazoCard(card: _myDeck.first, size: 70),
                    );
                  },
                ),

              // ===== اليد المتحركة + القرص الطائر (المشهد السينمائي) =====
              if (_phase == Phase.throwing || _phase == Phase.aiThrowing)
                AnimatedBuilder(
                  animation: _throwCtl,
                  builder: (_, __) {
                    final t = _throwCtl.value;
                    final card = _throwerIsMe
                        ? (_myDeck.isNotEmpty ? _myDeck.first : _stack.last.card)
                        : (_aiDeck.isNotEmpty ? _aiDeck.first : _stack.last.card);
                    return _cinematicThrowScene(w, h, t, card, fromOpp: !_throwerIsMe);
                  },
                ),

              // ===== غبار الارتطام (جسيمات حقيقية) =====
              AnimatedBuilder(
                animation: _dustCtl,
                builder: (_, __) => _dustCtl.value > 0
                    ? Positioned(
                        left: _landPos.dx * w - 100,
                        top: _landPos.dy * h - 80,
                        child: CustomPaint(
                          size: const Size(200, 160),
                          painter: _DustPainter(_dustCtl.value, _particles),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ===== احتفال الفوز (أشعة + نجوم) =====
              if (_winner == 'me' || (_phase != Phase.over && _winCtl.value > 0))
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _winCtl,
                      builder: (_, __) => CustomPaint(
                        painter: _CelebrationPainter(_winCtl.value),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  /// يُرجع true إذا كان هذا القرص في الكومة هو الذي يخضع لأنيميشن القلب
  bool _flipTarget(int i) =>
      i == _stack.length - 1 && _flipCtl.isAnimating || _flipCtl.value == 1.0;

  Widget _flippingDisc(PlayingCardModel card) {
    return AnimatedBuilder(
      animation: _flipCtl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_flipCtl.value);
        // قلب 3D كامل + قفزة في الهواء
        final jumpY = -40 * sin(pi * t);
        final scale = 1 + 0.15 * sin(pi * t);
        return Transform.translate(
          offset: Offset(0, jumpY),
          child: Transform.scale(
            scale: scale,
            child: TazoCard(
              card: card,
              size: 96,
              angleX: pi * t,
              faceUp: t > 0.5,
            ),
          ),
        );
      },
    );
  }

  /// المشهد السينمائي: يد تتحرك + قرص يطير في قوس
  Widget _cinematicThrowScene(double w, double h, double t,
      PlayingCardModel card, {required bool fromOpp}) {
    // المرحلة 1 (0 - 0.25): اليد ترجع للخلف (تحضير)
    // المرحلة 2 (0.25 - 0.4): اليد تندفع للأمام (إطلاق)
    // المرحلة 3 (0.4 - 1.0): القرص يطير في قوس
    final startHand = fromOpp ? _oppPos : _handStart;
    final pullBack = fromOpp
        ? Offset(_oppPos.dx + 0.1, _oppPos.dy - 0.1)
        : _handPullBack;
    final release = fromOpp
        ? Offset(_oppPos.dx - 0.05, _oppPos.dy + 0.15)
        : _handRelease;

    Offset handPos;
    double handRot;
    Widget? flyingDisc;

    if (t < 0.25) {
      // تحضير
      final p = t / 0.25;
      final eased = Curves.easeOut.transform(p);
      handPos = Offset.lerp(startHand, pullBack, eased)!;
      handRot = fromOpp ? -0.3 * eased : 0.4 * eased;
    } else if (t < 0.4) {
      // إطلاق
      final p = (t - 0.25) / 0.15;
      final eased = Curves.easeIn.transform(p);
      handPos = Offset.lerp(pullBack, release, eased)!;
      handRot = fromOpp
          ? -0.3 + 0.9 * eased
          : 0.4 - 1.2 * eased;
    } else {
      // استراحة اليد + القرص يطير
      final p = (t - 0.4) / 0.6;
      handPos = release;
      handRot = fromOpp ? 0.6 : -0.8;

      // قوس القطع المكافئ
      final startX = release.dx * w;
      final startY = release.dy * h;
      final endX = _landPos.dx * w;
      final endY = _landPos.dy * h;
      final eased = Curves.easeOut.transform(p);
      final curX = startX + (endX - startX) * eased;
      // parabola: y = startY + (endY-startY)*t - height*sin(pi*t)
      final arcHeight = 150.0 + 80 * _lockedPower;
      final curY = startY + (endY - startY) * eased -
          arcHeight * sin(pi * eased);

      // دوران القرص في 3 محاور
      final rotX = 2 * pi * eased * 2;
      final rotZ = 6 * pi * eased;
      final scaleDown = 1 - 0.2 * eased; // يصغر كلما ابتعد

      flyingDisc = Positioned(
        left: curX - 48,
        top: curY - 48,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotX)
            ..rotateZ(rotZ)
            ..scale(scaleDown),
          child: Stack(
            children: [
              // ظل متحرك
              Positioned(
                left: 10 + eased * 20,
                top: 50 + eased * 80,
                child: Container(
                  width: 80 * (1 - eased * 0.4),
                  height: 20 * (1 - eased * 0.4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4 * (1 - eased)),
                  ),
                ),
              ),
              TazoCard(card: card, size: 96, faceUp: true),
              // Motion blur overlay
              if (p < 0.8)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0x44FFFFFF),
                          const Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // اليد
        Positioned(
          left: handPos.dx * w - 60,
          top: handPos.dy * h - 60,
          child: Transform.rotate(
            angle: handRot,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _CartoonHandPainter(
                skin: fromOpp ? const Color(0xFF8D5A3B) : const Color(0xFFE8B08A),
                grip: t < 0.4, // يمسك القرص حتى الإطلاق
              ),
            ),
          ),
        ),
        if (flyingDisc != null) flyingDisc,
      ],
    );
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC1B1208),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x66F3E9D2)),
        ),
        child: Text(s,
            style: const TextStyle(
                color: Color(0xFFF3E9D2),
                fontWeight: FontWeight.w800,
                fontSize: 13)),
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
                color: Color(0xFF241608),
                fontSize: 15,
                fontWeight: FontWeight.w900)),
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
                      left: w * 0.7,
                      top: 2,
                      bottom: 2,
                      width: w * 0.2,
                      child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xAAFFD54F),
                              borderRadius: BorderRadius.circular(5))),
                    ),
                    Positioned(
                      top: -4,
                      left: v * (w - 10),
                      child: Container(
                          width: 10,
                          height: 22,
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
            gradient: LinearGradient(
                colors: _phase == Phase.aiming
                    ? const [Color(0xFFE07A2F), Color(0xFFB4551B)]
                    : const [Color(0xFF7A6248), Color(0xFF5C4936)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3E2412), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: const Text('💥 كبس!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFF6E5))),
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
                    Text(
                        _winner == 'me'
                            ? '🏆 فزت يا كسّاب!'
                            : '💀 خسرت… صودر قرصك',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                        _winner == 'me'
                            ? 'كسبت ${_won.length} قرص + ${150 + 25 * _won.length} عملة'
                            : 'جرب حظك بجولة جديدة',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _startMatch,
                        child: const Text('جولة جديدة 🔁')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ===== بطاقة في الكومة مع إزاحة ودوران عشوائي للطبيعة =====
class _StackCard {
  final PlayingCardModel card;
  final double offX, offY, rot;
  _StackCard(this.card)
      : offX = (Random().nextDouble() - 0.5) * 8,
        offY = (Random().nextDouble() - 0.5) * 4,
        rot = (Random().nextDouble() - 0.5) * 0.15;
}

// ===== جسيم غبار فردي =====
class _DustParticle {
  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  _DustParticle(this.angle, this.speed, this.size, this.lifetime);
  static _DustParticle random(Random r) => _DustParticle(
        r.nextDouble() * 2 * pi,
        30 + r.nextDouble() * 80,
        3 + r.nextDouble() * 8,
        0.5 + r.nextDouble() * 0.5,
      );
}

// ===== رسّام اليد الكرتونية بمفاصل =====
class _CartoonHandPainter extends CustomPainter {
  final Color skin;
  final bool grip;
  _CartoonHandPainter({required this.skin, required this.grip});

  @override
  void paint(Canvas c, Size s) {
    final dark = HSLColor.fromColor(skin).withLightness(0.3).toColor();
    final light = HSLColor.fromColor(skin).withLightness(0.75).toColor();
    final outline = Paint()
      ..color = const Color(0xFF2B1B0E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = skin;
    final shadow = Paint()..color = dark;

    // الكف
    final palm = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.25, s.height * 0.45,
            s.width * 0.55, s.height * 0.45),
        const Radius.circular(22));
    c.drawRRect(palm, fill);
    c.drawRRect(palm, outline);

    // الأصابع الأربعة
    for (int i = 0; i < 4; i++) {
      final x = s.width * (0.30 + i * 0.13);
      final y = s.height * (grip ? 0.28 : 0.20);
      final finger = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, s.width * 0.11, s.height * 0.28),
          const Radius.circular(12));
      c.drawRRect(finger, fill);
      c.drawRRect(finger, outline);
    }

    // الإبهام (أعلى عندما يمسك)
    final thumb = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.18,
            grip ? s.height * 0.32 : s.height * 0.48,
            s.width * 0.18, s.height * 0.30),
        const Radius.circular(14));
    c.drawRRect(thumb, fill);
    c.drawRRect(thumb, outline);

    // ظلال بسيطة
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * 0.28, s.height * 0.75,
              s.width * 0.45, s.height * 0.10),
          const Radius.circular(10)),
      shadow,
    );

    // تلميع (light)
    c.drawCircle(
        Offset(s.width * 0.45, s.height * 0.55), 8,
        Paint()..color = light.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(covariant _CartoonHandPainter o) =>
      o.skin != skin || o.grip != grip;
}

// ===== غبار حقيقي (40 جسيم) =====
class _DustPainter extends CustomPainter {
  final double t;
  final List<_DustParticle> particles;
  _DustPainter(this.t, this.particles);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height * 0.75);
    for (final p in particles) {
      final life = (t / p.lifetime).clamp(0.0, 1.0);
      if (life >= 1) continue;
      final dist = p.speed * life;
      final x = center.dx + cos(p.angle) * dist;
      final y = center.dy + sin(p.angle) * dist * 0.5 - 20 * life;
      final alpha = (1 - life) * 0.8;
      final size = p.size * (1 - life * 0.5);
      c.drawCircle(
        Offset(x, y),
        size,
        Paint()..color = const Color(0xFFC9A15F).withOpacity(alpha),
      );
      // جسيم أصغر أفتح
      c.drawCircle(
        Offset(x + 2, y - 2),
        size * 0.6,
        Paint()..color = const Color(0xFFE8D3A0).withOpacity(alpha * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter o) => o.t != t;
}

// ===== احتفال الفوز: أشعة ونجوم =====
class _CelebrationPainter extends CustomPainter {
  final double t;
  _CelebrationPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    if (t <= 0) return;
    final center = Offset(s.width / 2, s.height / 2);
    final rays = 12;
    final rayPaint = Paint()
      ..color = const Color(0xFFFFE082).withOpacity(0.3 * (1 - t))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < rays; i++) {
      final a = i * 2 * pi / rays + t * pi;
      final len = 200 * t;
      c.drawLine(
        center + Offset(cos(a) * 50, sin(a) * 50),
        center + Offset(cos(a) * (50 + len), sin(a) * (50 + len)),
        rayPaint,
      );
    }
    // نجوم متطايرة
    final starPaint = Paint()..color = const Color(0xFFFFD54F);
    for (int i = 0; i < 20; i++) {
      final a = i * 2 * pi / 20;
      final d = 100 + 300 * t;
      final alpha = 1 - t;
      c.drawCircle(
        center + Offset(cos(a) * d, sin(a) * d),
        4 + 4 * (1 - t),
        starPaint..color = const Color(0xFFFFD54F).withOpacity(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter o) => o.t != t;
}
