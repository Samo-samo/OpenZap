// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenZap';

  @override
  String get findDevices => 'Find devices';

  @override
  String get noDevicesFound =>
      'No devices found. Make sure the TV is turned on and the virtual remote feature is enabled.';

  @override
  String get recentDevice => 'Recent device';

  @override
  String scanningProgress(int scanned, int total) {
    return 'Scanning $scanned of $total devices';
  }

  @override
  String get tvStatusOn => 'On';

  @override
  String get tvStatusOff => 'Off';

  @override
  String get tvStatusUnknown => 'Unknown';

  @override
  String get noDeviceSelected => 'No device selected';

  @override
  String get commandFailed => 'Could not send the command to the TV.';

  @override
  String get commandSent => 'Command sent';

  @override
  String get cancelScan => 'Cancel';

  @override
  String get settings => 'Settings';

  @override
  String get commandFeedback => 'Command feedback';

  @override
  String get commandFeedbackDescription =>
      'Controls whether sending a command shows a message.';

  @override
  String get feedbackErrorsOnly => 'Errors only';

  @override
  String get feedbackAll => 'Successes and errors';

  @override
  String get feedbackNone => 'Off';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get sleepTimerRemaining => 'TV turns off in';

  @override
  String get sleepTimerCustom => 'Custom…';

  @override
  String get customSleepTimerTitle => 'Custom sleep timer';

  @override
  String get cancelSleepTimer => 'Cancel sleep timer';

  @override
  String get tooltipPower => 'Power';

  @override
  String get tooltipMute => 'Mute';

  @override
  String get tooltipVolumeUp => 'Volume up';

  @override
  String get tooltipVolumeDown => 'Volume down';

  @override
  String get tooltipChannelUp => 'Channel up';

  @override
  String get tooltipChannelDown => 'Channel down';

  @override
  String get tooltipUp => 'Up';

  @override
  String get tooltipDown => 'Down';

  @override
  String get tooltipLeft => 'Left';

  @override
  String get tooltipRight => 'Right';

  @override
  String get tooltipOk => 'OK';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipExit => 'Exit';

  @override
  String get tooltipInfo => 'Info';
}
