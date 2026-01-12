import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal.dart';
import '../models/journal_detail.dart';
import '../services/journal_service.dart';
import '../components/common/generic_paginated_table.dart';
import '../models/journal_book.dart';

class GLJournalPage extends StatefulWidget {
  final String shopids; // Renamed from branchSync
  final String? shopName; // Add shop name parameter
  final List<Journal> journals;

  const GLJournalPage({
    super.key,
    required this.shopids,
    this.shopName,
    required this.journals,
  });

  @override
  State<GLJournalPage> createState() => _GLJournalPageState();
}

class _GLJournalPageState extends State<GLJournalPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _numFormat = NumberFormat('#,##0.00');

  // Track expanded rows
  final Map<String, bool> _expandedRows = {};
  final Map<String, JournalDetail?> _rowDetails = {};

  final Map<String, bool> _loadingDetails = {};

  List<JournalBook> _journalBooks = [];
  bool _isLoadingBooks = false;
  JournalBook? _selectedBook;

  @override
  void initState() {
    super.initState();
    _fetchJournalBooks();
  }

  Future<void> _fetchJournalBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      final books = await JournalService.getJournalBooks();
      if (mounted) {
        setState(() {
          _journalBooks = books;
          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBooks = false);
        // Optionally show error
      }
    }
  }

  List<Journal> get _filteredJournals {
    var journals = widget.journals;

    // Filter by Journal Book
    if (_selectedBook != null && _selectedBook!.code != null) {
      journals = journals.where((j) {
        // Match by book code if available in Journal model,
        // fallback to matching by book name if code is missing in Journal model
        // Assuming Journal model has bookCode which we saw earlier
        return j.bookCode == _selectedBook!.code ||
            j.bookName == _selectedBook!.name1;
      }).toList();
    }

    if (_searchQuery.isEmpty) return journals;
    final lowerQuery = _searchQuery.toLowerCase();
    return journals.where((j) {
      return (j.docNo ?? '').toLowerCase().contains(lowerQuery) ||
          (j.accountCode ?? '').toLowerCase().contains(lowerQuery) ||
          (j.accountName ?? '').toLowerCase().contains(lowerQuery) ||
          (j.bookName ?? '').toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _toggleRowExpansion(String docNo) async {
    setState(() {
      _expandedRows[docNo] = !(_expandedRows[docNo] ?? false);
    });

    // Fetch details if expanding and not already loaded
    if (_expandedRows[docNo] == true && _rowDetails[docNo] == null) {
      setState(() {
        _loadingDetails[docNo] = true;
      });

      try {
        final detail = await JournalService.getJournalDetailByDocNo(docNo);
        setState(() {
          _rowDetails[docNo] = detail;
          _loadingDetails[docNo] = false;
        });
      } catch (e) {
        setState(() {
          _loadingDetails[docNo] = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถโหลดรายละเอียดได้: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredJournals;
    final totalDebit = filtered.fold(0.0, (sum, j) => sum + (j.debit ?? 0));
    final totalCredit = filtered.fold(0.0, (sum, j) => sum + (j.credit ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Lighter slate
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildDataTable(filtered)),
          _buildSummaryFooter(totalDebit, totalCredit),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สมุดรายวันทั่วไป',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.shopName ?? widget.shopids,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.print_outlined),
          tooltip: 'พิมพ์รายงาน',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined),
          tooltip: 'Export Excel',
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ค้นหาเลขที่เอกสาร, รหัสบัญชี, ชื่อบัญชี...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Journal Book Filter
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<JournalBook?>(
              tooltip: 'เลือกสมุดรายวัน',
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (book) {
                setState(() {
                  _selectedBook = book;
                });
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem<JournalBook?>(
                    value: null,
                    child: Text(
                      'ทั้งหมด',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_journalBooks.isEmpty && _isLoadingBooks)
                    const PopupMenuItem<JournalBook?>(
                      enabled: false,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ..._journalBooks.map((book) {
                    return PopupMenuItem<JournalBook>(
                      value: book,
                      child: Text(book.name1 ?? book.code ?? '-'),
                    );
                  }),
                ];
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: _selectedBook != null
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedBook?.name1 ?? 'คัดกรองสมุด',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedBook != null
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Journal> filtered) {
    return GenericPaginatedTable<Journal>(
      items: filtered,
      emptyWidget: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.rule_folder_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ไม่พบรายการที่ค้นหา',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองค้นหาด้วยคำสำคัญอื่น หรือเปลี่ยนตัวกรอง',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
      columns: const [
        CustomColumn(label: 'วันที่', flex: 1),
        CustomColumn(label: 'เลขที่เอกสาร', flex: 2),
        CustomColumn(label: 'สมุดบัญชี', flex: 1),
        CustomColumn(label: 'รหัสบัญชี', flex: 1),
        CustomColumn(label: 'ชื่อบัญชี', flex: 2),
        CustomColumn(label: 'คำอธิบาย', flex: 3),
        CustomColumn(label: 'เดบิต', flex: 1, alignment: Alignment.centerRight),
        CustomColumn(
          label: 'เครดิต',
          flex: 1,
          alignment: Alignment.centerRight,
        ),
      ],
      isRowExpanded: (journal) => _expandedRows[journal.docNo ?? ''] ?? false,
      onRowTap: (journal) => _toggleRowExpansion(journal.docNo ?? ''),
      cellBuilder: (journal) {
        final isExpanded = _expandedRows[journal.docNo ?? ''] ?? false;
        return [
          Row(
            children: [
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                journal.displayDate,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              journal.docNo ?? '-',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            journal.bookName ?? '-',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            journal.accountCode ?? '-',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            journal.accountName ?? '-',
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            journal.description ?? '-',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _getDebitDisplay(journal),
            style: TextStyle(
              color: _getDebitDisplay(journal) == '-'
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
          ),
          Text(
            _getCreditDisplay(journal),
            style: TextStyle(
              color: _getCreditDisplay(journal) == '-'
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
          ),
        ];
      },
      expandedDetailBuilder: (journal) {
        final docNo = journal.docNo ?? '';
        final detail = _rowDetails[docNo];
        final isLoading = _loadingDetails[docNo] ?? false;

        if (isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (detail == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'ไม่พบรายละเอียดเพิ่มเติม',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          );
        }

        return _buildExpandedDetail(detail);
      },
    );
  }

  // Removed unused methods _buildCustomTableRow, _buildCustomHeaderCell, _buildCustomDataCell

  Widget _buildExpandedDetail(JournalDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document info
        if (detail.exdocrefno != null) ...[
          Text(
            'เลขที่เอกสารอ้างอิง: ${detail.exdocrefno}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
        ],
        if (detail.accountdescription != null) ...[
          Text(
            'คำอธิบาย: ${detail.accountdescription}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
        ],
        // Debtor/Creditor
        if (detail.debtor?.names != null &&
            detail.debtor!.names!.isNotEmpty) ...[
          Text(
            'ลูกหนี้: ${detail.debtor!.names!.first.name ?? '-'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Journal detail table
        if (detail.journaldetail != null &&
            detail.journaldetail!.isNotEmpty) ...[
          const Text(
            'รายการบัญชี:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: [
                    _buildTableHeader('รหัสบัญชี'),
                    _buildTableHeader('ชื่อบัญชี'),
                    _buildTableHeader('เดบิต'),
                    _buildTableHeader('เครดิต'),
                  ],
                ),
                ...detail.journaldetail!.map((item) {
                  return TableRow(
                    children: [
                      _buildTableCell(item.accountcode ?? '-'),
                      _buildTableCell(item.accountname ?? '-'),
                      _buildTableCell(
                        item.debitamount != null && item.debitamount! > 0
                            ? _numFormat.format(item.debitamount)
                            : '-',
                      ),
                      _buildTableCell(
                        item.creditamount != null && item.creditamount! > 0
                            ? _numFormat.format(item.creditamount)
                            : '-',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
      ),
    );
  }

  // Removed unused _buildColumnHeader as we are using custom table layout

  Widget _buildSummaryFooter(double totalDebit, double totalCredit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'สรุปยอดรวม',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredJournals.length} รายการ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildSummaryCard(
                'รวมเดบิต',
                totalDebit,
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'รวมเครดิต',
                totalCredit,
                const Color(0xFFEF4444),
                const Color(0xFFFEF2F2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _numFormat.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getDebitDisplay(Journal journal) {
    if (journal.debit != null && journal.debit! > 0) {
      return _numFormat.format(journal.debit);
    }
    // Fallback to apiAmount if debit is empty, assuming apiAmount is the total
    if (journal.apiAmount != null && journal.apiAmount! > 0) {
      return _numFormat.format(journal.apiAmount);
    }
    return '-';
  }

  String _getCreditDisplay(Journal journal) {
    if (journal.credit != null && journal.credit! > 0) {
      return _numFormat.format(journal.credit);
    }
    // Fallback to apiAmount if credit is empty, assuming apiAmount is the total
    if (journal.apiAmount != null && journal.apiAmount! > 0) {
      return _numFormat.format(journal.apiAmount);
    }
    return '-';
  }
}
