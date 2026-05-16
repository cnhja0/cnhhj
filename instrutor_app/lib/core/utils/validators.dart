/// Validações compartilhadas — formulários de cadastro, login, perfil e
/// onboarding consultam essas funções para manter critérios consistentes.
///
/// Convenção: cada função retorna `null` quando o valor é válido e uma
/// `String` de mensagem de erro (apta a exibir ao usuário) quando inválido.
/// Isso casa direto com a assinatura de `FormFieldValidator` do Flutter.
library;

class Validators {
  Validators._();

  // ─── Nome completo ────────────────────────────────────────────────
  /// Exige pelo menos duas palavras com 2+ letras cada (nome + sobrenome).
  /// Rejeita "Ana", "  Ana ", "Ana B" e abreviações.
  static String? fullName(String? v) {
    final String s = (v ?? '').trim();
    if (s.isEmpty) return 'Informe seu nome completo';
    final List<String> parts = s
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) return 'Informe nome e sobrenome';
    for (final String p in parts) {
      if (p.length < 2) return 'Cada parte do nome precisa ter 2+ letras';
      if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ'\-]+$").hasMatch(p)) {
        return 'O nome contém caracteres inválidos';
      }
    }
    return null;
  }

  // ─── E-mail ───────────────────────────────────────────────────────
  /// Regex pragmática — exige `local@domínio.tld` com TLD de 2+ chars.
  /// Não é a RFC 5322 completa (que ninguém implementa), mas filtra os
  /// erros realistas de digitação ("a@b", "x@y.", "@gmail.com").
  static String? email(String? v) {
    final String s = (v ?? '').trim();
    if (s.isEmpty) return 'Informe o e-mail';
    final RegExp re = RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    );
    if (!re.hasMatch(s)) return 'E-mail inválido';
    return null;
  }

  /// Normaliza e-mail para persistência: trim + lower-case.
  static String normalizeEmail(String v) => v.trim().toLowerCase();

  // ─── Senha ────────────────────────────────────────────────────────
  /// Mínimo 8 chars, com pelo menos 1 letra e 1 dígito.
  static String? password(String? v) {
    final String s = v ?? '';
    if (s.isEmpty) return 'Crie uma senha';
    if (s.length < 8) return 'A senha precisa ter pelo menos 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(s)) {
      return 'Inclua pelo menos uma letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(s)) {
      return 'Inclua pelo menos um número';
    }
    return null;
  }

  /// Força da senha (0..4): usado por medidor visual abaixo do campo.
  static int passwordStrength(String s) {
    int score = 0;
    if (s.length >= 8) score++;
    if (s.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(s)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score++;
    return score.clamp(0, 4);
  }

  // ─── CPF ──────────────────────────────────────────────────────────
  /// Valida CPF pelo algoritmo oficial (dois dígitos verificadores).
  /// Aceita `digitsOnly` (11 dígitos) ou texto com pontuação (`123.456.789-09`).
  static String? cpf(String? v) {
    final String digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF inválido';
    // Rejeita CPFs com todos dígitos iguais (111.111.111-11, etc.) que
    // passam no cálculo mas são inválidos.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return 'CPF inválido';

    int calcDigit(String base, int startWeight) {
      int sum = 0;
      for (int i = 0; i < base.length; i++) {
        sum += int.parse(base[i]) * (startWeight - i);
      }
      final int mod = (sum * 10) % 11;
      return mod == 10 ? 0 : mod;
    }

    final int d1 = calcDigit(digits.substring(0, 9), 10);
    final int d2 = calcDigit(digits.substring(0, 10), 11);
    if (d1 != int.parse(digits[9]) || d2 != int.parse(digits[10])) {
      return 'CPF inválido';
    }
    return null;
  }

  // ─── Celular ──────────────────────────────────────────────────────
  /// Brasil: 11 dígitos com DDD válido e 9 inicial (após DDD). Rejeita
  /// fixo — instrutor precisa receber notificação push/WhatsApp.
  static String? mobilePhone(String? v) {
    final String digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'Informe celular com DDD (11 dígitos)';
    final int ddd = int.parse(digits.substring(0, 2));
    if (ddd < 11 || ddd > 99) return 'DDD inválido';
    if (digits[2] != '9') return 'Celular deve começar com 9 após o DDD';
    return null;
  }

  // ─── Placa de veículo ─────────────────────────────────────────────
  /// Aceita placa antiga (`ABC-1234` / `ABC1234`) e placa Mercosul
  /// (`ABC-1D23` / `ABC1D23`) — letras maiúsculas, hífen opcional.
  static String? plate(String? v) {
    final String raw = (v ?? '').toUpperCase().replaceAll('-', '');
    if (raw.length != 7) return 'Placa inválida';
    final RegExp antiga = RegExp(r'^[A-Z]{3}[0-9]{4}$');
    final RegExp mercosul = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    if (!antiga.hasMatch(raw) && !mercosul.hasMatch(raw)) {
      return 'Placa inválida';
    }
    return null;
  }

  /// Normaliza placa: maiúsculas, sem hífen.
  static String normalizePlate(String v) =>
      v.toUpperCase().replaceAll('-', '').replaceAll(' ', '');

  // ─── Ano de veículo ───────────────────────────────────────────────
  static String? vehicleYear(String? v) {
    final int? year = int.tryParse((v ?? '').trim());
    if (year == null) return 'Ano inválido';
    final int now = DateTime.now().year;
    if (year < 1980 || year > now + 1) return 'Ano inválido';
    return null;
  }
}
