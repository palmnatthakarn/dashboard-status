abstract class DashboardEvent {}

class FetchDashboardData extends DashboardEvent {}

class FetchShopDaily extends DashboardEvent {
  final String shopId;
  FetchShopDaily(this.shopId);
}

class UpdateSearchQuery extends DashboardEvent {
  final String query;
  UpdateSearchQuery(this.query);
}

class UpdateFilter extends DashboardEvent {
  final String filter;
  UpdateFilter(this.filter);
}

class UpdateSelectedDate extends DashboardEvent {
  final DateTime? date;
  UpdateSelectedDate(this.date);
}
