import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/collection_service.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => CollectionService())],
    child: const KassabApp(),
  ));
}

class KassabApp extends StatelessWidget {
  const KassabApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كَسّاب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFE07A2F), useMaterial3: true),
      builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const MenuScreen(),
    );
  }
}
