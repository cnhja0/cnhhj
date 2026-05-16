# Validação de Aula + Endpoints do App do Aluno — Plano de Implementação

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing (batch) ou flutter-craft:flutter-subagent-dev (subagent per task).

**Goal:** Adicionar validação de aula via código 6 dígitos (instrutor → aluno), auto-confirm em 48h, dispute window de 48h via "Reportar problema". Preparar endpoints que o app do aluno (Fase 2) vai consumir do mesmo backend.

**Arquitetura:** Continua o padrão existente — abstract repositories + mock impl, Riverpod providers, feature folders por escopo. NÃO introduzir camada `domain/usecases` (não está em uso no projeto). Manter consistência com código atual.

**Design upstream:** [2026-05-16-lesson-validation-and-student-endpoints.md](./2026-05-16-lesson-validation-and-student-endpoints.md)

**Dependencies:** Nenhuma nova. Tudo com pacotes já no `pubspec.yaml`.

**Decisões já firmadas:**
- Geo: P3 (backlog)
- Foto em dispute: não usa
- Janela de dispute: 48h
- Auto-confirm: 48h após `scheduledEnd`
- Cron: Supabase Postgres no futuro; **no mock = boot-check** no Splash

---

## Camada 1 — Modelos e Enums

### Task 1: Enum `BookingCompletedBy` + edits no `Booking`

**Layer:** Domain/Models

**Files:**
- Modify: `instrutor_app/lib/data/models/enums.dart`
- Modify: `instrutor_app/lib/data/models/booking.dart`

**Implementation (enums.dart, adicionar no fim):**

```dart
/// Quem marcou a aula como concluída.
enum BookingCompletedBy {
  student,     // aluno digitou o código
  auto,        // cron / boot-check após 48h
  instructor;  // raro: instrutor confirma sem o código (suporte)

  String toJson() => name;
  static BookingCompletedBy fromJson(String value) =>
      BookingCompletedBy.values.firstWhere((BookingCompletedBy e) => e.name == value);
}
```

**Implementation (booking.dart — adicionar campos):**

Adicionar no construtor após `cancellationReason`:
```dart
this.completedAt,
this.completedBy,
```

Adicionar como campos `final`:
```dart
final DateTime? completedAt;
final BookingCompletedBy? completedBy;
```

Atualizar `copyWith` (adicionar params + retorno), `fromJson` (chaves `completed_at`, `completed_by`), `toJson` (mesmas chaves).

**Verification:**
```bash
# Não dá pra rodar flutter analyze localmente; depende do CI.
grep -n 'completedAt\|completedBy' instrutor_app/lib/data/models/booking.dart
# Esperado: aparece em 4 lugares (constructor, field, copyWith param, fromJson, toJson)
```

**Commit:** `feat(domain): add Booking.completedAt/completedBy + BookingCompletedBy enum`

---

### Task 2: Modelo `LessonCode`

**Layer:** Domain/Models

**Files:**
- Create: `instrutor_app/lib/data/models/lesson_code.dart`

**Implementation:**

```dart
/// Código de 6 dígitos que o instrutor gera ao concluir a aula. Aluno
/// digita no app dele para confirmar que a aula aconteceu.
///
/// Validade: 24 horas. Uso único. Vinculado a UMA booking.
/// Janela de 24h permite que o aluno digite mais tarde caso esteja sem
/// internet na hora da aula (cenário comum em ruas/regiões com sinal ruim).
class LessonCode {
  const LessonCode({
    required this.bookingId,
    required this.code,
    required this.expiresAt,
    required this.createdAt,
    this.usedAt,
  });

  final String bookingId;
  /// Plain 6-digit string. No mock guardamos cru; em produção guardar HASH.
  final String code;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? usedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;

  LessonCode copyWith({DateTime? usedAt}) => LessonCode(
        bookingId: bookingId,
        code: code,
        expiresAt: expiresAt,
        createdAt: createdAt,
        usedAt: usedAt ?? this.usedAt,
      );

  factory LessonCode.fromJson(Map<String, dynamic> json) => LessonCode(
        bookingId: json['booking_id'] as String,
        code: json['code'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        usedAt: json['used_at'] == null
            ? null
            : DateTime.parse(json['used_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'booking_id': bookingId,
        'code': code,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'used_at': usedAt?.toIso8601String(),
      };
}
```

