import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acessadores tipados para variáveis de ambiente.
///
/// `Env.load()` é seguro de chamar mesmo se o `.env` não existir como asset
/// (caso típico do build de CI sem .env commitado). Quando o arquivo está
/// ausente, todos os getters retornam defaults e o app roda em modo mock.
class Env {
  Env._();

  static bool _loaded = false;

  /// Tenta carregar o `.env`. Falha silenciosamente se o arquivo não estiver
  /// disponível — nesse caso, todos os getters caem para defaults.
  static Future<void> load() async {
    try {
      await dotenv.load();
      _loaded = true;
    } catch (_) {
      _loaded = false;
    }
  }

  /// Lê uma chave do .env sem nunca lançar exceção.
  /// Em flutter_dotenv 5.x, `dotenv.maybeGet` lança `NotInitializedError`
  /// quando `load()` nunca rodou — esse wrapper evita o crash.
  static String _safeGet(String key) {
    if (!_loaded) return '';
    try {
      return dotenv.maybeGet(key) ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get supabaseUrl     => _safeGet('SUPABASE_URL');
  static String get supabaseAnonKey => _safeGet('SUPABASE_ANON_KEY');

  /// 'mock' (default) usa dados em memória; 'supabase' conecta no backend real.
  static AppMode get mode {
    final String raw = _safeGet('APP_MODE').toLowerCase();
    return raw == 'supabase' ? AppMode.supabase : AppMode.mock;
  }
}

enum AppMode { mock, supabase }
