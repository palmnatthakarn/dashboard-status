# การแก้ไขตารางให้ใช้ข้อมูลจาก API

## สิ่งที่เปลี่ยนแปลง

### 1. แหล่งข้อมูลใหม่
- **เดิม**: ใช้ข้อมูลจาก hardcoded fields เช่น `shop.totalDeposit`
- **ใหม่**: ใช้ข้อมูลจาก API `/api/dashboard/shops/:shopid/daily` และ `monthly_summary`

### 2. คอลัมน์ที่แสดงข้อมูลจาก API

#### รายวัน (Daily)
```dart
double _getDailySum(dynamic shop) {
  if (shop.daily == null || shop.daily.isEmpty) return 0.0;
  
  double sum = 0.0;
  for (final transaction in shop.daily) {
    if (transaction.deposit != null) {
      sum += transaction.deposit!;
    }
  }
  return sum;
}
```

#### รายเดือน (Monthly)
```dart
double _getMonthlySum(dynamic shop) {
  if (shop.monthlySummary == null) return 0.0;
  
  double sum = 0.0;
  shop.monthlySummary.forEach((String month, dynamic monthData) {
    if (monthData.deposit != null) {
      sum += monthData.deposit!;
    }
  });
  return sum / 12; // เฉลี่ยต่อเดือน
}
```

#### รายปี (Yearly)
```dart
double _getYearlySum(dynamic shop) {
  if (shop.monthlySummary == null) return 0.0;
  
  double sum = 0.0;
  shop.monthlySummary.forEach((String month, dynamic monthData) {
    if (monthData.deposit != null) {
      sum += monthData.deposit!;
    }
  });
  return sum;
}
```

### 3. คอลัมน์ที่ยังคงไว้เดิม

#### สถานะ (Status)
- ยังคงใช้การคำนวณจากยอดรายปี
- เปลี่ยนใช้ `_getYearlySum()` แทน `getIncomeForPeriod()`
- เกณฑ์เดิม: Safe (<1M), Warning (1M-1.8M), Exceeded (>1.8M)

#### อัปโหลด (Upload)
- ยังคงใช้ `shop.imageCount` จาก `dailyImages`
- คลิกเพื่อดูรายการไฟล์และรูปภาพ
- แสดงจำนวนไฟล์ที่มี `imageUrl` ที่ถูกต้อง

#### ผู้รับผิดชอบ (Responsible)
- ยังคงใช้ `shop.responsible?.name`
- แสดงชื่อผู้รับผิดชอบจาก API

### 4. การแสดงผลในตาราง

#### ข้อมูลพื้นฐาน
- **ชื่อร้านค้า**: `shop.shopname` จาก API
- **รหัสร้าน**: `shop.shopid` จาก API

#### ข้อมูลทางการเงิน
- **รายวัน**: ผลรวมจาก `shop.daily[].deposit`
- **รายเดือน**: เฉลี่ยจาก `shop.monthlySummary[month].deposit`
- **รายปี**: ผลรวมจาก `shop.monthlySummary[month].deposit`

### 5. การจัดการข้อมูล null
- ตรวจสอบ null ก่อนการคำนวณทุกครั้ง
- คืนค่า 0.0 เมื่อข้อมูลไม่พร้อมใช้งาน
- แสดง '-' เมื่อค่าเป็น 0

### 6. Performance และ Animation
- ใช้ `TweenAnimationBuilder` สำหรับ smooth animation
- คำนวณข้อมูลแบบ real-time จาก API
- Cache ผลลัพธ์เพื่อป้องกันการคำนวณซ้ำ

## ข้อดีของการเปลี่ยนแปลง

1. **ข้อมูลแม่นยำ**: ใช้ข้อมูลจาก API โดยตรง
2. **Flexible**: สามารถปรับเปลี่ยนการคำนวณได้ง่าย
3. **Real-time**: ข้อมูลอัพเดทตาม API
4. **Null Safe**: จัดการ null values อย่างปลอดภัย
5. **Backward Compatible**: คอลัมน์เดิมยังทำงานได้

## การทดสอบ

เมื่อรันแอพ จะเห็น:
- คอลัมน์รายวัน/รายเดือน/รายปี แสดงข้อมูลจาก API
- สถานะเปลี่ยนตามยอดรายปีที่คำนวณใหม่
- คอลัมน์อัปโหลดและผู้รับผิดชอบยังทำงานเดิม
- Animation ที่ smooth และ responsive