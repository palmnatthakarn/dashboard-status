import 'package:moniter/services/api_service.dart';

void main() async {
  print('🧪 Starting API test...');

  try {
    // ทดสอบ fetchSummary
    print('📊 Testing fetchSummary...');
    final summary = await ApiService.fetchSummary();
    print('✅ Summary: ${summary.doctotal} total docs');

    // ทดสอบ fetchShops
    print('🏪 Testing fetchShops...');
    final shops = await ApiService.fetchShops();
    print('✅ Shops: ${shops.docdetails.length} shops found');

    // ทดสอบ fetchShopDaily สำหรับร้านแรก
    if (shops.docdetails.isNotEmpty) {
      final firstShop = shops.docdetails.first;
      print('🖼️ Testing fetchShopDaily for ${firstShop.shopid}...');
      final dailyImages = await ApiService.fetchShopDaily(
        firstShop.shopid ?? '',
      );
      print('✅ Daily Images: ${dailyImages.length} images found');
    }

    print('🎉 All tests passed!');
  } catch (e) {
    print('💥 Test failed: $e');
  }
}
