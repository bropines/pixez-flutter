import 'package:bot_toast/bot_toast.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pixez/main.dart';
import 'package:pixez/page/splash/common_splash_page.dart';
import 'package:pixez/win32_utils.dart';

class FluentAppState extends AppStateBase {
  late AccentColor _accentColor;

  @override
  void initState() {
    _accentColor = Color(getAccentColor()).toAccentColor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final botToastBuilder = BotToastInit();
      final theme = ThemeData(
        visualDensity: VisualDensity.standard,
        accentColor: _accentColor,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen() ? 2.0 : 0.0,
        ),
      );
      return FluentApp(
        home: Builder(builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(statusBarColor: Colors.transparent),
            child: SplashPage(),
          );
        }),
        builder: (context, child) {
          child = botToastBuilder(context, child);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: NavigationPaneTheme(
              data: NavigationPaneThemeData(
                backgroundColor: Colors.transparent,
              ),
              child: child,
            ),
          );
        },
        title: 'PixEz',
        locale: userSetting.locale,
        navigatorObservers: [
          BotToastNavigatorObserver(),
          routeObserver,
        ],
        themeMode: userSetting.themeMode,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          visualDensity: VisualDensity.standard,
          accentColor: _accentColor,
          focusTheme: FocusThemeData(
            glowFactor: is10footScreen() ? 2.0 : 0.0,
          ),
        ),
        theme: theme,
        localizationsDelegates: [
          _FluentLocalizationsDelegate(),
          ...AppLocalizations.localizationsDelegates
        ],
        supportedLocales: AppLocalizations.supportedLocales, // Add this line
      );
    });
  }

}

class _FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalizations> {
  const _FluentLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<FluentLocalizations> load(Locale locale) {
    return DefaultFluentLocalizations.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalizations> old) {
    return false;
  }
}

