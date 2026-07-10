import 'package:go_router/go_router.dart';

import '../features/analysis/analysis_controller.dart';
import '../features/analysis/results_screen.dart';
import '../features/ball_selection/ball_selection_screen.dart';
import '../features/calibration/calibration_screen.dart';
import '../features/camera_setup/camera_setup_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recording/recording_screen.dart';
import '../features/replay/replay_screen.dart';
import '../features/tracking/tracking_correction_screen.dart';
import '../features/video_import/video_import_screen.dart';

final paceLensRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const CameraSetupScreen(),
    ),
    GoRoute(
      path: '/record',
      builder: (context, state) => const RecordingScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) => const VideoImportScreen(),
    ),
    GoRoute(
      path: '/calibration',
      builder: (context, state) => const CalibrationScreen(),
    ),
    GoRoute(
      path: '/ball-selection',
      builder: (context, state) => const BallSelectionScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingCorrectionScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(path: '/replay', builder: (context, state) => const ReplayScreen()),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/calibration' ||
        path == '/ball-selection' ||
        path == '/tracking' ||
        path == '/results' ||
        path == '/replay') {
      return null;
    }
    return null;
  },
);

String confidenceLabel(AnalysisConfidence confidence) {
  return switch (confidence) {
    AnalysisConfidence.high => 'High',
    AnalysisConfidence.medium => 'Medium',
    AnalysisConfidence.low => 'Low',
    AnalysisConfidence.failed => 'Failed',
  };
}
