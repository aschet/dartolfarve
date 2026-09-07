// SPDX-FileCopyrightText: 2026 Thomas Ascher <thomas.ascher@gmx.at>
//
// SPDX-License-Identifier: MIT

/// Øl farve: sRGB color rendering of SRM/EBC beer color values.
///
/// Basic usage:
///
/// ```dart
/// import 'package:olfarve/olfarve.dart';
///
/// srmToSrgb(10).toHex();
/// ebcToSrgb(20, pathLengthCm: 1.0).toHex();
/// ```
library;

export 'src/beer_color.dart';
export 'src/srgb_color.dart';
