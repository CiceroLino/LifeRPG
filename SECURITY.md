# Security Policy

## Supported Versions

LifeRPG ainda não mantém múltiplas linhas de release. Correções de segurança são aplicadas na branch principal e, quando houver releases públicas, na versão mais recente.

| Branch or version | Security support |
| --- | --- |
| `main` | Supported |
| Latest public release | Supported |
| Older snapshots, forks or local builds | Best effort |

## Reporting a Vulnerability

Relate vulnerabilidades abrindo uma issue privada ou, se isso não estiver disponível, uma issue pública com o mínimo de detalhe necessário para iniciar contato. Evite publicar payloads completos, dados pessoais, arquivos de banco ou passos exploráveis em ambientes reais.

Inclua, quando possível:

- Versão, commit ou branch afetada.
- Plataforma afetada, como Android, iOS, web, Linux, Windows ou macOS.
- Resumo do impacto.
- Passos de reprodução em ambiente local ou dados anonimizados.
- Evidências relevantes, como logs sem segredos.

## Handling

O objetivo é confirmar o recebimento em até 7 dias. Se a vulnerabilidade for válida, a correção deve priorizar preservação de dados locais do usuário e compatibilidade com backups existentes.

Quando uma correção estiver disponível, o reporte público deve descrever impacto, versões afetadas e orientação de atualização sem divulgar detalhes exploráveis desnecessários.

## Scope

Estão no escopo:

- Vazamento ou corrupção de dados locais do usuário.
- Falhas em backup, restore, importação ou exportação.
- Problemas com arquivos importados, como PDFs e áudios.
- Exposição indevida por notificações, storage local ou permissões de plataforma.

Fora de escopo:

- Problemas que exigem acesso físico completo ao dispositivo desbloqueado sem outro impacto demonstrável.
- Vulnerabilidades em dependências sem impacto reproduzível no LifeRPG.
- Relatos sem informação suficiente para reprodução ou triagem.
