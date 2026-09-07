// SPDX-FileCopyrightText: 2026 Thomas Ascher <thomas.ascher@gmx.at>
//
// SPDX-License-Identifier: MIT

import 'package:olfarve/olfarve.dart';
import 'package:test/test.dart';

const _srmReferenceColors = {
  1: '#fae8b6',
  2: '#f4d180',
  4: '#e7aa31',
  10: '#ba5b00',
  20: '#7d1900',
  30: '#540000',
  40: '#390000',
  50: '#270000',
};

void main() {
  test('unabsorbing sample renders as white', () {
    final color = absorptionToSrgb(0.0);
    expect(color.r, closeTo(1.0, 1e-4));
    expect(color.g, closeTo(1.0, 1e-4));
    expect(color.b, closeTo(1.0, 1e-4));
    expect(color.toHex(), '#ffffff');
  });

  group('srmToSrgb matches reference colors', () {
    for (final MapEntry(key: srm, value: expected)
        in _srmReferenceColors.entries) {
      test('SRM $srm', () {
        expect(srmToSrgb(srm.toDouble()).toHex(), expected);
      });
    }
  });

  group('ebcToSrgb matches equivalent srmToSrgb', () {
    for (final srm in [1, 5, 10, 25, 40]) {
      test('SRM $srm', () {
        final ebc = srm * 25.0 / 12.7;
        final expected = srmToSrgb(srm.toDouble());
        final actual = ebcToSrgb(ebc);
        expect(actual.r, closeTo(expected.r, 1e-9));
        expect(actual.g, closeTo(expected.g, 1e-9));
        expect(actual.b, closeTo(expected.b, 1e-9));
      });
    }
  });

  test('components are within unit range', () {
    for (var srm = 0; srm <= 60; srm++) {
      final color = srmToSrgb(srm.toDouble());
      expect(color.r, inInclusiveRange(0.0, 1.0));
      expect(color.g, inInclusiveRange(0.0, 1.0));
      expect(color.b, inInclusiveRange(0.0, 1.0));
    }
  });

  test('color darkens monotonically with color value', () {
    var previousSum = double.infinity;
    for (var srm = 0; srm <= 40; srm++) {
      final color = srmToSrgb(srm.toDouble());
      final sum = color.r + color.g + color.b;
      expect(sum, lessThan(previousSum));
      previousSum = sum;
    }
  });

  test('longer path length darkens color', () {
    final shortPath = srmToSrgb(10, pathLengthCm: 1.0);
    final longPath = srmToSrgb(10, pathLengthCm: 10.0);
    final shortSum = shortPath.r + shortPath.g + shortPath.b;
    final longSum = longPath.r + longPath.g + longPath.b;
    expect(shortSum, greaterThan(longSum));
  });

  test('zero path length is white', () {
    expect(srmToSrgb(20, pathLengthCm: 0.0).toHex(), '#ffffff');
  });

  test('default path length matches BJCP glass width', () {
    expect(defaultPathLengthCm, 5.0);
    expect(srmToSrgb(10), srmToSrgb(10, pathLengthCm: defaultPathLengthCm));
  });

  group('absorptionToSrgb rejects negative input', () {
    test('negative absorption430', () {
      expect(
        () => absorptionToSrgb(-0.1, pathLengthCm: 5.0),
        throwsArgumentError,
      );
    });
    test('negative pathLengthCm', () {
      expect(
        () => absorptionToSrgb(1.0, pathLengthCm: -1.0),
        throwsArgumentError,
      );
    });
  });

  group('srmToSrgb rejects negative input', () {
    test('negative srm', () {
      expect(() => srmToSrgb(-1, pathLengthCm: 5.0), throwsArgumentError);
    });
    test('negative pathLengthCm', () {
      expect(() => srmToSrgb(1, pathLengthCm: -1.0), throwsArgumentError);
    });
  });

  group('ebcToSrgb rejects negative input', () {
    test('negative ebc', () {
      expect(() => ebcToSrgb(-1, pathLengthCm: 5.0), throwsArgumentError);
    });
    test('negative pathLengthCm', () {
      expect(() => ebcToSrgb(1, pathLengthCm: -1.0), throwsArgumentError);
    });
  });
}
