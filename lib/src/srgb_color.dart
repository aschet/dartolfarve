// SPDX-FileCopyrightText: 2026 Thomas Ascher <thomas.ascher@gmx.at>
//
// SPDX-License-Identifier: MIT

/// An sRGB color, gamma encoded, with components in `[0, 1]`.
///
/// Being a record, an [SRGBColor] supports value equality and can be
/// destructured, e.g. `final (:r, :g, :b) = color;`.
typedef SRGBColor = ({double r, double g, double b});

/// Conversions from [SRGBColor] to other representations.
extension SRGBColorConversions on SRGBColor {
  /// Quantizes this color's components to 8-bit-per-channel integers,
  /// clamping out-of-gamut components into `[0, 255]` first.
  ///
  /// ## Example
  ///
  /// ```dart
  /// (r: 1.0, g: 0.5, b: 0.0).toRgb8(); // (r: 255, g: 128, b: 0)
  /// (r: 2.0, g: -1.0, b: 0.0).toRgb8(); // (r: 255, g: 0, b: 0)
  /// ```
  ({int r, int g, int b}) toRgb8() =>
      (r: _to8Bit(r), g: _to8Bit(g), b: _to8Bit(b));

  /// Formats this color as a lowercase `#rrggbb` hex string, clamping
  /// out-of-gamut components into `[0, 255]` first.
  ///
  /// ## Example
  ///
  /// ```dart
  /// (r: 1.0, g: 0.5, b: 0.0).toHex(); // '#ff8000'
  /// (r: 2.0, g: -1.0, b: 0.0).toHex(); // '#ff0000'
  /// ```
  String toHex() {
    final rgb8 = toRgb8();
    return '#'
        '${rgb8.r.toRadixString(16).padLeft(2, '0')}'
        '${rgb8.g.toRadixString(16).padLeft(2, '0')}'
        '${rgb8.b.toRadixString(16).padLeft(2, '0')}';
  }
}

int _to8Bit(double component) {
  final rounded = (component * 255.0).round();
  if (rounded < 0) return 0;
  if (rounded > 255) return 255;
  return rounded;
}
