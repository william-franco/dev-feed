import 'package:dev_feed_app/src/common/services/connection_service.dart';
import 'package:dev_feed_app/src/common/services/http_service.dart';
import 'package:dev_feed_app/src/common/services/location_service.dart';
import 'package:dev_feed_app/src/common/services/storage_service.dart';
import 'package:dev_feed_app/src/features/auth/repositories/auth_repository.dart';
import 'package:dev_feed_app/src/features/auth/view_models/auth_session_view_model.dart';
import 'package:dev_feed_app/src/features/auth/view_models/login_view_model.dart';
import 'package:dev_feed_app/src/features/auth/view_models/register_view_model.dart';
import 'package:dev_feed_app/src/features/posts/repositories/post_repository.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:dev_feed_app/src/features/settings/repositories/setting_repository.dart';
import 'package:dev_feed_app/src/features/settings/view_models/setting_view_model.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void dependencyInjector() {
  _registerServices();
  _registerAuth();
  _registerPosts();
  _registerSettings();
}

void _registerServices() {
  locator.registerLazySingleton<ConnectionService>(
    () => ConnectionServiceImpl(),
  );
  locator.registerLazySingleton<StorageService>(() => StorageServiceImpl());
  locator.registerLazySingleton<HttpService>(
    () => HttpServiceImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<LocationService>(() => LocationServiceImpl());
}

void _registerAuth() {
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<LoginViewModel>(
    () => LoginViewModelImpl(authRepository: locator<AuthRepository>()),
  );
  locator.registerLazySingleton<RegisterViewModel>(
    () => RegisterViewModelImpl(authRepository: locator<AuthRepository>()),
  );
  locator.registerLazySingleton<AuthSessionViewModel>(
    () => AuthSessionViewModelImpl(authRepository: locator<AuthRepository>()),
  );
}

void _registerPosts() {
  locator.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
      locationService: locator<LocationService>(),
    ),
  );
  locator.registerLazySingleton<PostViewModel>(
    () => PostViewModelImpl(postRepository: locator<PostRepository>()),
  );
}

void _registerSettings() {
  locator.registerLazySingleton<SettingRepository>(
    () => SettingRepositoryImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<SettingViewModel>(
    () => SettingViewModelImpl(settingRepository: locator<SettingRepository>()),
  );
}

Future<void> initDependencies() async {
  await locator<StorageService>().initStorage();
  final bootTasks = <Future<void>>[
    locator<SettingViewModel>().getTheme(),
  ];
  if (!skipBootLocationCheck) {
    bootTasks.add(locator<LocationService>().checkLocation());
  }
  await Future.wait(bootTasks);
}

void resetDependencies() {
  locator.reset();
}