**Commit:** `feat(domain): add LessonCode model`

---

### Task 3: Modelo `BookingDispute`

**Layer:** Domain/Models

**Files:**
- Create: `instrutor_app/lib/data/models/booking_dispute.dart`

**Implementation:**

```dart
enum DisputeStatus {
  pending,
  resolved,
  rejected;

  String toJson() => name;
  static DisputeStatus fromJson(String value) =>
      DisputeStatus.values.firstWhere((DisputeStatus e) => e.name == value);
}

/// Quando alguém aperta "Reportar problema" numa booking — instrutor ou
/// aluno. Pausa o auto-confirm e exige resolução manual.
class BookingDispute {
  const BookingDispute({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.reason,
    this.description,
    this.status = DisputeStatus.pending,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String bookingId;
  final String reporterId;
  final String reason;        // ex: "aluno-nao-compareceu", "instrutor-nao-veio", "outro"
  final String? description;  // texto livre opcional
  final DisputeStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  BookingDispute copyWith({DisputeStatus? status, DateTime? resolvedAt}) =>
      BookingDispute(
        id: id,
        bookingId: bookingId,
        reporterId: reporterId,
        reason: reason,
        description: description,
        status: status ?? this.status,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  factory BookingDispute.fromJson(Map<String, dynamic> json) => BookingDispute(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        reporterId: json['reporter_id'] as String,
        reason: json['reason'] as String,
        description: json['description'] as String?,
        status: DisputeStatus.fromJson(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        resolvedAt: json['resolved_at'] == null
            ? null
            : DateTime.parse(json['resolved_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'booking_id': bookingId,
        'reporter_id': reporterId,
        'reason': reason,
        'description': description,
        'status': status.toJson(),
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };
}
```

**Commit:** `feat(domain): add BookingDispute model + DisputeStatus enum`

---

### Task 4: Modelo `InstructorSearchResult` (projeção leve)

**Layer:** Domain/Models

**Files:**
- Create: `instrutor_app/lib/data/models/instructor_search_result.dart`

**Justificativa:** o aluno precisa de uma lista com info essencial pra escolher (sem documentos, sem fotos do veículo). Esse modelo achata `Instructor + Profile`.

**Implementation:**

```dart
import 'enums.dart';

/// Projeção leve para a vitrine do aluno (`InstructorRepository.search`).
/// Não traz documentos (CNH, DETRAN) nem fotos do veículo — economia de
/// banda e privacidade. Quando o aluno toca pra ver detalhes, chama
/// `InstructorRepository.getById(id)` que retorna o `Instructor` completo.
class InstructorSearchResult {
  const InstructorSearchResult({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.city,
    this.neighborhood,
    this.state,
    required this.averageRating,
    required this.totalReviews,
    this.vehicleType,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleTransmission,
    this.pricePerClass,
    this.categories = const <VehicleCategory>[],
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? city;
  final String? neighborhood;
  final String? state;
  final double averageRating;
  final int totalReviews;
  final VehicleType? vehicleType;
  final String? vehicleBrand;
  final String? vehicleModel;
  final Transmission? vehicleTransmission;
  final double? pricePerClass;
  final List<VehicleCategory> categories;
}
```

**Commit:** `feat(domain): add InstructorSearchResult projection model`

---

## Camada 2 — Repository Interfaces

### Task 5: Estender `BookingRepository` com 6 métodos novos

