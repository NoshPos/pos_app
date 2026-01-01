/// Model class for restaurant sales data
class RestaurantSalesData {
  final String restaurantName;
  final String invoiceNumbers;
  final int totalBills;

  const RestaurantSalesData({
    required this.restaurantName,
    required this.invoiceNumbers,
    required this.totalBills,
  });
}

/// Summary statistics for sales report
class SalesReportSummary {
  final int total;
  final int min;
  final int max;
  final int avg;

  const SalesReportSummary({
    required this.total,
    required this.min,
    required this.max,
    required this.avg,
  });
}

/// Order status options
enum OrderStatus {
  success('Success'),
  cancelled('Cancelled'),
  complimentary('Complimentary'),
  salesReturn('Sales Return'),
  all('All');

  final String displayName;
  const OrderStatus(this.displayName);
}

/// Restaurant filter model
class RestaurantFilter {
  final String id;
  final String name;
  final bool isSelected;

  const RestaurantFilter({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  RestaurantFilter copyWith({String? id, String? name, bool? isSelected}) {
    return RestaurantFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  static List<RestaurantFilter> getDefaultRestaurants() {
    return [
      const RestaurantFilter(id: 'aarthi_cake', name: 'Aarthi cake Magic'),
      const RestaurantFilter(
        id: 'ambattur_aarthi',
        name: 'Ambattur Aarthi sweets and bakery',
      ),
    ];
  }
}
