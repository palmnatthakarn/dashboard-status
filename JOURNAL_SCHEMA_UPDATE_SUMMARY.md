# 🔄 Journal Schema Update Summary

อัพเดท Journal model ให้ตรงกับ database schema ที่ถูกต้องสำเร็จแล้ว!

## ✅ Journal Model Fields

### Document Information
| Field | Type | JSON Key | Description |
|-------|------|----------|-------------|
| `branchSync` | String? | `branch_sync` | รหัสสาขา (000) |
| `docDatetime` | String? | `doc_datetime` | วันที่เอกสาร |
| `docNo` | String? | `doc_no` | เลขที่เอกสาร |
| `periodNumber` | String? | `period_number` | งวดที่ |
| `accountYear` | String? | `account_year` | ปีบัญชี |

### Book Information
| Field | Type | JSON Key | Description |
|-------|------|----------|-------------|
| `bookCode` | String? | `book_code` | รหัสสมุดบัญชี |
| `bookName` | String? | `book_name` | ชื่อสมุดบัญชี |

### Account Information
| Field | Type | JSON Key | Description |
|-------|------|----------|-------------|
| `accountCode` | String? | `account_code` | รหัสบัญชี |
| `accountName` | String? | `account_name` | ชื่อบัญชี |
| `accountType` | String? | `account_type` | ประเภทบัญชี (ASSETS, EXPENSES, LIABILITIES, INCOME) |

### Transaction Amounts
| Field | Type | JSON Key | Description |
|-------|------|----------|-------------|
| `debit` | double? | `debit` | เดบิต |
| `credit` | double? | `credit` | เครดิต |

### Branch Information
| Field | Type | JSON Key | Description |
|-------|------|----------|-------------|
| `branchCode` | String? | `branch_code` | รหัสสาขา |
| `branchName` | String? | `branch_name` | ชื่อสาขา |

## 🔄 Account Types

### ประเภทบัญชี (Account Types)
- **ASSETS** - สินทรัพย์
- **EXPENSES** - ค่าใช้จ่าย
- **LIABILITIES** - หนี้สิน
- **INCOME** - รายได้

### Transaction Logic
```dart
// INCOME & LIABILITIES
- Debit = ลดยอด (decrease)
- Credit = เพิ่มยอด (increase)

// ASSETS & EXPENSES
- Debit = เพิ่มยอด (increase)
- Credit = ลดยอด (decrease)
```

## 📊 Helper Getters

### Compatibility Getters (Backward Compatibility)
```dart
String? get shopId => branchSync;
String? get shopName => branchName;
String? get transactionDate => docDatetime;
String? get referenceNumber => docNo;
```

### Display Getters
```dart
// Account type display in Thai
String get accountTypeDisplay {
  // ASSETS → 'สินทรัพย์'
  // EXPENSES → 'ค่าใช้จ่าย'
  // LIABILITIES → 'หนี้สิน'
  // INCOME → 'รายได้'
}

// Transaction type based on account type
String get transactionType {
  // Returns: 'increase', 'decrease', or 'none'
}

// Transaction type display in Thai
String get transactionTypeDisplay {
  // INCOME → 'รายรับ'
  // EXPENSES → 'รายจ่าย'
  // ASSETS → 'เพิ่มสินทรัพย์' or 'ลดสินทรัพย์'
  // LIABILITIES → 'ลดหนี้สิน' or 'เพิ่มหนี้สิน'
}

// Format date display
String get displayDate {
  // Returns: 'DD/MM/YYYY' or '-'
}

// Format amount display
String get displayAmount {
  // >= 1M → 'X.XXM'
  // >= 1K → 'X.XXK'
  // else → 'X.XX'
}
```

### Calculation Getters
```dart
double get amount => (debit ?? 0) + (credit ?? 0);
bool get isDebit => (debit ?? 0) > 0;
bool get isCredit => (credit ?? 0) > 0;
```

## 🚀 การใช้งาน

### 1. ดึงข้อมูล Journal
```dart
final journal = await JournalService.getJournalById(1);

// ข้อมูลเอกสาร
print('Branch: ${journal.branchSync}');
print('Doc No: ${journal.docNo}');
print('Date: ${journal.displayDate}');

// ข้อมูลบัญชี
print('Account: ${journal.accountCode} - ${journal.accountName}');
print('Type: ${journal.accountTypeDisplay}');

// ข้อมูลธุรกรรม
print('Debit: ${journal.debit}');
print('Credit: ${journal.credit}');
print('Amount: ${journal.displayAmount}');
print('Transaction: ${journal.transactionTypeDisplay}');

// ข้อมูลสาขา
print('Branch: ${journal.branchCode} - ${journal.branchName}');
```

