# การแก้ไขปัญหา ShopDataTable ไม่แสดงผล

## ปัญหาที่พบบ่อย

### 1. ไม่มี BlocProvider
**อาการ**: Widget ไม่แสดงผลหรือเกิด error เกี่ยวกับ BlocProvider

**วิธีแก้ไข**: ต้องมี BlocProvider ครอบ ShopDataTable
```dart
BlocProvider(
  create: (context) => JournalBloc(),
  child: ShopDataTable(
    selectedDate: selectedDate,
    onDateChanged: (date) {
      // handle date change
    },
  ),
)
```

### 2. API Server ไม่ทำงาน
**อาการ**: แสดง loading ตลอดเวลาหรือแสดง error message

**วิธีแก้ไข**: 
- ตรวจสอบว่า API server รันที่ `http://localhost:3000` หรือไม่
- หรือใช้ Demo version แทน:

```dart
// ใช้ ShopDataTableDemo แทน ShopDataTable
import 'lib/widgets/shop_data_table_demo.dart';

// ในหน้าที่ต้องการใช้งาน
const ShopDataTableDemo()
```

### 3. ไม่มีข้อมูล Journal
**อาการ**: แสดงข้อความ "ไม่มีข้อมูลสาขา"

**วิธีแก้ไข**: 
- ตรวจสอบว่าฐานข้อมูลมีข้อมูล Journal ที่มี `branch_sync` หรือไม่
- ตรวจสอบ API endpoint `/api/journals` ว่าส่งข้อมูลถูกต้องหรือไม่

### 4. ข้อมูลไม่อัปเดต
**อาการ**: ข้อมูลไม่เปลี่ยนแปลงเมื่อเลือกวันที่ใหม่

**วิธีแก้ไข**: เพิ่มการ reload ข้อมูลเมื่อวันที่เปลี่ยน:
```dart
ShopDataTable(
  selectedDate: selectedDate,
  onDateChanged: (date) {
    setState(() {
      selectedDate = date;
    });
    // Reload data
    context.read<JournalBloc>().add(LoadJournals(
      startDate: date != null ? DateFormat('yyyy-MM-dd').format(date) : null,
      endDate: date != null ? DateFormat('yyyy-MM-dd').format(date) : null,
    ));
  },
)
```

## การใช้งานที่แนะนำ

### 1. การใช้งานพื้นฐาน
```dart
class ShopDataPage extends StatefulWidget {
  @override
  State<ShopDataPage> createState() => _ShopDataPageState();
}

class _ShopDataPageState extends State<ShopDataPage> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลสาขา')),
      body: BlocProvider(
        create: (context) => JournalBloc(),
        child: ShopDataTable(
          selectedDate: selectedDate,
          onDateChanged: (date) {
            setState(() {
              selectedDate = date;
            });
          },
        ),
      ),
    );
  }
}
```

### 2. การใช้งานแบบ Demo (สำหรับทดสอบ)
```dart
class DemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลสาขา (Demo)')),
      body: const ShopDataTableDemo(),
    );
  }
}
```

## การตรวจสอบปัญหา

### 1. ตรวจสอบ Console Log
- เปิด Debug Console ใน IDE
- ดู error messages หรือ API response

### 2. ตรวจสอบ Network
- ใช้ Network tab ใน Browser DevTools
- ตรวจสอบว่า API calls ส่งไปถูกต้องหรือไม่

### 3. ตรวจสอบ State
- ใช้ Flutter Inspector
- ดู BlocBuilder state ว่าเป็น Loading, Loaded, หรือ Error

## ไฟล์ที่เกี่ยวข้อง

- `lib/widgets/shop_data_table.dart` - Widget หลัก
- `lib/widgets/shop_data_table_demo.dart` - Demo version
- `lib/blocs/journal_bloc.dart` - BLoC สำหรับจัดการ state
- `lib/services/journal_service.dart` - Service สำหรับเรียก API
- `lib/models/journal.dart` - Model สำหรับข้อมูล Journal

## การติดต่อขอความช่วยเหลือ

หากยังมีปัญหา กรุณาแจ้ง:
1. Error message ที่แสดง
2. ขั้นตอนที่ทำก่อนเกิดปัญหา  
3. Screenshot หรือ video ของปัญหา