# 📊 Shop Data Table - Journal Integration Summary

เพิ่มการแสดง Journal ใน shop_data_table สำเร็จแล้ว!

## ✅ การเปลี่ยนแปลง

### 1. **เพิ่ม Imports**
```dart
import '../blocs/bloc/bloc_seaandhill_bloc.dart';
import '../models/journal.dart';
```

### 2. **เพิ่มคอลัมน์ Journal**
เพิ่มคอลัมน์ใหม่ระหว่าง "รายปี" และ "อัปโหลด":
```dart
DataColumn2(
  label: Center(child: Text('Journal')),
  size: ColumnSize.M,
  numeric: false,
),
```

### 3. **เพิ่มปุ่ม "ดู Journal"**
```dart
DataCell(
  Center(
    child: ElevatedButton.icon(
      onPressed: () => _showJournalDialog(context, shop),
      icon: const Icon(Icons.account_balance_wallet, size: 16),
      label: const Text('ดู Journal'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
    ),
  ),
),
```

### 4. **สร้าง Journal Dialog**
Dialog แสดงข้อมูล Journal ของร้านค้าแต่ละร้าน:

#### Features:
- 📊 **Summary Cards**: แสดง Total Debit, Total Credit, Net Amount
- 📋 **Journal List**: แสดงรายการ journal entries ทั้งหมด
- 🎨 **Color Coding**: แยกสีตาม account type
- 📱 **Responsive**: ปรับขนาดตามหน้าจอ

## 🎨 UI Components

### 1. **_JournalDialog**
Dialog หลักที่แสดงข้อมูล Journal:
- Header พร้อมชื่อร้าน
- Summary cards แสดงยอดรวม
- List ของ journal entries
- Loading และ Error states

### 2. **_SummaryCard**
Card แสดงสรุปยอดเงิน:
- Total Debit (สีเขียว)
- Total Credit (สีแดง)
- Net Amount (สีน้ำเงิน)

### 3. **_JournalCard**
Card แสดงรายละเอียด journal แต่ละรายการ:
- Account type badge
- Account code และ name
- Document number
- Book name
- Debit/Credit amount
- Transaction type

### 4. **_InfoChip**
Chip แสดงข้อมูลเพิ่มเติม:
- Document number
- Book name

## 🔄 Data Flow

```
User clicks "ดู Journal" button
    ↓
_showJournalDialog() called
    ↓
Create BlocSeaandhillBloc
    ↓
Dispatch LoadJournalsByShopEvent
    ↓
BlocBuilder listens to states
    ↓
Display Journal data
```

## 🎨 Color Scheme

### Account Types:
- **INCOME** (รายได้): `#10B981` (Green)
- **EXPENSES** (ค่าใช้จ่าย): `#EF4444` (Red)
- **ASSETS** (สินทรัพย์): `#3B82F6` (Blue)
- **LIABILITIES** (หนี้สิน): `#F59E0B` (Orange)

### Transaction Direction:
- **Debit**: Green with ↑ icon
- **Credit**: Red with ↓ icon

## 📊 Journal Card Layout

```
┌─────────────────────────────────────────┐
│ [INCOME Badge]              2024-01-08  │
│                                         │
│ 1001 - รายได้จากการขาย                 │
│                                         │
│ [Doc: DOC001] [Book: สมุดรายวัน]       │
│                                         │
│ ↑ Debit: 10,000.00          รายรับ     │
└─────────────────────────────────────────┘
```

## 🚀 การใช้งาน

### 1. ดู Journal ของร้าน:
```dart
// User clicks "ดู Journal" button in table
// Dialog will automatically:
// 1. Load journals for that shop
// 2. Calculate summary
// 3. Display journal list
```

### 2. ข้อมูลที่แสดง:
- **Summary**: Total Debit, Total Credit, Net Amount
- **Journal Entries**:
  - Account type และ name
  - Document number
  - Book name
  - Transaction date
  - Debit/Credit amount
  - Transaction type

### 3. States:
- **Loading**: แสดง CircularProgressIndicator
- **Loaded**: แสดง summary และ journal list
- **Empty**: แสดง "ไม่มีข้อมูล Journal"
- **Error**: แสดง error message

## 📱 Responsive Design

### Dialog Size:
- Width: 90% ของหน้าจอ
- Height: 80% ของหน้าจอ
- Scrollable content

### Summary Cards:
- 3 cards in a row
- Equal width
- Responsive padding

### Journal List:
- Scrollable
- Card-based layout
- Consistent spacing

## 🔧 Technical Details

### BlocProvider:
```dart
BlocProvider(
  create: (context) => BlocSeaandhillBloc()
    ..add(LoadJournalsByShopEvent(shopId: shopId)),
  child: _JournalDialog(shopId: shopId, shopName: shopName),
)
```

### State Management:
- Uses BlocSeaandhillBloc
- Listens to JournalLoadingState, JournalLoadedState, JournalErrorState
- Automatic data loading on dialog open

### Data Calculation:
```dart
final totalDebit = journals.fold(0.0, (sum, j) => sum + (j.debit ?? 0));
final totalCredit = journals.fold(0.0, (sum, j) => sum + (j.credit ?? 0));
final netAmount = totalDebit - totalCredit;
```

## ⚠️ สิ่งที่ต้องระวัง

1. **Shop ID**: ต้องมี shopid ที่ถูกต้อง
2. **API Response**: ตรวจสอบว่า API ส่งข้อมูล journal ถูกต้อง
3. **Empty State**: จัดการกรณีไม่มีข้อมูล
4. **Error Handling**: แสดง error message ที่เหมาะสม
5. **Performance**: ใช้ ListView.builder สำหรับ list ยาวๆ

## 📈 ประโยชน์

1. **Easy Access**: ดู journal ได้ง่ายจากตาราง
2. **Visual Summary**: เห็นภาพรวมยอดเงินทันที
3. **Detailed View**: ดูรายละเอียดแต่ละ entry
4. **Color Coding**: แยกประเภทได้ง่าย
5. **Responsive**: ใช้งานได้ทุกขนาดหน้าจอ

## 🎯 Next Steps

1. **Add Filters**: เพิ่ม filter ตาม date range, account type
2. **Export**: เพิ่มปุ่ม export เป็น CSV/Excel
3. **Search**: เพิ่มการค้นหา journal
4. **Sorting**: เพิ่มการเรียงลำดับ
5. **Pagination**: เพิ่ม pagination สำหรับข้อมูลเยอะๆ

## 📞 สรุป

- ✅ **เพิ่มคอลัมน์ Journal**: ในตาราง shop_data_table
- ✅ **ปุ่ม "ดู Journal"**: เปิด dialog แสดงข้อมูล
- ✅ **Summary Cards**: แสดงยอดรวม Debit, Credit, Net
- ✅ **Journal List**: แสดงรายการ journal entries
- ✅ **Color Coding**: แยกสีตาม account type
- ✅ **Responsive**: ปรับขนาดตามหน้าจอ
- ✅ **State Management**: ใช้ BlocSeaandhillBloc
- ✅ **Error Handling**: จัดการ loading, empty, error states

---

**Status**: ✅ Completed
**Date**: 2025-01-08