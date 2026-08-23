import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/card_catalog.dart';
import '../logic/flip_engine.dart';
import '../models/playing_card_model.dart';
import '../services/collection_service.dart';

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

    // الخصم يفرش أول بطاقة وأنت تكبس أولاً
    _stack.add(_aiDeck.removeAt(0));
    _flipCtl.reset();
    _throwerIsMe = true;
    _phase = Phase.aiming;
    _msg = 'الخصم فرش بطاقته… اكبس!';
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
      _msg = 'الخصم فرش بطاقة جديدة… اكبس!';
    } else {
      _stack.add(_myDeck.removeAt(0));
      _msg = 'ما انقلبت… بطاقتك صارت بالكومة';
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
      col.addCards(const [], coins: 20, xp: 10); // مواساة
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
              Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0xFF8EC9E8),
                      Color(0xFFE8D3A0),
                      Color(0xFFD9B36C)
                    ], stops: [
                      0, .45, 1
                    ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: SafeArea(
                  child: Column(
                    children: [
                      _topBar(),
                      Expanded(child: _ground()),
                      _messageBar(),
                      _powerBar(),
                      _kapsButton(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_winner != null) _winnerOverlay(),
            ],
          ),
        ),
      );

  Widget _topBar() => Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const CircleAvatar(child: Text('🤖', style: TextStyle(fontSize: 20))),
            const SizedBox(width: 8),
            Text('بطاقات الخصم: ${_aiDeck.length}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('بطاقاتي: ${_myDeck.length}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const CircleAvatar(child: Text('😎', style: TextStyle(fontSize: 20))),
          ],
        ),
      );

  Widget _ground() => LayoutBuilder(
        builder: (context, size) => Stack(
          children: [
            // ===== الكومة في المنتصف =====
            if (_stack.isNotEmpty)
              Center(
                child: AnimatedBuilder(
                  animation: _flipCtl,
                  builder: (_, __) => SizedBox(
                    width: 140,
                    height: 170,
                    child: Stack(
                      children: [
                        for (int i = 0; i < _stack.length; i++)
                          Positioned(
                            left: 20.0 + i * 4,
                            top: 25.0 - i * 6,
                            child: Transform.rotate(
                              angle: (i % 2 == 0 ? -1 : 1) * 0.05 * i,
                              child: _CardFace(
                                card: _stack[i],
                                faceUp: i != _stack.length - 1 || _flipCtl.value > .5,
                                angleX: i == _stack.length - 1
                                    ? pi * Curves.easeInOut.transform(_flipCtl.value)
                                    : 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // ===== البطاقة الطائرة =====
            if (_phase == Phase.throwing || _phase == Phase.aiThrowing)
              AnimatedBuilder(
                animation: _throwCtl,
                builder: (_, __) {
                  final t = Curves.easeIn.transform(_throwCtl.value);
                  final startTop = _fromTop ? -140.0 : size.maxHeight;
                  final endTop = size.maxHeight / 2 - 80;
                  return Positioned(
                    left: size.maxWidth / 2 - 45,
                    top: startTop + (endTop - startTop) * t,
                    child: Transform.rotate(
                      angle: 4 * pi * t,
                      child: _CardFace(
                        card: _throwerIsMe
                            ? (_myDeck.isNotEmpty ? _myDeck.first : _stack.last)
                            : (_aiDeck.isNotEmpty ? _aiDeck.first : _stack.last),
                        faceUp: true,
                      ),
                    ),
                  );
                },
              ),

            // ===== غبار الارتطام =====
            AnimatedBuilder(
              animation: _dustCtl,
              builder: (_, __) => _dustCtl.value > 0
                  ? Center(
                      child: CustomPaint(
                          size: const Size(160, 120),
                          painter: _DustPainter(_dustCtl.value)),
                    )
                  : const SizedBox.shrink(),
            ),

            // يد الخصم (أعلى)
            Positioned(
                top: -30,
                right: 30,
                child: Transform.scale(
                    scale: -1, child: _Hand(color: const Color(0xFF8D5A3B)))),

            // يدي أنا (أسفل)
            Positioned(
                bottom: -34,
                left: 26,
                child: _Hand(
                    color: const Color(0xFFE8B08A),
                    card: _myDeck.isNotEmpty ? _myDeck.first : null)),
          ],
        ),
      );

  Widget _messageBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xCC3E2412), borderRadius: BorderRadius.circular(14)),
        child: Text(_msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _powerBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
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
                            color: const Color(0x55000000),
                            borderRadius: BorderRadius.circular(7))),
                    // المنطقة المثالية (0.7 - 0.9)
                    Positioned(
                      left: w * 0.7,
                      top: 0,
                      bottom: 0,
                      width: w * 0.2,
                      child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0x88FFD54F),
                              borderRadius: BorderRadius.circular(7))),
                    ),
                    // المؤشر المتحرك
                    Positioned(
                      top: -4,
                      left: v * (w - 10),
                      child: Container(
                          width: 10,
                          height: 22,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5))),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _kapsButton() => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE07A2F),
              minimumSize: const Size(220, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _phase == Phase.aiming ? _kapsTap : null,
          icon: const Text('💥'),
          label: const Text('كبس!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
                    Text(_winner == 'me' ? '🏆 فزت يا كسّاب!' : '💀 خسرت… صودرت بطاقتك',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                        _winner == 'me'
                            ? 'كسبت ${_won.length} بطاقة + ${150 + 25 * _won.length} عملة'
                            : 'جرب حظك بجولة جديدة',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _startMatch, child: const Text('جولة جديدة 🔁')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// بطاقة بوجه/ظهر مع قلب ثلاثي الأبعاد
class _CardFace extends StatelessWidget {
  final PlayingCardModel card;
  final bool faceUp;
  final double angleX;
  const _CardFace({required this.card, this.faceUp = true, this.angleX = 0});

  static const _colors = {
    Rarity.common: Color(0xFF9E9E9E),
    Rarity.rare: Color(0xFF42A5F5),
    Rarity.epic: Color(0xFFAB47BC),
    Rarity.legendary: Color(0xFFFFB300),
    Rarity.limited: Color(0xFF26C6DA)
  };

  @override
  Widget build(BuildContext context) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angleX),
        child: Container(
          width: 90,
          height: 120,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: faceUp
                  ? [
                      _colors[card.rarity]!.withOpacity(.9),
                      _colors[card.rarity]!.withOpacity(.6)
                    ]
                  : const [Color(0xFF5D2E0F), Color(0xFF8A4B2A)]),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ]),
          child: Center(
            child: faceUp
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🦊', style: TextStyle(fontSize: 30)),
                      Text(card.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('#${card.number}',
                          style: const TextStyle(fontSize: 9, color: Colors.white70)),
                    ],
                  )
                : const Text('كَسّاب',
                    style: TextStyle(
                        color: Color(0xFFFFD9A0),
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
          ),
        ),
      );
}

