# Contributing

Este documento concentra as informações de desenvolvimento que antes ficavam no README. Para regras de produto e detalhes internos, leia também [docs/project-guide.md](docs/project-guide.md) antes de mudar comportamento.

## Setup Local

1. Instale o Flutter SDK compatível com `environment.sdk` em [pubspec.yaml](pubspec.yaml). O repositório inclui `.fvmrc`; se você usa FVM, rode os comandos como `fvm flutter ...`.
2. Configure a toolchain da plataforma alvo, como Android SDK, Xcode, Linux desktop, Windows desktop, macOS desktop ou Chrome.
3. Instale dependências:

```bash
flutter pub get
```

4. Verifique os dispositivos disponíveis:

```bash
flutter devices
```

5. Rode o app:

```bash
flutter run
```

Use `-d <device>` para escolher um destino específico, por exemplo `linux`, `android`, `ios`, `macos`, `windows` ou `chrome`.

## Comandos de Qualidade

Rode a análise estática:

```bash
flutter analyze
```

Rode todos os testes:

```bash
flutter test
```

Rode um teste focado:

```bash
flutter test test/path/to_test.dart
```

## Builds

Android:

```bash
flutter build apk --release
flutter build appbundle --release
```

iOS, apenas em macOS com Xcode configurado:

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

Cada build exige a toolchain nativa da plataforma. Se o destino não aparecer em `flutter devices`, revise a instalação da plataforma antes de investigar o app.

## Organização do Projeto

- `lib/ui`: telas e widgets. Deve compor estado e chamar APIs existentes.
- `lib/providers`: estado com `ChangeNotifier` e operações expostas para a aplicação.
- `lib/services`: fluxos de negócio transacionais que envolvem múltiplas tabelas ou agregados.
- `lib/data/repositories`: acesso ao banco para cada agregado.
- `lib/data/models`: modelos com `toMap`, `fromMap` e `copyWith`.
- `lib/data/database/database_helper.dart`: schema, migrações, backup, restore e resets.
- `lib/core/utils`: calculadoras puras e auxiliares de negócio.
- `lib/core/theme/app_theme.dart`: tokens de design e tema Material.

## Regras de Desenvolvimento

- Preserve regras de negócio fora da UI. A UI deve chamar providers, services, repositories ou utils existentes.
- Ao mudar XP, missões, recorrência, recompensas, inventário, energia, backup ou migrações, adicione ou atualize testes focados.
- Preserve dados do usuário. Migrações de banco devem ser aditivas ou migrar dados antigos explicitamente.
- Se o código e a documentação divergirem, confie no código e atualize a documentação na mesma mudança.
- Prefira constantes de `AppTheme` e widgets compartilhados antes de criar novos estilos visuais.
- Consulte documentação atual das bibliotecas com `ctx7` quando alterar uso de Flutter, Dart, Provider, sqflite, shared_preferences, file_picker, share_plus ou outras dependências.

## Banco de Dados

O banco SQLite é criado automaticamente na primeira execução. Em mobile, o app usa o caminho padrão de `sqflite`; em desktop, usa `sqflite_common_ffi`.

Mudanças de schema devem atualizar:

- Criação inicial em `DatabaseHelper`.
- Caminho de migração em `_onUpgrade`.
- Modelos, repositories e testes relacionados.
- [docs/project-guide.md](docs/project-guide.md), quando a regra de negócio ou schema documentado mudar.

## Fluxo Sugerido

1. Leia [docs/project-guide.md](docs/project-guide.md) para entender as regras da área alterada.
2. Faça mudanças pequenas e focadas.
3. Rode `flutter analyze`.
4. Rode `flutter test` ou um teste focado quando a mudança for localizada.
5. Atualize README, docs ou SECURITY quando o comportamento, setup ou processo mudar.

## Licença

Ao contribuir, você concorda que sua contribuição será disponibilizada sob a licença MIT do projeto.
