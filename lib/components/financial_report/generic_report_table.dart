import 'package:flutter/material.dart';

class GenericReportTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int>? highlightRows;

  const GenericReportTable({
    super.key,
    required this.headers,
    required this.rows,
    this.highlightRows,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth > 800
                    ? constraints.maxWidth
                    : 800,
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.grey.shade200),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF1F5F9), // Slate 100
                  ),
                  dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(MaterialState.hovered)) {
                      return const Color(
                        0xFFF8FAFC,
                      ); // Very light slate on hover
                    }
                    return null;
                  }),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155), // Slate 700
                    fontSize: 14,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Color(0xFF475569), // Slate 600
                    fontSize: 14,
                  ),
                  horizontalMargin: 24,
                  columnSpacing: 32,
                  headingRowHeight: 52,
                  dataRowHeight: 56,
                  dividerThickness: 1,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade100,
                      width: 1,
                    ),
                    bottom: BorderSide.none,
                  ),
                  columns: headers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final h = entry.value;
                    final isFirst = index == 0;
                    return DataColumn(
                      label: Expanded(
                        child: Text(
                          h,
                          textAlign: isFirst ? TextAlign.left : TextAlign.right,
                        ),
                      ),
                      numeric: !isFirst,
                    );
                  }).toList(),
                  rows: rows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cells = entry.value;
                    final isHighLight = highlightRows?.contains(index) ?? false;
                    final isEven = index % 2 == 0;

                    // Row Background Color
                    Color rowColor = isEven
                        ? Colors.white
                        : const Color(0xFFF8FAFC);
                    if (isHighLight) {
                      rowColor = const Color(0xFFEFF6FF); // Blue 50
                    }

                    // Highlight Text Style
                    final isTotalRow =
                        isHighLight || cells[0].toString().contains('รวม');
                    final fontWeight = isTotalRow
                        ? FontWeight.bold
                        : FontWeight.normal;
                    final textColor = isTotalRow
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF475569);

                    return DataRow(
                      color: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.hovered)) {
                          return const Color(0xFFE2E8F0).withOpacity(0.4);
                        }
                        return rowColor;
                      }),
                      cells: cells.asMap().entries.map((cellEntry) {
                        final cellIndex = cellEntry.key;
                        final cell = cellEntry.value;
                        final isFirst = cellIndex == 0;

                        return DataCell(
                          Container(
                            alignment: isFirst
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Text(
                              cell,
                              style: TextStyle(
                                fontWeight: fontWeight,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
