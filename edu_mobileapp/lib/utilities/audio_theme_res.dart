import 'package:flutter/material.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Curated gradient background presets for audio rooms — shared between
/// the in-room Themes feature (AudioRoomScreen) and the Go-Live setup
/// screen's theme-card gallery, so both read from one real source instead
/// of a fake/mocked "theme image API" that doesn't exist.
class AudioThemeRes {
  static const List<List<Color>> presets = [
    [ColorRes.surfaceBackground, ColorRes.blackPure],
    [Color(0xFF6A1B9A), Color(0xFF1A0033)],
    [Color(0xFF8B0000), Color(0xFF1A0000)],
    [ColorRes.green, ColorRes.blackPure],
    [ColorRes.orangeDark, ColorRes.blackPure],
    [ColorRes.gold, ColorRes.blackPure],
  ];
}
