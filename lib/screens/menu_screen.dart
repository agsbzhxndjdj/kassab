import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final col = context.watch<CollectionService>();
    return Scaffold(body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xFFEFC98A), Color(0xFFB4713B), Color(0xFF7A4426)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('كَسّاب', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900,
          color: Color(0xFFFFF6E5), shadows: [Shadow(color: Color(0x99402010), blurRadius: 12, offset: Offset(0, 5))])),
        const Text('كبس • صورة ولا فاضي • تخمين', style: TextStyle(color: Color(0xCCFFF6E5))),
        const SizedBox(height: 24),
        for (final b in ['🎯 كبس', '🪙 صورة ولا فاضي', '🧠 تخمين', '📦 الصناديق', '🗃️ مجموعتي'])
          Padding(padding: const EdgeInsets.symmetric(vertical: 5),
            child: SizedBox(width: 250, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE07A2F),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () {}, child: Text(b, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _stat('💰 ${col.coins}'), const SizedBox(width: 10),
          _stat('⭐ مستوى ${col.level}'), const SizedBox(width: 10),
          _stat('🃏 ${col.owned.length}'),
        ]),
      ])),
    ));
  }
  Widget _stat(String s) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(20)),
    child: Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
}
