# LifeRPG

LifeRPG é um aplicativo Flutter local-first que transforma tarefas reais em progresso de RPG.

No app, missões funcionam como tarefas, conclusões concedem XP e moedas/RP, skills evoluem conforme as missões vinculadas, recompensas podem ser compradas ou dropadas, e itens obtidos ficam no inventário para uso posterior. A energia do jogador é exibida como HP e pode ser ajustada manualmente ou calculada pelo ciclo acordado/dormindo.

O projeto também inclui Focus Quest/Pomodoro, notebooks locais, leitura de PDFs importados como tomes e uma tavern para biblioteca/player de áudio local.

## Documentação

- [CONTRIBUTING.md](CONTRIBUTING.md): setup, comandos, fluxo de contribuição e builds.
- [docs/project-guide.md](docs/project-guide.md): regras de produto, arquitetura, banco de dados e áreas de risco.
- [SECURITY.md](SECURITY.md): política para relatar vulnerabilidades.
- [LICENSE](LICENSE): licença MIT.

## Como Rodar

Requisitos:

- Flutter SDK compatível com o `pubspec.yaml`. O repositório inclui `.fvmrc`, então você pode usar `fvm flutter` se trabalha com FVM.
- Toolchain da plataforma que você quer executar, como Android SDK, Xcode, toolchain Linux, Windows ou macOS.

Instale as dependências:

```bash
flutter pub get
```

Rode o app:

```bash
flutter run
```

Escolha um dispositivo específico quando necessário:

```bash
flutter devices
flutter run -d linux
flutter run -d android
flutter run -d chrome
```

## Build

Android:

```bash
flutter build apk --release
flutter build appbundle --release
```

iOS, em macOS com Xcode configurado:

```bash
flutter build ipa --release
```

Web:

```bash
flutter build web --release
```

Desktop:

```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

Antes de publicar uma versão, rode:

```bash
flutter analyze
flutter test
```
