/// Runs [work] over [items], allowing at most [concurrency] invocations to be
/// in flight at the same time. Results are returned in the same order as
/// [items], regardless of completion order.
///
/// This is a middle ground between:
/// - a fully sequential `for` loop with `await` inside (safe but multiplies
///   latency by the number of items), and
/// - firing every request at once with `Future.wait` (fast, but can hammer
///   the backend with an unbounded number of simultaneous requests).
///
/// Useful for fetching per-shop/per-branch data where the underlying API
/// call is stateless (e.g. takes an explicit shopId param) and safe to run
/// concurrently. Do NOT use this for calls that depend on shared, mutable
/// server-side session state (e.g. an API that requires a separate
/// "select shop" call first) — running those concurrently can cause one
/// request to pick up another's context.
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) work,
) async {
  if (items.isEmpty) return <R>[];

  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final index = nextIndex;
      if (index >= items.length) return;
      nextIndex++;
      results[index] = await work(items[index]);
    }
  }

  final workerCount = concurrency < items.length ? concurrency : items.length;
  await Future.wait(List.generate(workerCount, (_) => worker()));
  return results.cast<R>();
}
