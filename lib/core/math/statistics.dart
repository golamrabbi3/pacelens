import 'dart:math' as math;

class Statistics {
  const Statistics._();

  static double median(List<double> values) {
    if (values.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'Cannot calculate median of an empty list.',
      );
    }
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double medianAbsoluteDeviation(List<double> values) {
    final centre = median(values);
    return median(values.map((value) => (value - centre).abs()).toList());
  }

  static double linearRegressionSlope({
    required List<double> x,
    required List<double> y,
  }) {
    if (x.length != y.length || x.length < 2) {
      throw ArgumentError('Regression needs matching x/y values.');
    }
    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < x.length; i++) {
      numerator += (x[i] - meanX) * (y[i] - meanY);
      denominator += math.pow(x[i] - meanX, 2).toDouble();
    }
    if (denominator == 0) {
      throw ArgumentError('Regression timestamps must vary.');
    }
    return numerator / denominator;
  }

  static double residualRootMeanSquare({
    required List<double> x,
    required List<double> y,
    required double slope,
  }) {
    final intercept = y.first - slope * x.first;
    final sum = Iterable<int>.generate(x.length).fold<double>(0, (
      total,
      index,
    ) {
      final residual = y[index] - (intercept + slope * x[index]);
      return total + residual * residual;
    });
    return math.sqrt(sum / x.length);
  }
}
