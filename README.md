# dartolfarve

[![Pub Version](https://img.shields.io/pub/v/olfarve)](https://pub.dev/packages/olfarve)

*Øl farve* ("beer color") renders SRM and EBC beer color values as sRGB
colors, following the spectral model described by A. J. de Lange, "Color," in
*Brewing Materials and Processes*, Elsevier, 2016, pp. 199-249.

Given a color value and an optical path length (the width of the glass the
beer is viewed through), the sample's spectral transmittance is derived from
its absorption coefficient at 430 nm via the Beer-Lambert law, integrated
against the CIE 1931 color matching functions of the 2 degree standard
colorimetric observer under illuminant D65, and the resulting XYZ tristimulus
values are transformed to sRGB.

## Installation

```bash
dart pub add olfarve
```

## Usage

```dart
import 'package:olfarve/olfarve.dart';

void main() {
  srmToSrgb(10).toHex();
  ebcToSrgb(20).toHex();

  // The default path length is 5 cm, the width of a typical sample glass.
  srmToSrgb(10, pathLengthCm: 1.0).toHex();

  // Results are SRGBColor records of gamma encoded components in [0, 1].
  final color = srmToSrgb(10);
  final (:r, :g, :b) = color;
  color.toRgb8();

  // Or start from an absorbance measured at 430 nm.
  absorptionToSrgb(0.7874);
}
```

See [example/olfarve_example.dart](example/olfarve_example.dart) for a
complete, runnable example.

## Development

```bash
dart pub get
dart test
dart format --output=none --set-exit-if-changed .
dart analyze
```
