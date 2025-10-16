// ✅ injection_container.dart (ADD STOCK MANAGEMENT SERVICE)
import 'package:get_it/get_it.dart';
import 'package:inventory_system/presentation/blocs/category/category_bloc.dart';
import 'package:inventory_system/presentation/blocs/order/order_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/network/network_info.dart';

// Data Sources
import 'data/datasources/category_remote_datasource.dart';
import 'data/datasources/inventory_local_datasource.dart';
import 'data/datasources/inventory_remote_datasource.dart';
import 'data/datasources/order_remote_datasource.dart';

// Repositories
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/inventory_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';

// Services
import 'data/services/barcode_service.dart';
import 'data/services/import_export_service.dart';
import 'data/services/stock_management_service.dart'; // ✅ NEW

// Domain
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/repositories/order_repository.dart';

// Use cases with aliases
import 'domain/usecases/approve_order.dart' as approve_order_usecase;
import 'domain/usecases/create_category.dart' as create_category_usecase;
import 'domain/usecases/create_order.dart' as create_order_usecase;
import 'domain/usecases/delete_order.dart' as delete_order_usecase;
import 'domain/usecases/filter_orders.dart' as filter_orders_usecase;
import 'domain/usecases/get_categories.dart' as get_categories_usecase;
import 'domain/usecases/get_inventory_items.dart' as get_items_usecase;
import 'domain/usecases/create_inventory_item.dart' as create_item_usecase;
import 'domain/usecases/get_orders.dart' as get_orders_usecase;
import 'domain/usecases/reject_order.dart' as reject_order_usecase;
import 'domain/usecases/search_orders.dart' as search_orders_usecase;
import 'domain/usecases/update_inventory_item.dart' as update_item_usecase;
import 'domain/usecases/delete_inventory_item.dart' as delete_item_usecase;
import 'domain/usecases/search_inventory_items.dart' as search_items_usecase;
import 'domain/usecases/filter_inventory_items.dart' as filter_items_usecase;
import 'domain/usecases/update_order.dart' as update_order_usecase;

// Blocs
import 'presentation/blocs/inventory/inventory_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  //! ========== EXTERNAL DEPENDENCIES ==========
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  getIt.registerLazySingleton(() => Supabase.instance.client);
  getIt.registerLazySingleton(() => Connectivity());

  //! ========== CORE ==========
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));

  //! ========== DATA SOURCES ==========
  getIt.registerLazySingleton<InventoryLocalDataSource>(
        () => InventoryLocalDataSourceImpl(sharedPreferences: getIt()),
  );

  getIt.registerLazySingleton<InventoryRemoteDataSource>(
        () => InventoryRemoteDataSourceImpl(supabase: getIt()),
  );

  getIt.registerLazySingleton<CategoryRemoteDataSource>(
        () => CategoryRemoteDataSourceImpl(supabase: getIt()),
  );

  getIt.registerLazySingleton<OrderRemoteDataSource>(
        () => OrderRemoteDataSourceImpl(supabase: getIt()),
  );

  //! ========== REPOSITORIES ==========
  getIt.registerLazySingleton<CategoryRepository>(
        () => CategoryRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton<InventoryRepository>(
        () => InventoryRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  //! ========== SERVICES ==========
  // ✅ NEW: Register StockManagementService BEFORE OrderRepository
  getIt.registerLazySingleton<StockManagementService>(
        () => StockManagementService(inventoryRepository: getIt()),
  );

  // ✅ UPDATED: OrderRepository now depends on StockManagementService
  getIt.registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(
      remoteDataSource: getIt(),
      networkInfo: getIt(),
      stockManagementService: getIt(), // ✅ NEW dependency
    ),
  );

  //! ========== USE CASES ==========

  // Category use cases
  getIt.registerLazySingleton(() => get_categories_usecase.GetCategories(getIt()));
  getIt.registerLazySingleton(() => create_category_usecase.CreateCategory(getIt()));

  // Inventory use cases
  getIt.registerLazySingleton(() => get_items_usecase.GetInventoryItems(getIt()));
  getIt.registerLazySingleton(() => create_item_usecase.CreateInventoryItem(getIt()));
  getIt.registerLazySingleton(() => update_item_usecase.UpdateInventoryItem(getIt()));
  getIt.registerLazySingleton(() => delete_item_usecase.DeleteInventoryItem(getIt()));
  getIt.registerLazySingleton(() => search_items_usecase.SearchInventoryItems(getIt()));
  getIt.registerLazySingleton(() => filter_items_usecase.FilterInventoryItems(getIt()));

  // Order use cases
  getIt.registerLazySingleton(() => get_orders_usecase.GetOrders(getIt()));
  getIt.registerLazySingleton(() => create_order_usecase.CreateOrder(getIt()));
  getIt.registerLazySingleton(() => update_order_usecase.UpdateOrder(getIt()));
  getIt.registerLazySingleton(() => delete_order_usecase.DeleteOrder(getIt()));
  getIt.registerLazySingleton(() => approve_order_usecase.ApproveOrder(getIt()));
  getIt.registerLazySingleton(() => reject_order_usecase.RejectOrder(getIt()));
  getIt.registerLazySingleton(() => search_orders_usecase.SearchOrders(getIt()));
  getIt.registerLazySingleton(() => filter_orders_usecase.FilterOrders(getIt()));

  //! ========== OTHER SERVICES ==========
  getIt.registerLazySingleton<ImportExportService>(
        () => ImportExportService(getCategories: getIt<get_categories_usecase.GetCategories>()),
  );

  getIt.registerLazySingleton<BarcodeService>(() => BarcodeService());

  //! ========== BLOCS ==========
  getIt.registerFactory(
        () => InventoryBloc(
      getInventoryItems: getIt(),
      createInventoryItem: getIt(),
      updateInventoryItem: getIt(),
      deleteInventoryItem: getIt(),
      searchInventoryItems: getIt(),
      filterInventoryItems: getIt(),
    ),
  );

  getIt.registerFactory(
        () => CategoryBloc(
      getCategories: getIt(),
      createCategory: getIt(),
    ),
  );

  // ✅ UPDATED: OrderBloc now gets OrderRepositoryImpl directly
  getIt.registerFactory(
        () => OrderBloc(
      getOrders: getIt(),
      createOrder: getIt(),
      updateOrder: getIt(),
      deleteOrder: getIt(),
      approveOrder: getIt(),
      rejectOrder: getIt(),
      searchOrders: getIt(),
      filterOrders: getIt(),
      orderRepository: getIt<OrderRepository>() as OrderRepositoryImpl, // ✅ NEW
    ),
  );
}
