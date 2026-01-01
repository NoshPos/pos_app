import 'package:flutter/foundation.dart';
import '../model/sales_report_model.dart';

/// ViewModel for the Sales Report Detail screen
class SalesReportViewModel extends ChangeNotifier {
  String _selectedOutlet = 'All Outlets';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  OrderStatus _selectedOrderStatus = OrderStatus.success;
  List<RestaurantFilter> _restaurants = [];
  List<RestaurantSalesData> _salesData = [];
  SalesReportSummary? _summary;
  bool _isLoading = false;

  SalesReportViewModel() {
    _restaurants = RestaurantFilter.getDefaultRestaurants();
    _loadSampleData();
  }

  // Getters
  String get selectedOutlet => _selectedOutlet;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  OrderStatus get selectedOrderStatus => _selectedOrderStatus;
  List<RestaurantFilter> get restaurants => _restaurants;
  List<RestaurantSalesData> get salesData => _salesData;
  SalesReportSummary? get summary => _summary;
  bool get isLoading => _isLoading;

  /// List of available outlets
  List<String> get availableOutlets => [
    'All Outlets',
    'Aarthi cake Magic',
    'Ambattur Aarthi sweets and bakery',
  ];

  /// Get selected restaurant names
  String get selectedRestaurantsText {
    final selected = _restaurants.where((r) => r.isSelected).toList();
    if (selected.isEmpty) {
      return 'Choose Restaurant';
    } else if (selected.length == 1) {
      return selected.first.name;
    } else {
      return '${selected.length} restaurants selected';
    }
  }

  // Setters
  void setSelectedOutlet(String outlet) {
    if (_selectedOutlet != outlet) {
      _selectedOutlet = outlet;
      notifyListeners();
    }
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setOrderStatus(OrderStatus status) {
    _selectedOrderStatus = status;
    notifyListeners();
  }

  void toggleRestaurant(String restaurantId) {
    final index = _restaurants.indexWhere((r) => r.id == restaurantId);
    if (index != -1) {
      _restaurants[index] = _restaurants[index].copyWith(
        isSelected: !_restaurants[index].isSelected,
      );
      notifyListeners();
    }
  }

  Future<void> search() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    _loadSampleData();
    _isLoading = false;
    notifyListeners();
  }

  void _loadSampleData() {
    _salesData = [
      const RestaurantSalesData(
        restaurantName: 'Aarthi cake Magic',
        invoiceNumbers: '211-212',
        totalBills: 2,
      ),
      const RestaurantSalesData(
        restaurantName: 'Ambattur Aarthi sweets and bakery',
        invoiceNumbers: '6435-6518',
        totalBills: 84,
      ),
    ];

    _summary = const SalesReportSummary(total: 86, min: 2, max: 84, avg: 43);
  }

  void exportToExcel() {
    // TODO: Implement Excel export
    debugPrint('Exporting to Excel...');
  }

  void printReport() {
    // TODO: Implement print functionality
    debugPrint('Printing report...');
  }
}
