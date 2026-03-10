import 'dart:convert';
import 'dart:io';

void main() async {
  const String token =
      '003c0b8494b05b8590f51f584d4158b9d117d1ddb8e42fe64ce50a4b8a42cf0f';
  const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';
  const String testShopId =
      '36xq3C3RKkSrkcCJNj6lnjfBl6Z'; // Shop from the result

  final client = HttpClient();
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  print('--- Testing Shop: $testShopId ---');

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

  // 2. Fetch Tasks to see its properties
  List<dynamic> tasks = [];
  try {
    print('\n--- Fetching /task ---');
    final req = await client.getUrl(
      Uri.parse('$baseUrl/task?limit=5&status=0,1,2,3,4&page=1'),
    );
    for (final e in headers.entries) req.headers.set(e.key, e.value);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final j = jsonDecode(body);
    if (j['data'] is List) {
      tasks = j['data'] as List;
      print('✅ Found ${tasks.length} tasks');
    }
  } catch (e) {
    print('❌ Error fetching task: $e');
  }

  // 3. For each task, fetch documentimagegroup by taskguid
  print('\n--- Analysis (Task -> ImageGroup -> GL) ---');
  for (final t in tasks) {
    final taskGuid = t['guidfixed'];
    print(
      '\n📌 Task | guid: $taskGuid | code: ${t['code']} | owner: ${t['ownerby']}',
    );

    // 3.1 Fetch Image Groups
    List<dynamic> groups = [];
    try {
      final req = await client.getUrl(
        Uri.parse('$baseUrl/documentimagegroup?taskguid=$taskGuid'),
      );
      for (final e in headers.entries) req.headers.set(e.key, e.value);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final j = jsonDecode(body);
      if (j['data'] is List) {
        groups = j['data'] as List;
        print('   📸 Found ${groups.length} document image groups');
      } else if (j['data'] is Map) {
        groups = [j['data']];
        print('   📸 Found 1 document image group');
      }
    } catch (e) {
      print('   ❌ Error fetching image group for task: $e');
    }

    // 3.2 For each image group, try to find matching GL Journal
    for (final g in groups) {
      final groupGuid = g['guidfixed'];
      print('      Group | guid: $groupGuid');

      // Let's test two potential ways to link:
      // Way A: Is groupGuid = journal.documentref?
      // Way B: Use a specific endpoint to fetch journal by docref

      try {
        final req = await client.getUrl(
          Uri.parse('$baseUrl/gl/journal?documentref=$groupGuid'),
        );
        for (final e in headers.entries) req.headers.set(e.key, e.value);
        final res = await req.close();
        final body = await res.transform(utf8.decoder).join();
        final j = jsonDecode(body);
        if (j['data'] is List && (j['data'] as List).isNotEmpty) {
          final journals = j['data'] as List;
          print(
            '      📖 GL Journals Found! (${journals.length} matches via ?documentref=$groupGuid)',
          );
          for (final jou in journals) {
            print(
              '         -> guid: ${jou['guidfixed']} | createdby: ${jou['createdby']} | no: ${jou['docno']}',
            );
          }
        } else {
          print('      ⚠️ No GL Journals found using ?documentref=$groupGuid');
        }
      } catch (e) {
        print('      ❌ Error finding journal: $e');
      }
    }
  }

  client.close();
}
