import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'pages/home_page.dart';
import 'services/notifications.dart';
import 'services/tts.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState.instance;
  await state.load();
  await TtsService.instance.init(rate: state.speechRate, pitch: state.speechPitch);
  try {
    await NotificationService.instance.init();
    await state.rescheduleAll();
  } catch (e) {
    debugPrint('通知初始化失败: $e');
  }
  runApp(const ReadRxApp());
}

class ReadRxApp extends StatelessWidget {
  const ReadRxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => MaterialApp(
        title: 'ReadRx 读药助手',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 全局字体放大（设置里可调）
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(AppState.instance.textScale)),
          child: child!,
        ),
        home: const HomePage(),
      ),
    );
  }
}
