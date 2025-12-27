import 'package:flutter/foundation.dart';

/// ViewModel for the Item Out-Of-Stock Tracking screen
class ItemOutOfStockViewModel extends ChangeNotifier {
  String _selectedOutlet = 'All Outlets';
  int _selectedMainTabIndex = 0; // 0 for Items, 1 for Addons
  int _selectedViewTabIndex = 0; // 0 for Restaurant Wise, 1 for Item Wise

  // Filter state
  String _selectedRestaurant = 'All';
  String _selectedCategory = 'All';
  String _itemName = '';
  String _selectedBrand = 'All';
  String _selectedOffDuration = 'Select';
  bool _showRestaurantsWithAllItemsInStock = false;

  // Getters
  String get selectedOutlet => _selectedOutlet;
  int get selectedMainTabIndex => _selectedMainTabIndex;
  int get selectedViewTabIndex => _selectedViewTabIndex;
  String get selectedRestaurant => _selectedRestaurant;
  String get selectedCategory => _selectedCategory;
  String get itemName => _itemName;
  String get selectedBrand => _selectedBrand;
  String get selectedOffDuration => _selectedOffDuration;
  bool get showRestaurantsWithAllItemsInStock =>
      _showRestaurantsWithAllItemsInStock;

  /// List of available outlets
  List<String> get availableOutlets => [
    'All Outlets',
    'Aarthi cake Magic',
    'Ambattur Aarthi sweets and bakery',
  ];

  /// List of available restaurants
  List<String> get restaurants => [
    'All',
    'Aarthi cake Magic',
    'Ambattur Aarthi sweets and bakery',
  ];

  /// List of available categories
  List<String> get categories => [
    'All',
    'Beverages',
    'Snacks',
    'Main Course',
    'Desserts',
  ];

  /// List of available brands
  List<String> get brands => ['All', 'Brand A', 'Brand B', 'Brand C'];

  /// List of offline duration options
  List<String> get offDurationOptions => [
    'Select',
    '30 minutes',
    '1 hour',
    '2 hours',
    '4 hours',
    '8 hours',
    '24 hours',
  ];

  // Setters
  void setSelectedOutlet(String outlet) {
    _selectedOutlet = outlet;
    notifyListeners();
  }

  void setSelectedMainTabIndex(int index) {
    _selectedMainTabIndex = index;
    notifyListeners();
  }

  void setSelectedViewTabIndex(int index) {
    _selectedViewTabIndex = index;
    notifyListeners();
  }

  void setSelectedRestaurant(String restaurant) {
    _selectedRestaurant = restaurant;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setItemName(String name) {
    _itemName = name;
    notifyListeners();
  }

  void setSelectedBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void setSelectedOffDuration(String duration) {
    _selectedOffDuration = duration;
    notifyListeners();
  }

  void toggleShowRestaurantsWithAllItemsInStock() {
    _showRestaurantsWithAllItemsInStock = !_showRestaurantsWithAllItemsInStock;
    notifyListeners();
  }

  /// Reset all filters
  void resetFilters() {
    _selectedRestaurant = 'All';
    _selectedCategory = 'All';
    _itemName = '';
    _selectedBrand = 'All';
    _selectedOffDuration = 'Select';
    _showRestaurantsWithAllItemsInStock = false;
    notifyListeners();
  }

  /// Search with current filters
  void search() {
    // TODO: Implement actual search API call
    notifyListeners();
  }

  /// Export data
  void exportData() {
    // TODO: Implement export functionality
  }

  /// Refresh data
  void refresh() {
    // TODO: Implement refresh API call
    notifyListeners();
  }
}
