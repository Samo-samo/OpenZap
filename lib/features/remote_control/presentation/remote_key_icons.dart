import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/remote_key.dart';

/// Icon for each [RemoteKey], shared by the remote screen and the layout
/// editor.
IconData remoteKeyIcon(RemoteKey key) => switch (key) {
  RemoteKey.power => Icons.power_settings_new,
  RemoteKey.mute => Icons.volume_off,
  RemoteKey.volumeUp => Icons.volume_up,
  RemoteKey.volumeDown => Icons.volume_down,
  RemoteKey.channelUp => Icons.add,
  RemoteKey.channelDown => Icons.remove,
  RemoteKey.up => Icons.keyboard_arrow_up,
  RemoteKey.down => Icons.keyboard_arrow_down,
  RemoteKey.left => Icons.keyboard_arrow_left,
  RemoteKey.right => Icons.keyboard_arrow_right,
  RemoteKey.select => Icons.circle_outlined,
  RemoteKey.back => Icons.arrow_back,
  RemoteKey.exit => Icons.cancel_outlined,
  RemoteKey.info => Icons.info_outline,
  RemoteKey.digit0 ||
  RemoteKey.digit1 ||
  RemoteKey.digit2 ||
  RemoteKey.digit3 ||
  RemoteKey.digit4 ||
  RemoteKey.digit5 ||
  RemoteKey.digit6 ||
  RemoteKey.digit7 ||
  RemoteKey.digit8 ||
  RemoteKey.digit9 => Icons.filter_9_plus,
  RemoteKey.settings => Icons.settings_outlined,
  RemoteKey.favorites => Icons.star_outline,
  RemoteKey.pictureFormat => Icons.aspect_ratio,
  RemoteKey.pictureMode => Icons.palette_outlined,
  RemoteKey.audioTrack => Icons.audiotrack,
  RemoteKey.subtitleAudio => Icons.subtitles_outlined,
  RemoteKey.subtitles => Icons.closed_caption,
  RemoteKey.teletext => Icons.article_outlined,
};

/// Localized label for each [RemoteKey], shared by the remote screen and the
/// layout editor.
String remoteKeyLabel(RemoteKey key, AppLocalizations l10n) => switch (key) {
  RemoteKey.power => l10n.tooltipPower,
  RemoteKey.mute => l10n.tooltipMute,
  RemoteKey.volumeUp => l10n.tooltipVolumeUp,
  RemoteKey.volumeDown => l10n.tooltipVolumeDown,
  RemoteKey.channelUp => l10n.tooltipChannelUp,
  RemoteKey.channelDown => l10n.tooltipChannelDown,
  RemoteKey.up => l10n.tooltipUp,
  RemoteKey.down => l10n.tooltipDown,
  RemoteKey.left => l10n.tooltipLeft,
  RemoteKey.right => l10n.tooltipRight,
  RemoteKey.select => l10n.tooltipOk,
  RemoteKey.back => l10n.tooltipBack,
  RemoteKey.exit => l10n.tooltipExit,
  RemoteKey.info => l10n.tooltipInfo,
  RemoteKey.digit0 ||
  RemoteKey.digit1 ||
  RemoteKey.digit2 ||
  RemoteKey.digit3 ||
  RemoteKey.digit4 ||
  RemoteKey.digit5 ||
  RemoteKey.digit6 ||
  RemoteKey.digit7 ||
  RemoteKey.digit8 ||
  RemoteKey.digit9 => '${key.index - RemoteKey.digit0.index}',
  RemoteKey.settings => l10n.tooltipSettings,
  RemoteKey.favorites => l10n.tooltipFavorites,
  RemoteKey.pictureFormat => l10n.tooltipPictureFormat,
  RemoteKey.pictureMode => l10n.tooltipPictureMode,
  RemoteKey.audioTrack => l10n.tooltipAudioTrack,
  RemoteKey.subtitleAudio => l10n.tooltipSubtitleAudio,
  RemoteKey.subtitles => l10n.tooltipSubtitles,
  RemoteKey.teletext => l10n.tooltipTeletext,
};
