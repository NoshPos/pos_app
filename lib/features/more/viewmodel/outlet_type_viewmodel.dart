import 'package:flutter/foundation.dart';

/// Model class representing an outlet/restaurant
class OutletModel {
  final String id;
  final String name;
  final String state;
  final String city;
  final String outletType;

  const OutletModel({
    required this.id,
    required this.name,
    required this.state,
    required this.city,
    required this.outletType,
  });
}

/// ViewModel for the Outlet Type screen
class OutletTypeViewModel extends ChangeNotifier {
  String _selectedOutlet = 'All Outlets';
  List<OutletModel> _outlets = [];
  final Map<String, String> _selectedOutletTypes = {};

  OutletTypeViewModel() {
    _loadOutlets();
  }

  // Getters
  String get selectedOutlet => _selectedOutlet;
  List<OutletModel> get outlets => _outlets;
  Map<String, String> get selectedOutletTypes => _selectedOutletTypes;

  /// List of available outlets for picker
  List<String> get availableOutlets => [
    'All Outlets',
    'Aarthi cake Magic',
    'Ambattur Aarthi sweets and bakery',
  ];

  /// List of available outlet types
  List<String> get outletTypes => [
    'COFO - Company Owned Franchisee',
    'FOFO - Franchisee Owned Franchisee',
    'COCO - Company Owned Company Operated',
    'FOCO - Franchisee Owned Company Operated',
  ];

  /// Load outlets data
  void _loadOutlets() {
    _outlets = [
      const OutletModel(
        id: '363317',
        name: 'Aarthi cake Magic',
        state: 'Tamil Nadu',
        city: 'Chennai',
        outletType: 'COFO - Company Owned Franchisee',
      ),
      const OutletModel(
        id: '383514',
        name: 'Ambattur Aarthi sweets and bakery',
        state: 'Tamil Nadu',
        city: 'Chennai',
        outletType: 'COFO - Company Owned Franchisee',
      ),
    ];

    // Initialize selected outlet types
    for (final outlet in _outlets) {
      _selectedOutletTypes[outlet.id] = outlet.outletType;
    }
    notifyListeners();
  }

  // Setters
  void setSelectedOutlet(String outlet) {
    _selectedOutlet = outlet;
    notifyListeners();
  }

  /// Update outlet type for a specific outlet
  void setOutletType(String outletId, String outletType) {
    _selectedOutletTypes[outletId] = outletType;
    notifyListeners();
  }

  /// Get the selected outlet type for an outlet
  String getSelectedOutletType(String outletId) {
    return _selectedOutletTypes[outletId] ?? outletTypes.first;
  }

  /// Save changes
  void save() {
    // TODO: Implement save API call
    notifyListeners();
  }

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges {
    for (final outlet in _outlets) {
      if (_selectedOutletTypes[outlet.id] != outlet.outletType) {
        return true;
      }
    }
    return false;
  }
}
