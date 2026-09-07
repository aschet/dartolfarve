// SPDX-FileCopyrightText: 2026 Thomas Ascher <thomas.ascher@gmx.at>
//
// SPDX-License-Identifier: MIT

import 'package:olfarve/olfarve.dart';
import 'package:test/test.dart';

void main() {
  test('supports value equality and destructuring', () {
    const colorA = (r: 0.5, g: 0.25, b: 0.0);
    const colorB = (r: 0.5, g: 0.25, b: 0.0);
    expect(colorA, colorB);

    const SRGBColor color = (r: 0.1, g: 0.2, b: 0.3);
    final (:r, :g, :b) = color;
    expect((r, g, b), (0.1, 0.2, 0.3));
  });

  test('toHex encodes full precision colors', () {
    expect((r: 1.0, g: 0.5, b: 0.0).toHex(), '#ff8000');
    expect((r: 0.0, g: 0.0, b: 0.0).toHex(), '#000000');
  });

  test('toRgb8 quantizes to byte components', () {
    expect((r: 1.0, g: 0.5, b: 0.0).toRgb8(), (r: 255, g: 128, b: 0));
  });

  group('hex endpoints', () {
    test('white', () {
      expect((r: 1.0, g: 1.0, b: 1.0).toHex(), '#ffffff');
    });
    test('black', () {
      expect((r: 0.0, g: 0.0, b: 0.0).toHex(), '#000000');
    });
    test('red', () {
      expect((r: 1.0, g: 0.0, b: 0.0).toHex(), '#ff0000');
    });
  });

  test('hex output is lowercase and padded', () {
    final hex = (r: 0.04, g: 0.04, b: 0.04).toHex();
    expect(hex, hex.toLowerCase());
    expect(hex.length, 7);
  });

  test('hex agrees with rgb8', () {
    for (var srm = 0; srm <= 60; srm++) {
      final color = srmToSrgb(srm.toDouble());
      final rgb8 = color.toRgb8();
      final expected = '#'
          '${rgb8.r.toRadixString(16).padLeft(2, '0')}'
          '${rgb8.g.toRadixString(16).padLeft(2, '0')}'
          '${rgb8.b.toRadixString(16).padLeft(2, '0')}';
      expect(color.toHex(), expected);
    }
  });

  group('out-of-gamut components are clamped', () {
    test('above range', () {
      expect((r: 2.0, g: 0.0, b: 0.0).toHex(), '#ff0000');
    });
    test('below range', () {
      expect((r: -1.0, g: -1.0, b: -1.0).toHex(), '#000000');
    });
    test('fractionally above range', () {
      expect((r: 1.5, g: 0.0, b: 0.0).toHex(), '#ff0000');
    });
  });
}
