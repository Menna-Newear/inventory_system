// ✅ injection_container.dart (FIXED)
import 'package:get_it/get_it.dart';
import 'package:inventory_system/presentation/blocs/category/category_bloc.dart';
import 'package:inventory_system/presentation/blocs/order/order_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/network/network_info.dart';

// ===================================
// DATA SOURCES
// ===================================
import 'data/datasources/category_remote_datasource.dart';
import 'data/datasources/inventory_local_datasource.dart';
import 'data/datasources/inventory_remote_datasource.dart';
import 'data/datasources/order_remote_datasource.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/user_remote_data_source.dart';

// ===================================
// REPOSITORIES
// ===================================
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/inventory_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';

// ===================================
// SERVICES
// ===================================
import 'data/services/barcode_service.dart';
import 'data/services/import_export_service.dart';
import 'data/services/serial_number_cache_service.dart';
import 'data/services/stock_management_service.dart';

// ===================================
// DOMAIN REPOSITORIES
// ===================================
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';

// ===================================
// USE CASES - AUTH
// ===================================
import 'domain/usecases/auth/login.dart';
import 'domain/usecases/auth/logout.dart';
import 'domain/usecases/auth/get_current_user.dart';

// ===================================
// USE CASES - USER MANAGEMENT
// ===================================
import 'domain/usecases/user/create_user.dart';
import 'domain/usecases/user/get_all_users.dart';
import 'domain/usecases/user/delete_user.dart';
import 'domain/usecases/user/update_user.dart' as update_user_usecase;
import 'domain/usecases/user/update_user_password.dart';

// ===================================
// USE CASES - INVENTORY & ORDERS
// ===================================
import 'domain/usecases/add_serial_usecase.dart' as add_serial_usecase;
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

// ===================================
// BLOCS
// ===================================
import 'presentation/blocs/inventory/inventory_bloc.dart';
import 'presentation/blocs/serial/serial_number_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // ===================================
  // EXTERNAL DEPENDENCIES
  // ===================================
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  getIt.registerLazySingleton(() => Supabase.instance.client);
  getIt.registerLazySingleton(() => Connectivity());
  getIt.registerLazySingleton(() => CreateUser(getIt()));

  // ===================================
  // CORE
  // ===================================
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));

  // ===================================
  // DATA SOURCES
  // ===================================
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
  getIt.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<UserRemoteDataSource>(
        () => UserRemoteDataSourceImpl(getIt()),
  );

  // ===================================
  // CACHE SERVICES
  // ===================================
  getIt.registerLazySingleton<SerialNumberCacheService>(
        () => SerialNumberCacheService(getIt<SharedPreferences>()),
  );

  // ===================================
  // REPOSITORIES
  // ===================================
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
        () => CategoryRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<InventoryRepository>(
        () => InventoryRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      cacheService: getIt(),
      networkInfo: getIt(),
    ),
  );

  // ===================================
  // SERVICES
  // ===================================
  getIt.registerLazySingleton<StockManagementService>(
        () => StockManagementService(inventoryRepository: getIt()),
  );
  getIt.registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(
      remoteDataSource: getIt(),
      networkInfo: getIt(),
      stockManagementService: getIt(),
    ),
  );
  getIt.registerLazySingleton<ImportExportService>(
        () => ImportExportService(
      getCategories: getIt<get_categories_usecase.GetCategories>(),
    ),
  );
  getIt.registerLazySingleton<BarcodeService>(() => BarcodeService());

  // ===================================
  // USE CASES
  // ===================================
  getIt.registerLazySingleton(() => Login(getIt()));
  getIt.registerLazySingleton(() => Logout(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUser(getIt()));
  getIt.registerLazySingleton(() => GetAllUsers(getIt()));
  getIt.registerLazySingleton(() => update_user_usecase.UpdateUser(getIt()));
  getIt.registerLazySingleton(() => DeleteUser(getIt()));
  getIt.registerLazySingleton(() => UpdateUserPassword(getIt()));
  getIt.registerLazySingleton(() => get_categories_usecase.GetCategories(getIt()));
  getIt.registerLazySingleton(() => create_category_usecase.CreateCategory(getIt()));
  getIt.registerLazySingleton(() => get_items_usecase.GetInventoryItems(getIt()));
  getIt.registerLazySingleton(() => create_item_usecase.CreateInventoryItem(getIt()));
  getIt.registerLazySingleton(() => update_item_usecase.UpdateInventoryItem(getIt()));
  getIt.registerLazySingleton(() => delete_item_usecase.DeleteInventoryItem(getIt()));
  getIt.registerLazySingleton(() => search_items_usecase.SearchInventoryItems(getIt()));
  getIt.registerLazySingleton(() => filter_items_usecase.FilterInventoryItems(getIt()));
  getIt.registerLazySingleton(() => get_orders_usecase.GetOrders(getIt()));
  getIt.registerLazySingleton(() => create_order_usecase.CreateOrder(getIt()));
  getIt.registerLazySingleton(() => update_order_usecase.UpdateOrder(getIt()));
  getIt.registerLazySingleton(() => delete_order_usecase.DeleteOrder(getIt()));
  getIt.registerLazySingleton(() => approve_order_usecase.ApproveOrder(getIt()));
  getIt.registerLazySingleton(() => reject_order_usecase.RejectOrder(getIt()));
  getIt.registerLazySingleton(() => search_orders_usecase.SearchOrders(getIt()));
  getIt.registerLazySingleton(() => filter_orders_usecase.FilterOrders(getIt()));
  getIt.registerLazySingleton(() => add_serial_usecase.AddSerialNumbers(getIt()));

  // ===================================
  // BLOCS
  // ===================================
  getIt.registerLazySingleton<AuthBloc>(
        () => AuthBloc(
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
      getAllUsersUseCase: getIt(),
      updateUserUseCase: getIt(),
      deleteUserUseCase: getIt(),
      updateUserPasswordUseCase: getIt(), createUserUseCase: getIt(),
    ),
  );

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
      orderRepository: getIt<OrderRepository>() as OrderRepositoryImpl,
    ),
  );

  getIt.registerFactory(
        () => SerialNumberBloc(
          supabaseClient: getIt<SupabaseClient>(),  // ✅ ADD THIS
          addSerialNumbersUseCase: getIt<add_serial_usecase.AddSerialNumbers>(),
      inventoryRepository: getIt<InventoryRepository>(),
      cacheService: getIt<SerialNumberCacheService>(),
    ),
  );
}
