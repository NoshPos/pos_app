/// Model representing the dashboard statistics data
class DashboardStatsModel {
  final String totalSales;
  final int totalOutlets;
  final int totalOrders;
  final String onlineSales;
  final String onlineSalesPercent;
  final String cashCollected;
  final String cashCollectedPercent;
  final String netSales;
  final int netSalesOutlets;
  final String expenses;
  final String taxes;
  final String discounts;
  final String discountsPercent;

  const DashboardStatsModel({
    required this.totalSales,
    required this.totalOutlets,
    required this.totalOrders,
    required this.onlineSales,
    required this.onlineSalesPercent,
    required this.cashCollected,
    required this.cashCollectedPercent,
    required this.netSales,
    required this.netSalesOutlets,
    required this.expenses,
    required this.taxes,
    required this.discounts,
    required this.discountsPercent,
  });

  /// Empty/default stats
  static const DashboardStatsModel empty = DashboardStatsModel(
    totalSales: '0.00',
    totalOutlets: 0,
    totalOrders: 0,
    onlineSales: '0.00',
    onlineSalesPercent: '0%',
    cashCollected: '0.00',
    cashCollectedPercent: '0%',
    netSales: '0.00',
    netSalesOutlets: 0,
    expenses: '0.00',
    taxes: '0.00',
    discounts: '0.00',
    discountsPercent: '0%',
  );
}
