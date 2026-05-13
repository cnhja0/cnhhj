# Codemagic — Setup passo a passo

Guia para gerar APKs do CNHhj na nuvem sem instalar Flutter localmente.

## Visão geral do fluxo

```
seu PC                  GitHub                   Codemagic
  │                        │                         │
  │  git push ──────────────►                        │
  │                        │  webhook ────────────────►
  │                        │                         │  builda APK (~5-10 min)
  │                        │                         │
  │                        │                         │
  ◄────────────────────────────────────── e-mail com APK
  │
  │  instalar APK no celular Android
  ▼
```

Cada `git push` dispara um build novo automaticamente. Você recebe o APK por e-mail e instala no Android via "instalar de fontes desconhecidas".

---

## Passo 1: Criar conta GitHub (5 min)

Se você já tem, pode pular.

1. Vá em [github.com/signup](https://github.com/signup)
2. Crie a conta com o e-mail `cnh.ja0@gmail.com`
3. Verifique o e-mail
4. Anote o seu username (vamos chamar de `SEU_USER`)

## Passo 2: Criar repositório no GitHub (3 min)

1. Logado, clique no `+` no canto superior direito → **New repository**
2. Nome: `cnhhj` (ou outro nome qualquer)
3. **Visibilidade**: PRIVATE — porque o código tem lógica de negócio. Se preferir Public, fique à vontade
4. **NÃO marque** "Add a README" / "Add .gitignore" — já temos esses arquivos
5. Clique em **Create repository**
6. Anote a URL que aparece (algo como `https://github.com/SEU_USER/cnhhj.git`)

## Passo 3: Subir o código para o GitHub (5 min)

No terminal do seu PC, dentro da pasta do projeto:

```powershell
# Inicializar git (se ainda não estiver inicializado)
git init

# Configurar seu nome e e-mail (só na primeira vez)
git config user.name "Seu Nome"
git config user.email "cnh.ja0@gmail.com"

# Adicionar todos os arquivos
git add .

# Criar primeiro commit
git commit -m "feat: estrutura inicial do app CNHhj Instrutor"

# Conectar com o repositório GitHub (use a URL anotada no passo 2)
git remote add origin https://github.com/SEU_USER/cnhhj.git

# Renomear branch principal para main (padrão moderno)
git branch -M main

# Enviar para o GitHub
git push -u origin main
```

> Se for a primeira vez que você usa git com o GitHub, ele vai pedir suas credenciais. Use um **Personal Access Token** em vez da senha:
>
> - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
> - Marque o escopo `repo`
> - Copie o token e use como "senha" quando o git pedir

## Passo 4: Criar conta no Codemagic (3 min)

1. Vá em [codemagic.io](https://codemagic.io/signup)
2. **Login com GitHub** (mais fácil — autoriza acesso aos repos automaticamente)
3. Aceite os termos

## Passo 5: Conectar o repositório (2 min)

1. No dashboard do Codemagic, clique em **Add application**
2. Escolha **GitHub** → autorize se for a primeira vez
3. Selecione o repositório `cnhhj`
4. Tipo de projeto: **Flutter App** → Codemagic vai detectar o `codemagic.yaml` automaticamente

## Passo 6: Primeiro build (5-10 min)

1. Na página do app no Codemagic, clique em **Start new build**
2. Branch: `main`
3. Workflow: `CNHhj Instrutor — Android Debug APK`
4. Clique em **Start build**

O Codemagic vai:
- Clonar o repo
- Rodar `flutter create .` (gera as pastas Android/iOS que não comitamos)
- `flutter pub get`
- `flutter analyze` (avisa de problemas mas não bloqueia)
- `flutter build apk --debug`
- Subir o APK como artifact e te enviar por e-mail

Acompanhe os logs na própria página do build.

## Passo 7: Instalar APK no celular Android (2 min)

1. Quando o build terminar com sucesso, você recebe um e-mail com link de download
2. Abra o e-mail **no celular Android**
3. Toque no link `app-debug.apk` → baixa
4. Toque no APK baixado → o Android pergunta se você quer **permitir instalação de fontes desconhecidas**
5. Vá em Configurações → Apps → permitir o navegador a instalar APKs
6. Volte e toque no APK novamente → instala

Pronto — você tem o **CNHhj Instrutor rodando no seu celular!** 🎉

---

## Builds futuros — automáticos

A partir de agora, toda vez que você (ou eu) der `git push` para a branch `main` ou `develop`, o Codemagic vai rodar o workflow automaticamente e te mandar o APK novo por e-mail.

## Quando algo der errado

| Sintoma | O que fazer |
|---------|-------------|
| Build falha em `flutter create` | Verificar se o `pubspec.yaml` tem `name: cnhhj_instrutor` (deve estar OK) |
| Build falha em `flutter pub get` | Provavelmente uma versão de pacote conflitando — me avise e eu ajusto o `pubspec.yaml` |
| Build falha em `flutter analyze` | Não bloqueia porque está com `|| echo` — só avisa |
| Build falha em `flutter build apk` | Olha o log do Codemagic e me manda — geralmente é configuração de Android (signing, gradle) |
| APK não instala no celular | Permitir "fontes desconhecidas" nas configs do Android |

## Custos

- **Codemagic free tier**: 500 minutos de build/mês. Um build de debug leva ~5-8 min. Dá pra fazer ~60 builds/mês de graça.
- **GitHub**: gratuito para repos privados (com limites generosos para projetos pessoais).
- **Custo zero** para começar e validar.

## Próximos passos depois desse setup

1. Criar APK release com **assinatura própria** (quando for publicar na Play Store)
2. Configurar **deploy automático** para Play Store Internal Testing
3. Adicionar workflow de iOS (precisa de conta Apple Developer + Mac)
