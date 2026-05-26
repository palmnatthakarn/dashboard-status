import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/blocs/kpi_journal/kpi_journal_bloc.dart';
import 'package:moniter/blocs/kpi_journal/kpi_journal_event.dart';
import 'package:moniter/blocs/kpi_journal/kpi_journal_state.dart';
import 'package:moniter/models/journal.dart';
import 'package:moniter/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GlCall {
  final String? shopId;
  final String? startDate;
  final String? endDate;

  const _GlCall({this.shopId, this.startDate, this.endDate});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KpiJournalBloc KJ-401 fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'retries without shopids and keeps journals that match selected branch name',
      () async {
        final glCalls = <_GlCall>[];

        final bloc = KpiJournalBloc(
          isAuthenticated: () => true,
          listShops: () async => [
            {
              'shopid': 'legacy-shop-id',
              'names': [
                {'name': 'สาขาทดสอบ'},
              ],
            },
          ],
          selectShop: ({String? shopId}) async => true,
          fetchDocumentImageGroups: ({
            int page = 1,
            int perPage = 9999,
            String? fromDate,
            String? toDate,
            int ref = 1,
            String? shopId,
          }) async =>
              {},
          fetchTasksForShop: ({
            required String shopId,
            int limit = 10,
            List<int> status = const [0, 1, 2, 3, 4, 5, 6],
            int page = 1,
          }) async =>
              TaskResponse(success: true, tasks: const []),
          fetchGLJournals: ({
            int page = 1,
            int limit = 1000,
            String? shopId,
            String? task,
            String sort = 'docdate:-1',
            String timezone = '+07',
            String? startDate,
            String? endDate,
          }) async {
            glCalls.add(
              _GlCall(shopId: shopId, startDate: startDate, endDate: endDate),
            );

            if (shopId == null) {
              return JournalResponse(
                success: true,
                journals: [
                  Journal(
                    id: 401,
                    branchSync: 'api-branch-sync',
                    branchName: 'สาขาทดสอบ',
                    docNo: 'GL-KJ-401',
                    docDatetime: '2026-05-20T10:00:00+07:00',
                    bookCode: 'JV',
                    debit: 100,
                    credit: 0,
                    createdBy: 'keyer@example.com',
                    checkedBy: 'reviewer@example.com',
                    updatedBy: 'updater@example.com',
                    jobGuidfixed: 'task-kj-401',
                  ),
                ],
                pagination: Pagination(total: 1, totalPages: 1),
              );
            }

            return JournalResponse(
              success: true,
              journals: const [],
              pagination: Pagination(total: 0, totalPages: 1),
            );
          },
        );
        addTearDown(bloc.close);

        final initialLoaded = bloc.stream
            .where((state) => state is KpiJournalLoaded)
            .cast<KpiJournalLoaded>()
            .first;
        bloc.add(LoadKpiJournalData());
        await initialLoaded;

        final searchLoaded = bloc.stream
            .where(
              (state) =>
                  state is KpiJournalLoaded &&
                  !state.isSearching &&
                  state.selectedShopId == 'legacy-shop-id',
            )
            .cast<KpiJournalLoaded>()
            .first;
        bloc.add(
          SelectShopAndSearchJournal(
            shopId: 'legacy-shop-id',
            shopName: 'สาขาทดสอบ',
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 5, 20),
          ),
        );

        final loaded = await searchLoaded;

        final keyer = loaded.employees.firstWhere(
          (employee) => employee.name == 'keyer@example.com',
        );

        expect(loaded.totalJournals, 1);
        expect(keyer.shopStats.single.shopName, 'สาขาทดสอบ');
        expect(
          keyer.details.single.docNo,
          'GL-KJ-401',
        );
        expect(
          glCalls
              .where(
                (call) =>
                    call.shopId == 'legacy-shop-id' &&
                    call.startDate == '2026-05-01' &&
                    call.endDate == '2026-05-20',
              )
              .length,
          greaterThanOrEqualTo(1),
        );
        expect(
          glCalls
              .where(
                (call) =>
                    call.shopId == null &&
                    call.startDate == '2026-05-01' &&
                    call.endDate == '2026-05-20',
              )
              .length,
          greaterThanOrEqualTo(1),
        );
      },
    );
  });
}
