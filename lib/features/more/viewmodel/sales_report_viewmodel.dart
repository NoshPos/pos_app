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
  List<ColumnOption> _columns = [];

  SalesReportViewModel() {
    _restaurants = RestaurantFilter.getDefaultRestaurants();
    _columns = ColumnOption.getDefaultColumns();
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
  List<ColumnOption> get columns => _columns;

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

  void toggleColumn(String columnId) {
    final index = _columns.indexWhere((c) => c.id == columnId);
    if (index != -1) {
      _columns[index] = _columns[index].copyWith(
        isVisible: !_columns[index].isVisible,
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
        myAmount: 11456.11,
        totalDiscount: 0,
        netSales: 11456.11,
        deliveryCharge: 0,
        containerCharge: 0,
        serviceCharge: 0,
        additionalCharge: 0,
        totalTax: 572.82,
        roundOff: 0.07,
        waivedOff: 0,
        totalSales: 12029,
        onlineTaxCalculated: 0,
        gstPaidByMerchant: 0,
        gstPaidByEcommerce: 0,
        cash: 12029,
        card: 0,
        duePayment: 0,
        other: 0,
        wallet: 0,
        online: 0,
        pax: 0,
        dataSynced: '2026-01-02 17:28:24',
      ),
      const RestaurantSalesData(
        restaurantName: 'Ambattur Aarthi sweets and bakery',
        invoiceNumbers: '6435-6518',
        totalBills: 84,
        myAmount: 11456.11,
        totalDiscount: 0,
        netSales: 11456.11,
        deliveryCharge: 0,
        containerCharge: 0,
        serviceCharge: 0,
        additionalCharge: 0,
        totalTax: 572.82,
        roundOff: 0.07,
        waivedOff: 0,
        totalSales: 12029,
        onlineTaxCalculated: 0,
        gstPaidByMerchant: 0,
        gstPaidByEcommerce: 0,
        cash: 12029,
        card: 0,
        duePayment: 0,
        other: 0,
        wallet: 0,
        online: 0,
        pax: 0,
        dataSynced: '2026-01-02 17:28:24',
      ),
    ];

    _summary = const SalesReportSummary(
      total: 86,
      min: 2,
      max: 84,
      avg: 43,
      myAmount: 11456.11,
      totalDiscount: 0.00,
      netSales: 11456.11,
      deliveryCharge: 0.00,
      containerCharge: 0.00,
      serviceCharge: 0.00,
      additionalCharge: 0.00,
      totalTax: 572.82,
      roundOff: 0.07,
      waivedOff: 0.00,
      totalSales: 12029.00,
      onlineTaxCalculated: 0.00,
      gstPaidByMerchant: 0.00,
      gstPaidByEcommerce: 0.00,
      cash: 12029.00,
      card: 0.00,
      duePayment: 0.00,
      other: 0.00,
      wallet: 0.00,
      online: 0.00,
      pax: 0,
    );
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
