# Arquitetura — CNHhj

## Visão de longo prazo (referência — NÃO é o MVP)

A plataforma final é multi-sided com 4 perfis de usuário e 5 clientes:

```
┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│  Instrutor Mobile │  │   Aluno Mobile    │  │ Autoescola (Web)  │  │  Clínica (Web)    │
│     (Flutter)     │  │     (Flutter)     │  │    (Next.js)      │  │    (Next.js)      │
└─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘
          │                      │                      │                      │
          └──────────────────────┼──────────────────────┼──────────────────────┘
                                 │                      │
                          ┌──────▼──────┐        ┌──────▼──────┐
                          │   Backend   │        │ Painel Admin│
                          │  Supabase   │◀───────│   (Next.js) │
                          └─────────────┘        └─────────────┘
```

## Escopo deste documento: **MVP**

```
┌───────────────────┐         ┌───────────────────┐
│  Instrutor Mobile │         │   Aluno Mobile    │
│     (Flutter)     │         │     (Flutter)     │
└─────────┬─────────┘         └─────────┬─────────┘
          │                             │
          │       HTTPS + WebSocket     │
          └──────────────┬──────────────┘
                         │
                ┌────────▼────────┐
                │    Supabase     │
                │                 │
                │  ├─ Auth        │  Login email/senha + Google OAuth
                │  ├─ PostgreSQL  │  Schema em backend/supabase/migrations
                │  ├─ Storage     │  Fotos: perfil, veículo, CNH, certificado DETRAN
                │  └─ Realtime    │  Chat em tempo real e notificações in-app
                └─────────────────┘
```

## Princípios arquiteturais

1. **Camada de serviços abstraída**: o app Flutter conversa com `interfaces` (abstract classes) em vez de chamar o Supabase diretamente. No início, há uma implementação mockada (dados em memória) que será substituída por uma implementação Supabase quando o backend estiver pronto.

2. **Feature-first**: o código é organizado por feature de produto (auth, onboarding, schedule, bookings, chat, etc.) e não por camada técnica. Cada feature contém UI, lógica e modelos próprios.

3. **Modelos espelhando o banco**: os modelos Dart (`Profile`, `Instructor`, `Booking`, etc.) refletem 1:1 as tabelas do PostgreSQL.

4. **Row Level Security (RLS) no banco**: autorização garantida no PostgreSQL via políticas, não apenas no app. Mesmo um cliente comprometido não consegue ler/escrever dados de outro usuário.

5. **Aprovação automática no MVP**: o fluxo de "análise em processo" do design existe visualmente, mas o status no banco já é gravado como `approved`. Quando entrar na fase paga, basta mudar o trigger de auto-aprovação para `pending` e construir o painel admin.

## Decisões importantes do MVP

| Decisão | Escolha | Razão |
|---------|---------|-------|
| Pagamento | Fora do app (PIX direto) | Reduz complexidade e custo; valida o conceito antes de integrar gateway |
| Comissão / markup | Sem comissão no MVP | Modelo de monetização entra na fase paga |
| Aprovação de cadastro | Automática | Telas de "análise" do design mantidas para coerência visual |
| Geolocalização | Cidade + bairro auto-declarados pelo instrutor | Sem mapa interativo no MVP — busca por proximidade vem depois |
| Notificações push | Apenas in-app (Supabase Realtime) | FCM/APNS são adições de fase 2 |
| Idioma | Português do Brasil apenas | Foco geográfico em Guarulhos |

## Fluxos principais

### 1. Cadastro do instrutor (7 passos)
1. Splash → Login → "Criar conta"
2. Coleta progressiva: dados pessoais (nome, CPF, data nascimento, sexo, e-mail, senha) → tipo de veículo (carro/moto/ambos) → modelo, ano, transmissão → foto frontal e traseira do veículo → foto de perfil → documentos (CNH + Certificado DETRAN)
3. Tela "Análise em Processo" exibida por ~2s (cosmética)
4. Backend grava `approval_status = 'approved'` automaticamente
5. Tela "Cadastro Finalizado!" com CTA "Configurar aula"
6. Vai para a aba AULA do app

### 2. Configuração de aula (definir oferta)
1. Instrutor define: área de atuação (bairro + cidade + UF), valor por aula, dias da semana e horários disponíveis
2. Visualiza pré-visualização do card que o aluno verá
3. Salva → fica disponível para alunos da região

### 3. Recebimento de solicitação
1. Aluno solicita aula em um slot disponível → bookings recebe linha com `status = 'pending'`
2. Realtime entrega notificação ao app do instrutor
3. Instrutor aceita ou recusa
4. Status muda para `confirmed` ou `cancelled`

### 4. Chat
1. Conversa criada automaticamente quando o aluno solicita aula pela primeira vez
2. Mensagens via Supabase Realtime (canal por `conversation_id`)
3. Bloqueio: instrutor pode bloquear aluno → no banco, marca `blocked_by_instructor = true` e impede novos envios

### 5. Avaliação (pós-aula)
1. Quando `bookings.status = 'completed'`, ambos podem avaliar
2. Aluno avalia instrutor (1-5 estrelas + comentário)
3. Instrutor avalia aluno (1-5 estrelas + comentário) — avaliação bidirecional
4. Médias recalculadas via trigger

## Decisões em aberto (a definir antes da fase 2)

- **Gateway de pagamento**: Pagar.me parece favorito pelo modelo de split, mas Mercado Pago também é candidato
- **Geocodificação**: Google Maps API (caro mas robusto) vs Mapbox (mais barato) vs Nominatim/OpenStreetMap (grátis mas limitado)
- **CI/CD**: Codemagic vs GitHub Actions para builds Android/iOS
- **Notificações push (fase 2)**: FCM (Google) é padrão da indústria
- **Stack do lado web (fase 2)**: Next.js confirmado no Excalidraw, conectando ao mesmo banco Supabase via SDK
