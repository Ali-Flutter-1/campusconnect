import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  // Without Supabase credentials the app cannot talk to the backend. Fail with a
  // clear, actionable message instead of a cryptic "not initialized" assertion
  // deep in the widget tree (this happens when the run is missing the
  // `--dart-define-from-file=env.json` flag — e.g. the IDE's default Run button).
  if (!AppConfig.hasSupabaseConfig) {
    runApp(const _MissingConfigApp());
    return;
  }

  await bootstrap();
  runApp(const ConnectApp());
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.key_off, size: 48, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  'Supabase credentials missing',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Run the app with the env file:\n\n'
                  'flutter run --dart-define-from-file=env.json\n\n'
                  'In your IDE, add that flag to the run configuration arguments.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
