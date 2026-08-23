import '../models/playing_card_model.dart';

class CardCatalog {
  CardCatalog._();
  static final List<PlayingCardModel> all = _build();
  static const _themes = ['الحارة', 'المدرسة', 'الصحراء', 'البحر', 'الفضاء', 'الساحة'];
  static const _chars = ['الثعلب', 'القط', 'البطل', 'الجنّي', 'الصقر', 'النمر', 'الساحر', 'العمدة'];

  static List<PlayingCardModel> _build() {
    final list = <PlayingCardModel>[];
    int n = 1;
    for (final t in _themes) for (final c in _chars) for (final r in Rarity.values) {
      list.add(PlayingCardModel(id: 'card_$n', name: '$c $t', number: n, rarity: r,
        artAsset: 'assets/cards/${t}_$c.png',
        flipFx: (r == Rarity.common || r == Rarity.rare) ? 'default' : 'fx_${r.name}'));
      n++;
    }
    return list;
  }
}
