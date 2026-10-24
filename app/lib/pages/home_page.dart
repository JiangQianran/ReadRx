import 'package:flutter/material.dart';

import '../services/tts.dart';
import 'cabinet_page.dart';
import 'interaction_page.dart';
import 'reminders_page.dart';
import 'scan_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = ['拍照识药', '我的药箱', '相克查询', '用药提醒'];

  void _go(int i) {
    TtsService.instance.stop();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: '设置',
            iconSize: 30,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          ScanPage(onOpenCabinet: () => _go(1)),
          CabinetPage(onGoScan: () => _go(0)),
          const InteractionPage(),
          const RemindersPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined, size: 30), selectedIcon: Icon(Icons.photo_camera, size: 30), label: '识药'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined, size: 30), selectedIcon: Icon(Icons.medical_services, size: 30), label: '药箱'),
          NavigationDestination(icon: Icon(Icons.health_and_safety_outlined, size: 30), selectedIcon: Icon(Icons.health_and_safety, size: 30), label: '相克'),
          NavigationDestination(icon: Icon(Icons.alarm_outlined, size: 30), selectedIcon: Icon(Icons.alarm, size: 30), label: '提醒'),
        ],
      ),
    );
  }
}