/// يد كرتونية تمسك البطاقة
class _Hand extends StatelessWidget {
  final Color color;
  final PlayingCardModel? card;
  const _Hand({required this.color, this.card});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          children: [
            CustomPaint(size: const Size(150, 150), painter: _HandPainter(color)),
            if (card != null)
              Positioned(
                  left: 18,
                  top: 6,
                  child: Transform.rotate(angle: -0.15, child: _CardFace(card: card!))),
            CustomPaint(size: const Size(150, 150), painter: _HandPainter(color, thumbOver: true)),
          ],
        ),
      );
}

class _HandPainter extends CustomPainter {
  final Color skin;
  final bool thumbOver;
  _HandPainter(this.skin, {this.thumbOver = false});

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = skin;
    void rect(double x, double y, double w, double h, double rad) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Offset(s.width * x, s.height * y) & Size(s.width * w, s.height * h),
              Radius.circular(rad)),
          p);
    }

    if (!thumbOver) {
      // الكف والأصابع خلف البطاقة
      rect(.35, .55, .55, .45, 26);
      for (int i = 0; i < 4; i++) {
        rect(.38 + i * .13, .38, .10, .30, 10);
      }
    } else {
      // الإبهام فوق البطاقة
      rect(.30, .42, .16, .34, 12);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
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
