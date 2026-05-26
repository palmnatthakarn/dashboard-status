# KPI Journal Manual Test Plan

วันที่จัดทำ: 2026-05-20

## ขอบเขตที่ต้องทดสอบ

เมนู `KPI Journal` ใช้ดู KPI จาก GL Journal โดยสรุปตามพนักงาน ร้าน สมุดบัญชี และช่วงวันที่ รวมถึงยอดงานคีย์ ตรวจสอบ และแก้ไข

## Preconditions

- Login ด้วย user ที่มีสิทธิ์เห็นเมนู `KPI Journal`
- Backend/API ใช้งานได้ และมีข้อมูล GL Journal ในช่วงวันที่ที่เลือก
- มีข้อมูลร้านอย่างน้อย 1 ร้าน
- แนะนำให้เตรียมร้านที่มีข้อมูล GL Journal หลายสมุดบัญชี และมีรายการที่มี `createdBy`, `checkedBy`, `updatedBy`

## Smoke Test

| TC | ขั้นตอน | Expected Result |
| --- | --- | --- |
| KJ-001 | Login แล้วคลิกเมนู `KPI Journal` ที่ sidebar | หน้า `KPI - บันทึกบัญชี` แสดงได้ ไม่เกิด error |
| KJ-002 | รอโหลดข้อมูลเริ่มต้น | แสดง summary cards, filter bar และตารางพนักงาน |
| KJ-003 | ตรวจช่วงวันที่เริ่มต้น | วันที่เริ่มต้นเป็นวันแรกของเดือนปัจจุบัน และวันที่สิ้นสุดเป็นวันปัจจุบัน |
| KJ-004 | กด refresh icon | มี loading state แล้วกลับมาแสดงข้อมูลใหม่ได้ |

## Filter Test

| TC | ขั้นตอน | Expected Result |
| --- | --- | --- |
| KJ-101 | เลือกร้าน 1 ร้าน แล้วกดค้นหา | ตารางแสดงเฉพาะข้อมูลของร้านนั้น และ summary เปลี่ยนตามผลลัพธ์ |
| KJ-102 | เลือกหลายร้าน แล้วกดค้นหา | ตารางแสดงเฉพาะร้านที่เลือกแบบ client-side filter |
| KJ-103 | เลือกช่วงวันที่ที่มีข้อมูล แล้วกดค้นหา | แสดงเฉพาะ GL Journal ในช่วงวันที่นั้น |
| KJ-104 | เลือกช่วงวันที่ที่ไม่มีข้อมูล แล้วกดค้นหา | แสดง empty state `ไม่พบข้อมูล` ไม่ crash |
| KJ-105 | ค้นหาพนักงานจากช่องค้นหา แล้วเลือกชื่อ | ตารางเหลือเฉพาะพนักงานที่เลือก |
| KJ-106 | เลือกสมุดบัญชี แล้วกดค้นหา/กรอง | จำนวนคีย์และรายละเอียดแสดงเฉพาะ book code ที่เลือก |
| KJ-107 | ลบ chip พนักงาน หรือ clear filter | ตารางกลับมาแสดงข้อมูลตาม filter อื่นที่ยังค้างอยู่ |

## Table And Expand Test

| TC | ขั้นตอน | Expected Result |
| --- | --- | --- |
| KJ-201 | กดแถวพนักงานเพื่อ expand | แสดงแถวร้านใต้พนักงานนั้น |
| KJ-202 | กดแถวร้านเพื่อ expand | แสดงรายการเอกสารใต้ร้านนั้น สูงสุด 200 รายการ |
| KJ-203 | ตรวจ column `เอกสารที่ต้องบันทึก`, `คีย์`, `ตรวจสอบ`, `แก้ไข` | ตัวเลขตรงกับข้อมูลของพนักงาน/ร้าน/เอกสาร |
| KJ-204 | Hover tooltip ที่จุดคีย์/ตรวจสอบ/แก้ไข | แสดงเวลา created/checked/updated เมื่อมีข้อมูล |
| KJ-205 | เปลี่ยนขนาด font 1x, 1.2x, 1.4x | ตารางอ่านได้ ไม่ล้นจนใช้งานไม่ได้ |
| KJ-206 | เปลี่ยนหน้า pagination และ rows per page | รายการเปลี่ยนหน้าถูกต้อง และไม่ reset แบบผิดจังหวะ |

## Data Validation

