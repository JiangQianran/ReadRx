import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../services/api.dart';
import '../services/expiry.dart';
import '../widgets/common.dart';
import 'medicine_detail_page.dart';
import 'multi_result_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.onOpenCabinet});
  final VoidCallback? onOpenCabinet;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const _maxPhotos = 6;
  final _picker = ImagePicker();
  final List<Uint8List> _photos = [];
  bool _loading = false;

  // 压缩参数：长边 1600 像素足够看清说明书，又不会太大
  static const _maxSide = 1600.0;
  static const _quality = 82;

  Future<void> _takePhoto() async {
    if (_photos.length >= _maxPhotos) return _tooMany();
    try {
      final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: _maxSide, maxHeight: _maxSide, imageQuality: _quality);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() => _photos.add(bytes));
    } catch (e) {
      if (mounted) showMessage(context, '打开相机失败：$e');
    }
  }

  Future<void> _pickGallery() async {
    if (_photos.length >= _maxPhotos) return _tooMany();
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
        limit: _maxPhotos - _photos.length,
      );
      for (final f in files.take(_maxPhotos - _photos.length)) {
        _photos.add(await f.readAsBytes());
      }
      setState(() {});
    } catch (e) {
      if (mounted) showMessage(context, '打开相册失败：$e');
    }
  }

  void _tooMany() => showMessage(context, '最多 $_maxPhotos 张照片');

  Future<void> _recognize() async {
    if (_photos.isEmpty) return;
    setState(() => _loading = true);
    try {
      final meds = await AppState.instance.api.parse(List.of(_photos));
      if (!mounted) return;
      if (meds.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('没认出来'),
            content: const Text('照片里好像没有药品信息，或者太模糊了。\n请靠近一点、光线亮一点，重新拍一张。', style: TextStyle(fontSize: 18)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('好的'))],
          ),
        );
        return;
      }
      setState(_photos.clear);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => meds.length == 1 ? MedicineDetailPage(medicine: meds.first, isNew: true) : MultiResultPage(medicines: meds),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('出错了：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('识别失败'),
        content: Text(msg, style: const TextStyle(fontSize: 18)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                children: _photos.isEmpty ? _buildStart() : _buildPhotos(),
              ),
            ),
            if (_photos.isNotEmpty) _buildRecognizeBar(),
          ],
        ),
        if (_loading) _buildLoading(),
      ],
    );
  }

  /// 还没拍照：大号扫描框 + 相册 + 拍摄建议 + 药箱概况
  List<Widget> _buildStart() {
    final scheme = Theme.of(context).colorScheme;
    return [
      Text('拍一拍药盒', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
      const SizedBox(height: 4),
      Text('AI 帮您读懂有效期、用法和副作用', style: TextStyle(fontSize: 17, color: Colors.grey.shade600)),
      const SizedBox(height: 20),
      AspectRatio(
        aspectRatio: 1.1,
        child: Material(
          color: Colors.white,
          elevation: 0,
          shadowColor: scheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _loading ? null : _takePhoto,
            child: CustomPaint(
              painter: _ScanCornersPainter(scheme.primary.withValues(alpha: 0.35)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary, Color.lerp(scheme.primary, Colors.teal.shade300, 0.45)!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.photo_camera, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 20),
                    Text('点这里拍照', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.primary)),
                    const SizedBox(height: 6),
                    Text('对准药盒或说明书', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: _loading ? null : _pickGallery,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(58), backgroundColor: Colors.white),
        icon: const Icon(Icons.photo_library_outlined, size: 26),
        label: const Text('从相册选照片'),
      ),
      const SizedBox(height: 24),
      Text('建议拍这几面，识别更准', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      const SizedBox(height: 10),
      const Row(
        children: [
          Expanded(child: _TipChip(icon: Icons.inventory_2_outlined, label: '药盒正面')),
          SizedBox(width: 10),
          Expanded(child: _TipChip(icon: Icons.event_outlined, label: '有效期')),
          SizedBox(width: 10),
          Expanded(child: _TipChip(icon: Icons.description_outlined, label: '说明书')),
        ],
      ),
      const SizedBox(height: 20),
      _buildCabinetStatus(),
    ];
  }

  /// 药箱概况：有过期 / 快过期的药时醒目提示，否则只是一行小字入口
  Widget _buildCabinetStatus() {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final meds = AppState.instance.medicines;
        if (meds.isEmpty || widget.onOpenCabinet == null) return const SizedBox.shrink();
        final expired = meds.where((m) => Expiry.status(m.expiryDate) == ExpiryStatus.expired).length;
        final soon = meds.where((m) => Expiry.status(m.expiryDate) == ExpiryStatus.soon).length;
        if (expired == 0 && soon == 0) {
          return Center(
            child: TextButton.icon(
              onPressed: widget.onOpenCabinet,
              icon: const Icon(Icons.medical_services_outlined),
              label: Text('我的药箱里有 ${meds.length} 种药', style: const TextStyle(fontSize: 17)),
            ),
          );
        }
        final c = expired > 0 ? Colors.red.shade700 : Colors.orange.shade800;
        final text = [if (expired > 0) '$expired 种药已过期', if (soon > 0) '$soon 种药快到期'].join('，');
        return Material(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onOpenCabinet,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: c, size: 28),
                  const SizedBox(width: 10),
                  Expanded(child: Text('药箱里$text，点这里查看', style: TextStyle(fontSize: 17, color: c, fontWeight: FontWeight.w600))),
                  Icon(Icons.chevron_right, color: c, size: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 已拍照片：网格 + 「再拍一张」
  List<Widget> _buildPhotos() {
    final scheme = Theme.of(context).colorScheme;
    return [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已选照片', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                const SizedBox(height: 2),
                Text('还可以补拍有效期或说明书', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          ),
          TextButton(
            onPressed: _loading ? null : () => setState(_photos.clear),
            child: const Text('清空', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (var i = 0; i < _photos.length; i++)
            Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(_photos[i], fit: BoxFit.cover)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _loading ? null : () => setState(() => _photos.removeAt(i)),
                      child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close, color: Colors.white, size: 22)),
                    ),
                  ),
                ),
              ],
            ),
          if (_photos.length < _maxPhotos)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _loading ? null : _takePhoto,
                child: CustomPaint(
                  painter: _ScanCornersPainter(scheme.primary.withValues(alpha: 0.3), inset: 14, length: 22, stroke: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: scheme.primary),
                      const SizedBox(height: 8),
                      Text('再拍一张', style: TextStyle(fontSize: 18, color: scheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (_photos.length < _maxPhotos)
        OutlinedButton.icon(
          onPressed: _loading ? null : _pickGallery,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: Colors.white),
          icon: const Icon(Icons.photo_library_outlined, size: 26),
          label: const Text('从相册添加'),
        ),
    ];
  }

  /// 固定在底部的识别按钮
  Widget _buildRecognizeBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: FilledButton.icon(
        onPressed: _loading ? null : _recognize,
        icon: const Icon(Icons.auto_awesome, size: 28),
        label: const Text('开始识别'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
      ),
    );
  }

  Widget _buildLoading() {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        alignment: Alignment.center,
        child: const Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 52, height: 52, child: CircularProgressIndicator(strokeWidth: 5)),
                SizedBox(height: 20),
                Text('AI 正在看说明书…', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('大约需要 10～30 秒，请稍等', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: c, size: 28),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

/// 扫描框四个角的取景线
class _ScanCornersPainter extends CustomPainter {
  _ScanCornersPainter(this.color, {this.inset = 22, this.length = 36, this.stroke = 5});
  final Color color;
  final double inset;
  final double length;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    const r = 10.0;
    final l = inset, t = inset, rt = size.width - inset, b = size.height - inset;
    final path = Path()
      // 左上
      ..moveTo(l, t + length)
      ..lineTo(l, t + r)
      ..arcToPoint(Offset(l + r, t), radius: const Radius.circular(r))
      ..lineTo(l + length, t)
      // 右上
      ..moveTo(rt - length, t)
      ..lineTo(rt - r, t)
      ..arcToPoint(Offset(rt, t + r), radius: const Radius.circular(r))
      ..lineTo(rt, t + length)
      // 右下
      ..moveTo(rt, b - length)
      ..lineTo(rt, b - r)
      ..arcToPoint(Offset(rt - r, b), radius: const Radius.circular(r))
      ..lineTo(rt - length, b)
      // 左下
      ..moveTo(l + length, b)
      ..lineTo(l + r, b)
      ..arcToPoint(Offset(l, b - r), radius: const Radius.circular(r))
      ..lineTo(l, b - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanCornersPainter old) => old.color != color;
}