**Layer:** Data (interface)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/booking_repository.dart`

**Adicionar imports:**
```dart
import '../models/booking_dispute.dart';
import '../models/lesson_code.dart';
```

**Adicionar ao abstract class:**

```dart
/// Aluno cria uma solicitação. Booking nasce `pending`.
Future<Booking> create({
  required String instructorId,
  required String studentId,
  required DateTime scheduledStart,
  required DateTime scheduledEnd,
  String? meetingPoint,
  String? notes,
  double? agreedPrice,
});

/// Bookings de um aluno específico (todas as situações).
Future<List<Booking>> listForStudent(String studentId);

/// Instrutor gera código 6 dígitos ao concluir aula. Booking precisa estar
/// `confirmed`. Código vale 24 horas, uso único.
Future<LessonCode> generateCompletionCode(String bookingId);

/// Aluno digita o código no app dele. Server valida e transita booking
/// para `completed` (completedBy=student).
///
/// Erros: [InvalidLessonCodeException] (código errado/expirado),
/// [StateError] (booking não está confirmed ou não pertence ao student).
Future<Booking> validateCompletionCode({
  required String bookingId,
  required String code,
  required String studentId,
});

/// Botão "Reportar problema" — pausa o auto-confirm e marca booking como
/// `disputed` (transição cosmética no MVP; em produção, status separado).
Future<BookingDispute> reportIssue({
  required String bookingId,
  required String reporterId,
  required String reason,
  String? description,
});

/// Varre bookings `confirmed` com `scheduledEnd` há mais de 48h sem
/// dispute e marca como `completed` (completedBy=auto).
///
/// No MVP: chamado no boot do app via SplashScreen.
/// Em produção: feito por `pg_cron` no Supabase, esse método vira no-op
/// no client (mantém assinatura pra não quebrar UI).
Future<int> autoCompleteIfDue();
```

**Adicionar exception class no fim do arquivo:**

```dart
class InvalidLessonCodeException implements Exception {
  const InvalidLessonCodeException(this.reason);
  final String reason; // 'expired' | 'used' | 'mismatch' | 'wrong_owner' | 'wrong_status'
  @override
  String toString() => 'InvalidLessonCodeException($reason)';
}
```

**Commit:** `feat(data): extend BookingRepository with student-facing endpoints`

---

### Task 6: Estender `InstructorRepository` com `search()`

**Layer:** Data (interface)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/instructor_repository.dart`

**Adicionar import:**
```dart
import '../models/instructor_search_result.dart';
```

**Adicionar à abstract class:**

```dart
/// Vitrine do aluno. Filtros são todos opcionais — sem nenhum, retorna
/// todos os instrutores aprovados e ativos.
Future<List<InstructorSearchResult>> search({
  String? city,
  String? state,
  VehicleCategory? category,
  VehicleType? vehicleType,
  Transmission? transmission,
  double? maxPricePerClass,
  double? minRating,
});
```

**Commit:** `feat(data): add InstructorRepository.search for student vitrine`

---

### Task 7: Estender `ChatRepository` com `startConversation()`

**Layer:** Data (interface)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/chat_repository.dart`

**Adicionar à abstract class:**

```dart
/// Cria conversa entre instrutor e aluno se ainda não existir. Retorna
/// a conversa (nova ou já existente). Idempotente.
Future<Conversation> startConversation({
  required String instructorId,
  required String studentId,
});
```

**Commit:** `feat(data): add ChatRepository.startConversation`

---

## Camada 3 — Mock Implementations

### Task 8: Estender `MockState` com `lessonCodes` e `disputes`

**Layer:** Data (mock state)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/mock/_seed.dart`

**Adicionar imports:**
```dart
import '../../models/booking_dispute.dart';
import '../../models/lesson_code.dart';
```

**Adicionar à classe `MockState`:**

```dart
/// Códigos gerados pelo instrutor, indexados por bookingId. Um booking
/// só tem um código ativo por vez — se gerar de novo, sobrescreve.
final Map<String, LessonCode> lessonCodes = <String, LessonCode>{};

/// Disputes em ordem de criação (mock simples; em produção é tabela).
final List<BookingDispute> disputes = <BookingDispute>[];
```

