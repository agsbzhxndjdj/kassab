import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';
import 'kaps_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final col = context.watch<CollectionService>();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== خلفية الحارة الليلية =====
          Image.asset(
            'assets/images/menu_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1A2233), Color(0xFF2B1B0E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
            ),
          ),
          const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x55000000))),

          SafeArea(
            child: Column(
              children: [
                _topBar(col),
                const SizedBox(height: 4),
                const Text(
                  'كَسَّابُ',
                  style: TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF3E9D2),
                    shadows: [
                      Shadow(
                          color: Colors.black87,
                          blurRadius: 14,
                          offset: Offset(0, 6)),
                      Shadow(color: Color(0x66E07A2F), blurRadius: 30),
                    ],
                  ),
                ),
                const Spacer(),
                _gameButtons(context),
                const Spacer(),
                _bottomBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== الشريط العلوي: عملات + مستوى + أفاتار =====
  Widget _topBar(CollectionService col) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _currency('🪙', '${col.coins}'),
            _currency('💎', '${col.gems}'),
            GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Color(0xFFE07A2F), shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ),
            const Spacer(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'مستوى ${col.level} • ${col.title}',
                    style: const TextStyle(
                        color: Color(0xFFEFE3C8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (col.xp % 100) / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0x66000000),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4FC3F7)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF2B1B0E),
                    child: Text('🧔', style: TextStyle(fontSize: 26))),
                Positioned(
                  bottom: -4,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE07A2F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black87)),
                    child: Text('${col.level}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _currency(String icon, String value) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xCC1B1208),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x66F3E9D2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ),
      );

  // ===== أزرار الأوضاع (أوراق قديمة مثل الكونسبت) =====
  Widget _gameButtons(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _parchment(context, 'تخمين', const ComingSoonScreen(),
              w: 125, h: 95, rot: 0.05, fs: 20),
          const SizedBox(width: 12),
          _parchment(context, 'كبس', const KapsScreen(),
              w: 170, h: 125, rot: -0.02, fs: 34),
          const SizedBox(width: 12),
          _parchment(context, 'صورة ولا\nفاضي', const ComingSoonScreen(),
              w: 125, h: 95, rot: -0.05, fs: 20),
        ],
      );

  Widget _parchment(BuildContext context, String label, Widget screen,
          {double w = 140, double h = 110, double rot = 0, double fs = 22}) =>
      GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen)),
        child: Transform.rotate(
          angle: rot,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                Positioned.fill(
                    child:
                        Transform.rotate(angle: 0.07, child: _paper())),
                Positioned.fill(child: _paper()),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: fs,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF241608),
                          height: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _paper() => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [
                Color(0xFFEFDDB4),
                Color(0xFFDCC493),
                Color(0xFFC7AC79)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(12)),
          border: Border.all(color: const Color(0x99705A33), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
      );

  // ===== الشريط السفلي: مجموعتي + الصناديق + المتجر =====
  Widget _bottomBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            _collectionChip(context),
            const Spacer(),
            _iconBtn(context, '🧰', 'الصناديق', const ComingSoonScreen()),
            const SizedBox(width: 18),
            _iconBtn(context, '🛒', 'المتجر', const ComingSoonScreen()),
          ],
        ),
      );

  Widget _iconBtn(
          BuildContext context, String icon, String label, Widget screen) =>
      GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon,
                style: const TextStyle(fontSize: 34, shadows: [
                  Shadow(
                      color: Colors.black87,
                      blurRadius: 6,
                      offset: Offset(0, 3))
                ])),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFF3E9D2),
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ),
      );

  Widget _collectionChip(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen())),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2B1B0E),
                border: Border.all(color: Color(0xFFB33A2B), width: 5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ],
              ),
              child: const Center(
                  child: Text('كَسّاب',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF3E9D2)))),
            ),
            const SizedBox(height: 4),
            const Text('مجموعتي',
                style: TextStyle(
                    color: Color(0xFFF3E9D2),
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ),
      );
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('قريباً')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚧', style: TextStyle(fontSize: 60)),
              SizedBox(height: 12),
              Text('هذه الشاشة تصل في الدفعة القادمة 😉',
                  style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
}
