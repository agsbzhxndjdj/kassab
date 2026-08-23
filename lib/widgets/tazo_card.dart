import 'package:flutter/material.dart';
import '../models/playing_card_model.dart';

/// قرص تازو دائري — الوجه قرص مزخرف، والظهر شعار كَسّاب
class TazoCard extends StatelessWidget {
  final PlayingCardModel card;
  final bool faceUp;
  final double angleX;
  final double size;

  const TazoCard({super.key, required this.card, this.faceUp = true, this.angleX = 0, this.size = 90});

  static const Map<Rarity, List<Color>> _rim = {
    Rarity.common: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
    Rarity.rare: [Color(0xFF81D4FA), Color(0xFF0277BD)],
    Rarity.epic: [Color(0xFFE1BEE7), Color(0xFF6A1B9A)],
    Rarity.legendary: [Color(0xFFFFE082), Color(0xFFEF6C00)],
    Rarity.limited: [Color(0xFF84FFFF), Color(0xFF00695C)],
  };

  static const Map<Rarity, Color> _glow = {
    Rarity.common: Color(0x00000000),
    Rarity.rare: Color(0x6642A5F5),
    Rarity.epic: Color(0x88AB47BC),
    Rarity.legendary: Color(0xAAFFB300),
    Rarity.limited: Color(0xAA26C6DA),
  };

  static const Map<String, String> _emoji = {
    'الثعلب': '🦊', 'القط': '🐱', 'البطل': '🦸', 'الجنّي': '🧞',
    'الصقر': '🦅', 'النمر': '🐯', 'الساحر': '🧙', 'العمدة': '👳',
  };

  String get _icon {
    for (final e in _emoji.entries) {
      if (card.name.startsWith(e.key)) return e.value;
    }
    return '🦊';
  }

  @override
  Widget build(BuildContext context) {
    final rim = _rim[card.rarity]!;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angleX),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: rim, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: _glow[card.rarity]!, blurRadius: 14, spreadRadius: 1),
            const BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        padding: EdgeInsets.all(size * 0.07),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: faceUp
                ? const RadialGradient(colors: [Color(0xFF3E2A18), Color(0xFF241608)])
                : const RadialGradient(colors: [Color(0xFF6B3A16), Color(0xFF3E2008)]),
            border: Border.all(color: Colors.white.withOpacity(.35), width: 1.5),
          ),
          child: faceUp
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_icon, style: TextStyle(fontSize: size * 0.30)),
                    Text(card.name, maxLines: 1, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: size * 0.105, fontWeight: FontWeight.w800, color: const Color(0xFFFFE9C4))),
                    Text('#${card.number}', style: TextStyle(fontSize: size * 0.09, color: Colors.white54)),
                  ],
                )
              : Center(
                  child: Text('كَسّاب',
                      style: TextStyle(color: const Color(0xFFFFD9A0), fontSize: size * 0.22, fontWeight: FontWeight.w900))),
        ),
      ),
    );
  }
}
