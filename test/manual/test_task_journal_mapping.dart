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

  try {
    final req = await client.postUrl(Uri.parse('$baseUrl/select-shop'));
    for (final e in headers.entries) req.headers.set(e.key, e.value);
    req.write('{"shopid":"$testShopId"}');
    await req.close();

    // Fetch some tasks
    print('--- TASKS ---');
    final req1 = await client.getUrl(
      Uri.parse('$baseUrl/task?limit=5&status=0,1,2,3,4&page=1'),
    );
    for (final e in headers.entries) req1.headers.set(e.key, e.value);
    final res1 = await req1.close();
    final body1 = await res1.transform(utf8.decoder).join();
    final j1 = jsonDecode(body1);

    if (j1['data'] is List) {
      for (final t in j1['data']) {
        print(
          'Task: guid=${t['guidfixed']} code=${t['code']} name=${t['name']} owner=${t['ownerby']}',
        );
        if (t['taskchild'] != null) {
          print('  TaskChild: ${t['taskchild']}');
        }
      }
    }

    print('\n--- JOURNALS ---');
    final taskParam = Uri.encodeComponent('GL Journal');
    final req2 = await client.getUrl(
      Uri.parse('$baseUrl/gl/journal?limit=5&task=$taskParam'),
    );
    for (final e in headers.entries) req2.headers.set(e.key, e.value);
    final res2 = await req2.close();
    final body2 = await res2.transform(utf8.decoder).join();
    final j2 = jsonDecode(body2);

    if (j2['data'] is List) {
      for (final j in j2['data']) {
        print(
          'Journal: docno=${j['docno']} documentref=${j['documentref']} exdocrefno=${j['exdocrefno']} createdby=${j['createdby']}',
        );
      }
    }
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
