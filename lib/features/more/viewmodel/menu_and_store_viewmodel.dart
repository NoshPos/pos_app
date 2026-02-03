import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_app/core/providers/store_provider.dart';
import 'package:pos_app/core/repositories/store_repository.dart';

part 'menu_and_store_viewmodel.g.dart';

/// State class for Menu and Store Actions
class MenuAndStoreState {
  final String? selectedStoreId;
  final List<StoreModel> stores;
  final bool isLoading;
  final String? error;

  const MenuAndStoreState({
    this.selectedStoreId,
    this.stores = const [],
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

  MenuAndStoreState copyWith({
    String? selectedStoreId,
    List<StoreModel>? stores,
    bool? isLoading,
    String? error,
  }) {
    return MenuAndStoreState(
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      stores: stores ?? this.stores,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for Menu and Store page
@riverpod
class MenuAndStoreViewModel extends _$MenuAndStoreViewModel {
  @override
  MenuAndStoreState build() {
    // Watch global store provider for store list and selection
    final storeState = ref.watch(globalStoreNotifierProvider);

    return MenuAndStoreState(
      stores: storeState.stores,
      selectedStoreId: storeState.selectedStoreId,
    );
  }

  void setSelectedOutlet(String outletName) {
    ref
        .read(globalStoreNotifierProvider.notifier)
        .setSelectedOutlet(outletName);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
