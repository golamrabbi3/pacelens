enum SpeedMeasurementMode {
  calibratedGuides,
  arDepth;

  String get label {
    return switch (this) {
      SpeedMeasurementMode.calibratedGuides => 'Calibrated mph',
      SpeedMeasurementMode.arDepth => 'AR depth mph',
    };
  }
}
