// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'OpenZap';

  @override
  String get findDevices => 'Cihaz Bul';

  @override
  String get noDevicesFound =>
      'Cihaz bulunamadı. TV\'nin açık olduğundan ve sanal uzaktan kumanda özelliğinin etkin olduğundan emin olun.';

  @override
  String get recentDevice => 'Son cihaz';

  @override
  String scanningProgress(int scanned, int total) {
    return 'Taranıyor: $scanned/$total';
  }

  @override
  String get tvStatusOn => 'Açık';

  @override
  String get tvStatusOff => 'Kapalı';

  @override
  String get tvStatusUnknown => 'Bilinmiyor';

  @override
  String get noDeviceSelected => 'Cihaz seçilmedi';

  @override
  String get commandFailed => 'Komut TV\'ye gönderilemedi.';

  @override
  String get commandSent => 'Komut gönderildi';

  @override
  String get cancelScan => 'İptal';

  @override
  String get settings => 'Ayarlar';

  @override
  String get commandFeedback => 'Komut geri bildirimi';

  @override
  String get commandFeedbackDescription =>
      'Komut gönderiminde mesaj gösterilip gösterilmeyeceğini kontrol eder.';

  @override
  String get feedbackErrorsOnly => 'Sadece hatalar';

  @override
  String get feedbackAll => 'Başarılar ve hatalar';

  @override
  String get feedbackNone => 'Kapalı';

  @override
  String get sleepTimer => 'Uyku zamanlayıcısı';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes dakika';
  }

  @override
  String get sleepTimerRemaining => 'TV kapanıyor';

  @override
  String get sleepTimerCustom => 'Özel…';

  @override
  String get customSleepTimerTitle => 'Özel uyku zamanlayıcısı';

  @override
  String get cancelSleepTimer => 'Uyku zamanlayıcısını iptal et';

  @override
  String get tooltipPower => 'Güç';

  @override
  String get tooltipMute => 'Sessiz';

  @override
  String get tooltipVolumeUp => 'Ses aç';

  @override
  String get tooltipVolumeDown => 'Ses kıs';

  @override
  String get tooltipChannelUp => 'Kanal +';

  @override
  String get tooltipChannelDown => 'Kanal -';

  @override
  String get tooltipUp => 'Yukarı';

  @override
  String get tooltipDown => 'Aşağı';

  @override
  String get tooltipLeft => 'Sol';

  @override
  String get tooltipRight => 'Sağ';

  @override
  String get tooltipOk => 'OK';

  @override
  String get tooltipBack => 'Geri';

  @override
  String get tooltipExit => 'Çıkış';

  @override
  String get tooltipInfo => 'Bilgi';
}
