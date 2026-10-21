# Resultado da remediação — LifeRPG

Data: 2026-10-21. Branch local: `feature/mvp-closeout`. Base auditada: `1cff6d2`. Implementação autorizada pelo usuário após a entrega da [auditoria](2026-10-21-project-audit.md) e do [plano](../superpowers/plans/2026-10-21-project-remediation.md). Não houve push nem deploy.

## Rastreabilidade

| Achados | Correção entregue | Evidência automatizada |
| --- | --- | --- |
| A01–A02 | Banco desktop em Application Support; migração por snapshot com original preservado; sandbox obrigatório de teste | Migração entre diretórios, destino existente preservado, banco real sentinela intocado |
| A03, A08–A09 | Backup formato 2/schema explícito, validação antes de DELETE, conversão legada identificável, snapshot transacional, ordenação de hierarquia | JSON inválido não apaga; ciclo rejeitado; hierarquia própria restaurada; XP/histórico consistentes sob concorrência |
| A04 | Patches de perfil/energia e incrementos transacionais de XP/RP | Escritas concorrentes, perfil antigo e compra não perdem progresso |
| A05–A06 | Constructors seguros no browser, capability de importação, fallback opcional; configuração Windows de notificações | Testes de bootstrap/adaptador; build e startup Chromium |
| A07 | Gradle 8.14.6 com SHA oficial; SQLite/pdfrx atualizados; scan Pub/Gradle/Maven no CI | Wrapper executado sob Temurin21; OSV sobre lockfile; hashes dos assets Web |
| A10, A14 | XP+histórico de foco na mesma transação, chave de sessão idempotente e callback de refresh | Trigger de falha reverte XP; retry não duplica; timer atualiza provider |
| A11 | copyWith distingue omissão/null; duplicação sem ID; remoção de parent/datas/local | Testes de modelo, criação de nova identidade e movimento para raiz |
| A12–A13 | Recorrência respeita semanas elegíveis e avança atrasos longos, preservando horário/offset do lembrete | Intervalo biweekly, atraso 2.005 dias, mês/ano, bloqueio de segunda recompensa |
| A15, A26 | Perfil reativo sem sobrescrever edição; formulários aguardam persistência; editor salva dentro da tela; missão+skills+drops atômicos | Player tardio, dirty input, erro de disco sem pop, FK inválida sem missão parcial |
| A16–A19 | Preferências reais, permissão negada explícita, som por canal, reconciliação serializada e receivers Android | 8 regressões de lembretes; confirmação de configuração Windows; CI Android preparado |
| A20 | Barreira de operações, pausa de sessões, drain de writes antigos e reload de todos os caches antes de liberar UI | Concorrência durante reset; restore inválido; reset/restore real com todas as áreas preenchidas |
| A21 | Reserva exclusiva por importação, arquivo parcial e rename final; descarte de cópia nova após erro no insert | 40 streams homônimos mantêm 40 caminhos/bytes; interrupção não publica arquivo parcial |
| A22 | Início não espera o fim do áudio; repeat-all/one reinicia; erros tardios capturados; source em completion | Future controlada até stop, fila/repeat/shuffle, completion anterior ignorada |
| Riscos assíncronos confirmados | Token de consulta das notas; progresso PDF por patch, sem sobrescrever lastOpenedAt | Respostas A/B fora de ordem; página9 deixa de regredir para1 |
| A23–A25 | Linux com backend real e libmpv do sistema; Windows WinRT; entitlements macOS; release Android exige identidade/chave externa | Decode WAV Linux real, plists analisados, CI de plataformas e validação de credenciais no Gradle |
| A27–A28 | Curva triangular compartilhada; barra XP/24h efetivos; controles sem efeito retirados | Limites de nível, comparação de skills, HP preservado ao ocultar XP, telas de settings |
| A29 | SDK/actions fixados; lockfile; análise/testes, scan, builds por SO e smoke de startup | Workflow versionado; execução remota continua pendente até envio autorizado |

## Decisões de implementação

- Trabalhar no checkout já auditado preservou o estado local do usuário. A pinagem FVM 3.44.2 e compatibilidade `SizeTransition` existentes foram incorporadas; VS Code e milhares de SVGs fora do escopo permaneceram sem stage. Custo: não houve isolamento de worktree; staging e revisão foram por escopo.
- Preservar o ID de desenvolvimento Android e exigir ID/certificado externos no release evita inventar a identidade de distribuição. Custo: o proprietário ainda precisa configurar as credenciais e preservar as de instalações existentes.
- Manter o overflow de calendário do Dart: recorrência mensal de 31/01 continua em 03/03. Custo: não foi criada uma política de “último dia do mês”.
- Preservar mídia no reset/restore evita invalidar backups que referenciam esses arquivos. Custo: arquivos sem referência podem ocupar espaço; limpeza destrutiva precisa de fluxo explícito separado.
- Retirar controles de efeitos sonoros/início da semana e calendário sem propósito. Chaves antigas continuam compatíveis. Custo: os controles só devem voltar quando houver comportamento implementado.

## Limites e validação externa necessária

- O SDK Android configurado nesta máquina não existe. Não houve build APK local, manifesto mesclado, entrega de lembrete ou reboot em dispositivo.
- Windows/macOS/iOS precisam dos respectivos runners/dispositivos: build, startup, reprodução/codecs, GPS, sandbox, permissão negada e assinatura de release. CI preparado não significa CI executado.
- O scan OSV cobre versões Pub resolvidas e Gradle; o grafo Maven exige executar o job Android. Não cobre automaticamente parsers binários nem bibliotecas do SO.
- PDFium permanece na revisão upstream `chromium/7811` na linha compatível. Hashes Linux foram inventariados; mapeamento completo de advisories/build flags/artefatos por SO continua pendente. Nenhum exploit foi demonstrado. Não é correto afirmar “zero CVEs no aplicativo”.
- O pacote de áudio Windows que baixava binários de 2023 foi removido. WinRT usa os codecs do SO. Linux utiliza libmpv/FFmpeg mantidos pelo gerenciador do sistema; atualizações desses componentes são parte da manutenção do ambiente.
- Backup JSON contém dados e metadados, sem transportar PDFs/áudios, avatares externos e preferências. Um pacote portátil com anexos precisa de exportação/importação própria, mapeamento de caminhos e verificações de integridade; não foi prometido pelo formato atual.
- Os 39 SVGs distribuídos foram associados a autores por geometria exata e receberam créditos no app e [notices](../../THIRD_PARTY_NOTICES.md). O arquivo completo local de milhares de ícones não integra o manifest nem este conjunto de commits.

## Verificação final

Resultados finais e revisão independente serão registrados abaixo após a conclusão dos comandos em andamento.