**Commit:** `feat(data): seed state for lessonCodes + disputes`

---

### Task 9: Implementar novos métodos em `MockBookingRepository`

**Layer:** Data (mock impl)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/mock/mock_booking_repository.dart`

**Imports a adicionar:**
```dart
import 'dart:math';
import '../../models/booking_dispute.dart';
import '../../models/lesson_code.dart';
```

**Adicionar implementações dos 6 métodos (anotações `@override`):**

```dart
@override
Future<Booking> create({
  required String instructorId,
  required String studentId,
  required DateTime scheduledStart,
  required DateTime scheduledEnd,
  String? meetingPoint,
  String? notes,
  double? agreedPrice,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  if (!scheduledEnd.isAfter(scheduledStart)) {
    throw ArgumentError('scheduledEnd deve ser após scheduledStart');
  }
  final DateTime now = DateTime.now();
  final Booking b = Booking(
    id: 'book-${now.microsecondsSinceEpoch.toRadixString(36)}',
    instructorId: instructorId,
    studentId: studentId,
    scheduledStart: scheduledStart,
    scheduledEnd: scheduledEnd,
    status: BookingStatus.pending,
    meetingPoint: meetingPoint,
    notes: notes,
    agreedPrice: agreedPrice,
    createdAt: now,
    updatedAt: now,
  );
  MockState.instance.bookings.add(b);
  _changes.add(<Booking>[]);
  // Notif para o instrutor (já existe pattern em updateStatus).
  if (notifications != null) {
    try {
      await notifications!.create(
        AppNotification(
          id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-br',
          userId: instructorId,
          type: NotificationType.bookingRequest,
          title: 'Nova solicitação de aula',
          body: 'Toque para ver os detalhes.',
          createdAt: now,
          actionRoute: '/home/solicitacoes',
        ),
      );
    } catch (_) {}
  }
  return b;
}

@override
Future<List<Booking>> listForStudent(String studentId) async {
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return MockState.instance.bookings
      .where((Booking b) => b.studentId == studentId)
      .toList(growable: false)
    ..sort((Booking a, Booking b) =>
        b.scheduledStart.compareTo(a.scheduledStart));
}

@override
Future<LessonCode> generateCompletionCode(String bookingId) async {
  await Future<void>.delayed(const Duration(milliseconds: 200));
  final int idx = MockState.instance.bookings
      .indexWhere((Booking b) => b.id == bookingId);
  if (idx == -1) throw StateError('Booking não encontrada: $bookingId');
  final Booking b = MockState.instance.bookings[idx];
  if (b.status != BookingStatus.confirmed) {
    throw StateError('Booking precisa estar confirmed para gerar código.');
  }
  final DateTime now = DateTime.now();
  // 6 dígitos com leading zeros: 000000-999999
  final String code = (Random.secure().nextInt(1000000))
      .toString()
      .padLeft(6, '0');
  final LessonCode lc = LessonCode(
    bookingId: bookingId,
    code: code,
    expiresAt: now.add(const Duration(hours: 24)),
    createdAt: now,
  );
  MockState.instance.lessonCodes[bookingId] = lc;
  return lc;
}

@override
Future<Booking> validateCompletionCode({
  required String bookingId,
  required String code,
  required String studentId,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 200));
  final int idx = MockState.instance.bookings
      .indexWhere((Booking b) => b.id == bookingId);
  if (idx == -1) throw StateError('Booking não encontrada.');
  final Booking b = MockState.instance.bookings[idx];
  if (b.studentId != studentId) {
    throw const InvalidLessonCodeException('wrong_owner');
  }
  if (b.status != BookingStatus.confirmed) {
    throw const InvalidLessonCodeException('wrong_status');
  }
  final LessonCode? lc = MockState.instance.lessonCodes[bookingId];
  if (lc == null || lc.code != code) {
    throw const InvalidLessonCodeException('mismatch');
  }
  if (lc.isExpired) {
    throw const InvalidLessonCodeException('expired');
  }
  if (lc.isUsed) {
    throw const InvalidLessonCodeException('used');
  }
  final DateTime now = DateTime.now();
  MockState.instance.lessonCodes[bookingId] = lc.copyWith(usedAt: now);
  final Booking updated = b.copyWith(
    status: BookingStatus.completed,
    completedAt: now,
    completedBy: BookingCompletedBy.student,
    updatedAt: now,
  );
  MockState.instance.bookings[idx] = updated;
  _changes.add(<Booking>[]);
  // Notif: solicita avaliação pros dois lados (já existe pattern).
  if (notifications != null) {
    try {
      await notifications!.create(AppNotification(
        id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-cs',
        userId: b.instructorId,
        type: NotificationType.review,
        title: 'Aula concluída',
        body: 'Avalie o aluno desta aula.',
        createdAt: now,
        actionRoute: '/reviews',
      ));
      await notifications!.create(AppNotification(
        id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-cs2',
        userId: b.studentId,
        type: NotificationType.review,
        title: 'Aula concluída',
        body: 'Avalie seu instrutor.',
        createdAt: now,
        actionRoute: '/reviews',
      ));
    } catch (_) {}
  }
  return updated;
}

