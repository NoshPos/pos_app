/// Model representing statistics for a single outlet
class OutletStatsModel {
  final String outletName;
  final bool isTotal;
  final int orders;
  final double sales;
  final double netSales;
  final double tax;
  final double discounts;
  final int modified;
  final int reprint;

  const OutletStatsModel({
    required this.outletName,
    this.isTotal = false,
    required this.orders,
    required this.sales,
    required this.netSales,
    required this.tax,
    required this.discounts,
    required this.modified,
    required this.reprint,
  });
}
