import 'package:stacked_localisation/stacked_localisation.dart';

mixin LocalisedMixin {
  final LocalisationService _localisationService = locator<LocalisationService>();

  String translate(String key, {List<dynamic> replacements}) {
    String stringFromFile = _localisationService[key];
    if (replacements != null) {
      for (int i = 0; i < replacements.length; i++) {
        stringFromFile =
            stringFromFile.replaceAll('{$i}', replacements[i].toString());
      }
    }

    return stringFromFile;
  }
}
