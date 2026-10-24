import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/api.dart';
import '../services/notifications.dart';
import '../services/tts.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final state = AppState.instance;
  late final _server = TextEditingController(text: state.serverUrl);
  late final _token = TextEditingController(text: state.appToken);
  bool _testing = false;

  static const _scales = {'标准': 1.0, '大': 1.15, '特大': 1.3, '超大': 1.5};
  static const _pitches = {'低沉': 0.8, '标准': 1.0, '清亮': 1.2};
  static const _sample = '您好，这是 ReadRx 助手。每次一片，每天三次，饭后服用。';

  Widget _subTitle(String s) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(s, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      );

  @override
  void dispose() {
    _server.dispose();
    _token.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _saveServer() async {
    await state.saveSettings(serverUrl: _server.text, appToken: _token.text);
  }

  Future<void> _test() async {
    FocusScope.of(context).unfocus();
    await _saveServer();
    setState(() => _testing = true);
    try {
      final msg = await state.api.health();
      if (mounted) showMessage(context, msg);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('服务器'),
            TextField(
              controller: _server,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(labelText: '服务器地址', hintText: 'http://192.168.1.5:3000'),
              onSubmitted: (_) => _saveServer(),
            ),
            const SizedBox(height: 6),
            Text('启动后端时，命令行窗口会显示要填的地址。手机和电脑要连同一个 Wi-Fi。',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: _token,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(labelText: '访问口令（没设置可留空）'),
              onSubmitted: (_) => _saveServer(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _testing ? null : _test,
              icon: const Icon(Icons.wifi_tethering),
              label: Text(_testing ? '正在连接…' : '保存并测试连接'),
            ),
            _section('字体大小'),
            SegmentedButton<double>(
              segments: [
                for (final e in _scales.entries)
                  ButtonSegment(value: e.value, label: Text(e.key, style: const TextStyle(fontSize: 16))),
              ],
              selected: {_scales.values.contains(state.textScale) ? state.textScale : 1.15},
              showSelectedIcon: false,
              onSelectionChanged: (s) => state.saveSettings(textScale: s.first),
            ),
            _section('语音朗读'),
            _subTitle('语速'),
            Row(
              children: [
                const Text('慢', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Slider(
                    value: state.speechRate.clamp(0.25, 0.7),
                    min: 0.25,
                    max: 0.7,
                    divisions: 9,
                    onChanged: (v) => state.saveSettings(speechRate: v),
                  ),
                ),
                const Text('快', style: TextStyle(fontSize: 16)),
              ],
            ),
            _subTitle('音调'),
            SegmentedButton<double>(
              segments: [
                for (final e in _pitches.entries)
                  ButtonSegment(value: e.value, label: Text(e.key, style: const TextStyle(fontSize: 16))),
              ],
              selected: {_pitches.values.contains(state.speechPitch) ? state.speechPitch : 1.0},
              showSelectedIcon: false,
              onSelectionChanged: (s) async {
                await state.saveSettings(speechPitch: s.first);
                TtsService.instance.speak(_sample);
              },
            ),
            const SizedBox(height: 12),
            const SpeakButton(text: _sample, label: '试听'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('识别完成后自动朗读', style: TextStyle(fontSize: 18)),
              value: state.autoSpeak,
              onChanged: (v) => state.saveSettings(autoSpeak: v),
            ),
            _section('提醒'),
            OutlinedButton.icon(
              onPressed: () async {
                await NotificationService.instance.requestPermissions();
                await NotificationService.instance.showTest();
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('发一条测试通知'),
            ),
            _section('关于'),
            const Text('ReadRx 读药助手 1.0\n拍照识别药品说明书，用大白话讲清楚怎么吃。\n\n'
                'AI 生成的内容仅供参考，用药请遵医嘱。',
                style: TextStyle(fontSize: 16, height: 1.6)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
