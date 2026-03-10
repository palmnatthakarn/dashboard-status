import 'dart:convert';
import 'dart:io';

void main() async {
  const String token =
      '003c0b8494b05b8590f51f584d4158b9d117d1ddb8e42fe64ce50a4b8a42cf0f';
  const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';
  const String testShopId =
      '36xq3C3RKkSrkcCJNj6lnjfBl6Z'; // Shop ID from previous test

  final client = HttpClient();
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  print('--- Testing GL Journal with Task Filter ---');

  // 1. Select Shop
  try {
    final req = await client.postUrl(Uri.parse('$baseUrl/select-shop'));
    for (final e in headers.entries) req.headers.set(e.key, e.value);
    req.write('{"shopid":"$testShopId"}');
    await req.close();
    print('✅ Shop Selected');
  } catch (e) {
    print('❌ Error selecting shop: $e');
    return;
  }

  // 2. Fetch GL Journals with filter Task = "GL Journal"
  try {
    print('\n--- Fetching /gl/journal?task=GL Journal ---');
    // URL encoding the task value just in case
    final taskParam = Uri.encodeComponent('GL Journal');
    final req = await client.getUrl(
      Uri.parse('$baseUrl/gl/journal?limit=10&task=$taskParam'),
    );
    for (final e in headers.entries) req.headers.set(e.key, e.value);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final j = jsonDecode(body);

    if (j['data'] is List) {
      final journals = j['data'] as List;
      print('✅ Found ${journals.length} GL Journals');

      for (final journal in journals) {
        print(
          '  - Doc No: ${journal['docno']} | Account: ${journal['accountcode']} - ${journal['accountname']} | Amount: ${journal['amount']}',
        );
      }
    } else {
      print('⚠️ Unexpected data format: ${j['data']}');
    }
  } catch (e) {
    print('❌ Error fetching GL Journals with task filter: $e');
  }

  client.close();
}
