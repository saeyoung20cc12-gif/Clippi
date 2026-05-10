import 'package:flutter/material.dart';
import 'data/category_seeds.dart';
import 'screens/home_screen.dart';
import 'services/isar_service.dart';
import 'services/ai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. AI 서비스(Gemini) 초기화 (.env 파일 로드 등)
  await AiService.instance.init();

  // 1. DB 초기화
  await IsarService.instance.init();

  // 2. 최초 실행 시에만 카테고리 시드 데이터 주입
  await IsarService.instance.seedCategoriesIfEmpty(buildCategorySeeds());
  await IsarService.instance.syncCategoriesWithSeeds(buildCategorySeeds());

  runApp(const ClippiApp());
}

class ClippiApp extends StatelessWidget {
  const ClippiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clippi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
