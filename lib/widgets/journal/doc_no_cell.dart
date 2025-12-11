import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocNoCell extends StatefulWidget {
  const DocNoCell({super.key, required this.docNo});
  final String docNo;

  @override
  State<DocNoCell> createState() => _DocNoCellState();
}

class _DocNoCellState extends State<DocNoCell> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.docNo));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('คัดลอก "${widget.docNo}" แล้ว'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.docNo,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _copied ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 14,
              color: _copied ? const Color(0xFF059669) : const Color(0xFF4F46E5),
            ),
          ],
        ),
      ),
    );
  }
}
