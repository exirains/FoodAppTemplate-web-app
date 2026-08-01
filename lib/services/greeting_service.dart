import 'package:flutter/material.dart';
import 'package:sangak/l10n/app_localizations.dart';

class GreetingService {
  static String getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context);

    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      try {
        return (l10n as dynamic).goodAfternoon ?? 'Good Afternoon,';
      } catch (e) {
        return 'Good Afternoon,';
      }
    } else {
      try {
        return (l10n as dynamic).goodEvening ?? 'Good Evening,';
      } catch (e) {
        return 'Good Evening,';
      }
    }
  }
}
