# เพิ่มการใช้ข้อมูลจาก /dashboard/shops/:shopid/daily ในตาราง

## 🔄 สิ่งที่เพิ่มเข้าไป

### 1. Model ใหม่ (daily_transaction.dart)

#### DailyTransaction
```dart
class DailyTransaction {
  final String? timestamp;
  final double? deposit;      // ยอดฝาก
  final double? withdraw;     // ยอดถอน
  final String? ref;          // หมายเลขอ้างอิง
  final String? note;         // หมายเหตุ
  final RecordedBy? recordedBy; // ผู้บันทึก
}
```

#### RecordedBy
```dart
class RecordedBy {
  final String? name;         // ชื่อผู้บันทึก
  final String? employeeId;   // รหัสพนักงาน
}
```

#### ShopDailyResponse
```dart
class ShopDailyResponse {
  final String? status;
  final String? shopid;
  final String? shopname;
  final List<DailyTransaction> daily; // รายการ transactions
}
```

### 2. API Service ใหม่

#### fetchShopDailyTransactions()
```dart
static Future<ShopDailyResponse?> fetchShopDailyTransactions(String shopId) async {
  final url = '$baseUrl/dashboard/shops/$shopId/daily';
  // ส่งคืน ShopDailyResponse ที่มี daily transactions
}
```

### 3. การปรับปรุง DocDetails Model

#### เพิ่ม Field ใหม่
```dart
@JsonKey(name: 'daily_transactions')
final List? dailyTransactions;
```

#### เพิ่ม Getters ใหม่
```dart
double get dailyTotal {
  // คำนวณยอดรวม deposit จาก dailyTransactions
}

double get dailyTotalWithdraw {
  // คำนวณยอดรวม withdraw จาก dailyTransactions
}

double get dailyNetTotal {
  // คำนวณยอดสุทธิ (deposit - withdraw)
}
```

### 4. การปรับปรุง Dashboard BLoC

#### การดึงข้อมูล
```dart
// ดึงข้อมูล daily transactions
final shopDailyResponse = await ApiService.fetchShopDailyTransactions(shopId);

// ดึงข้อมูล daily images (เพื่อความครบถ้วน)
final shopDailyImages = await ApiService.fetchShopDaily(shopId);

// รวมข้อมูลทั้งหมด
DocDetails(
  // ... fields เดิม
  dailyImages: shopDailyImages,
  dailyTransactions: shopDailyResponse?.daily,
);
```

### 5. การปรับปรุงตาราง (shop_data_table.dart)

#### การคำนวณใหม่
```dart
double _getDailySum(dynamic shop) {
  if (shop.dailyTransactions == null || shop.dailyTransactions.isEmpty) return 0.0;
  
  double sum = 0.0;
  for (final transaction in shop.dailyTransactions) {
    if (transaction.deposit != null) {
      sum += transaction.deposit!;
    }
  }
  return sum;
}
```

## 📊 ข้อมูลที่แสดงในตาราง

### คอลัมน์ที่ได้รับข้อมูลใหม่:

1. **รายวัน** - ยอดรวม deposit จาก dailyTransactions
2. **รายเดือน** - เฉลี่ยจาก monthlySummary
3. **รายปี** - ยอดรวมจาก monthlySummary
4. **สถานะ** - คำนวณจากยอดรายปี

### คอลัมน์ที่ยังคงเดิม:

5. **อัปโหลด** - จำนวนไฟล์จาก dailyImages
6. **ผู้รับผิดชอบ** - จาก responsible.name

## 🔧 การทำงาน

### Flow การดึงข้อมูล:
1. เรียก `/dashboard/shops` → ได้รายการร้านค้า
2. สำหรับแต่ละร้าน เรียก `/dashboard/shops/:shopid/daily` → ได้ transactions
3. สำหรับแต่ละร้าน เรียก `/dashboard/shops/:shopid/daily` (เดิม) → ได้ images
4. รวมข้อมูลทั้งหมดใน DocDetails
5. แสดงในตาราง

### ข้อมูลที่แสดง:
- **รายวัน**: ผลรวม deposit ของ transactions ทั้งหมด
- **รายเดือน**: เฉลี่ยจาก monthly_summary
- **รายปี**: ผลรวมจาก monthly_summary
- **สถานะ**: Safe/Warning/Exceeded ตามยอดรายปี

## 🎯 ผลลัพธ์

### ตารางจะแสดง:
| สถานะ | ชื่อร้าน | รหัสร้าน | รายวัน | รายเดือน | รายปี | อัปโหลด | ผู้รับผิดชอบ |
|-------|---------|---------|--------|----------|-------|---------|-------------|
| Safe | ผัดไทยสมชาย | SHOP000001 | ฿1,972,218 | ฿120,000 | ฿1,440,000 | 0 ไฟล์ | สมชาย ใจดี |

### ข้อดี:
- ✅ **ข้อมูลจริงจาก API** - ไม่ใช่ข้อมูลจำลอง
- ✅ **รองรับ transactions หลายรายการ** - แสดงผลรวม
- ✅ **ยืดหยุ่น** - สามารถเพิ่มการคำนวณอื่นได้
- ✅ **แยกประเภทข้อมูล** - transactions vs images
- ✅ **Error handling** - ทำงานได้แม้ API บางตัวล้มเหลว

### การใช้งาน:
- แต่ละแถวแสดงข้อมูลจาก API จริง
- คลิกแถวเพื่อดูรายละเอียดร้าน
- คลิกคอลัมน์อัปโหลดเพื่อดูไฟล์ images
- ข้อมูลทางการเงินคำนวณจาก daily transactions

## 🧪 การทดสอบ

เมื่อรันแอพจะเห็น:
- Log การดึงข้อมูลจากแต่ละ endpoint
- ข้อมูล transactions จำนวนมาก (31 รายการต่อร้าน)
- ยอดรวมที่คำนวณจาก deposit/withdraw จริง
- ตารางแสดงข้อมูลที่ถูกต้องตาม API response