import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_footer.dart';
import '../widgets/auth_page.dart';
import '../widgets/back_next_row.dart';
import '../widgets/labeled_field.dart';
import '../widgets/register_header.dart';
import 'account_type.dart';

/// Step 3: upload documents. A row turns green with a check mark once its file is chosen.
class DocumentsScreen extends StatefulWidget {
  final AccountType accountType;
  final Map<String, String> orgData;
  const DocumentsScreen({
    super.key,
    required this.accountType,
    required this.orgData,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const _maxBytes = 5 * 1024 * 1024; // 5 MB

  late final List<DocSpec> _docs = widget.accountType.config.documents;
  late final List<PlatformFile?> _files = List<PlatformFile?>.filled(
    _docs.length,
    null,
  );
  bool _confirmed = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb, // on web the bytes are needed to upload later
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > _maxBytes) {
        _snack('That file is too large. Please choose one under 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() => _files[index] = file);
    } catch (_) {
      _snack('Could not open the file picker. Please try again.');
    }
  }

  void _submit() {
    if (_files.any((f) => f == null)) {
      _snack('Please upload all the required documents.');
      return;
    }
    if (!_confirmed) {
      _snack('Please tick the confirmation box to continue.');
      return;
    }

    // TODO: send widget.orgData + the picked files (_files) to your backend.

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Submitted for verification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        content: const Text(
          "Thanks! We'll review your details and documents, then let you know by email.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RegisterHeader(step: 3, stepTitle: 'Documents'),
          const SizedBox(height: 12),
          const SectionLabel('Upload required documents'),
          const SizedBox(height: 8),
          const Text(
            'PDF, JPG or PNG, up to 5 MB each.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          ...List.generate(_docs.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DocumentTile(
                spec: _docs[i],
                file: _files[i],
                onPick: () => _pick(i),
              ),
            );
          }),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _confirmed = !_confirmed),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                  activeColor: AppColors.green,
                  side: const BorderSide(color: AppColors.textGrey, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12, right: 4),
                    child: Text(
                      "I confirm these details and documents are accurate, and I'm authorised to register this organisation",
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BackNextRow(nextLabel: 'Submit for verification', onNext: _submit),
          const SizedBox(height: 16),
          const AuthFooter(),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocSpec spec;
  final PlatformFile? file;
  final VoidCallback onPick;

  const _DocumentTile({
    required this.spec,
    required this.file,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final done = file != null;

    return CustomPaint(
      foregroundPainter: _BorderPainter(
        color: done ? AppColors.green : const Color(0xFFD5D0C0),
        dashed: !done,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFEAF5E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: done
                  ? const Icon(
                      Icons.check_circle,
                      key: ValueKey('done'),
                      size: 26,
                      color: AppColors.green,
                    )
                  : const Icon(
                      Icons.insert_drive_file_outlined,
                      key: ValueKey('todo'),
                      size: 26,
                      color: AppColors.dark,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done ? file!.name : spec.helper,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: done ? AppColors.green : AppColors.textGrey,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onPick,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.dark,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                done ? 'Change' : 'Choose file',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  _BorderPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = dashed ? 1.2 : 1.6;

    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.8),
      const Radius.circular(16),
    );

    if (!dashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BorderPainter old) =>
      old.color != color || old.dashed != dashed;
}
