# Mythling Realms — Checklist de implementação e entrega

Este arquivo separa **implementação no código** de **verificação em execução**. Não marcar algo como testado sem rodar a experiência no Roblox Studio.

## Fase 1 — Auditoria e estrutura
- [x] Revisar a estrutura Rojo e os scripts principais.
- [x] Manter as alterações em branch de trabalho; não modificar diretamente `main`.
- [x] Separar a geometria gerada em `Workspace.MythlingRealmsRuntime`, sem destruir `Workspace.MythlingMap`.
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
- [ ] Testar todas as combinações de mascote equipado, duplicata, evolução e reentrada.

## Fase 4 — Ovos e probabilidades
- [x] Validar no servidor que os pesos dos ovos somam 100 e correspondem às raridades exibidas.
- [x] Fazer a loja ler as probabilidades do estado do servidor.
- [x] Incrementar o contador persistente de ovos abertos.
- [x] Manter o resultado autoritativo no servidor e a animação no cliente.
- [x] Remover a notificação genérica duplicada de sucesso.
- [ ] Testar resultado, animação, saldo insuficiente e salvamento da coleção no Studio.

## Fase 5 — Missões e campanha
- [x] Missões iniciais: coleta, nível, exploração e evolução.
- [x] Acrescentar objetivos de Emberfall, combate, ovos e nível 10.
- [x] Validar no servidor a missão ativa antes de liberar recompensa.
- [x] Registrar os contadores novos no salvamento.
- [ ] Percorrer a campanha inteira com uma conta limpa e conferir o equilíbrio das recompensas.

## Fase 6 — Combate
- [x] Criaturas geradas no servidor em Starfall Haven e Emberfall.
- [x] Ataques validados no servidor por jogador, alcance, personagem vivo e mundo desbloqueado.
- [x] Vida visível das criaturas, recompensas e XP do mascote equipado.
- [x] Reaparecimento de criaturas.
- [ ] Ajustar efeitos visuais, áudio, movimento/IA e balanceamento após testar no Studio.

## Fase 7 — Mundos e progressão
- [x] Starfall Haven como área inicial.
- [x] Emberfall com portal de ida e retorno.
- [x] Verificar desbloqueio de Emberfall no servidor tanto no portal quanto na coleta/combate.
- [x] Recompensas de cristais específicas por mundo.
- [ ] Fazer walkthrough de todas as rotas e verificar visualmente as colisões e os pontos de surgimento.

## Fase 8 — Eventos e roleta
- [x] Evento global por hora: Crystal Rush ou Creature Hunt.
- [x] Aplicar multiplicador de evento no servidor e exibir o evento no HUD.
- [x] Roleta diária de Starshards com pesos configurados no servidor e animação visual no cliente.
- [x] Impedir múltiplos giros diários por usuário, com base em dia UTC.
- [x] Recompensa diária com sequência de dias e limite de bônus.
- [ ] Verificar o comportamento entre servidores e na virada de hora/dia.

## Fase 9 — Multiplayer e cooperação
- [x] Cristais e criaturas compartilhados no mundo; recompensas validadas por servidor.
- [x] Tabelas de classificação do jogador existentes para moeda/nível.
- [ ] Testar dois ou mais jogadores disputando a mesma criatura/cristal.
- [ ] Sistema de grupos, trocas e presentes não implementado nesta entrega; definir regras anti-fraude antes de adicionar.

## Fase 10 — Monetização transparente
- [ ] Ainda não habilitada. Não há IDs reais de Game Passes ou Developer Products no repositório.
- [ ] Criar os produtos no Creator Dashboard, informar os IDs e implementar/testar compras e recibos antes de publicar.
- [ ] Exibir preço e conteúdo claramente, sem pressionar jogadores e sem prometer itens cujos IDs não estejam configurados.

## Fase 11 — Economia e desempenho
- [x] Recompensas, níveis e custo de upgrade permanecem calculados no servidor.
- [x] Limites contra spam nas ações principais e verificação de distância para coleta/combate.
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
- Os scripts são revisados estaticamente e **não foram compilados nem executados no Roblox Studio neste ambiente**.
- Os sistemas de eventos, roleta, recompensas e combate usam recompensas definidas no servidor; a interface é apenas visual.
- A versão principal `main` é preservada até a revisão do PR consolidado.
