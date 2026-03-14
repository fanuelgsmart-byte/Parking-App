import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/di/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // @preResolve singletons (e.g. encrypted database) are awaited here
  await getIt.init();
}
