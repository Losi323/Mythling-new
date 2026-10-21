# Mythling Realms — Checklist de implementação e entrega

Este arquivo separa **implementação no código** de **verificação em execução**. Não marcar algo como testado sem rodar a experiência no Roblox Studio.

## Fase 1 — Auditoria e estrutura
- [x] Revisar a estrutura Rojo e os scripts principais.
- [x] Manter as alterações em branch de trabalho; não modificar diretamente `main`.
- [x] Separar a geometria gerada em `Workspace.MythlingRealmsRuntime`, sem destruir `Workspace.MythlingMap`.
- [x] Tornar o puzzle Forgotten Ruins autossuficiente: criar geometria ausente e manter as runas por jogador, com recompensa guardada no DataStore principal.
- [x] Bloquear interações das runas/baú da Forgotten Ruins com validação de acesso no servidor até Emberfall ser desbloqueado.
- [ ] Conferir o mapa visualmente no Studio e reconciliar a pasta `MythlingMap/ForgottenRuins` com o layout final desejado.

## Fase 2 — Dados, remotes e persistência
- [x] Validar os tipos dos dados salvos e normalizar dados antigos.
- [x] Manter níveis, XP e evolução individuais por mascote.
- [x] Repetir tentativas de salvamento após falhas transitórias do DataStore.
- [x] Evitar inicializar dados de jogador que saiu durante o carregamento.
- [x] Aguardar operações de salvamento e aumentar a janela de encerramento.
- [ ] Testar migração de dados existentes e encerramento com vários jogadores no Studio com acesso à API habilitado.

## Fase 3 — Mascotes e coleção
- [x] Catálogo de mascotes, raridades, duplicatas, equipamento, nível e evolução.
- [x] Verificar propriedade antes de permitir equipar mascotes.
- [x] Mascote VIP Aurora Stag existe como entrada exclusiva à posse do passe VIP; permanece fora do ovo básico.
- [ ] Testar todas as combinações de mascote equipado, duplicata, evolução e reentrada.

## Fase 4 — Ovos e probabilidades
- [x] Validar no servidor que os pesos dos ovos somam 100 e correspondem às raridades exibidas.
- [x] Fazer a loja ler as probabilidades do estado do servidor.
- [x] Mostrar os requisitos de evolução e desbloqueio de Emberfall no menu, desativando ações quando não podem ser concluídas.
- [x] Incrementar o contador persistente de ovos abertos.
- [x] Manter o resultado autoritativo no servidor e a animação no cliente.
- [x] Remover a notificação genérica duplicada de sucesso.
- [ ] Testar resultado, animação, saldo insuficiente e salvamento da coleção no Studio.

## Fase 5 — Missões e campanha
- [x] Missões iniciais: coleta, nível, exploração e evolução.
- [x] Acrescentar objetivos de Emberfall, Forgotten Vault, combate, ovos e nível 10.
- [x] Persistir contadores de Emberfall, criatura derrotada, ovos abertos e recompensa única do vault.
- [x] Integrar o puzzle das três runas em Forgotten Ruins a uma recompensa autoritativa e persistente.
- [x] Validar no servidor a missão ativa antes de liberar recompensa.
- [x] Registrar os contadores novos no salvamento.
- [ ] Percorrer a campanha inteira com uma conta limpa e conferir o equilíbrio das recompensas.

## Fase 6 — Combate
- [x] Criaturas geradas no servidor em Starfall Haven e Emberfall.
- [x] Criaturas perseguem jogadores próximos no próprio mundo e atacam com dano/cooldown moderados.
- [x] Compartilhar a recompensa base de uma criatura entre contribuidores próximos; bônus por evento/passe é aplicado individualmente.
- [x] Ataques validados no servidor por jogador, alcance, personagem vivo e mundo desbloqueado.
- [x] Vida visível das criaturas, feedback de dano flutuante, brilho de acerto, recompensas e XP do mascote equipado.
- [x] Cristais flutuantes com luzes limitadas para reduzir o custo visual.
- [x] Reaparecimento de criaturas.
- [ ] Ajustar áudio, movimento/IA e balanceamento após testar no Studio.

## Fase 7 — Mundos e progressão
- [x] Starfall Haven como área inicial.
- [x] Emberfall com portal de ida e retorno.
- [x] Terceira área, Forgotten Ruins, com ponte iluminada, sinalização de trilha e puzzle de três runas.
- [x] Distinguir visualmente Starfall Haven e Emberfall com floresta, portais iluminados, pináculos de basalto e fissuras de lava.
- [x] Verificar desbloqueio de Emberfall no servidor tanto no portal quanto na coleta/combate.
- [x] Recompensas de cristais específicas por mundo.
- [ ] Fazer walkthrough de todas as rotas e verificar visualmente as colisões e os pontos de surgimento.

