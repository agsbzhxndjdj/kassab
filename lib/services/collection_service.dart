import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/card_catalog.dart';
import '../models/playing_card_model.dart';

enum BoxTier {
  bronze('برونزي', 100, 3), silver('فضي', 250, 4),
  gold('ذهبي', 600, 5), legendary('أسطوري', 1200, 6);
  const BoxTier(this.label, this.price, this.cards);
  final String label; final int price, cards;
}

class CollectionService extends ChangeNotifier {
  final List<PlayingCardModel> _owned = [];
  int coins = 500, gems = 50, xp = 0, _boxes = 0;

  CollectionService() {
    _owned.addAll(CardCatalog.all.where((c) => c.rarity == Rarity.common).take(5));
  }

  List<PlayingCardModel> get owned => List.unmodifiable(_owned);
  int get level => 1 + xp ~/ 100;

  void rewardWin(int c, int x) { coins += c; xp += x; notifyListeners(); }

  List<PlayingCardModel> openBox(BoxTier tier) {
    if (coins < tier.price) return const [];
    coins -= tier.price; _boxes++;
    final draws = List.generate(tier.cards, (_) => _draw(tier));
    if (_boxes % 10 == 0 && !draws.any((c) => c.rarity != Rarity.common))
      draws[0] = _from(Rarity.rare); // نظام الـPity
    _owned.addAll(draws); xp += 20; notifyListeners();
    return draws;
  }

  PlayingCardModel _draw(BoxTier t) {
    final r = Random().nextDouble() * 100; double acc = 0;
    for (final e in _w[t]!.entries) { acc += e.value; if (r <= acc) return _from(e.key); }
    return _from(Rarity.common);
  }

  PlayingCardModel _from(Rarity r) {
    final pool = CardCatalog.all.where((c) => c.rarity == r).toList();
    final card = pool[Random().nextInt(pool.length)];
    return r == Rarity.limited ? card.copyWith(serial: Random().nextInt(500) + 1) : card;
  }

  static const Map<BoxTier, Map<Rarity, double>> _w = {
    BoxTier.bronze:    {Rarity.common: 70, Rarity.rare: 20, Rarity.epic: 7,  Rarity.legendary: 2.5, Rarity.limited: 0.5},
    BoxTier.silver:    {Rarity.common: 55, Rarity.rare: 28, Rarity.epic: 11, Rarity.legendary: 4.5, Rarity.limited: 1},
    BoxTier.gold:      {Rarity.common: 40, Rarity.rare: 30, Rarity.epic: 18, Rarity.legendary: 9,  Rarity.limited: 3},
    BoxTier.legendary: {Rarity.common: 25, Rarity.rare: 32, Rarity.epic: 24, Rarity.legendary: 14, Rarity.limited: 5},
  };
}
