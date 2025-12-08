# 🔄 Journal Field Update Summary

อัพเดทการใช้ `branch_sync` และ `doc_on` แทน `shop_id` และ `shop_name` สำเร็จแล้ว!

## ✅ การเปลี่ยนแปลง

### 1. **Journal Model Updates** (`lib/models/journal.dart`)

#### เดิม:
```dart
@JsonKey(name: 'shop_id')
final String? shopId;
@JsonKey(name: 'shop_name')
final String? shopName;
```

#### ใหม่:
```dart
@JsonKey(name: 'branch_sync')
final String? branchSync;
@JsonKey(name: 'doc_on')
final String? docOn;

// Compatibility getters
String? get shopId => branchSync;
String? get shopName => docOn;
```

### 2. **JournalSummary Model Updates**

#### เดิม:
```dart
@JsonKey(name: 'shop_id')
final String? shopId;
@JsonKey(name: 'shop_name')
final String? shopName;
```

#### ใหม่:
```dart
@JsonKey(name: 'branch_sync')
final String? branchSync;
@JsonKey(name: 'doc_on')
final String? docOn;

// Compatibility getters
String? get shopId => branchSync;
String? get shopName => docOn;
```

### 3. **Service Updates** (`lib/services/journal_service.dart`)

#### API Parameter Updates:
- `shop_id` parameter → `branch_sync` parameter
- API endpoints ยังคงใช้ชื่อเดิม แต่ส่ง `branch_sync` value
- Comment updates: "Get journals by shop" → "Get journals by branch"

#### Data Processing Updates:
```dart
// เดิม
final shopId = journal.shopId ?? 'unknown';
final shopName = journal.shopName ?? 'Unknown Shop';

// ใหม่ (ใช้ field ตรงๆ)
final shopId = journal.branchSync ?? 'unknown';
final shopName = journal.docOn ?? 'Unknown Shop';
```

## 🔄 Backward Compatibility

### Compatibility Getters
เพิ่ม getters เพื่อให้โค้ดเดิมยังใช้งานได้:

```dart
// ใน Journal class
String? get shopId => branchSync;
String? get shopName => docOn;

// ใน JournalSummary class  
String? get shopId => branchSync;
String? get shopName => docOn;
```

### การใช้งาน
โค้ดเดิมยังคงใช้งานได้ปกติ:

```dart
// ยังใช้ได้เหมือนเดิม
final journal = Journal(...);
print(journal.shopId);    // จะได้ค่าจาก branchSync
print(journal.shopName);  // จะได้ค่าจาก docOn

// หรือใช้ field ใหม่โดยตรง
print(journal.branchSync);
print(journal.docOn);
```

## 📊 Database Mapping

### Table: journals
| Database Field | JSON Field | Dart Property | Compatibility Getter |
|---------------|------------|---------------|---------------------|
| `branch_sync` | `branch_sync` | `branchSync` | `shopId` |
| `doc_on` | `doc_on` | `docOn` | `shopName` |

### ความหมายของ Fields:
- **`branch_sync`**: รหัสสาขา/ร้านค้า (เทียบเท่า shop_id)
- **`doc_on`**: ชื่อเอกสาร/ร้านค้า (เทียบเท่า shop_name)

## 🚀 การใช้งาน

### 1. ใช้ Field ใหม่โดยตรง:
```dart
final journal = await JournalService.getJournalById(1);
print('Branch: ${journal.branchSync}');
print('Doc: ${journal.docOn}');
```

### 2. ใช้ Compatibility Getters:
```dart
final journal = await JournalService.getJournalById(1);
print('Shop ID: ${journal.shopId}');      // จะได้ branchSync
print('Shop Name: ${journal.shopName}');  // จะได้ docOn
```

### 3. API Calls:
```dart
// ใช้ branchSync เป็น shopId parameter
final journals = await JournalService.getJournalsByShop('BRANCH001');
final summary = await JournalService.getJournalSummaryByShop('BRANCH001');
```

## 🔧 การทดสอบ

### รันไฟล์ทดสอบ:
```bash
dart test_journal_migration.dart
```

### ผลลัพธ์ที่คาดหวัง:
```
✅ Get all journals: X items
✅ Get journals by shop: X items  
✅ Get journal summary: Found/Not found
✅ Dashboard journal data: X journals
   - Branch Sync: BRANCH001
   - Doc On: Shop Name
```

## ⚠️ สิ่งที่ต้องระวัง

1. **API Endpoints**: ยังคงใช้ `/api/journals/shop/:shop_id` แต่ส่งค่า `branch_sync`
2. **Data Validation**: ตรวจสอบว่า `branch_sync` และ `doc_on` มีค่าถูกต้อง
3. **Legacy Code**: โค้ดเดิมที่ใช้ `shopId` และ `shopName` ยังใช้งานได้
4. **Database Schema**: ตรวจสอบว่า database มี fields `branch_sync` และ `doc_on`

## 📈 ประโยชน์

1. **ความถูกต้อง**: ใช้ field names ที่ตรงกับ database schema
2. **Backward Compatibility**: โค้ดเดิมยังใช้งานได้
3. **Flexibility**: สามารถใช้ทั้ง field ใหม่และ compatibility getters
4. **Clear Mapping**: ชัดเจนว่า field ไหนมาจาก database field ไหน

## 🔄 Next Steps

1. **ทดสอบ Integration**: ทดสอบกับ API จริง
2. **Update Documentation**: อัพเดทเอกสาร API
3. **Monitor Performance**: ตรวจสอบประสิทธิภาพ
4. **Gradual Migration**: ค่อยๆ เปลี่ยนไปใช้ field ใหม่ในโค้ดใหม่

## 📞 Support

หากมีปัญหา:
- ตรวจสอบว่า database มี fields `branch_sync` และ `doc_on`
- ตรวจสอบ API response structure
- รันไฟล์ทดสอบเพื่อยืนยันการทำงาน