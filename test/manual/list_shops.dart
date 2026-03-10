/// Helper: print all available shops for your account
/// Run: dart run test/manual/list_shops.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  const String token =
      '4ba9b965f2157f4111d47fdf2ef75a7a7eb866e90e168304296d091119f1084c';
  const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('$baseUrl/list-shop'));
  req.headers.set('Authorization', 'Bearer $token');
  req.headers.set('Content-Type', 'application/json');

  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body);

  print('\nStatus: ${res.statusCode}');

  if (json['data'] is List) {
    final shops = json['data'] as List;
    print('Found ${shops.length} shop(s):\n');
    for (final s in shops) {
      final id = s['shopid'] ?? s['shop_id'] ?? s['id'] ?? '?';
      final name = s['shopname'] ?? s['shop_name'] ?? id;
      print('  shopId: $id  →  $name');
    }
  } else {
    print('Body: $body');
  }

  client.close();
}
