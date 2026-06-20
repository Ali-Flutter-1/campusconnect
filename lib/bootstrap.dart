import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'injection.dart';

/// One-time application startup: initialize Flutter bindings, Supabase, and the
/// dependency-injection container. Called from `main` before `runApp`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Accepts both the new publishable key and a legacy anon key.
      publishableKey: AppConfig.supabaseAnonKey,
    );
  } else if (kDebugMode) {
    debugPrint(
      'WARNING: Supabase credentials missing. Run with '
      '`flutter run --dart-define-from-file=env.json`. '
      'The UI shell will load, but any Supabase-backed feature will fail.',
    );
  }

  await configureDependencies();
}
