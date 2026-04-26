import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_widgets.dart';
import '../review/review_screen.dart';

/// Free-form text → AI classify → review
class TextEntryScreen extends ConsumerStatefulWidget {
  final Category? prefilledCategory;
  const TextEntryScreen({super.key, this.prefilledCategory});

  @override
  ConsumerState<TextEntryScreen> createState() => _TextEntryScreenState();
}

class _TextEntryScreenState extends ConsumerState<TextEntryScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCategory != null) {
      _ctrl.text = '${widget.prefilledCategory!.label}: ';
      _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
    }
  }

  Future<void> _classify() async {
    final text = _ctrl.text.trim();
    if (text.length < 3) return;
    setState(() { _busy = true; _error = null; });
    try {
      final api = ref.read(apiProvider);
      final me = await ref.read(meProvider.future);
      final receipt = await api.classifyText(text, model: me.preferredLlm);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewScreen(receipt: receipt, sourceLabel: 'METİN'),
      ));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'AI çağrısı başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  RoundIconBtn(icon: 'arrow-left', onTap: () => context.pop()),
                  const Spacer(),
                  Text('Yaz', style: TLText.body(color: T.inkMute, size: 13, weight: FontWeight.w500)),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tek satır da olur', style: TLText.label()),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün ne harcadın?',
                    style: TLText.display(28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TLText.body(size: 17, weight: FontWeight.w400),
                  decoration: const InputDecoration(
                    hintText: 'Bugün markete 320 lira verdim, akşam Espressolab\'da 65 lira kahve içtim...',
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(_error!, style: TLText.body(color: T.alert, size: 12)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _classify,
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: Text(
                    _busy ? 'AI çalışıyor…' : 'Yapay zeka ile çözümle',
                    style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: T.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
