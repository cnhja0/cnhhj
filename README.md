# CNHhj

> Plataforma mobile que conecta **instrutores de aula prática de CNH** com **alunos em processo de habilitação**.

[![Stack](https://img.shields.io/badge/mobile-Flutter-02569B)](https://flutter.dev) [![Stack](https://img.shields.io/badge/backend-Supabase-3ECF8E)](https://supabase.com)

## Sobre o produto

No Brasil, quem está tirando a CNH é obrigado a cumprir uma carga horária mínima de aulas práticas. Hoje o aluno depende da autoescola ou conhece um instrutor por indicação, sem visibilidade de preço, disponibilidade ou reputação. O CNHhj resolve isso conectando instrutores independentes diretamente aos alunos.

## Escopo deste MVP

**Lançamento focado em Guarulhos/SP**. Tudo neste repositório se refere ao MVP — funcionalidades de longo prazo (autoescolas, clínicas de exame, painel admin web, integração de pagamentos) estão fora do escopo desta fase.

| Componente | Estado |
|------------|--------|
| App do Instrutor (Flutter) | Em desenvolvimento ← prioridade atual |
| App do Aluno (Flutter) | Próximo |
| Backend Supabase | Schema definido, integração depois |

**Premissas do MVP:**
- Uso **gratuito** para instrutores e alunos
- **Sem pagamento dentro do app** — aluno e instrutor combinam o valor e pagam via PIX por fora
- **Aprovação de cadastro automática** — as telas de "análise em processo" do design são mantidas visualmente, mas o status já vai aprovado por baixo dos panos (aprovação manual entra na fase paga)
- **Sem markup/comissão** — instrutor define o preço, aluno vê o mesmo valor

## Visão de longo prazo (fora do MVP)

```
                  ┌───────────────────────────────┐
                  │       Backend Supabase        │
                  │   (PostgreSQL + Auth + ...)   │
                  └───────────────┬───────────────┘
                                  │
        ┌─────────────────┬───────┴───────┬─────────────────┐
        │                 │               │                 │
   ┌────▼────┐      ┌─────▼────┐    ┌─────▼──────┐   ┌──────▼──────┐
   │ Instru- │      │  Aluno   │    │ Autoescola │   │   Clínicas  │
   │  tor    │      │          │    │   (web)    │   │    (web)    │
   │ Mobile  │      │  Mobile  │    │            │   │             │
   └─────────┘      └──────────┘    └────────────┘   └─────────────┘
        │                                                    │
        │                  ┌──────────────────┐              │
        └──────────────────┤  Painel Admin    ├──────────────┘
                           │      (web)       │
                           └──────────────────┘

   MVP — em construção   ◀ Fase 2+ — planejado, fora do escopo atual ▶
```

**Modelo de negócio (futuro)**: comissão de 20% sobre aulas e exames, plano VIP R$19,90/mês (primeiros 100), patrocínio para aparecer no topo.

## Stack técnica

- **Mobile**: Flutter (iOS + Android com base única de código)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Linguagem**: Dart (mobile) / SQL (banco)

## Identidade visual

| Cor | Hex | Uso |
|-----|-----|-----|
| Amarelo principal | `#FFD000` | Background principal, botões de destaque |
| Amarelo xoxo claro | `#FFFAE6` | Fundos secundários |
| Amarelo xoxo escuro | `#FEF5C6` | Barra de progresso (pendente) |
| Verde sucesso | `#47C100` | Barra de progresso (concluído) |
| Preto | `#000000` | Textos, ícones, botões primários |
| Branco | `#FFFFFF` | Caixas de input |

## Estrutura do repositório

```
APP/
├── backend/supabase/    Migrações SQL, políticas de segurança e seed data
├── instrutor_app/       Aplicativo Flutter do instrutor (em construção)
├── aluno_app/           Aplicativo Flutter do aluno (próximo)
├── docs/                Arquitetura, decisões técnicas
│   └── design/          Excalidraw + Figma originais
└── README.md
```

## Funcionalidades do app do Instrutor (MVP)

Telas espelhadas a partir do design no Figma:

1. **Onboarding**: splash → login → cadastro (7 passos: dados pessoais, veículo, fotos, documentos) → análise em processo (auto-aprovação) → cadastro finalizado
2. **AULA**: definir área de atuação, valor, dias e horários disponíveis, com pré-visualização do card que o aluno vai ver
3. **SOLICITAÇÕES**: pedidos de aula pendentes para confirmar ou recusar
4. **AGENDA**: calendário visual de aulas confirmadas, coloridas por dia da semana
5. **FINANCEIRO**: histórico de aulas com valores combinados (sem integração de pagamento no MVP)
6. **MAIS**: perfil, guia/passo-a-passo, suporte, logout
7. **Chat**: conversa em tempo real com alunos (com opção de bloquear)
8. **Avaliações**: visualizar avaliações recebidas

## Estado do desenvolvimento

Em fase de **construção local** com dados mockados. A integração com o Supabase real será conectada depois, sem reescrever o código graças à camada de serviços abstraída.

## Como rodar (futuro — quando Flutter for instalado)

```bash
cd instrutor_app
flutter pub get
flutter run
```

## Documentação adicional

- [Arquitetura](docs/arquitetura.md) — visão técnica e fluxos
- [Design (Excalidraw + Figma)](docs/design/) — mockups e planejamento estratégico
