import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/services/multi_shop_service.dart';

void main() {
  test('shop-session leases serialize session-scoped work', () async {
    final firstRelease = await MultiShopService.acquireShopSession();
    var secondEntered = false;

    final second = MultiShopService.acquireShopSession().then((release) {
      secondEntered = true;
      release();
    });

    await Future<void>.delayed(Duration.zero);
    expect(secondEntered, isFalse);

    firstRelease();
    await second;
    expect(secondEntered, isTrue);
  });
}