## Fase 8 — Eventos e roleta
- [x] Evento global por hora: Crystal Rush ou Creature Hunt.
- [x] Aplicar multiplicador de evento no servidor e exibir o evento no HUD.
- [x] Roleta diária de Starshards com pesos configurados no servidor e animação visual no cliente.
- [x] Impedir múltiplos giros diários por usuário, com base em dia UTC.
- [x] Recompensa diária com sequência de dias e limite de bônus.
- [x] Roleta diária com recompensas definidas exclusivamente pelo servidor.
- [ ] Verificar o comportamento entre servidores e na virada de hora/dia.

## Fase 9 — Multiplayer e cooperação
- [x] Cristais e criaturas compartilhados no mundo; recompensas validadas por servidor.
- [x] Tabelas de classificação do jogador existentes para moeda/nível.
- [x] Recompensas de combate compartilhadas proporcionalmente entre contribuidores próximos; leaderstats incluem cristais e criaturas derrotadas.
- [x] Contribuições e salvamentos de combate são agregados para evitar rajadas desnecessárias ao DataStore.
- [x] Sistema de grupo com até 4 jogadores, convites, aceitar/recusar, sair, expiração de convite e limpeza ao desconectar.
- [ ] Testar dois ou mais jogadores disputando a mesma criatura/cristal e entrando/saindo de grupos.
- [ ] Troca direta de mascotes e presentes não implementados; exigem inventário transacional e regras anti-fraude para evitar duplicação/perda.

## Fase 10 — Monetização transparente
- [x] Loja opcional com suporte a Game Pass de 2x Starshards e Game Pass VIP Aurora Stag.
- [x] Suporte a três pacotes consumíveis de Starshards com ProcessReceipt idempotente e PurchaseId salvo com os dados do jogador.
- [x] A compra usa a janela oficial do Roblox; o servidor valida a posse do passe e concede os benefícios.
- [x] Game Passes e Developer Products com ID zero ficam desativados; nenhum ID ou preço fictício foi inserido.
- [ ] Criar os passes/produtos no Creator Dashboard e preencher os IDs reais em GAMEPASS_IDS e DEVELOPER_PRODUCTS.
- [ ] Testar compra, cancelamento, reprocessamento de recibo, posse prévia e reentrada com conta de teste.

## Fase 11 — Economia e desempenho
- [x] Recompensas, níveis e custo de upgrade permanecem calculados no servidor.
- [x] Limites contra spam nas ações principais e verificação de distância para coleta/combate.
- [x] HUD de navegação ampliado para 7 áreas e dimensionado para janelas/dispositivos menores.
- [x] Recompensas de evento não se acumulam em cada reaparecimento de criatura.
- [ ] Fazer perfil de desempenho com muitos jogadores/partes e rebalancear a economia após observar dados reais.

## Fase 12 — Testes e regressões
- [ ] Não executados nesta entrega (conforme pedido para continuar sem pausar).
- [ ] Antes de publicar, testar: entrada/saída rápida, salvar/carregar, abertura de ovos, missões, evolução, desbloqueio de Emberfall, combate, roleta, recompensa diária, multiplayer e reconexão após erro de DataStore.

## Fase 13 — Publicação
- [ ] Abrir o projeto no Roblox Studio/Rojo e verificar erros do Output.
- [ ] Publicar uma versão de teste, habilitar DataStore em ambiente de teste e conferir permissões.
- [ ] Verificar spawn, dispositivos móveis, controles, textos, desempenho e conteúdo apropriado para a audiência.
- [ ] Fazer backup da publicação antes do lançamento público.

## Fase 14 — Pós-lançamento
- [ ] Acompanhar crashes, falhas de salvamento, retenção, conclusão de missões e economia.
- [ ] Corrigir bugs antes de adicionar conteúdo grande.
- [ ] Adicionar mundos, criaturas e eventos novos a partir dos dados de uso, sem prometer funcionalidades ainda não publicadas.

## Notas técnicas
- Os scripts foram revisados estaticamente, incluindo uma verificação de equilíbrio de delimitadores/blocos, mas **não foram compilados nem executados no Roblox Studio neste ambiente**.
- O bloqueio de salvamento para reconexão é local ao servidor; não implementa lease/lock distribuído entre servidores diferentes.
- A configuração comercial permanece pendente: todos os IDs de compra são zero até serem criados no Creator Dashboard.
- Os sistemas de eventos, roleta, recompensas e combate usam recompensas definidas no servidor; a interface é apenas visual.
- A versão principal `main` é preservada até a revisão do PR consolidado.
