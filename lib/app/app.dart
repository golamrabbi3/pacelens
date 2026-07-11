import 'package:flutter/material.dart';

import 'app_metadata.dart';
import 'router.dart';
import 'theme.dart';

class PaceLensApp extends StatelessWidget {
  const PaceLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PaceLens',
      debugShowCheckedModeBanner: false,
      theme: PaceLensTheme.dark(),
      routerConfig: paceLensRouter,
      builder: (context, child) {
        return PaceLensAppChrome(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
