enum Rarity {
  common('عادي'), rare('نادر'), epic('ملحمي'),
  legendary('أسطوري'), limited('محدود');
  const Rarity(this.label);
  final String label;
}

class PlayingCardModel {
  final String id, name, artAsset, flipFx;
  final int number;          // تجميعي/شكلي فقط — لا يؤثر على التوازن أبداً
  final Rarity rarity;
  final int? serial;         // للمحدود: #23/500

  const PlayingCardModel({required this.id, required this.name, required this.number,
    required this.rarity, required this.artAsset, this.flipFx = 'default', this.serial});

  PlayingCardModel copyWith({int? serial}) => PlayingCardModel(
      id: id, name: name, number: number, rarity: rarity,
      artAsset: artAsset, flipFx: flipFx, serial: serial ?? this.serial);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'number': number, 'rarity': rarity.name,
       'art': artAsset, 'fx': flipFx, 'serial': serial};
}
