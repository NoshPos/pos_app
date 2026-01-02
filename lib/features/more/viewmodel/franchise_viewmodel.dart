import 'package:flutter/material.dart';
import '../model/franchise_model.dart';

class FranchiseViewModel extends ChangeNotifier {
  String _selectedOutlet = 'All Outlets';
  final List<String> _availableOutlets = [
    'All Outlets',
    'Outlet 1',
    'Outlet 2',
  ];

  String _nameFilter = '';
  String _refIdFilter = '';

  List<FranchiseOutlet> _franchises = [];
  List<FranchiseOutlet> _filteredFranchises = [];

  FranchiseViewModel() {
    _initializeData();
  }

  String get selectedOutlet => _selectedOutlet;
  List<String> get availableOutlets => _availableOutlets;
  String get nameFilter => _nameFilter;
  String get refIdFilter => _refIdFilter;
  List<FranchiseOutlet> get filteredFranchises => _filteredFranchises;

  void setSelectedOutlet(String outlet) {
    _selectedOutlet = outlet;
    notifyListeners();
  }

  void setNameFilter(String value) {
    _nameFilter = value;
  }

  void setRefIdFilter(String value) {
    _refIdFilter = value;
  }

  void search() {
    _filteredFranchises = _franchises.where((franchise) {
      final matchesName =
          _nameFilter.isEmpty ||
          franchise.name.toLowerCase().contains(_nameFilter.toLowerCase());
      final matchesRefId =
          _refIdFilter.isEmpty ||
          franchise.refId.toLowerCase().contains(_refIdFilter.toLowerCase());
      return matchesName && matchesRefId;
    }).toList();
    notifyListeners();
  }

  void showAll() {
    _nameFilter = '';
    _refIdFilter = '';
    _filteredFranchises = List.from(_franchises);
    notifyListeners();
  }

  void toggleLock(String id) {
    final index = _franchises.indexWhere((f) => f.id == id);
    if (index != -1) {
      _franchises[index] = FranchiseOutlet(
        id: _franchises[index].id,
        name: _franchises[index].name,
        refId: _franchises[index].refId,
        isLocked: !_franchises[index].isLocked,
      );
      search();
    }
  }

  void _initializeData() {
    _franchises = [
      FranchiseOutlet(id: '1', name: 'Aarthi cake Magic', refId: '363317'),
      FranchiseOutlet(
        id: '2',
        name: 'Ambattur Aarthi sweets and bakery',
        refId: '383514',
      ),
    ];
    _filteredFranchises = List.from(_franchises);
  }
}
