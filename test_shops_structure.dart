import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing /dashboard/shops API...');

  const baseUrl = 'http://localhost:3000/api';

  try {
    // ทดสอบ fetchShops ก่อน
    final shopsResponse = await http.get(Uri.parse('$baseUrl/dashboard/shops'));
    print('Shops API Status: ${shopsResponse.statusCode}');

    if (shopsResponse.statusCode == 200) {
      final shopsData = json.decode(shopsResponse.body);
      print('Shops Response keys: ${shopsData.keys.toList()}');

      // ดูโครงสร้างของ shop แรก
      if (shopsData['shops'] is List && shopsData['shops'].isNotEmpty) {
        final firstShop = shopsData['shops'][0];
        print('\nFirst shop structure:');
        print('Keys: ${firstShop.keys.toList()}');

        // ดูว่ามี daily_images หรือ images field ไหม
        if (firstShop.containsKey('daily_images')) {
          print('✅ Has daily_images field');
        }
        if (firstShop.containsKey('images')) {
          print('✅ Has images field');
        }
        if (firstShop.containsKey('daily')) {
          print('✅ Has daily field');
        }

        print('Shop ID: ${firstShop['shopid']}');
        print('Shop Name: ${firstShop['shopname']}');
      }
    } else {
      print('❌ Shops API failed: ${shopsResponse.body}');
    }
  } catch (e) {
    print('💥 Error: $e');
  }
}
