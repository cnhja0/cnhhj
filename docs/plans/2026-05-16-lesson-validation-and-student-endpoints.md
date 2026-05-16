# Validação de Aula + Endpoints do App do Aluno

**Data:** 2026-05-16
**Status:** Design aprovado, aguardando plano de implementação
**Brainstorm pelo:** Henrique + Claude (skill: flutter-brainstorming)

## Overview

Duas peças interligadas:

1. **Validação de aula concluída** (P0 do feature de confiança). Instrutor gera código de 6 dígitos; aluno confirma no app dele. Auto-confirm em 24h. Janela de "Reportar problema" em 48h.
2. **Inventário de endpoints** que o app do aluno (Fase 2) vai consumir do backend compartilhado. Identifica o que JÁ existe nos repos, o que falta criar, e o que precisa ser ajustado.

## User Stories

### Instrutor
- Como instrutor, ao terminar uma aula presencial, quero gerar um código de 6 dígitos para que o aluno confirme que a aula aconteceu.
- Como instrutor, quero ver o status da aula transicionar para "Concluída" assim que o aluno digitar o código (ou após 24h sem dispute).
- Como instrutor, se o aluno não comparecer, quero marcar como "não compareceu" pra não ser penalizado em rating.

### Aluno (Fase 2 — esboço)
- Como aluno, quero buscar instrutores na minha região por categoria CNH e faixa de preço.
- Como aluno, quero ver perfil completo do instrutor (carro, fotos, bio, reviews, rating) antes de agendar.
- Como aluno, quero solicitar uma aula em horário disponível na grade do instrutor.
- Como aluno, ao terminar a aula, quero digitar o código que o instrutor me passou para confirmar.
- Como aluno, se algo dá errado, quero reportar o problema sem precisar avaliar uma aula que não aconteceu.

## Decisão de design — Modelo de validação

**Modelo escolhido:** Híbrido **A + D** — código do instrutor → digitação do aluno, com auto-confirm de 24h e janela de dispute de 48h.

| Modelo | Quem inicia | Considerado? | Decisão |
|---|---|---|---|
| A. Instrutor → Aluno (código) | Instrutor | ✅ | **Escolhido** |
| B. Aluno → Instrutor (código) | Aluno | ✅ | Preterido: aluno pode se recusar e deixar instrutor sem comprovação |
| C. Confirmação mútua simultânea | Ambos | ✅ | Preterido: fricção alta, depende de rede em ambos os lados |
| D. Auto-confirm + dispute window | Sistema | ✅ | **Combinado com A** como fallback |
| E. Foto/video proof | Manual | ❌ | Privacidade; fora do MVP |
| F. Geolocalização obrigatória | Sistema | ❌ | GPS urbano falha muito; privacidade. **Opcional como bônus de trust score** no futuro |

### Fluxo escolhido

```
[instrutor] termina aula
   ↓
[instrutor app] toca "Concluir aula" no booking
   ↓
[backend] gera código 6 dígitos (válido 15 min, 1 uso, vinculado ao booking)
   ↓
[instrutor app] mostra código grande + countdown
   ↓
[aluno app] recebe push "Confirme sua aula"
   ↓
[aluno] digita código
   ↓
[backend] valida: booking existe, code matches, não expirou, não foi usado,
                 booking.student_id == auth.userId, booking.status == confirmed
   ↓
   ✅ booking → completed
   ✅ abre janela de avaliação pros dois lados
   ✅ trava o lesson_code (used_at = now)

Caminhos alternativos:
- 24h após scheduledEnd sem confirmação → auto-completed
- Em até 48h após scheduledEnd, qualquer lado abre "Reportar problema" →
    booking → disputed → bloqueia auto-confirm, exige mediação
- Instrutor marca "Não compareceu" → booking → no_show
```

### UX terminology

- Botão para "informar que algo deu errado": **"Reportar problema"** (não "Disputar" / não "Recorrer")
- Botão pra finalizar aula: **"Concluir aula"** (já existe na agenda)

## Inventário de endpoints (aluno vai usar)

### Repositórios existentes — sem mudança

