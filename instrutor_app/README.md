# CNHhj — App do Instrutor

Aplicativo Flutter para instrutores de aulas práticas de CNH oferecerem suas aulas, gerirem agenda e conversarem com alunos.

## Pré-requisitos (futuro — quando for rodar)

- Flutter SDK ≥ 3.22
- Android Studio + Android SDK (para Android) ou Xcode (para iOS, requer Mac)
- Copiar `.env.example` para `.env` e preencher se quiser conectar no Supabase real

## Estrutura

```
lib/
├── main.dart                    Entry point
├── app.dart                     Widget raiz (MaterialApp + tema + router)
├── core/
│   ├── theme/                   Cores, tipografia, ThemeData
│   ├── router/                  Rotas (go_router)
│   ├── config/                  Configs e env
│   └── constants/               Strings, dimensões, etc.
├── data/
│   ├── models/                  Modelos Dart (Profile, Instructor, Booking, ...)
│   └── services/                Interfaces abstratas + impl. Mock e Supabase
├── features/
│   ├── auth/                    Login, cadastro
│   ├── onboarding/              Wizard de 7 passos do cadastro do instrutor
│   ├── home/                    Shell com bottom nav
│   ├── lesson/                  Configurar disponibilidade (aba AULA)
│   ├── bookings/                Solicitações + agenda
│   ├── financial/               Histórico financeiro
│   ├── chat/                    Conversas em tempo real
│   ├── reviews/                 Avaliações recebidas
│   └── settings/                Aba MAIS (perfil, guia, suporte, sair)
└── shared/
    └── widgets/                 Widgets reutilizáveis (botões, inputs, cards)
```

## Modo de execução

Controlado pela variável `APP_MODE` no `.env`:

- `APP_MODE=mock` → usa dados em memória (sem necessidade de Supabase)
- `APP_MODE=supabase` → conecta ao backend Supabase real

Permite desenvolver o app inteiro localmente antes de configurar o Supabase.

## Padrões de código

- **Estado**: Riverpod (`flutter_riverpod`)
- **Navegação**: `go_router`
- **Lint**: `flutter_lints` com regras adicionais em `analysis_options.yaml`
- **Idioma da UI**: pt-BR (sem internacionalização no MVP)
