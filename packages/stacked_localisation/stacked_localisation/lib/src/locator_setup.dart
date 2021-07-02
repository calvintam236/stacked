import 'package:get_it/get_it.dart';
import 'package:stacked_localisation/src/utils/locale_provider.dart';
import 'package:stacked_localisation/src/utils/string_reader.dart';

final locator = GetIt.asNewInstance();

void setupLocator() {
  locator.registerLazySingleton(() => LocaleProvider());
  locator.registerLazySingleton(() => StringReader());
}