| TC | วิธีตรวจ | Expected Result |
| --- | --- | --- |
| KJ-301 | เทียบจำนวน `คีย์` กับ `/gl/journal` ตามร้านและวันที่ | จำนวนรวมต่อพนักงานตรงกับ GL Journal ที่มี `createdBy` |
| KJ-302 | เทียบ `ตรวจสอบ` | นับรายการที่ `checkedBy` เท่ากับพนักงานนั้น |
| KJ-303 | เทียบ `แก้ไข` | นับรายการที่ `updatedBy` เท่ากับพนักงานนั้น |
| KJ-304 | เทียบรายการที่ผูก task | รายการที่มี `jobguidfixed` หรือ `documentRef` ถูกนับเป็น linked journal |
| KJ-305 | กรณี reviewer ไม่ใช่ keyer | reviewer แสดงยอดตรวจสอบ/แก้ไขได้ แม้ไม่มีรายการคีย์เอง |

## Edge Cases

| TC | ขั้นตอน | Expected Result |
| --- | --- | --- |
| KJ-401 | ร้านที่เลือกไม่มี GL Journal จาก shopId แต่ branch name มีข้อมูล | ระบบ retry ด้วยชื่อร้านและแสดงข้อมูลได้ |
| KJ-402 | GL Journal ไม่มี `createdBy` | รายการนั้นไม่ถูกนับเป็นงานคีย์ และหน้าไม่ crash |
| KJ-403 | GL Journal มีวันที่ parse ไม่ได้ | รายการไม่ทำให้หน้า crash |
| KJ-404 | ข้อมูลร้านโหลดไม่ได้ แต่ GL Journal โหลดได้ | หน้า fallback ได้ หรือแสดง error ที่ retry ได้ |
| KJ-405 | token หมดอายุหรือ API error | แสดง error/loading จบได้ และกด retry ได้ |

## Regression Checks From Code Review

- ค่า summary `filteredTotalDocuments` ต้องไม่นับเอกสารซ้ำเมื่อพนักงานหลายคนอยู่ร้านเดียวกัน
- เมื่อเปลี่ยนร้าน/วันที่/พนักงาน/สมุดบัญชี ต้อง reset expanded rows และกลับหน้าแรก
- เมื่อเลือกหลายร้าน ระบบต้อง filter เฉพาะ shop names ที่เลือก ไม่ดึงร้านอื่นมาแสดง
- เมื่อกรอง book code ค่า `totalJournals`, `totalDebit`, `totalCredit`, `totalChecked`, `totalUpdated` ต้อง recalculate ใหม่
- ตารางต้องยังใช้งานได้เมื่อชื่อพนักงานยาว หรือมี mapping ชื่อภาษาไทย

## Automated Checks Run

- `flutter analyze`
  - Result: fail จาก analyzer issues 250 รายการ ส่วนใหญ่เป็น lint/info เดิม เช่น `avoid_print`, `deprecated_member_use`, `curly_braces_in_flow_control_structures`
- `flutter analyze lib\blocs\kpi_journal lib\pages\kpi\kpi_journal_page.dart lib\pages\kpi\widgets\kpi_journal_filter_section.dart`
  - Result: fail จาก 11 analyzer issues ระดับ warning/info ไม่มี compile error
- `flutter test`
  - Result: รันผ่าน 33 tests ก่อนจบด้วย VM out-of-memory / thread resource error ระหว่าง test runner ไม่ใช่ assertion failure ของ KPI Journal โดยตรง
- `flutter test --concurrency=1 test\unit`
  - Result: รันผ่าน 25 tests ก่อนจบด้วย VM resource error ตอนโหลด `kpi_employee_test.dart`
- `flutter test test\unit\app_constants_test.dart test\unit\kpi_employee_test.dart`
  - Result: ผ่านทั้งหมด 15 tests
- `flutter test test\widget_test.dart`
  - Result: ผ่านทั้งหมด 3 tests แต่มี Dart process crash หลังจบคำสั่งจาก resource pressure
- `dart run test\manual\test_kpi_doc_count.dart`
  - Result: execute จบและพิมพ์ `FINAL` แต่ไม่มีรายการนับออกมา อาจไม่มีข้อมูล match เงื่อนไขที่ script print
- `dart run test\manual\test_gl_journal_task_filter.dart`
  - Result: timeout / network call ไม่จบใน environment นี้

## Analyzer Issues To Follow Up

- `lib\blocs\kpi_journal\kpi_journal_bloc.dart`: unnecessary null comparisons และ lint เรื่อง curly braces/local underscore
- `lib\pages\kpi\kpi_journal_page.dart`: unused local variables `fmt` และ `scrollW`
