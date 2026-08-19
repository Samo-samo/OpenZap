import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenZap'**
  String get appTitle;

  /// No description provided for @findDevices.
  ///
  /// In en, this message translates to:
  /// **'Find devices'**
  String get findDevices;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found. Make sure the TV is turned on and the virtual remote feature is enabled.'**
  String get noDevicesFound;

  /// No description provided for @recentDevice.
  ///
  /// In en, this message translates to:
  /// **'Recent device'**
  String get recentDevice;

  /// No description provided for @scanningProgress.
  ///
  /// In en, this message translates to:
  /// **'Scanning {scanned} of {total} devices'**
  String scanningProgress(int scanned, int total);

  /// No description provided for @tvStatusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get tvStatusOn;

  /// No description provided for @tvStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get tvStatusOff;

  /// No description provided for @tvStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get tvStatusUnknown;

  /// No description provided for @noDeviceSelected.
  ///
  /// In en, this message translates to:
  /// **'No device selected'**
  String get noDeviceSelected;

  /// No description provided for @commandFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the command to the TV.'**
  String get commandFailed;

  /// No description provided for @commandSent.
  ///
  /// In en, this message translates to:
  /// **'Command sent'**
  String get commandSent;

  /// No description provided for @cancelScan.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelScan;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @wifiWarningText.
  ///
  /// In en, this message translates to:
  /// **'Make sure your device is on the same Wi-Fi network as the TV.'**
  String get wifiWarningText;

  /// No description provided for @wifiWarningDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get wifiWarningDismiss;

  /// No description provided for @wifiWarningSwitch.
  ///
  /// In en, this message translates to:
  /// **'Show the same-network warning'**
  String get wifiWarningSwitch;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @commandFeedback.
  ///
  /// In en, this message translates to:
  /// **'Command feedback'**
  String get commandFeedback;

  /// No description provided for @commandFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls whether sending a command shows a message.'**
  String get commandFeedbackDescription;

  /// No description provided for @feedbackErrorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Errors only'**
  String get feedbackErrorsOnly;

  /// No description provided for @feedbackAll.
  ///
  /// In en, this message translates to:
  /// **'Successes and errors'**
  String get feedbackAll;

  /// No description provided for @feedbackNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get feedbackNone;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get addDevice;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeDevice;

  /// No description provided for @noSavedDevices.
  ///
  /// In en, this message translates to:
  /// **'No saved devices.'**
  String get noSavedDevices;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get deviceNameLabel;

  /// No description provided for @deviceIpLabel.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get deviceIpLabel;

  /// No description provided for @deviceIpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address.'**
  String get deviceIpInvalid;

  /// No description provided for @deviceAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This device is already added.'**
  String get deviceAlreadyAdded;

  /// No description provided for @saveDevice.
  ///
  /// In en, this message translates to:
  /// **'Save device'**
  String get saveDevice;

  /// No description provided for @renameDevice.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameDevice;

  /// No description provided for @renameDeviceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename device'**
  String get renameDeviceDialogTitle;

  /// No description provided for @deviceSaved.
  ///
  /// In en, this message translates to:
  /// **'Device saved'**
  String get deviceSaved;

  /// No description provided for @deviceRenamed.
  ///
  /// In en, this message translates to:
  /// **'Device renamed'**
  String get deviceRenamed;

  /// No description provided for @deviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed'**
  String get deviceRemoved;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsTitle;

  /// No description provided for @appYouTube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get appYouTube;

  /// No description provided for @appNetflix.
  ///
  /// In en, this message translates to:
  /// **'Netflix'**
  String get appNetflix;

  /// No description provided for @appHdmi.
  ///
  /// In en, this message translates to:
  /// **'HDMI'**
  String get appHdmi;

  /// No description provided for @appPortal.
  ///
  /// In en, this message translates to:
  /// **'Portal'**
  String get appPortal;

  /// No description provided for @appLaunched.
  ///
  /// In en, this message translates to:
  /// **'App launched'**
  String get appLaunched;

  /// No description provided for @appLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not launch the app.'**
  String get appLaunchFailed;

  /// No description provided for @remoteLayout.
  ///
  /// In en, this message translates to:
  /// **'Remote layout'**
  String get remoteLayout;

  /// No description provided for @layoutSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get layoutSections;

  /// No description provided for @layoutClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get layoutClassic;

  /// No description provided for @layoutCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get layoutCompact;

  /// No description provided for @layoutMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get layoutMinimal;

  /// No description provided for @layoutSectionTvStatus.
  ///
  /// In en, this message translates to:
  /// **'TV status'**
  String get layoutSectionTvStatus;

  /// No description provided for @layoutSectionDigits.
  ///
  /// In en, this message translates to:
  /// **'Digit keys'**
  String get layoutSectionDigits;

  /// No description provided for @layoutSectionSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get layoutSectionSleepTimer;

  /// No description provided for @layoutSectionExtras.
  ///
  /// In en, this message translates to:
  /// **'Quick controls'**
  String get layoutSectionExtras;

  /// No description provided for @keyTesterTitle.
  ///
  /// In en, this message translates to:
  /// **'Key test'**
  String get keyTesterTitle;

  /// No description provided for @keyTesterDescription.
  ///
  /// In en, this message translates to:
  /// **'Send raw remote key codes to discover and verify them'**
  String get keyTesterDescription;

  /// No description provided for @keyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Key code'**
  String get keyCodeLabel;

  /// No description provided for @sendKey.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendKey;

  /// No description provided for @presetKeys.
  ///
  /// In en, this message translates to:
  /// **'Preset keys'**
  String get presetKeys;

  /// No description provided for @keySent.
  ///
  /// In en, this message translates to:
  /// **'Key {code} sent'**
  String keySent(int code);

  /// No description provided for @tvStatusTracking.
  ///
  /// In en, this message translates to:
  /// **'Live status tracking'**
  String get tvStatusTracking;

  /// No description provided for @tvStatusTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the TV\'s power state on the remote screen.'**
  String get tvStatusTrackingDescription;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{1 minute} other{{minutes} minutes}}'**
  String sleepTimerMinutes(int minutes);

  /// No description provided for @sleepTimerHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{1 hour} other{{hours} hours}}'**
  String sleepTimerHours(int hours);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @sleepTimerSwitchHumanReadable.
  ///
  /// In en, this message translates to:
  /// **'Show durations as hours and minutes'**
  String get sleepTimerSwitchHumanReadable;

  /// No description provided for @sleepTimerSwitchMinutesInParens.
  ///
  /// In en, this message translates to:
  /// **'Show the total in parentheses'**
  String get sleepTimerSwitchMinutesInParens;

  /// No description provided for @sleepTimerSwitchManualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual minute entry in the custom dialog'**
  String get sleepTimerSwitchManualInput;

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In en, this message translates to:
  /// **'TV turns off in'**
  String get sleepTimerRemaining;

  /// No description provided for @sleepTimerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get sleepTimerCustom;

  /// No description provided for @customSleepTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom sleep timer'**
  String get customSleepTimerTitle;

  /// No description provided for @cancelSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel sleep timer'**
  String get cancelSleepTimer;

  /// No description provided for @tooltipPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get tooltipPower;

  /// No description provided for @tooltipMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get tooltipMute;

  /// No description provided for @tooltipVolumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get tooltipVolumeUp;

  /// No description provided for @tooltipVolumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get tooltipVolumeDown;

  /// No description provided for @tooltipChannelUp.
  ///
  /// In en, this message translates to:
  /// **'Channel up'**
  String get tooltipChannelUp;

  /// No description provided for @tooltipChannelDown.
  ///
  /// In en, this message translates to:
  /// **'Channel down'**
  String get tooltipChannelDown;

  /// No description provided for @tooltipUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get tooltipUp;

  /// No description provided for @tooltipDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get tooltipDown;

  /// No description provided for @tooltipLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get tooltipLeft;

  /// No description provided for @tooltipRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get tooltipRight;

  /// No description provided for @tooltipOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get tooltipOk;

  /// No description provided for @tooltipBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tooltipBack;

  /// No description provided for @tooltipExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get tooltipExit;

  /// No description provided for @tooltipInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tooltipInfo;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tooltipFavorites;

  /// No description provided for @tooltipPictureFormat.
  ///
  /// In en, this message translates to:
  /// **'Picture format'**
  String get tooltipPictureFormat;

  /// No description provided for @tooltipPictureMode.
  ///
  /// In en, this message translates to:
  /// **'Picture mode'**
  String get tooltipPictureMode;

  /// No description provided for @tooltipAudioTrack.
  ///
  /// In en, this message translates to:
  /// **'Audio track'**
  String get tooltipAudioTrack;

  /// No description provided for @tooltipSubtitleAudio.
  ///
  /// In en, this message translates to:
  /// **'Subtitle & audio'**
  String get tooltipSubtitleAudio;

  /// No description provided for @tooltipSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get tooltipSubtitles;

  /// No description provided for @tooltipTeletext.
  ///
  /// In en, this message translates to:
  /// **'Teletext'**
  String get tooltipTeletext;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
