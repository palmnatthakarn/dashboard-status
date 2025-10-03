# VAT Dashboard Status Monitor 📊

ระบบติดตามสถานะภาษีมูลค่าเพิ่ม (VAT) พร้อมระบบอนุมัติไฟล์แบบ Real-time

## ✨ Features

### 🎯 **Dashboard หลัก**
- แสดงสถิติร้านค้าตามช่วงรายได้ (ต่ำกว่า 1 ล้าน, 1-1.8 ล้าน, เกิน 1.8 ล้าน)
- ติดตามจำนวนเอกสารรายรับ/รายจ่าย
- แสดงสถานะการจัดการไฟล์แบบ Real-time

### 🏪 **ระบบจัดการร้านค้า**
- ตารางแสดงข้อมูลร้านค้าพร้อมสถานะ
- คำนวณรายได้รายวัน/รายเดือน/รายปี
- ระบบกรองและค้นหาร้านค้า
- เลือกวันที่เพื่อดูข้อมูลรายวัน

### 📁 **ระบบจัดการไฟล์**
- อัปโหลดและจัดการไฟล์รูปภาพ
- จัดหมวดหมู่ไฟล์ตาม Category และ Subcategory
- ระบบ File Explorer แบบโฟลเดอร์
- ดูตัวอย่างรูปภาพแบบ Interactive Viewer

### ✅ **ระบบอนุมัติไฟล์** (ใหม่!)
- อนุมัติไฟล์ทีละไฟล์หรือทั้งหมดในครั้งเดียว
- ติดตามสถานะ "x/n ไฟล์" ในตารางหลัก
- สีและไอคอนเปลี่ยนตามสถานะการอนุมัติ
- อัปเดตแบบ Real-time ผ่าน BLoC pattern

## 🛠️ Technical Stack

### **Frontend**
- **Flutter** - Cross-platform framework
- **BLoC Pattern** - State management
- **Material Design 3** - UI/UX
- **Data Table 2** - Advanced table widget

### **Key Packages**
```yaml
dependencies:
  flutter_bloc: ^8.1.6
  data_table_2: ^2.5.15
  http: ^1.2.2
  json_annotation: ^4.9.0
  intl: ^0.19.0
  fl_chart: ^0.69.0
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK >= 3.24.3
- Dart >= 3.5.3

### Installation
```bash
# Clone repository
git clone https://github.com/palmnatthakarn/dashboard-status.git
cd dashboard-status

# Get dependencies
flutter pub get

# Generate models (if needed)
flutter packages pub run build_runner build

# Run the app
flutter run
```

### การตั้งค่า API
แก้ไขไฟล์ `lib/services/api_service.dart` เพื่อชื้อไปยัง API endpoint ของคุณ:

```dart
class ApiService {
  static const String baseUrl = 'YOUR_API_ENDPOINT_HERE';
  // ...
}
```

## 📱 Screenshots

### Dashboard หลัก
- สถิติร้านค้าแบ่งตามช่วงรายได้
- การ์ดเอกสารพร้อมจำนวนไฟล์ที่จัดการแล้ว

### ตารางร้านค้า
- แสดงสถานะ Safe/Warning/Exceeded
- คอลัมน์ "อัปโหลด" แสดง "x/n ไฟล์"
- สีเปลี่ยนตามสถานะการอนุมัติ

### ระบบจัดการไฟล์
- File Explorer แบบโฟลเดอร์
- ปุ่มอนุมัติทั้งหมดใน Header
- ปุ่มอนุมัติแต่ละไฟล์
- เครื่องหมายยืนยันเมื่อได้รับการอนุมัติ

## 🏗️ Architecture

### BLoC Pattern
```
lib/blocs/
├── dashboard_bloc.dart          # จัดการข้อมูล dashboard
├── dashboard_event.dart         # Events สำหรับ dashboard
├── dashboard_state.dart         # States สำหรับ dashboard
├── image_approval_bloc.dart     # จัดการการอนุมัติไฟล์
├── image_approval_event.dart    # Events สำหรับการอนุมัติ
└── image_approval_state.dart    # States สำหรับการอนุมัติ
```

### Models & API
```
lib/models/
├── doc_details.dart           # โมเดลข้อมูลร้านค้า
├── daily_transaction.dart     # โมเดลธุรกรรมรายวัน
├── daily_images.dart          # โมเดลรูปภาพรายวัน
└── ...

lib/services/
└── api_service.dart          # HTTP client สำหรับ API calls
```

## 🔄 State Management

### Image Approval State
```dart
class ImageApprovalState {
  final Map<String, Set<String>> approvedImages;  // เก็บรายการไฟล์ที่อนุมัติ
  final Map<String, int> totalImageCounts;        // เก็บจำนวนไฟล์ทั้งหมด
  
  // Methods
  int getApprovedCount(String shopId);           // ดึงจำนวนที่อนุมัติแล้ว
  bool isAllApproved(String shopId);             // ตรวจสอบว่าอนุมัติหมดแล้ว
  String getApprovalStatusText(String shopId);   // สร้างข้อความสถานะ
}
```

## 📈 การพัฒนาต่อ

### TODO List
- [ ] เชื่อมต่อ Backend API จริง
- [ ] ระบบ Authentication
- [ ] Export ข้อมูลเป็น Excel/PDF
- [ ] Push Notifications
- [ ] Offline Support
- [ ] Multi-language Support

### การ Contribute
1. Fork repository
2. สร้าง feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

**Natthakarn Palm**
- GitHub: [@palmnatthakarn](https://github.com/palmnatthakarn)
- Email: palmnatthakarn@gmail.com

---
**Made with ❤️ using Flutter**
