import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moniter/models/journal.dart';

void main() async {
  print('🔍 Testing API connection...');

  try {
    final url = Uri.parse(
      'http://localhost:3000/api/journals?page=1&limit=200',
    );
    print('📡 Calling: $url');

    final response = await http.get(url);
    print('📊 Status Code: ${response.statusCode}');
    print('📝 Response Headers: ${response.headers}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('✅ Raw Response: ${response.body}');

      // พยายาม parse เป็น JournalResponse
      final journalResponse = JournalResponse.fromJson(responseData);
      print('✅ Parsed successfully!');
      print('📦 Total journals: ${journalResponse.journals?.length ?? 0}');
      print('📋 Summary data: ${journalResponse.summary?.toJson()}');

      if (journalResponse.journals != null &&
          journalResponse.journals!.isNotEmpty) {
        print('📑 First journal sample:');
        final first = journalResponse.journals!.first;
        print('  - ID: ${first.id}');
        print('  - Branch Sync: ${first.branchSync}');
        print('  - Doc DateTime: ${first.docDatetime}');
        print('  - Doc No: ${first.docNo}');
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
    print('💡 Make sure API server is running on http://localhost:3000');
  }
}