@override
Future<BookingDispute> reportIssue({
  required String bookingId,
  required String reporterId,
  required String reason,
  String? description,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 200));
  final DateTime now = DateTime.now();
  final BookingDispute d = BookingDispute(
    id: 'disp-${now.microsecondsSinceEpoch.toRadixString(36)}',
    bookingId: bookingId,
    reporterId: reporterId,
    reason: reason,
    description: description,
    createdAt: now,
  );
  MockState.instance.disputes.add(d);
  // Notif para o suporte interno (no MVP: pra outro lado da booking).
  if (notifications != null) {
    final int idx = MockState.instance.bookings
        .indexWhere((Booking b) => b.id == bookingId);
    if (idx != -1) {
      final Booking b = MockState.instance.bookings[idx];
      final String otherId =
          b.instructorId == reporterId ? b.studentId : b.instructorId;
      try {
        await notifications!.create(AppNotification(
          id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-dp',
          userId: otherId,
          type: NotificationType.system,
          title: 'Problema reportado',
          body: 'Algo deu errado na aula. Verifique no app.',
          createdAt: now,
          actionRoute: '/home/agenda',
        ));
      } catch (_) {}
    }
  }
  return d;
}

@override
Future<int> autoCompleteIfDue() async {
  final DateTime now = DateTime.now();
  final DateTime threshold = now.subtract(const Duration(hours: 48));
  int count = 0;
  for (int i = 0; i < MockState.instance.bookings.length; i++) {
    final Booking b = MockState.instance.bookings[i];
    if (b.status != BookingStatus.confirmed) continue;
    if (!b.scheduledEnd.isBefore(threshold)) continue;
    // Bookings com dispute pendente NÃO viram auto-completed.
    final bool hasOpenDispute = MockState.instance.disputes.any(
      (BookingDispute d) =>
          d.bookingId == b.id && d.status == DisputeStatus.pending,
    );
    if (hasOpenDispute) continue;
    MockState.instance.bookings[i] = b.copyWith(
      status: BookingStatus.completed,
      completedAt: now,
      completedBy: BookingCompletedBy.auto,
      updatedAt: now,
    );
    count++;
  }
  if (count > 0) _changes.add(<Booking>[]);
  return count;
}
```

**Verification:** rode busca para garantir que não há `@override` solto sem método correspondente na interface.

**Commit:** `feat(data): implement student-facing methods in MockBookingRepository`

---

### Task 10: Implementar `MockInstructorRepository.search`

**Layer:** Data (mock impl)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/mock/mock_instructor_repository.dart`

