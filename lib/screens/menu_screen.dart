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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFC98A), Color(0xFFB4713B), Color(0xFF7A4426)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 18),

                // ===== الشعار =====
                const Text(
                  'كَسّاب',
                  style: TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFF6E5),
                    shadows: [
                      Shadow(color: Color(0x99402010), blurRadius: 12, offset: Offset(0, 5)),
                    ],
                  ),
                ),
                const Text(
                  'كبس • صورة ولا فاضي • تخمين',
                  style: TextStyle(fontSize: 15, color: Color(0xCCFFF6E5)),
                ),
                const SizedBox(height: 20),

                // ===== بطاقة اللاعب =====
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE07A2F),
                        child: Text('😎', style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(col.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text('مستوى ${col.level} • ${col.owned.length} بطاقة',
                                style: const TextStyle(
                                    color: Color(0xBBFFFFFF), fontSize: 12)),
                          ],
                        ),
                      ),
                      _stat('💰', '${col.coins}'),
                      const SizedBox(width: 6),
                      _stat('💎', '${col.gems}'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ===== أزرار اللعب =====
                _menuButton(context, '🎯', 'كبس', 'النزال الكلاسيكي بالأدوار', const KapsScreen()),
                _menuButton(context, '🪙', 'صورة ولا فاضي', 'رمية متزامنة… وانتبه للاصق!', const ComingSoonScreen()),
                _menuButton(context, '🧠', 'تخمين', 'صورة ولا فاضي؟ اختبر حدسك', const ComingSoonScreen()),
                _menuButton(context, '📦', 'الصناديق', 'افتح واجمع مئات البطاقات', const ComingSoonScreen()),
                _menuButton(context, '🗃️', 'مجموعتي', 'من العادي حتى المحدود', const ComingSoonScreen()),
                const SizedBox(height: 20),

                const Text(
                  'اللعب الأونلاين والحارات قريباً 🔜',
                  style: TextStyle(color: Color(0xAAFFF6E5), fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text('v0.2.0', style: TextStyle(color: Color(0x66FFF6E5), fontSize: 10)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String icon, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x44000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );

  Widget _menuButton(
          BuildContext context, String icon, String title, String sub, Widget screen) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: SizedBox(
          width: 270,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A2F),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
            ),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text(sub,
                          style: const TextStyle(fontSize: 11, color: Color(0xCCFFFFFF))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: Colors.white70),
              ],
            ),
          ),
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
