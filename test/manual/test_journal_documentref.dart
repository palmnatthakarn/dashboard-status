import 'dart:convert';
import 'dart:io';

void main() async {
  const String token =
      '003c0b8494b05b8590f51f584d4158b9d117d1ddb8e42fe64ce50a4b8a42cf0f';
  const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';
  const String testShopId = '36xq3C3RKkSrkcCJNj6lnjfBl6Z';

  final client = HttpClient();
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  print('--- Checking Journal documentref ---');
  try {
    final req = await client.postUrl(Uri.parse('$baseUrl/select-shop'));
    for (final e in headers.entries) req.headers.set(e.key, e.value);
    req.write('{"shopid":"$testShopId"}');
    await req.close();

    final taskParam = Uri.encodeComponent('GL Journal');
    final req2 = await client.getUrl(
      Uri.parse('$baseUrl/gl/journal?limit=2&task=$taskParam'),
    );
    for (final e in headers.entries) req2.headers.set(e.key, e.value);
    final res2 = await req2.close();
    final body = await res2.transform(utf8.decoder).join();
    final j = jsonDecode(body);

    if (j['data'] is List && (j['data'] as List).isNotEmpty) {
      final first = j['data'][0];
      print('Keys in Journal: ${first.keys.toList()}');
      print('documentref: ${first['documentref']}');
      print('createdby: ${first['createdby']}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  client.close();
}
