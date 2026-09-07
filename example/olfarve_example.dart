import 'package:olfarve/olfarve.dart';

void main() {
  print(srmToSrgb(10).toHex());
  print(ebcToSrgb(20).toHex());

  // The default path length is 5 cm, the width of a typical sample glass.
  print(srmToSrgb(10, pathLengthCm: 1.0).toHex());

  // Results are SRGBColor records of gamma encoded components in [0, 1].
  final color = srmToSrgb(10);
  final (:r, :g, :b) = color;
  print('r=$r, g=$g, b=$b');
  print(color.toRgb8());

  // Or start from an absorbance measured at 430 nm.
  print(absorptionToSrgb(0.7874).toHex());
}
