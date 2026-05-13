/// Enumerações do domínio, alinhadas 1:1 com os tipos enumerados do
/// PostgreSQL definidos em `backend/supabase/migrations/0001_initial_schema.sql`.

enum UserRole {
  instrutor,
  aluno;

  String toJson() => name;
  static UserRole fromJson(String value) =>
      UserRole.values.firstWhere((UserRole e) => e.name == value);
}

enum Gender {
  masculino,
  feminino,
  naoInformar;

  String toJson() => switch (this) {
        Gender.masculino    => 'masculino',
        Gender.feminino     => 'feminino',
        Gender.naoInformar  => 'nao_informar',
      };

  static Gender fromJson(String value) => switch (value) {
        'masculino'      => Gender.masculino,
        'feminino'       => Gender.feminino,
        'nao_informar'   => Gender.naoInformar,
        _ => throw ArgumentError('Gender desconhecido: $value'),
      };

  String get label => switch (this) {
        Gender.masculino   => 'Masculino',
        Gender.feminino    => 'Feminino',
        Gender.naoInformar => 'Prefiro não informar',
      };
}

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;
  static ApprovalStatus fromJson(String value) =>
      ApprovalStatus.values.firstWhere((ApprovalStatus e) => e.name == value);
}

enum VehicleType {
  carro,
  moto,
  ambos;

  String toJson() => name;
  static VehicleType fromJson(String value) =>
      VehicleType.values.firstWhere((VehicleType e) => e.name == value);

  String get label => switch (this) {
        VehicleType.carro => 'Carro',
        VehicleType.moto  => 'Moto',
        VehicleType.ambos => 'Carro e Moto',
      };
}

enum Transmission {
  automatico,
  manual,
  ambos;

  String toJson() => name;
  static Transmission fromJson(String value) =>
      Transmission.values.firstWhere((Transmission e) => e.name == value);

  String get label => switch (this) {
        Transmission.automatico => 'Automático',
        Transmission.manual     => 'Manual',
        Transmission.ambos      => 'Ambos',
      };
}

/// Categorias de habilitação (CNH).
enum VehicleCategory {
  A, B, AB, C, D, E;

  String toJson() => name;
  static VehicleCategory fromJson(String value) =>
      VehicleCategory.values.firstWhere((VehicleCategory e) => e.name == value);

  String get label => switch (this) {
        VehicleCategory.A  => 'A — Moto',
        VehicleCategory.B  => 'B — Carro',
        VehicleCategory.AB => 'A + B — Moto e Carro',
        VehicleCategory.C  => 'C — Caminhão',
        VehicleCategory.D  => 'D — Ônibus',
        VehicleCategory.E  => 'E — Carreta',
      };
}

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow;

  String toJson() => switch (this) {
        BookingStatus.pending   => 'pending',
        BookingStatus.confirmed => 'confirmed',
        BookingStatus.cancelled => 'cancelled',
        BookingStatus.completed => 'completed',
        BookingStatus.noShow    => 'no_show',
      };

  static BookingStatus fromJson(String value) => switch (value) {
        'pending'   => BookingStatus.pending,
        'confirmed' => BookingStatus.confirmed,
        'cancelled' => BookingStatus.cancelled,
        'completed' => BookingStatus.completed,
        'no_show'   => BookingStatus.noShow,
        _ => throw ArgumentError('BookingStatus desconhecido: $value'),
      };

  String get label => switch (this) {
        BookingStatus.pending   => 'Aguardando',
        BookingStatus.confirmed => 'Confirmada',
        BookingStatus.cancelled => 'Cancelada',
        BookingStatus.completed => 'Concluída',
        BookingStatus.noShow    => 'Não compareceu',
      };
}

enum ReviewTarget {
  instructor,
  student;

  String toJson() => name;
  static ReviewTarget fromJson(String value) =>
      ReviewTarget.values.firstWhere((ReviewTarget e) => e.name == value);
}

/// Dias da semana (0=domingo, alinhado com `extract(dow ...)` do PostgreSQL).
enum DayOfWeek {
  domingo(0, 'Dom'),
  segunda(1, 'Seg'),
  terca(2, 'Ter'),
  quarta(3, 'Qua'),
  quinta(4, 'Qui'),
  sexta(5, 'Sex'),
  sabado(6, 'Sáb');

  const DayOfWeek(this.value, this.shortLabel);
  final int value;
  final String shortLabel;

  static DayOfWeek fromValue(int v) =>
      DayOfWeek.values.firstWhere((DayOfWeek d) => d.value == v);
}
