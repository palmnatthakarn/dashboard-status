class KpiFetchScope {
  const KpiFetchScope._();

  static String cacheKey({
    required String account,
    required Iterable<String> shopIds,
    required String startDate,
    required String endDate,
  }) {
    final ids = shopIds.toList()..sort();
    return '${account.trim().toLowerCase()}|${ids.join(',')}|$startDate|$endDate';
  }
}
