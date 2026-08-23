import 'dart:math';

enum LandingState { picture, blank, flat } // flat = «اللاصق»

class ThrowOutcome {
  final bool flippedTarget;
  final LandingState landing;
  const ThrowOutcome({this.flippedTarget = false, this.landing = LandingState.picture});
}

class FlipEngine {
  FlipEngine([int? seed]) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
  final Random _rng;

  /// كبس: المهارة = توقيت شريط القوة (المنطقة المثالية ~0.8)
  ThrowOutcome resolveKaps(double power) {
    final accuracy = (1 - ((power - 0.8).abs() / 0.8)).clamp(0.0, 1.0);
    return ThrowOutcome(flippedTarget: _rng.nextDouble() < 0.25 + 0.65 * accuracy);
  }

  /// صورة ولا فاضي: رمية متزامنة للطرفين
  (LandingState, LandingState) resolvePictureBlank() => (_landing(), _landing());

  /// 12% احتمال «اللاصق» (هبوط بدون دوران)
  LandingState _landing() {
    final r = _rng.nextDouble();
    if (r < 0.12) return LandingState.flat;
    return r < 0.56 ? LandingState.picture : LandingState.blank;
  }

  /// الكبس القاضي على اللاصق: 85% نجاح
  bool resolveFlatKaps() => _rng.nextDouble() < 0.85;

  bool chance(double p) => _rng.nextDouble() < p;
  double nextDouble() => _rng.nextDouble();
}