**Adicionar imports:**
```dart
import '../../models/instructor_search_result.dart';
import '../../models/profile.dart';
```

**Adicionar método:**

```dart
@override
Future<List<InstructorSearchResult>> search({
  String? city,
  String? state,
  VehicleCategory? category,
  VehicleType? vehicleType,
  Transmission? transmission,
  double? maxPricePerClass,
  double? minRating,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final Iterable<Instructor> all =
      MockState.instance.instructors.values.where((Instructor i) {
    if (!i.isActive) return false;
    if (city != null && i.city?.toLowerCase() != city.toLowerCase()) return false;
    if (state != null && i.state != state) return false;
    if (vehicleType != null && i.vehicleType != vehicleType) return false;
    if (transmission != null && i.vehicleTransmission != transmission) return false;
    if (category != null && !i.categories.contains(category)) return false;
    if (maxPricePerClass != null &&
        (i.pricePerClass ?? double.infinity) > maxPricePerClass) {
      return false;
    }
    if (minRating != null && i.averageRating < minRating) return false;
    return true;
  });

  return all.map((Instructor i) {
    final Profile? p = MockState.instance.profiles[i.id];
    return InstructorSearchResult(
      id: i.id,
      fullName: p?.fullName ?? 'Instrutor',
      avatarUrl: p?.avatarUrl,
      city: i.city,
      neighborhood: i.neighborhood,
      state: i.state,
      averageRating: i.averageRating,
      totalReviews: i.totalReviews,
      vehicleType: i.vehicleType,
      vehicleBrand: i.vehicleBrand,
      vehicleModel: i.vehicleModel,
      vehicleTransmission: i.vehicleTransmission,
      pricePerClass: i.pricePerClass,
      categories: i.categories,
    );
  }).toList(growable: false)
    ..sort((InstructorSearchResult a, InstructorSearchResult b) =>
        b.averageRating.compareTo(a.averageRating));
}
```

**Commit:** `feat(data): implement MockInstructorRepository.search`

---

### Task 11: Implementar `MockChatRepository.startConversation`

**Layer:** Data (mock impl)

**Files:**
- Modify: `instrutor_app/lib/data/repositories/mock/mock_chat_repository.dart`

**Adicionar:**

```dart
@override
Future<Conversation> startConversation({
  required String instructorId,
  required String studentId,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 150));
  // Idempotente: se já existe conversa entre esses dois, retorna ela.
  final Conversation? existing = MockState.instance.conversations
      .where((Conversation c) =>
          c.instructorId == instructorId && c.studentId == studentId)
      .firstOrNull;
  if (existing != null) return existing;
  final DateTime now = DateTime.now();
  final Conversation conv = Conversation(
    id: 'conv-${now.microsecondsSinceEpoch.toRadixString(36)}',
    instructorId: instructorId,
    studentId: studentId,
    createdAt: now,
    lastMessageAt: null,
  );
  MockState.instance.conversations.add(conv);
  _convListChanges.add(conv.id);
  return conv;
}
```

**Imports necessários:** `package:collection/collection.dart` para `firstOrNull` (já incluído via outras dependências, verificar).

**Commit:** `feat(data): implement MockChatRepository.startConversation`

---

## Camada 4 — UI do Instrutor

### Task 12: Botão "Concluir aula" na `TabSchedule`

**Layer:** Presentation

**Files:**
- Modify: `instrutor_app/lib/features/home/tabs/tab_schedule.dart`

**Mudanças:**
1. Adicionar `onTap` no `_BookingTile` que abre bottom sheet com 3 ações:
   - **"Concluir aula"** (só se `status == confirmed` && `scheduledStart < now`)
   - **"Reportar problema"** (só se `status == confirmed`)
   - **"Marcar como não compareceu"** (só se `status == confirmed`)
