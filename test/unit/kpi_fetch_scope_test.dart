import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/blocs/kpi_combined/kpi_fetch_scope.dart';

void main() {
  test('KPI cache is isolated by account and stable across shop order', () {
    String key(String account, List<String> shops) => KpiFetchScope.cacheKey(
      account: account,
      shopIds: shops,
      startDate: '2026-08-01',
      endDate: '2026-08-31',
    );

    expect(key('first@example.com', ['b', 'a']), key('first@example.com', ['a', 'b']));
    expect(key('first@example.com', ['a']), isNot(key('second@example.com', ['a'])));
  });
}
