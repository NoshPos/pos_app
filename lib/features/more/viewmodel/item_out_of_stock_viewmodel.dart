import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_app/core/providers/store_provider.dart';
import 'package:pos_app/core/repositories/store_repository.dart';

part 'item_out_of_stock_viewmodel.g.dart';

/// State class for Item Out-Of-Stock Tracking
class ItemOutOfStockState {
  final String? selectedStoreId;
  final List<StoreModel> stores;
  final int selectedMainTabIndex; // 0 for Items, 1 for Addons
  final int selectedViewTabIndex; // 0 for Restaurant Wise, 1 for Item Wise
  final String? selectedRestaurantId;
  final String selectedCategory;
  final String itemName;
  final String selectedBrand;
  final String selectedOffDuration;
  final bool showRestaurantsWithAllItemsInStock;
  final bool isLoading;
  final String? error;

  const ItemOutOfStockState({
    this.selectedStoreId,
    this.stores = const [],
    this.selectedMainTabIndex = 0,
    this.selectedViewTabIndex = 0,
    this.selectedRestaurantId,
    this.selectedCategory = 'All',
    this.itemName = '',
    this.selectedBrand = 'All',
    this.selectedOffDuration = 'Select',
    this.showRestaurantsWithAllItemsInStock = false,
    this.isLoading = false,
    this.error,
  });

  List<String> get availableOutlets => [
    'All Outlets',
    ...stores.map((s) => s.name),
  ];

  String get selectedOutletName {
    if (selectedStoreId == null) return 'All Outlets';
    final store = stores.where((s) => s.id == selectedStoreId).firstOrNull;
    return store?.name ?? 'All Outlets';
  }

  String get selectedOutlet => selectedOutletName;

  /// Restaurants derived from stores
  List<String> get restaurants => ['All', ...stores.map((s) => s.name)];

  String get selectedRestaurant {
    if (selectedRestaurantId == null) return 'All';
    final store = stores.where((s) => s.id == selectedRestaurantId).firstOrNull;
    return store?.name ?? 'All';
  }

  /// Categories - will be fetched from real data in future
  List<String> get categories => const [
    'All',
    'Beverages',
    'Snacks',
    'Main Course',
    'Desserts',
  ];

  /// Brands - will be fetched from real data in future
  List<String> get brands => const ['All'];

  /// Off duration options
  List<String> get offDurationOptions => const [
    'Select',
    '30 minutes',
    '1 hour',
    '2 hours',
    '4 hours',
    '8 hours',
    '24 hours',
  ];

  ItemOutOfStockState copyWith({
    String? selectedStoreId,
    List<StoreModel>? stores,
    int? selectedMainTabIndex,
    int? selectedViewTabIndex,
    String? selectedRestaurantId,
    String? selectedCategory,
    String? itemName,
    String? selectedBrand,
    String? selectedOffDuration,
    bool? showRestaurantsWithAllItemsInStock,
    bool? isLoading,
    String? error,
  }) {
    return ItemOutOfStockState(
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      stores: stores ?? this.stores,
      selectedMainTabIndex: selectedMainTabIndex ?? this.selectedMainTabIndex,
      selectedViewTabIndex: selectedViewTabIndex ?? this.selectedViewTabIndex,
      selectedRestaurantId: selectedRestaurantId ?? this.selectedRestaurantId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      itemName: itemName ?? this.itemName,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      selectedOffDuration: selectedOffDuration ?? this.selectedOffDuration,
      showRestaurantsWithAllItemsInStock:
          showRestaurantsWithAllItemsInStock ??
          this.showRestaurantsWithAllItemsInStock,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for the Item Out-Of-Stock Tracking screen
@riverpod
class ItemOutOfStockViewModel extends _$ItemOutOfStockViewModel {
  @override
  ItemOutOfStockState build() {
    // Watch global store provider for store list and selection
    final storeState = ref.watch(globalStoreNotifierProvider);

    return ItemOutOfStockState(
      stores: storeState.stores,
      selectedStoreId: storeState.selectedStoreId,
    );
  }

  void setSelectedOutlet(String outletName) {
    ref
        .read(globalStoreNotifierProvider.notifier)
        .setSelectedOutlet(outletName);
  }

  void setSelectedMainTabIndex(int index) {
    state = state.copyWith(selectedMainTabIndex: index);
  }

  void setSelectedViewTabIndex(int index) {
    state = state.copyWith(selectedViewTabIndex: index);
  }

  void setSelectedRestaurant(String restaurant) {
    if (restaurant == 'All') {
      state = state.copyWith(selectedRestaurantId: null);
    } else {
      final store = state.stores.where((s) => s.name == restaurant).firstOrNull;
      state = state.copyWith(selectedRestaurantId: store?.id);
    }
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setItemName(String name) {
    state = state.copyWith(itemName: name);
  }

  void setSelectedBrand(String brand) {
    state = state.copyWith(selectedBrand: brand);
  }

  void setSelectedOffDuration(String duration) {
    state = state.copyWith(selectedOffDuration: duration);
  }

  void toggleShowRestaurantsWithAllItemsInStock() {
    state = state.copyWith(
      showRestaurantsWithAllItemsInStock:
          !state.showRestaurantsWithAllItemsInStock,
    );
  }

  void resetFilters() {
    state = state.copyWith(
      selectedRestaurantId: null,
      selectedCategory: 'All',
      itemName: '',
      selectedBrand: 'All',
      selectedOffDuration: 'Select',
      showRestaurantsWithAllItemsInStock: false,
    );
  }

  Future<void> search() async {
    state = state.copyWith(isLoading: true, error: null);
    // TODO: Implement actual search API call via repository
    state = state.copyWith(isLoading: false);
  }

  Future<void> exportData() async {
    // TODO: Implement export functionality via repository
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    // Refresh stores from global provider
    await ref.read(globalStoreNotifierProvider.notifier).refreshStores();
    state = state.copyWith(isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
