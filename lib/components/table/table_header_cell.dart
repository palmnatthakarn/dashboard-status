import 'package:flutter/material.dart';

class TableHeaderCell extends StatelessWidget {
  final String text;
  final bool alignLeft;
  final int flex;

  const TableHeaderCell({
    super.key,
    required this.text,
    this.alignLeft = false,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );

    if (flex > 0) {
      return Expanded(flex: flex, child: child);
    }

    return child;
  }
}