| Repo | Método | Quem usa |
|---|---|---|
| AuthRepository | signUp/signIn/signOut/restoreSession/currentProfile | aluno + instrutor (mesma API) |
| InstructorRepository | `getById(id)` | aluno vê perfil completo; instrutor edita próprio |
| AvailabilityRepository | `listForInstructor(id)` | aluno vê horários do instrutor |
| ReviewRepository | `listReceived(id)`, `create(...)` | aluno cria + lê; instrutor lê |
| ChatRepository | `listConversations`, `watchConversations`, `sendMessage`, `markAsRead` | ambos |
| NotificationRepository | `list`, `watch`, `markAsRead`, `create` | ambos |

### Endpoints faltando — precisa adicionar agora

| Repo | Método | Para quê | Prioridade |
|---|---|---|---|
| `InstructorRepository` | `search({city, state, category, minRating, maxPrice, transmission, vehicleType, ...})` | Vitrine do aluno | P0 |
| `BookingRepository` | `create({instructorId, studentId, scheduledStart, scheduledEnd, meetingPoint?, agreedPrice})` | Aluno solicita aula | P0 |
| `BookingRepository` | `listForStudent(studentId)` | Aluno vê histórico | P0 |
| `BookingRepository` | `generateCompletionCode(bookingId)` | Instrutor encerra aula | P0 (esse feature) |
| `BookingRepository` | `validateCompletionCode({bookingId, code, studentId})` | Aluno valida | P0 (esse feature) |
| `BookingRepository` | `reportIssue({bookingId, reporterId, reason, description?})` | Botão "Reportar problema" | P1 |
| `BookingRepository` | `autoCompleteIfDue()` | Cron / boot-check | P1 |
| `ChatRepository` | `startConversation({instructorId, studentId})` | Aluno inicia | P1 |

### Modelos novos

- `LessonCode` — `{id, bookingId, codeHash, expiresAt, usedAt?, generatedBy: instructorId, createdAt}`
- `BookingDispute` — `{id, bookingId, reporterId, reason, description?, status: pending|resolved|rejected, createdAt, resolvedAt?}`
- `InstructorSearchResult` — projeção leve pra vitrine (não traz fotos do veículo, documentos): `{id, fullName, avatarUrl, city, neighborhood, averageRating, totalReviews, vehicleType, vehicleBrand, vehicleModel, pricePerClass, categories}`

### Mudanças no schema (Supabase futuro)

- Tabela nova: `lesson_codes` (com TTL via cron Postgres ou check no app)
- Tabela nova: `booking_disputes`
- Campo no `bookings`: já temos `status`. Adicionar `completed_at`, `completed_by` (`student|auto|instructor`)

## Camadas Clean Architecture

```
lib/data/
├── models/
│   ├── lesson_code.dart                  ← NOVO
│   ├── booking_dispute.dart              ← NOVO
│   ├── instructor_search_result.dart     ← NOVO (projeção)
│   └── booking.dart                       ← edit: completedAt, completedBy
│
├── repositories/
│   ├── booking_repository.dart            ← edit: 5 métodos novos
│   ├── instructor_repository.dart         ← edit: search()
│   └── chat_repository.dart               ← edit: startConversation()
│
└── repositories/mock/
    ├── mock_booking_repository.dart       ← implementa novos métodos
    ├── mock_instructor_repository.dart    ← implementa search()
    └── mock_chat_repository.dart          ← implementa startConversation()
```

```
lib/features/
└── home/tabs/
    └── tab_schedule.dart                  ← edit: botão "Concluir aula" + modal de código
└── bookings/                              ← NOVO feature
    ├── completion_code_screen.dart        ← mostra código + countdown
    ├── completion_code_controller.dart    ← polling de status até validado
    └── report_issue_sheet.dart            ← bottom sheet de "Reportar problema"
```

## Fluxo de Estados — Booking

```
[criada pelo aluno: status=pending]
   │
   ├── instrutor aceita → status=confirmed
   │       │
   │       ├── aluno cancela → status=cancelled (cancelledBy=studentId)
   │       ├── instrutor cancela → status=cancelled (cancelledBy=instructorId)
   │       │
   │       └── chega ao scheduledEnd
   │              │
   │              ├── instrutor concluiu + aluno validou → status=completed
   │              ├── 24h após end sem confirmação → status=completed (auto)
   │              ├── instrutor marcou no-show → status=no_show
   │              └── alguém reportou problema → status=disputed
   │
   └── instrutor recusa → status=cancelled (cancelledBy=instructorId, reason)
```

## API Contract (esboço resumido)