2. "Concluir aula" → navega para `/bookings/:id/completion-code` (rota nova).
3. "Reportar problema" → mostra `_ReportIssueSheet` (Task 14).
4. "Marcar não compareceu" → confirma via modal, chama `updateStatus(noShow)`.

**Implementação chave (não código completo aqui — fica claro pelo padrão):**

Adicionar dentro do `_BookingTile` build:
```dart
return InkWell(
  onTap: () => _showActions(context, ref, booking),
  borderRadius: BorderRadius.circular(12),
  child: /* card atual */,
);
```

`_showActions` é função local que mostra bottom sheet com os 3 botões.

**Commit:** `feat(schedule): add booking actions sheet (complete / report / no-show)`

---

### Task 13: Tela `CompletionCodeScreen` + Controller

**Layer:** Presentation

**Files:**
- Create: `instrutor_app/lib/features/bookings/completion_code_screen.dart`
- Create: `instrutor_app/lib/features/bookings/completion_code_controller.dart`
- Modify: `instrutor_app/lib/core/router/app_router.dart` (nova rota `/bookings/:id/completion-code`)

**Comportamento:**
1. Ao entrar, controller chama `generateCompletionCode(bookingId)` → state vira `data(LessonCode)`.
2. UI mostra código GRANDE (`fontSize: 56`) tipo `4 8 2 7` (espaçamento entre dígitos).
3. Countdown ao vivo (`Timer.periodic` 1s) até `expiresAt`.
4. Ao mesmo tempo, observa `watchForInstructor(instructorId)` — quando booking transita pra `completed`, mostra tela de sucesso ("Aula concluída! Você ganhou um aluno satisfeito.") + botão "Voltar à agenda".
5. Se código expira sem validação, botão "Gerar novo código".
6. Botão "Cancelar" → volta sem mudar status.

**Controller state shape (Riverpod):**

```dart
class CompletionCodeState {
  const CompletionCodeState({
    this.loading = true,
    this.code,
    this.errorMessage,
    this.completed = false,
  });

  final bool loading;
  final LessonCode? code;
  final String? errorMessage;
  /// True quando a booking foi validada pelo aluno (status virou completed).
  final bool completed;
}

class CompletionCodeController
    extends AutoDisposeFamilyAsyncNotifier<CompletionCodeState, String> {
  /* family arg = bookingId */
  @override
  Future<CompletionCodeState> build(String bookingId) async { /* generate */ }

  Future<void> regenerate() async { /* call generateCompletionCode again */ }
}
```

Mantém UI desacoplada — quando o aluno (em outro app) validar o código, o stream do `bookingRepository.watchForInstructor` emite com a booking em `completed`, e a UI reage.

**Commit:** `feat(bookings): add CompletionCodeScreen with countdown`

---

### Task 14: Bottom sheet `_ReportIssueSheet`

**Layer:** Presentation

**Files:**
- Create: `instrutor_app/lib/features/bookings/report_issue_sheet.dart`

**Comportamento:**
- Bottom sheet com:
  - Dropdown "Motivo" (4 opções pra começar: "Aluno não compareceu" / "Veículo quebrou" / "Acidente" / "Outro")
  - Campo de descrição opcional (`maxLength: 300`)
  - Botão "Enviar"
- Ao enviar: chama `bookingRepository.reportIssue(...)`, fecha sheet, mostra snack "Problema reportado. Você será contactado pelo suporte."

**Helper exportado:**
```dart
Future<bool> showReportIssueSheet(
  BuildContext context, {
  required String bookingId,
  required String reporterId,
});
```

**Commit:** `feat(bookings): add report-issue bottom sheet`

---

### Task 15: Boot-check `autoCompleteIfDue` no Splash

**Layer:** Presentation

**Files:**
- Modify: `instrutor_app/lib/features/onboarding/splash_screen.dart`

**Adicionar em `_decideNextRoute()` após `restoreSession`:**

