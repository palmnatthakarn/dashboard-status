import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/generic_report_table.dart';

class ReportContent extends StatelessWidget {
  final String? selectedReportType;
  // This could potentially accept data rows instead of generating them internally if we want it truly generic,
  // but for now we follow the user's structure of having the logic inside.
  // Ideally, data should be passed in. I will keep the mock generation here for now as part of extraction.

  const ReportContent({Key? key, required this.selectedReportType})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Text(
              selectedReportType ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          _buildReportTable(),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    if (selectedReportType == null) return const SizedBox.shrink();

    final type = selectedReportType!;

    if (type.contains('งบแสดงฐานะทางการเงิน') ||
        type.contains('Balance Sheet')) {
      return _buildBalanceSheetTable();
    } else if (type == 'งบกำไรขาดทุน' || type.contains('Profit & Loss')) {
      return _buildProfitLossTable();
    } else if (type == 'งบกำไรขาดทุน 12 เดือน') {
      return _buildProfitLossTable();
    } else if (type.contains('งบทดลอง') || type.contains('Trial Balance')) {
      return _buildTrialBalanceTable();
    } else if (type.contains('งบกระแสเงินสด') || type.contains('Cash Flow')) {
      return _buildCashFlowTable();
    } else if (type == 'บัญชีแยกประเภท') {
      return const SizedBox.shrink();
    } else if (type == 'กระดาษทำการ') {
      return const SizedBox.shrink();
    } else if (type == 'รายงานการบันทึกบัญชี') {
      return _buildGeneralJournalTable();
    } else if (type == 'รายงานรหัสบัญชี') {
      return const SizedBox.shrink();
    } else if (type == 'รายงานสถานะเจ้าหนี้') {
      return _buildAPAgingTable();
    } else if (type == 'รายงานสถานะลูกหนี้') {
      return _buildARAgingTable();
    } else if (type == 'รายงานภาษีซื้อ' || type == 'รายงานภาษีขาย') {
      return _buildInputOutputVatTable();
    } else if (type == 'ภาษีถูกหัก ณ ที่จ่าย') {
      return _buildWithholdingTaxTable();
    } else if (type == 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.3)' ||
        type == 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.53)') {
      return _buildPnd353Table();
    } else if (type.contains('วิเคราะห์อายุลูกหนี้')) {
      return _buildARAgingTable();
    } else if (type.contains('สรุปยอดขาย')) {
      return _buildSalesSummaryTable();
    } else if (type.contains('การ์ดลูกหนี้รายตัว')) {
      return _buildCustomerLedgerTable();
    } else if (type.contains('วิเคราะห์อายุเจ้าหนี้')) {
      return _buildAPAgingTable();
    } else if (type.contains('สรุปยอดซื้อ')) {
      return _buildPurchaseSummaryTable();
    } else if (type.contains('บัญชีคุมสินค้า')) {
      return _buildStockCardTable();
    } else if (type.contains('สรุปความเคลื่อนไหวสินค้า')) {
      return _buildStockMovementTable();
    } else if (type.contains('สมุดรายวันทั่วไป')) {
      return _buildGeneralJournalTable();
    } else if (type.contains('สมุดรายวันจ่าย')) {
      return _buildPaymentJournalTable();
    } else if (type.contains('สมุดรายวันรับ')) {
      return _buildReceiptJournalTable();
    } else if (type.contains('สมุดรายวันซื้อ')) {
      return _buildPurchaseJournalTable();
    } else if (type.contains('สมุดรายวันขาย')) {
      return _buildSalesJournalTable();
    }
    return const SizedBox.shrink();
  }

  // --- Mock Tables for Preview ---

  Widget _buildBalanceSheetTable() {
    return _buildGenericTable(
      headers: ['รายการ (Assets)', 'หมายเหตุ', 'จำนวนเงิน (บาท)'],
      rows: [
        ['สินทรัพย์หมุนเวียน (Current Assets)', '', ''],
        ['  เงินสดและรายการเทียบเท่าเงินสด', '1', '1,500,000.00'],
        ['  ลูกหนี้การค้า', '2', '450,000.00'],
        ['  สินค้าคงเหลือ', '3', '890,000.00'],
        ['รวมสินทรัพย์หมุนเวียน', '', '2,840,000.00'],
        ['สินทรัพย์ไม่หมุนเวียน (Non-Current Assets)', '', ''],
        ['  ที่ดิน อาคาร และอุปกรณ์', '4', '5,200,000.00'],
        ['รวมสินทรัพย์', '', '8,040,000.00'],
        ['หนี้สินและส่วนของผู้ถือหุ้น', '', ''],
        ['  เจ้าหนี้การค้า', '5', '320,000.00'],
        ['  ทุนจดทะเบียน', '', '5,000,000.00'],
        ['  กำไรสะสม', '', '2,720,000.00'],
        ['รวมหนี้สินและส่วนของผู้ถือหุ้น', '', '8,040,000.00'],
      ],
      highlightRows: [4, 7, 12],
    );
  }

  Widget _buildProfitLossTable() {
    return _buildGenericTable(
      headers: ['รายการ (Items)', 'จำนวนเงิน (Amount)'],
      rows: [
        ['รายได้จากการขายและบริการ', '12,500,000.00'],
        ['หัก ต้นทุนขายและบริการ', '(8,000,000.00)'],
        ['กำไรขั้นต้น', '4,500,000.00'],
        ['รายได้อื่น', '50,000.00'],
        ['ค่าใช้จ่ายในการขายและบริหาร', '(1,200,000.00)'],
        ['กำไรก่อนดอกเบี้ยและภาษี', '3,350,000.00'],
        ['ต้นทุนทางการเงิน', '(50,000.00)'],
        ['ภาษีเงินได้', '(660,000.00)'],
        ['กำไรสุทธิ', '2,640,000.00'],
      ],
      highlightRows: [2, 5, 8],
    );
  }

  Widget _buildTrialBalanceTable() {
    return _buildGenericTable(
      headers: ['ชื่อบัญชี (Account Name)', 'เดบิต (Debit)', 'เครดิต (Credit)'],
      rows: [
        ['เงินสด', '500,000.00', '-'],
        ['เงินฝากธนาคาร', '1,000,000.00', '-'],
        ['ลูกหนี้การค้า', '450,000.00', '-'],
        ['สินค้าคงเหลือ', '890,000.00', '-'],
        ['เจ้าหนี้การค้า', '-', '320,000.00'],
        ['ทุนจดทะเบียน', '-', '5,000,000.00'],
        ['รายได้จากการขาย', '-', '12,500,000.00'],
        ['ต้นทุนขาย', '8,000,000.00', '-'],
        ['เงินเดือนพนักงาน', '800,000.00', '-'],
        ['ค่าเช่า', '120,000.00', '-'],
        ['ค่าไฟฟ้าและประปา', '60,000.00', '-'],
        ['รวม', '17,820,000.00', '17,820,000.00'],
      ],
      highlightRows: [11],
    );
  }

  Widget _buildCashFlowTable() {
    return _buildGenericTable(
      headers: ['รายการ (Items)', 'จำนวนเงิน (Amount)'],
      rows: [
        ['กระแสเงินสดจากกิจกรรมดำเนินงาน', ''],
        ['  กำไรก่อนภาษี', '3,300,000.00'],
        ['  ค่าเสื่อมราคา', '120,000.00'],
        ['  ลูกหนี้การค้า (เพิ่ม) ลดลง', '(50,000.00)'],
        ['  เจ้าหนี้การค้า เพิ่ม (ลดลง)', '30,000.00'],
        ['เงินสดสุทธิจากกิจกรรมดำเนินงาน', '3,400,000.00'],
        ['กระแสเงินสดจากกิจกรรมลงทุน', ''],
        ['  ซื้ออุปกรณ์สำนักงาน', '(200,000.00)'],
        ['เงินสดสุทธิใช้ไปในกิจกรรมลงทุน', '(200,000.00)'],
        ['กระแสเงินสดจากกิจกรรมจัดหาเงิน', ''],
        ['  จ่ายเงินปันผล', '(1,000,000.00)'],
        ['เงินสดและรายการเทียบเท่าเงินสดเพิ่มขึ้นสุทธิ', '2,200,000.00'],
        ['เงินสดต้นงวด', '1,300,000.00'],
        ['เงินสดปลายงวด', '3,500,000.00'],
      ],
      highlightRows: [5, 8, 11, 13],
    );
  }

  Widget _buildInputOutputVatTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่ใบกำกับ',
        'ชื่อผู้ซื้อ/ผู้ขาย',
        'สาขา',
        'มูลค่าสินค้า',
        'จำนวนภาษี',
      ],
      rows: [
        [
          '01/12/2025',
          'INV-2025-001',
          'บริษัท เอ บี ซี จำกัด',
          '00000',
          '10,000.00',
          '700.00',
        ],
        [
          '02/12/2025',
          'INV-2025-002',
          'นาย สมชาย ใจดี',
          '-',
          '5,000.00',
          '350.00',
        ],
        [
          '05/12/2025',
          'EXP-2025-089',
          'บริษัท น้ำมันไทย จำกัด',
          '00001',
          '2,000.00',
          '140.00',
        ],
        [
          '12/12/2025',
          'INV-2025-003',
          'หจก. การค้าขาย',
          '00000',
          '15,000.00',
          '1,050.00',
        ],
        ['รวมทั้งสิ้น', '', '', '', '32,000.00', '2,240.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildWithholdingTaxTable() {
    return _buildGenericTable(
      headers: [
        'วันที่จ่าย',
        'ชื่อผู้ถูกหัก',
        'เลขประจำตัวผู้เสียภาษี',
        'ประเภทเงินได้',
        'อัตรา (%)',
        'จำนวนเงินที่จ่าย',
        'ภาษีที่หัก',
      ],
      rows: [
        [
          '05/12/2025',
          'นางสาว สมหญิง',
          '1-1002-xxxxx-xx-x',
          'ค่าบริการ',
          '3%',
          '10,000.00',
          '300.00',
        ],
        [
          '15/12/2025',
          'นาย มานะ',
          '3-4501-xxxxx-xx-x',
          'ค่าเช่า',
          '5%',
          '20,000.00',
          '1,000.00',
        ],
        [
          '28/12/2025',
          'บริษัท รับเหมา จำกัด',
          '0-1055-xxxxx-xx-x',
          'ค่าขนส่ง',
          '1%',
          '5,000.00',
          '50.00',
        ],
        ['รวม', '', '', '', '', '35,000.00', '1,350.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildPnd353Table() {
    return _buildGenericTable(
      headers: [
        'ลำดับ',
        'ชื่อ-สกุล / ชื่อบริษัท',
        'เลขประจำตัวผู้เสียภาษี',
        'วันเดือนปีที่จ่าย',
        'ประเภทเงินได้',
        'จำนวนเงิน',
        'ภาษี',
      ],
      rows: [
        [
          '1',
          'นางสาว สมหญิง',
          '1-1002-xxxxx-xx-x',
          '05/12/2025',
          '40(2)',
          '10,000.00',
          '300.00',
        ],
        [
          '2',
          'นาย มานะ',
          '3-4501-xxxxx-xx-x',
          '15/12/2025',
          '40(5)',
          '20,000.00',
          '1,000.00',
        ],
        [
          '3',
          'บริษัท รับเหมา จำกัด',
          '0-1055-xxxxx-xx-x',
          '28/12/2025',
          '40(8)',
          '5,000.00',
          '50.00',
        ],
        ['รวม', '', '', '', '', '35,000.00', '1,350.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildARAgingTable() {
    return _buildGenericTable(
      headers: [
        'รหัสลูกค้า',
        'ชื่อลูกค้า',
        'ยังไม่ถึงกำหนด',
        'เกิน 1-30 วัน',
        'เกิน 31-60 วัน',
        'เกิน 60 วันขึ้นไป',
        'รวมทั้งสิ้น',
      ],
      rows: [
        [
          'CUS-001',
          'บริษัท เอ บี ซี จำกัด',
          '10,000.00',
          '-',
          '-',
          '-',
          '10,000.00',
        ],
        ['CUS-002', 'นาย สมชาย ใจดี', '-', '5,000.00', '-', '-', '5,000.00'],
        ['CUS-003', 'หจก. การค้าขาย', '-', '-', '15,000.00', '-', '15,000.00'],
        [
          'CUS-004',
          'บริษัท ขนส่งด่วน',
          '2,000.00',
          '1,000.00',
          '-',
          '500.00',
          '3,500.00',
        ],
        [
          'รวม',
          '',
          '12,000.00',
          '6,000.00',
          '15,000.00',
          '500.00',
          '33,500.00',
        ],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildSalesSummaryTable() {
    return _buildGenericTable(
      headers: [
        'รหัสสินค้า/บริการ',
        'ชื่อสินค้า/บริการ',
        'จำนวนหน่วย',
        'ยอดขายก่อนภาษี',
        'ภาษีมูลค่าเพิ่ม',
        'ยอดขายสุทธิ',
      ],
      rows: [
        ['PROD-001', 'สินค้า A', '100', '10,000.00', '700.00', '10,700.00'],
        ['PROD-002', 'สินค้า B', '50', '5,000.00', '350.00', '5,350.00'],
        [
          'SERV-001',
          'ค่าบริการติดตั้ง',
          '10',
          '2,000.00',
          '140.00',
          '2,140.00',
        ],
        ['PROD-003', 'สินค้า C', '200', '20,000.00', '1,400.00', '21,400.00'],
        ['รวม', '', '360', '37,000.00', '2,590.00', '39,590.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildCustomerLedgerTable() {
    return _buildGenericTable(
      headers: ['วันที่', 'เอกสาร', 'คำอธิบาย', 'เดบิต', 'เครดิต', 'คงเหลือ'],
      rows: [
        [
          '01/12/2025',
          'INV-001',
          'ขายเชื่อ - บริษัท เอ บี ซี จำกัด',
          '10,700.00',
          '-',
          '10,700.00',
        ],
        [
          '05/12/2025',
          'INV-002',
          'ขายเชื่อ - บริษัท เอ บี ซี จำกัด',
          '5,350.00',
          '-',
          '16,050.00',
        ],
        [
          '10/12/2025',
          'RCP-001',
          'รับชำระหนี้ - INV-001',
          '-',
          '10,700.00',
          '5,350.00',
        ],
        ['15/12/2025', 'CN-001', 'รับคืนสินค้า', '-', '500.00', '4,850.00'],
        ['ยอดยกไป', '', '', '', '', '4,850.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildAPAgingTable() {
    return _buildGenericTable(
      headers: [
        'รหัสเจ้าหนี้',
        'ชื่อเจ้าหนี้',
        'ยังไม่ถึงกำหนด',
        'เกิน 1-30 วัน',
        'เกิน 31-60 วัน',
        'เกิน 60 วันขึ้นไป',
        'รวมทั้งสิ้น',
      ],
      rows: [
        [
          'VEN-001',
          'บริษัท ซัพพลายเออร์ จำกัด',
          '20,000.00',
          '-',
          '-',
          '-',
          '20,000.00',
        ],
        ['VEN-002', 'หจก. ขายส่ง', '-', '10,000.00', '-', '-', '10,000.00'],
        ['VEN-003', 'นาย สมปอง', '-', '-', '5,000.00', '-', '5,000.00'],
        ['รวม', '', '20,000.00', '10,000.00', '5,000.00', '-', '35,000.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildPurchaseSummaryTable() {
    return _buildGenericTable(
      headers: [
        'รหัสสินค้า',
        'ชื่อสินค้า',
        'จำนวนหน่วย',
        'มูลค่าซื้อ',
        'ภาษีซื้อ',
        'มูลค่ารวม',
      ],
      rows: [
        ['MAT-001', 'วัตถุดิบ A', '500', '50,000.00', '3,500.00', '53,500.00'],
        ['MAT-002', 'วัตถุดิบ B', '200', '20,000.00', '1,400.00', '21,400.00'],
        [
          'EQUIP-001',
          'อุปกรณ์สำนักงาน',
          '5',
          '10,000.00',
          '700.00',
          '10,700.00',
        ],
        ['รวม', '', '705', '80,000.00', '5,600.00', '85,600.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildStockCardTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่เอกสาร',
        'รายละเอียด',
        'รับ (หน่วย)',
        'จ่าย (หน่วย)',
        'คงเหลือ (หน่วย)',
        'ต้นทุนต่อหน่วย',
        'รวมต้นทุน',
      ],
      rows: [
        ['01/12/2025', '-', 'ยอดยกมา', '-', '-', '100', '100.00', '10,000.00'],
        [
          '05/12/2025',
          'GR-001',
          'รับสินค้าจากการสั่งซื้อ',
          '50',
          '-',
          '150',
          '100.00',
          '15,000.00',
        ],
        [
          '10/12/2025',
          'IV-001',
          'เบิกสินค้าเพื่อขาย',
          '-',
          '20',
          '130',
          '100.00',
          '13,000.00',
        ],
        [
          '15/12/2025',
          'IV-002',
          'เบิกสินค้าเพื่อขาย',
          '-',
          '10',
          '120',
          '100.00',
          '12,000.00',
        ],
        ['รวม / ยอดคงเหลือ', '', '', '50', '30', '120', '100.00', '12,000.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildStockMovementTable() {
    return _buildGenericTable(
      headers: [
        'รหัสสินค้า',
        'ชื่อสินค้า',
        'ยอดยกมา',
        'รับเข้า',
        'จ่ายออก',
        'ยอดคงเหลือ',
        'มูลค่าคงเหลือ',
      ],
      rows: [
        ['PROD-001', 'สินค้า A', '100', '50', '30', '120', '12,000.00'],
        ['PROD-002', 'สินค้า B', '50', '20', '10', '60', '3,000.00'],
        ['PROD-003', 'สินค้า C', '200', '0', '50', '150', '22,500.00'],
        ['รวม', '', '350', '70', '90', '330', '37,500.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildGeneralJournalTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่ใบสำคัญ',
        'รายการ',
        'เลขที่บัญชี',
        'ชื่อบัญชี',
        'เดบิต',
        'เครดิต',
      ],
      rows: [
        [
          '01/12/2025',
          'JV-001',
          'ปรับปรุงบัญชีเงินเดือน',
          '55001',
          'เงินเดือน',
          '50,000.00',
          '-',
        ],
        ['', '', '', '21001', 'ค่าใช้จ่ายค้างจ่าย', '-', '50,000.00'],
        [
          '15/12/2025',
          'JV-002',
          'ปรับปรุงค่าเสื่อมราคา',
          '51001',
          'ค่าเสื่อมราคา',
          '5,000.00',
          '-',
        ],
        ['', '', '', '12002', 'ค่าเสื่อมราคาสะสม', '-', '5,000.00'],
        ['รวม', '', '', '', '', '55,000.00', '55,000.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildPaymentJournalTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่ใบสำคัญ',
        'จ่ายให้',
        'เลขที่บัญชี',
        'ชื่อบัญชี',
        'เดบิต',
        'เครดิต',
      ],
      rows: [
        [
          '05/12/2025',
          'PV-001',
          'บจก. ซัพพลายเออร์',
          '21001',
          'เจ้าหนี้การค้า',
          '10,700.00',
          '-',
        ],
        ['', '', '', '11001', 'เงินสด', '-', '10,700.00'],
        [
          '10/12/2025',
          'PV-002',
          'การไฟฟ้า',
          '53001',
          'ค่าไฟฟ้า',
          '2,000.00',
          '-',
        ],
        ['', '', '', '11002', 'เงินฝากธนาคาร', '-', '2,000.00'],
        ['รวม', '', '', '', '', '12,700.00', '12,700.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildReceiptJournalTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่ใบสำคัญ',
        'รับจาก',
        'เลขที่บัญชี',
        'ชื่อบัญชี',
        'เดบิต',
        'เครดิต',
      ],
      rows: [
        [
          '02/12/2025',
          'RV-001',
          'ลูกค้าทั่วไป',
          '11001',
          'เงินสด',
          '5,000.00',
          '-',
        ],
        ['', '', '', '41001', 'รายได้จากการขาย', '-', '5,000.00'],
        [
          '12/12/2025',
          'RV-002',
          'บจก. เอ บี ซี',
          '11002',
          'เงินฝากธนาคาร',
          '20,000.00',
          '-',
        ],
        ['', '', '', '13001', 'ลูกหนี้การค้า', '-', '20,000.00'],
        ['รวม', '', '', '', '', '25,000.00', '25,000.00'],
      ],
      highlightRows: [4],
    );
  }

  Widget _buildPurchaseJournalTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่ใบสำคัญ',
        'เจ้าหนี้',
        'เลขที่บัญชี',
        'ชื่อบัญชี',
        'เดบิต',
        'เครดิต',
      ],
      rows: [
        [
          '01/12/2025',
          'PJ-001',
          'บจก. วัตถุดิบไทย',
          '52001',
          'ซื้อสินค้า',
          '50,000.00',
          '-',
        ],
        ['', '', '', '21001', 'เจ้าหนี้การค้า', '-', '53,500.00'],
        ['', '', '', '11501', 'ภาษีซื้อ', '3,500.00', '-'],
        ['รวม', '', '', '', '', '53,500.00', '53,500.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildSalesJournalTable() {
    return _buildGenericTable(
      headers: [
        'วันที่',
        'เลขที่ใบสำคัญ',
        'ลูกค้า',
        'เลขที่บัญชี',
        'ชื่อบัญชี',
        'เดบิต',
        'เครดิต',
      ],
      rows: [
        [
          '03/12/2025',
          'SJ-001',
          'บจก. ลูกค้าประจำ',
          '13001',
          'ลูกหนี้การค้า',
          '107,000.00',
          '-',
        ],
        ['', '', '', '41001', 'ขายสินค้า', '-', '100,000.00'],
        ['', '', '', '21501', 'ภาษีขาย', '-', '7,000.00'],
        ['รวม', '', '', '', '', '107,000.00', '107,000.00'],
      ],
      highlightRows: [3],
    );
  }

  Widget _buildGenericTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<int>? highlightRows,
  }) {
    return GenericReportTable(
      headers: headers,
      rows: rows,
      highlightRows: highlightRows,
    );
  }
}