```dart
// LessonCode model
class LessonCode {
  final String code;      // 6 dígitos
  final DateTime expiresAt;
}

abstract class BookingRepository {
  // ─── Já existe ─────────────────────────────────
  Future<List<Booking>> listForInstructor(String instructorId);
  Stream<List<Booking>> watchForInstructor(String instructorId);
  Future<List<Booking>> listByStatus(String instructorId, BookingStatus status);
  Future<Booking> updateStatus(
    String bookingId, {
    required BookingStatus status,
    String? cancellationReason,
    String? cancelledBy,
  });

  // ─── NOVO ──────────────────────────────────────
  Future<Booking> create({
    required String instructorId,
    required String studentId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    String? meetingPoint,
    String? notes,
    double? agreedPrice,
  });

  Future<List<Booking>> listForStudent(String studentId);

  Future<LessonCode> generateCompletionCode(String bookingId);

  Future<Booking> validateCompletionCode({
    required String bookingId,
    required String code,
  });

  Future<BookingDispute> reportIssue({
    required String bookingId,
    required String reporterId,
    required String reason,
    String? description,
  });

  /// Verifica todas as bookings confirmadas com scheduledEnd > 24h
  /// e marca como completed se ninguém disputou. Idempotente.
  Future<void> autoCompleteIfDue();
}
```

## Plano de testes (priority order)

### 1ª prioridade — Repository
- `MockBookingRepository.generateCompletionCode` retorna código 6 dígitos único.
- `validateCompletionCode` rejeita: expirado / já usado / código errado / booking não pertence ao student / booking não está confirmed.
- `autoCompleteIfDue` ignora bookings disputed, no_show, cancelled e bookings dentro da janela de 24h.
- `create` aceita só horários dentro da `WeeklyAvailability` do instrutor (cross-check).

### 2ª prioridade — State
- `CompletionCodeController` (instrutor): roda timer de countdown, troca pra "expired" após 15min sem validação.
- Observa stream do booking e fecha modal ao detectar `status == completed`.

### 3ª prioridade — Widget (opcional MVP)
- Bottom sheet "Reportar problema" valida campo "motivo" obrigatório.

## Dependências (pubspec.yaml)

Nada novo. Já temos:
- `flutter_riverpod`, `go_router`, `shared_preferences`, `intl`, `mask_text_input_formatter`

Se quisermos QR code no futuro (alternativa ao código de 6 dígitos):
- `qr_flutter` (renderiza QR)
- `mobile_scanner` (leitor)

## Decisões finais

| Decisão | Escolha | Implicação |
|---|---|---|
| **Geolocalização** | **P3** (backlog) | MVP sem GPS; mais simples e respeita privacidade. Adicionar quando houver volume de fraude. |
| **Foto pós-aula em dispute** | **Não obrigatória** | Manter dispute leve no MVP (só motivo + descrição). |
| **Janela de dispute** | **48h** após `scheduledEnd` | Equilibra defesa do usuário sem postergar pagamento (futuro). |
| **Auto-confirm** | **48h** após `scheduledEnd` | Coincide com fim da janela de dispute — passou as 48h sem dispute = vira completed automaticamente. |
| **Quem aciona auto-confirm** | **Cron no Supabase Postgres** (`pg_cron`) | Roda de hora em hora no backend. Independe de o instrutor abrir o app. Requer Supabase Pro (~$25/mês), mas só ativa quando migrarmos do mock. **No mock, simular via boot-check** apenas pra demo. |

### Implicação técnica do cron Postgres

```sql
-- Migration futura
SELECT cron.schedule(
  'auto-complete-bookings',
  '0 * * * *',  -- a cada hora cheia
  $$
    UPDATE bookings
    SET status = 'completed',
        completed_at = NOW(),
        completed_by = 'auto'
    WHERE status = 'confirmed'
      AND scheduled_end < NOW() - INTERVAL '48 hours'
      AND NOT EXISTS (
        SELECT 1 FROM booking_disputes
        WHERE booking_id = bookings.id
          AND status = 'pending'
      )
  $$
);
```

No mock atual: `BookingRepository.autoCompleteIfDue()` é chamado no boot do app (no `SplashScreen` após `restoreSession`, antes de redirecionar). Quando migrar pra Supabase, o método vira no-op no client (o cron cuida) — assinatura preservada pra não quebrar UI.

## Próximo passo

Invocar **flutter-planning** pra detalhar o plano de implementação em tarefas executáveis seguindo a ordem Domain → Data → Presentation.
