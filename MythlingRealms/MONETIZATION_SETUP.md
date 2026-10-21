# Monetização — configuração antes de publicar

A loja já possui suporte no código a dois Game Passes, mas os IDs permanecem em zero intencionalmente. Isso evita prompts falsos ou compras que não concedem benefícios.

## Game Pass 1: 2x Starshards
- Benefício: duplica as recompensas de Starshards recebidas ao coletar cristais e derrotar criaturas.
- O bônus de evento é aplicado junto do passe: durante o evento relacionado, o multiplicador total é 3x (1,5x do evento × 2x do passe).
- Não duplica recompensas de missões, recompensa diária ou roleta.

## Game Pass 2: VIP Aurora Stag
- Benefício: desbloqueia o mascote exclusivo Aurora Stag no inventário.
- O servidor verifica a posse do passe; o cliente não pode conceder o mascote sozinho.
- O mascote não aparece na tabela do ovo básico.

## Como ativar
1. No Creator Dashboard, crie os dois Game Passes associados à experiência Mythling Realms.
2. Configure e publique os preços que você realmente deseja cobrar; a interface não inventa nem exibe preços.
3. Copie o ID numérico de cada Game Pass.
4. No arquivo MythlingRealms/src/ServerScriptService/MythlingServer.server.lua, encontre GAMEPASS_IDS e substitua os zeros pelos IDs reais:
   - DoubleStarshards = 0
   - VIPCompanion = 0
5. Salve, publique e confirme que os dois passes estão marcados para venda.
6. Em uma versão de teste, compre cada passe com uma conta de teste e confirme os benefícios depois de entrar e sair novamente.

## Limites desta implementação
- Nenhum Game Pass está ativo até que seus IDs reais sejam configurados.
- Ainda não foram criados Developer Products consumíveis nem um fluxo de recibos para compras repetíveis de moeda. Não adicione Developer Products antes de implementar e testar ProcessReceipt com idempotência.
- A confirmação da compra usa o evento do MarketplaceService no servidor; a concessão de 2x é verificada pela cache de posse consultada no servidor e o mascote VIP é salvo no inventário.
- Compras e salvamento de dados precisam ser testados em uma experiência publicada/configurada. Não é possível concluir essa etapa apenas editando arquivos no GitHub.
