// SPDX-FileCopyrightText: 2026 Thomas Ascher <thomas.ascher@gmx.at>
//
// SPDX-License-Identifier: MIT

/// Renders SRM and EBC beer color values as sRGB colors, following the
/// spectral model described in:
///
/// > A. J. de Lange, "Color," in *Brewing Materials and Processes*,
/// > Elsevier, 2016, pp. 199-249.
///
/// A beer color value is converted to an absorption coefficient at 430 nm.
/// The absorbance at every wavelength from 380 nm to 780 nm is then
/// approximated from it, and the resulting spectral transmittance is
/// integrated against the CIE 1931 standard observer and the D65 illuminant
/// to produce CIE XYZ tristimulus values, which are transformed to sRGB.
library;

import 'dart:math' as math;

import 'cie_data.dart';
import 'srgb_color.dart';

/// Default optical path length in cm, set to the typical sample glass width
/// specified by the BJCP color guide.
///
/// See https://www.bjcp.org/education-training/education-resources/color-guide.
const defaultPathLengthCm = 5.0;

const _srmPerAbsorbance = 12.7;
const _ebcPerAbsorbance = 25.0;

const _referenceWavelengthNm = 430.0;
const _shortDecayWeight = 0.02465;
const _shortDecayNm = 17.591;
const _longDecayWeight = 0.97535;
const _longDecayNm = 82.122;

const _gammaThreshold = 0.0031308;
const _gammaSlope = 12.92;
const _gammaScale = 1.055;
const _gammaOffset = 0.055;
const _gammaExponent = 1.0 / 2.4;

/// Precomputed wavelength dependent terms of the integration, as
/// `(absorptionRatio, sD65, xBar, yBar, zBar)`.
///
/// Only absorbance varies between conversions; absorption ratios and
/// colorimetric weights depend only on wavelength, so they are computed
/// once rather than on every call.
typedef _SpectrumEntry = (
  double absorptionRatio,
  double sD65,
  double xBar,
  double yBar,
  double zBar,
);

/// CIE defines `k = 100 / sum(S(lambda) * yBar(lambda))`, putting the
/// luminance of a perfectly transmitting sample at 100. Dropping the factor
/// of 100 puts it at 1.0 instead, which is the range sRGB expects.
///
/// Top-level `final` fields are lazily initialized on first use, so this is
/// computed once and then reused.
final double _k = _calculateK();

final List<_SpectrumEntry> _spectrum = _buildSpectrum();

double _calculateK() {
  var luminance = 0.0;
  for (final (_, yBar, _, sD65) in cieSamples) {
    luminance += sD65 * yBar;
  }
  return 1.0 / luminance;
}

/// Returns absorption at [wavelengthNm] relative to that at 430 nm.
double _absorptionRatio(double wavelengthNm) {
  final offsetNm = wavelengthNm - _referenceWavelengthNm;
  return (_shortDecayWeight * math.exp(-offsetNm / _shortDecayNm)) +
      (_longDecayWeight * math.exp(-offsetNm / _longDecayNm));
}

List<_SpectrumEntry> _buildSpectrum() {
  final spectrum = <_SpectrumEntry>[];
  var wavelengthNm = firstWavelengthNm;
  for (final (xBar, yBar, zBar, sD65) in cieSamples) {
    spectrum.add((_absorptionRatio(wavelengthNm), sD65, xBar, yBar, zBar));
    wavelengthNm += wavelengthStepNm;
  }
  return spectrum;
}

/// Gamma encodes one linear component, clamping it to `[0, 1]` first.
double _encodeGamma(double linear) {
  final clamped = math.max(0.0, math.min(1.0, linear));
  return clamped <= _gammaThreshold
      ? clamped * _gammaSlope
      : (_gammaScale * math.pow(clamped, _gammaExponent).toDouble()) -
          _gammaOffset;
}

void _checkNotNegative(double value, String name) {
  if (value < 0.0) {
    throw ArgumentError.value(value, name, 'Value must not be negative.');
  }
}

/// Converts a linear decadic absorption coefficient at 430 nm to an sRGB
/// color.
///
/// [absorption430] is numerically the ASBC/EBC absorbance A430 defined for a
/// 1 cm path. [pathLengthCm] is the optical path length in cm, e.g. the
/// width of the glass the sample is viewed through.
///
/// Throws an [ArgumentError] if [absorption430] or [pathLengthCm] is
/// negative.
///
/// ## Example
///
/// ```dart
/// absorptionToSrgb(10.0 / 12.7).toHex(); // '#ba5b00'
/// ```
SRGBColor absorptionToSrgb(
  double absorption430, {
  double pathLengthCm = defaultPathLengthCm,
}) {
  _checkNotNegative(absorption430, 'absorption430');
  _checkNotNegative(pathLengthCm, 'pathLengthCm');

  final absorbance430 = absorption430 * pathLengthCm;
  var tristimulusX = 0.0;
  var tristimulusY = 0.0;
  var tristimulusZ = 0.0;
  for (final (absorptionRatio, sD65, xBar, yBar, zBar) in _spectrum) {
    final transmittedPower =
        sD65 * math.pow(10.0, -absorbance430 * absorptionRatio);
    tristimulusX += transmittedPower * xBar;
    tristimulusY += transmittedPower * yBar;
    tristimulusZ += transmittedPower * zBar;
  }
  tristimulusX *= _k;
  tristimulusY *= _k;
  tristimulusZ *= _k;

  final rLinear = (3.2406255 * tristimulusX) +
      (-1.537208 * tristimulusY) +
      (-0.4986286 * tristimulusZ);
  final gLinear = (-0.9689307 * tristimulusX) +
      (1.8757561 * tristimulusY) +
      (0.0415175 * tristimulusZ);
  final bLinear = (0.0557101 * tristimulusX) +
      (-0.2040211 * tristimulusY) +
      (1.0569959 * tristimulusZ);

  return (
    r: _encodeGamma(rLinear),
    g: _encodeGamma(gLinear),
    b: _encodeGamma(bLinear),
  );
}

/// Converts an SRM beer color value to an sRGB color.
///
/// Throws an [ArgumentError] if [srm] or [pathLengthCm] is negative.
///
/// ## Example
///
/// ```dart
/// srmToSrgb(10).toHex(); // '#ba5b00'
/// ```
SRGBColor srmToSrgb(double srm, {double pathLengthCm = defaultPathLengthCm}) =>
    absorptionToSrgb(srm / _srmPerAbsorbance, pathLengthCm: pathLengthCm);

/// Converts an EBC beer color value to an sRGB color.
///
/// Throws an [ArgumentError] if [ebc] or [pathLengthCm] is negative.
///
/// ## Example
///
/// ```dart
/// ebcToSrgb(20).toHex(); // '#b95900'
/// ```
SRGBColor ebcToSrgb(double ebc, {double pathLengthCm = defaultPathLengthCm}) =>
    absorptionToSrgb(ebc / _ebcPerAbsorbance, pathLengthCm: pathLengthCm);
