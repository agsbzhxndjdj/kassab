import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/card_catalog.dart';
import '../models/playing_card_model.dart';

/// درجات الصناديق: السعر وعدد البطاقات
enum BoxTier {
  bronze('برونزي', 100, 3),
  silver('فضي', 250, 4),
  gold('ذهبي', 600, 5),
  legendary('أسطوري', 1200, 6);

  const BoxTier(this.label, this.price, this.cards);
  final String label;
  final int price;
  final int cards;
}

class CollectionService extends ChangeNotifier {
  // ================= الحالة =================
  final List<PlayingCardModel> _owned = [];
  int coins = 500;
  int gems = 50;
  int xp = 0;
  int _boxesOpened = 0;
  bool _loaded = false;

  CollectionService() {
    _load();
  }

  // ================= Getters =================
  List<PlayingCardModel> get owned => List.unmodifiable(_owned);
  int get level => 1 + xp ~/ 100;
  int get boxesOpened => _boxesOpened;

  /// ألقاب المستويات (تظهر في الملف الشخصي ولوائح الصدارة)
  String get title =>
      level >= 20 ? 'أسطورة الكبس 🐐'
      : level >= 10 ? 'كسّاب الحارة 🔥'
      : level >= 5 ? 'لاعب ساحة 😎'
      : 'مبتدئ الحارة 🌱';

  int countOf(String id) => _owned.where((c) => c.id == id).length;

  // ================= التحميل والحفظ =================
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt('k_coins') ?? 500;
    gems = prefs.getInt('k_gems') ?? 50;
    xp = prefs.getInt('k_xp') ?? 0;
    _boxesOpened = prefs.getInt('k_boxes') ?? 0;

    final saved = prefs.getStringList('k_owned') ?? [];
    if (saved.isEmpty) {
      // حزمة البداية: 5 بطاقات عادية
      _owned.addAll(CardCatalog.all.where((c) => c.rarity == Rarity.common).take(5));
    } else {
      for (final s in saved) {
        final parts = s.split('#');
        final id = parts[0];
        final serial = parts.length > 1 ? int.tryParse(parts[1]) : null;
        final base = CardCatalog.all.firstWhere((c) => c.id == id,
            orElse: () => CardCatalog.all.first);
        _owned.add(serial != null ? base.copyWith(serial: serial) : base);
      }
    }
    _loaded = true;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    if (!_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('k_coins', coins);
    await prefs.setInt('k_gems', gems);
    await prefs.setInt('k_xp', xp);
    await prefs.setInt('k_boxes', _boxesOpened);
    // نحفظ المعرّف فقط (+ الرقم التسلسلي للمحدودة) والبطاقة تُسترجع من الكتالوج
    await prefs.setStringList('k_owned', [
      for (final c in _owned) c.serial != null ? '${c.id}#${c.serial}' : c.id,
    ]);
  }

  // ================= المكافآت =================
  void rewardWin(int c, int x) {
    coins += c;
    xp += x;
    _save();
    notifyListeners();
  }

  void rewardCoins(int c) {
    coins += c;
    _save();
    notifyListeners();
  }

  /// تُستدعى بعد فوز جولة كبس: تضيف البطاقات المصادرة للمجموعة
  void addCards(List<PlayingCardModel> cards, {int coins = 0, int xp = 0}) {
    _owned.addAll(cards);
    this.coins += coins;
    this.xp += xp;
    _save();
    notifyListeners();
  }

  // ================= فتح الصناديق =================
  List<PlayingCardModel> openBox(BoxTier tier) {
    if (coins < tier.price) return const [];
    coins -= tier.price;
    _boxesOpened++;

    final draws = List.generate(tier.cards, (_) => _draw(tier));

    // نظام الـPity: كل 10 صناديق نضمن «نادر» على الأقل
    if (_boxesOpened % 10 == 0 && !draws.any((c) => c.rarity != Rarity.common)) {
      draws[0] = _from(Rarity.rare);
    }

    _owned.addAll(draws);
    xp += 20;
    _save();
    notifyListeners();
    return draws;
  }

  PlayingCardModel _draw(BoxTier tier) {
    final r = Random().nextDouble() * 100;
    double acc = 0;
    for (final e in _weights[tier]!.entries) {
      acc += e.value;
      if (r <= acc) return _from(e.key);
    }
    return _from(Rarity.common);
  }

  PlayingCardModel _from(Rarity rarity) {
    final pool = CardCatalog.all.where((c) => c.rarity == rarity).toList();
    final card = pool[Random().nextInt(pool.length)];
    // المحدودة تحصل على رقم تسلسلي تجميعي مثل #23/500
    return rarity == Rarity.limited
        ? card.copyWith(serial: Random().nextInt(500) + 1)
        : card;
  }

  // ================= نسب السحب لكل صندوق =================
  static const Map<BoxTier, Map<Rarity, double>> _weights = {
    BoxTier.bronze: {
      Rarity.common: 70, Rarity.rare: 20, Rarity.epic: 7,
      Rarity.legendary: 2.5, Rarity.limited: 0.5,
    },
    BoxTier.silver: {
      Rarity.common: 55, Rarity.rare: 28, Rarity.epic: 11,
      Rarity.legendary: 4.5, Rarity.limited: 1,
    },
    BoxTier.gold: {
      Rarity.common: 40, Rarity.rare: 30, Rarity.epic: 18,
      Rarity.legendary: 9, Rarity.limited: 3,
    },
    BoxTier.legendary: {
      Rarity.common: 25, Rarity.rare: 32, Rarity.epic: 24,
      Rarity.legendary: 14, Rarity.limited: 5,
    },
  };
}
