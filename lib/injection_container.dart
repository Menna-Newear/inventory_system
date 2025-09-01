// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:inventory_system/presentation/blocs/category/category_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/network/network_info.dart';
import 'data/datasources/category_remote_datasource.dart';
import 'data/datasources/inventory_local_datasource.dart';
import 'data/datasources/inventory_remote_datasource.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/inventory_repository_impl.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/inventory_repository.dart';

// Import use cases with aliases to avoid naming conflicts
import 'domain/usecases/create_category.dart' as create_category_usecase;
import 'domain/usecases/get_categories.dart' as get_categories_usecase;
import 'domain/usecases/get_inventory_items.dart' as get_items_usecase;
import 'domain/usecases/create_inventory_item.dart' as create_item_usecase;
import 'domain/usecases/update_inventory_item.dart' as update_item_usecase;
import 'domain/usecases/delete_inventory_item.dart' as delete_item_usecase;
import 'domain/usecases/search_inventory_items.dart' as search_items_usecase;
import 'domain/usecases/filter_inventory_items.dart' as filter_items_usecase;

import 'presentation/blocs/inventory/inventory_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  getIt.registerLazySingleton(() => Supabase.instance.client);
  getIt.registerLazySingleton(() => Connectivity());

  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));

  // Data sources
  getIt.registerLazySingleton<InventoryLocalDataSource>(
    () => InventoryLocalDataSourceImpl(sharedPreferences: getIt()),
  );

  getIt.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(supabase: getIt()),
  );

  getIt.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(supabase: getIt()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () =>
        CategoryRepositoryImpl(remoteDataSource: getIt(),),
  );
  // Repositories
  getIt.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  // Use cases - using the aliased imports
  getIt.registerLazySingleton(
    () => get_items_usecase.GetInventoryItems(getIt()),
  );
  getIt.registerLazySingleton(
    () => create_item_usecase.CreateInventoryItem(getIt()),
  );
  getIt.registerLazySingleton(
    () => update_item_usecase.UpdateInventoryItem(getIt()),
  );
  getIt.registerLazySingleton(
    () => delete_item_usecase.DeleteInventoryItem(getIt()),
  );
  getIt.registerLazySingleton(
    () => search_items_usecase.SearchInventoryItems(getIt()),
  );
  getIt.registerLazySingleton(
    () => filter_items_usecase.FilterInventoryItems(getIt()),
  );
  getIt.registerLazySingleton(
    () => get_categories_usecase.GetCategories(getIt()),
  );
  getIt.registerLazySingleton(
    () => create_category_usecase.CreateCategory(getIt()),
  );

  // BLoCs
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

  // ViewModels
  getIt.registerFactory(
    () => CategoryBloc(
      getCategories: getIt(),
      createCategory: getIt(),

    ),
  );
}
