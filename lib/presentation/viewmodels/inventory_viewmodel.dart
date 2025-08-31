// presentation/viewmodels/inventory_viewmodel.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_item.dart';
import '../blocs/inventory/inventory_bloc.dart';

class InventoryViewModel extends ChangeNotifier {
  final InventoryBloc inventoryBloc;

  InventoryViewModel({required this.inventoryBloc});

  // Getters for current state
  List<InventoryItem> get inventoryItems {
    final state = inventoryBloc.state;
    if (state is InventoryLoaded) {
      return state.displayItems;
    }
    return [];
  }

  bool get isLoading => inventoryBloc.state is InventoryLoading;

  String? get errorMessage {
    final state = inventoryBloc.state;
    if (state is InventoryError) {
      return state.message;
    }
    return null;
  }

  bool get hasError => inventoryBloc.state is InventoryError;

  int get totalItems {
    final state = inventoryBloc.state;
    if (state is InventoryLoaded) {
      return state.totalItems;
    }
    return 0;
  }

  int get lowStockCount {
    final state = inventoryBloc.state;
    if (state is InventoryLoaded) {
      return state.lowStockCount;
    }
    return 0;
  }

  double get totalValue {
    final state = inventoryBloc.state;
    if (state is InventoryLoaded) {
      return state.totalValue;
    }
    return 0.0;
  }

  // UI helper methods
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String getStockStatusText(InventoryItem item) {
    if (item.stockQuantity == 0) {
      return 'Out of Stock';
    } else if (item.isLowStock) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  Color getStockStatusColor(InventoryItem item) {
    if (item.stockQuantity == 0) {
      return Color(0xFFE57373); // Light red
    } else if (item.isLowStock) {
      return Color(0xFFFFB74D); // Light orange
    } else {
      return Color(0xFF81C784); // Light green
    }
  }

  String getItemDescription(InventoryItem item) {
    final buffer = StringBuffer();
    buffer.write(item.nameEn);

    if (item.nameAr.isNotEmpty) {
      buffer.write(' (${item.nameAr})');
    }

    buffer.write(' - SKU: ${item.sku}');
    return buffer.toString();
  }

  bool shouldShowLowStockWarning(InventoryItem item) {
    return item.stockQuantity <= (item.minStockLevel * 1.5);
  }

  String getItemSummary(InventoryItem item) {
    return '${item.stockQuantity} units @ ${formatCurrency(item.unitPrice)} each';
  }

  List<InventoryItem> get criticalStockItems {
    return inventoryItems.where((item) => item.stockQuantity == 0).toList();
  }

  List<InventoryItem> get lowStockItems {
    return inventoryItems.where((item) => item.isLowStock && item.stockQuantity > 0).toList();
  }

  // Business logic methods
  void loadInventory() {
    inventoryBloc.add(LoadInventoryItems());
  }

  void refreshInventory() {
    inventoryBloc.add(RefreshInventoryItems());
  }

  void createItem(InventoryItem item) {
    inventoryBloc.add(CreateInventoryItem(item));
  }

  void updateItem(InventoryItem item) {
    inventoryBloc.add(UpdateInventoryItem(item));
  }

  void deleteItem(String itemId) {
    inventoryBloc.add(DeleteInventoryItem(itemId));
  }

  void searchItems(String query) {
    inventoryBloc.add(SearchInventoryItems(query));
  }

  void filterItems(Map<String, dynamic> filters) {
    inventoryBloc.add(FilterInventoryItems(filters));
  }

  void clearFilters() {
    inventoryBloc.add(ClearFilters());
  }

  // Validation methods
  bool validateSku(String sku) {
    if (sku.trim().isEmpty) return false;

    // Check if SKU already exists
    final existingItem = inventoryItems.firstWhere(
          (item) => item.sku.toLowerCase() == sku.toLowerCase(),
      orElse: () => InventoryItem(
        id: '',
        sku: '',
        nameEn: '',
        nameAr: '',
        categoryId: '',
        subcategory: '',
        stockQuantity: 0,
        unitPrice: 0.0,
        minStockLevel: 0,
        dimensions: ProductDimensions(width: 0, height: 0, depth: 0, unit: 'cm'),
        imageProperties: ImageProperties(pixelWidth: 0, pixelHeight: 0, dpi: 0, colorSpace: 'RGB'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return existingItem.id.isEmpty;
  }

  bool validatePrice(String price) {
    final parsedPrice = double.tryParse(price);
    return parsedPrice != null && parsedPrice > 0;
  }

  bool validateStock(String stock) {
    final parsedStock = int.tryParse(stock);
    return parsedStock != null && parsedStock >= 0;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