### 2. ใช้ Compatibility Getters
```dart
// โค้ดเดิมยังใช้งานได้
print('Shop ID: ${journal.shopId}');        // จะได้ branchSync
print('Shop Name: ${journal.shopName}');    // จะได้ branchName
print('Date: ${journal.transactionDate}');  // จะได้ docDatetime
print('Ref: ${journal.referenceNumber}');   // จะได้ docNo
```

### 3. Filter ตาม Account Type
```dart
final journals = await JournalService.getAllJournals();

// รายรับ (INCOME)
final income = journals.where((j) => j.accountType == 'INCOME').toList();

// รายจ่าย (EXPENSES)
final expenses = journals.where((j) => j.accountType == 'EXPENSES').toList();

// สินทรัพย์ (ASSETS)
final assets = journals.where((j) => j.accountType == 'ASSETS').toList();

// หนี้สิน (LIABILITIES)
final liabilities = journals.where((j) => j.accountType == 'LIABILITIES').toList();
```

### 4. คำนวณยอดรวม
```dart
final journals = await JournalService.getAllJournals();

// รวม Debit
final totalDebit = journals.fold(0.0, (sum, j) => sum + (j.debit ?? 0));

// รวม Credit
final totalCredit = journals.fold(0.0, (sum, j) => sum + (j.credit ?? 0));

// ยอดสุทธิ
final netAmount = totalDebit - totalCredit;
```

## 📋 JournalSummary Updates

### New Fields
```dart
@JsonKey(name: 'branch_sync')
final String? branchSync;

@JsonKey(name: 'branch_code')
final String? branchCode;

@JsonKey(name: 'branch_name')
final String? branchName;

@JsonKey(name: 'account_year')
final String? accountYear;
```

### Compatibility
```dart
String? get shopId => branchSync;
String? get shopName => branchName;
```

## 🔧 การทดสอบ

### รันไฟล์ทดสอบ:
```bash
dart test_journal_migration.dart
```

### ตรวจสอบ Fields:
```dart
final journal = await JournalService.getJournalById(1);

print('✅ Document Info:');
print('   - Branch Sync: ${journal.branchSync}');
print('   - Doc Datetime: ${journal.docDatetime}');
print('   - Doc No: ${journal.docNo}');
print('   - Period: ${journal.periodNumber}');
print('   - Year: ${journal.accountYear}');

print('✅ Book Info:');
print('   - Book Code: ${journal.bookCode}');
print('   - Book Name: ${journal.bookName}');

print('✅ Account Info:');
print('   - Account Code: ${journal.accountCode}');
print('   - Account Name: ${journal.accountName}');
print('   - Account Type: ${journal.accountType}');

print('✅ Transaction:');
print('   - Debit: ${journal.debit}');
print('   - Credit: ${journal.credit}');

print('✅ Branch Info:');
print('   - Branch Code: ${journal.branchCode}');
print('   - Branch Name: ${journal.branchName}');
```

## ⚠️ สิ่งที่ต้องระวัง

1. **Account Type**: ต้องเป็น UPPERCASE (ASSETS, EXPENSES, LIABILITIES, INCOME)
2. **Date Format**: `doc_datetime` ควรเป็น ISO 8601 format
3. **Debit/Credit**: ต้องมีค่าอย่างใดอย่างหนึ่ง (ไม่ควรเป็น null ทั้งคู่)
4. **Branch Sync**: ใช้เป็น primary identifier สำหรับสาขา
5. **Backward Compatibility**: โค้ดเดิมที่ใช้ `shopId`, `shopName` ยังใช้งานได้

## 📈 ประโยชน์

1. **ความถูกต้อง**: ตรงกับ database schema จริง
2. **ครบถ้วน**: มีข้อมูลครบทุก field ที่จำเป็น
3. **Flexible**: รองรับทั้ง field ใหม่และ compatibility getters
4. **Type Safe**: มี account type validation
5. **Display Ready**: มี helper getters สำหรับแสดงผล

## 🔄 Migration Path

### จาก Old Schema:
```dart
// เดิม
final shopId = journal.shopId;
final shopName = journal.shopName;
final date = journal.transactionDate;
```

### ไป New Schema:
```dart
// ใหม่ (แนะนำ)
final branchSync = journal.branchSync;
final branchName = journal.branchName;
final date = journal.docDatetime;

// หรือใช้ compatibility getters (ยังใช้ได้)
final shopId = journal.shopId;        // จะได้ branchSync
final shopName = journal.shopName;    // จะได้ branchName
final date = journal.transactionDate; // จะได้ docDatetime
```

## 📞 Support

หากมีปัญหา:
- ตรวจสอบว่า database มี fields ครบถ้วน
- ตรวจสอบ account_type เป็น UPPERCASE
- ตรวจสอบ date format
- รันไฟล์ทดสอบเพื่อยืนยันการทำงาน