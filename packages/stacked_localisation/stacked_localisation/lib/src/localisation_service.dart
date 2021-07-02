import 'package:flutter/widgets.dart';
import 'package:stacked_localisation/src/locator_setup.dart';

class LocalisationService with WidgetsBindingObserver {
  final LocaleProvider _localeProvider = locator<LocaleProvider>();
  final StringReader _stringReader = locator<StringReader>();

  static LocalisationService? _instance;

  static Future<LocalisationService> getInstance() async {
    if (_instance == null) {
      _instance = LocalisationService();
    }
    return _instance;
  }

  LocalisationService() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stores the Strings for the locale that the service was initialised with
  Map<String, String> _localisedStrings;

  String operator [](String key) => _localisedStrings[key];

  static Future initialise() async {
    WidgetsFlutterBinding.ensureInitialized();
    await setupLocator();
    final String locale = await _localeProvider.getCurrentLocale();
    _localisedStrings = await _stringReader.getStringsFromAssets(locale);
  }

  @override
  void didChangeLocales(List<Locale> locale) async {
    final String currentLocale = locale.first.toString();
    _localisedStrings = await _stringReader.getStringsFromAssets(currentLocale);
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   // If the user changes language on the device and come back to the app,
  //   // it will trigger this function with AppLifecycleState.resumed
  //   if (state == AppLifecycleState.resumed) {
  //     await _instance.initialise();
  //   }
  // }
}
