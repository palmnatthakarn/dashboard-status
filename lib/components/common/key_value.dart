import 'package:flutter/material.dart';

class KeyValue extends StatelessWidget {
  final String keyText;
  final String value;
  const KeyValue(this.keyText, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            keyText,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF0F172A))),
        ),
      ],
    ),
  );
}
