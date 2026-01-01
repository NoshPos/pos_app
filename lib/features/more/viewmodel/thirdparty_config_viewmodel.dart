import 'package:flutter/foundation.dart';

/// ViewModel for the Third-Party Configuration screen
class ThirdPartyConfigViewModel extends ChangeNotifier {
  String _selectedOutlet = 'All Outlets';

  ThirdPartyConfigViewModel();

  // Getters
  String get selectedOutlet => _selectedOutlet;

  /// List of available outlets
  List<String> get availableOutlets => [
    'All Outlets',
    'Aarthi cake Magic',
    'Ambattur Aarthi sweets and bakery',
  ];

  // Setters
  void setSelectedOutlet(String outlet) {
    if (_selectedOutlet != outlet) {
      _selectedOutlet = outlet;
      notifyListeners();
    }
  }
}
