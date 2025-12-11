import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing API endpoints...');

  const baseUrl = 'http://localhost:3000/api';

  try {
    // ทดสอบ fetchShops ก่อน
    print('\n📋 Testing /dashboard/shops...');
    final shopsResponse = await http.get(Uri.parse('$baseUrl/dashboard/shops'));
    print('Status: ${shopsResponse.statusCode}');

    if (shopsResponse.statusCode == 200) {
      final shopsData = json.decode(shopsResponse.body);
      print('Response keys: ${shopsData.keys.toList()}');

      // ดูโครงสร้างของ shop แรก
      if (shopsData['shops'] is List && shopsData['shops'].isNotEmpty) {
        final firstShop = shopsData['shops'][0];
        print('First shop keys: ${firstShop.keys.toList()}');
        print('First shop data: $firstShop');

        if (shopsData['shops'] is List && shopsData['shops'].isNotEmpty) {
          final firstShop = shopsData['shops'][0];
          final shopId = firstShop['shopid'];
          print('First shop ID: $shopId');

          // ทดสอบ fetchShopDaily
          print('\n🏪 Testing /dashboard/shops/$shopId/daily...');
          final dailyUrl = '$baseUrl/dashboard/shops/$shopId/daily';
          print('URL: $dailyUrl');

          final dailyResponse = await http.get(Uri.parse(dailyUrl));
          print('Status: ${dailyResponse.statusCode}');
          print('Response body: ${dailyResponse.body}');

          if (dailyResponse.statusCode == 200) {
            final dailyData = json.decode(dailyResponse.body);
            print('Response type: ${dailyData.runtimeType}');
            if (dailyData is Map) {
              print('Response keys: ${dailyData.keys.toList()}');
            } else if (dailyData is List) {
              print('Array length: ${dailyData.length}');
            }
          }
        }
      }
    } else {
      print('Shops API failed: ${shopsResponse.body}');
    }
  } catch (e) {
    print('💥 Error: $e');
  }
}
