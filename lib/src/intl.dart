import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:citystat1/src/binding.dart';
import 'package:citystat1/src/model/settings/general_preferences.dart';
import 'package:citystat1/src/model/settings/preferences_storage.dart';

/// Setup [Intl.defaultLocale] and timeago locale and messages.
Future<Locale> setupIntl(WidgetsBinding widgetsBinding) async {
  final systemLocale = widgetsBinding.platformDispatcher.locale; //?This gives you the OS-level locale, like Locale('en', 'US'), from WidgetsBinding.instance.platformDispatcher.

  // Get locale from shared preferences, if any
  final json = CitystatBinding.instance.sharedPreferences.getString(PrefCategory.general.storageKey);
  final generalPref = json != null
      ? GeneralPrefs.fromJson(jsonDecode(json) as Map<String, dynamic>)
      : GeneralPrefs.defaults;
  final prefsLocale = generalPref.locale;
  final locale = prefsLocale ?? systemLocale;

  Intl.defaultLocale = locale.toLanguageTag();

  return locale;
}
