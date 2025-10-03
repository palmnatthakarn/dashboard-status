class DashboardHelper {
  static double getIncomeForPeriod(dynamic shop, DateTime? selectedDate) {
    // คำนวณยอดรายปีจาก monthly_summary
    if (shop.monthlySummary == null) return 0.0;

    double sum = 0.0;
    shop.monthlySummary.forEach((String month, dynamic monthData) {
      if (monthData.deposit != null) {
        sum += monthData.deposit!;
      }
    });
    return sum;
  }

  static int getShopCountByStatus(
    List shops,
    String status,
    DateTime? selectedDate,
  ) {
    return shops.where((shop) {
      final income = getIncomeForPeriod(shop, selectedDate);
      switch (status) {
        case 'safe':
          return income < 1000000;
        case 'warning':
          return income >= 1000000 && income <= 1800000;
        case 'exceeded':
          return income > 1800000;
        default:
          return false;
      }
    }).length;
  }

  static Map<String, int> getDocumentCounts(List shops) {
    int totalDeposit = 0;
    int totalWithdraw = 0;
    int totalDocs = 0;

    for (final shop in shops) {
      if (shop.dailyImages != null) {
        for (final image in shop.dailyImages) {
          totalDocs++;
          // ตรวจสอบ category เพื่อแยกประเภท
          if (image.category != null) {
            if (image.category!.toLowerCase().contains('รายรับ') ||
                image.category!.toLowerCase().contains('deposit')) {
              totalDeposit++;
            } else if (image.category!.toLowerCase().contains('รายจ่าย') ||
                image.category!.toLowerCase().contains('withdraw')) {
              totalWithdraw++;
            }
          }
        }
      }
    }

    return {
      'deposit': totalDeposit,
      'withdraw': totalWithdraw,
      'total': totalDocs,
    };
  }
}