```dart
// Boot-check: marca bookings vencidas há mais de 48h como completed.
// Em produção, isso é feito por `pg_cron` no Supabase — esse client-side
// fica como fallback / no-op quando o servidor já fez o trabalho.
try {
  await ref.read(bookingRepositoryProvider).autoCompleteIfDue();
} catch (_) {
  // Falha não-fatal — só silencia.
}
```

**Posição:** logo após `auth.restoreSession()` e ANTES do `Future.wait` que decide a rota. Como `autoCompleteIfDue` é fast no mock, não atrasa muito o Splash. Em produção (Supabase), o método retorna 0 imediatamente.

**Commit:** `feat(boot): trigger autoCompleteIfDue on splash`

---

## Camada 5 — Testes (priority order)

### Task 16: Testes do `MockBookingRepository`

**Layer:** Test (Priority 1)

**Files:**
- Create: `instrutor_app/test/data/repositories/mock/mock_booking_repository_test.dart`

**Cobertura mínima:**
- `generateCompletionCode` retorna LessonCode com 6 dígitos numéricos e `expiresAt` ≈ now+15min.
- `generateCompletionCode` rejeita booking que não está `confirmed`.
- `validateCompletionCode` aceita o código correto, transita booking pra `completed`, marca `usedAt`.
- `validateCompletionCode` rejeita: código errado, expirado, já usado, booking de outro aluno, booking não-confirmed.
- `autoCompleteIfDue` ignora confirmed dentro da janela; marca os de fora; pula os com dispute pendente.
- `reportIssue` cria registro e adiciona em `MockState.instance.disputes`.

**Setup mínimo:**
```dart
setUp(() {
  MockState.instance.bookings.clear();
  MockState.instance.lessonCodes.clear();
  MockState.instance.disputes.clear();
  // Insere uma booking confirmed default no estado.
});
```

**Commit:** `test(data): cover MockBookingRepository new methods`

---

### Task 17: Testes do `MockInstructorRepository.search`

**Layer:** Test (Priority 1)

**Files:**
- Create: `instrutor_app/test/data/repositories/mock/mock_instructor_repository_test.dart`

**Cobertura:**
- Sem filtros, retorna todos os instrutores `isActive`.
- Filtros combinados (city + category) intersectam corretamente.
- Instructor `isActive: false` nunca aparece.
- Ordenação por `averageRating` desc.

**Commit:** `test(data): cover MockInstructorRepository.search`

---

### Task 18: Teste do `CompletionCodeController`

**Layer:** Test (Priority 2)

**Files:**
- Create: `instrutor_app/test/features/bookings/completion_code_controller_test.dart`

**Cobertura:**
- `build(bookingId)` chama `generateCompletionCode` e retorna state com `code != null`.
- `regenerate()` chama de novo e atualiza state.
- Erro durante generate vira `errorMessage`.

**Commit:** `test(presentation): CompletionCodeController state transitions`

---

## Verificação Final

```bash
# Roda local OU via Codemagic / GitHub Actions
cd instrutor_app
flutter analyze
flutter test
flutter build apk --debug   # smoke test
```

**Sanity checks manuais:**
1. Splash → boot-check não trava (≤500ms extra).
2. Agenda: tap em booking confirmed → bottom sheet com 3 ações.
3. "Concluir aula" → tela de código com countdown decrescente.
4. "Reportar problema" → sheet → reason + descrição → snack de sucesso.

---

## Execução

**Plan complete and saved to `docs/plans/2026-05-16-lesson-validation-plan.md`. Two execution options:**

**1. Subagent-Driven (este chat)** — dispatch fresh subagent per task com 2-stage code review entre tarefas. Mais lento porém mais seguro pra tarefas grandes.

**2. Batch Execution (este chat)** — executa 3 tarefas por vez com checkpoint. Mais rápido. Recomendado pra esse plano (todas as tarefas são pequenas e bem definidas).

**Qual abordagem você prefere?**
