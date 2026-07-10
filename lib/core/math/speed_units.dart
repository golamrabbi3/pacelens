class SpeedUnits {
  const SpeedUnits._();

  static double metresPerSecondToKph(double metresPerSecond) =>
      metresPerSecond * 3.6;

  static double metresPerSecondToMph(double metresPerSecond) =>
      metresPerSecond * 2.236936;
}
