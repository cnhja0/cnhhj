import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acessadores tipados para variáveis de ambiente.
///
/// Carregue uma vez em `main()` com `await Env.load()` antes de usar.
class Env {
  Env._();

  static Future<void> load() => dotenv.load();

  static String get supabaseUrl =>
      dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  /// 'mock' para dados em memória; 'supabase' para backend real.
  static AppMode get mode {
    final String raw = (dotenv.maybeGet('APP_MODE') ?? 'mock').toLowerCase();
    return raw == 'supabase' ? AppMode.supabase : AppMode.mock;
  }
}

enum AppMode { mock, supabase }
