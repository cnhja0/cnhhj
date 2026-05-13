/// Exceção base para erros vindos da camada de dados.
///
/// Cada implementação concreta (mock, Supabase) deve lançar `DataException`
/// com uma mensagem amigável e, opcionalmente, um `code` técnico — assim
/// a UI sempre lida com a mesma interface, sem precisar conhecer detalhes
/// específicos do Supabase ou do mock.
class DataException implements Exception {
  const DataException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'DataException($code): $message';
}

/// Lançada quando o usuário não está autenticado mas o método requer.
class UnauthenticatedException extends DataException {
  const UnauthenticatedException()
      : super('Você precisa estar autenticado.', code: 'unauthenticated');
}

/// Lançada quando as credenciais informadas são inválidas.
class InvalidCredentialsException extends DataException {
  const InvalidCredentialsException()
      : super('E-mail ou senha incorretos.', code: 'invalid_credentials');
}

/// Lançada quando um e-mail já está cadastrado.
class EmailAlreadyInUseException extends DataException {
  const EmailAlreadyInUseException()
      : super('Este e-mail já está cadastrado.', code: 'email_in_use');
}
