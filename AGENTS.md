# Guia de Agentes do LifeRPG

## Contexto Primeiro Pela Documentação

Antes de alterar comportamento, leia [docs/project-guide.md](docs/project-guide.md). Esse arquivo é a fonte mantida de contexto para:

- Regras de negócio de missões, XP, níveis, skills, energia, recompensas, inventário, backup e resets.
- Sistema de design e padrões de UI usados pelo app Flutter.
- Limites de arquitetura e arquivos que normalmente são donos de cada responsabilidade.
- Expectativas de teste e áreas de maior risco.

Use este guia para não precisar redescobrir as regras do projeto em toda sessão. Se o código e a documentação divergirem, confie no código e atualize a documentação na mesma mudança.

Linha de raciocínio do produto:

- Missões são tarefas.
- Completar missões concede XP, Moedas/RP e pode conceder recompensas.
- Skills recebem XP quando missões vinculadas são completadas.
- Recompensas são itens usáveis comprados na loja ou dropados por missões.
- Inventário é onde recompensas obtidas são consumidas.
- Energia é exibida como HP e varia pelo ciclo acordado/dormindo ou por ajuste manual.

## Regra Para Consultar Documentação Atual

Use o CLI `ctx7` para buscar documentação atual sempre que o usuário perguntar sobre uma biblioteca, framework, SDK, API, ferramenta de CLI ou serviço de nuvem, incluindo Flutter, Dart, Provider, sqflite, shared_preferences, file_picker, share_plus ou qualquer outra dependência.

Não use para refatoração, scripts escritos do zero, depuração de regra de negócio, revisão de código ou conceitos gerais de programação.

Passos:

1. Resolva a biblioteca:

   ```bash
   npx ctx7@latest library <name> "<pergunta completa do usuário>"
   ```

2. Escolha o melhor resultado `/org/project` por nome exato, relevância da descrição, quantidade de exemplos, reputação da fonte e pontuação de benchmark.
3. Busque a documentação:

   ```bash
   npx ctx7@latest docs <libraryId> "<pergunta completa do usuário>"
   ```

Não rode mais de 3 comandos `ctx7` por pergunta. Se o `ctx7` falhar por quota, informe o usuário e sugira `npx ctx7@latest login` ou configurar `CONTEXT7_API_KEY`.

## Comandos do Projeto

- Instalar dependências: `flutter pub get`
- Análise estática: `flutter analyze`
- Testes: `flutter test`
- Teste focado: `flutter test test/path/to_test.dart`
- Rodar o app: `flutter run`

## Regras de Trabalho

- Mantenha regras de negócio em services, repositories, providers ou core utils. A UI deve chamar APIs existentes em vez de duplicar cálculos.
- Adicione ou atualize testes focados ao mudar recompensas, XP, recorrência, energia, inventário, migrações, backup ou filtros.
- Preserve a semântica dos dados do usuário. Migrações de banco devem ser aditivas ou migrar dados antigos explicitamente.
- Prefira constantes de `AppTheme` e widgets compartilhados existentes antes de criar novos estilos visuais.
