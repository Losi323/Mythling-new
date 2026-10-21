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

## Developer Products: pacotes consumíveis de Starshards

O código já inclui uma loja e um manipulador ProcessReceipt idempotente para três pacotes. Os IDs ficam em zero e as compras permanecem desativadas até você configurar produtos reais.

| Chave no código | Recompensa | ID inicial |
|---|---:|---:|
| StarshardSatchel | 500 Starshards | 0 |
| StarshardCache | 1.500 Starshards | 0 |
| StarshardVault | 5.000 Starshards | 0 |

1. No Creator Dashboard da mesma experiência, crie os três Developer Products e defina os preços que quiser cobrar.
2. Copie cada ID real e substitua o productId = 0 correspondente dentro de DEVELOPER_PRODUCTS no arquivo MythlingServer.server.lua.
3. Não repita IDs entre pacotes. O servidor valida IDs duplicados e valores de recompensa ao iniciar.
4. Mantenha MarketplaceService.ProcessReceipt centralizado nesse script. Não crie outro handler concorrente em outro Script da experiência.
5. Teste compras com uma conta de teste em um place publicado/configurado, incluindo fechar/reentrar durante a confirmação.

O recibo é marcado com o PurchaseId na mesma estrutura persistente do jogador e a compra só é confirmada ao Roblox depois que a gravação retorna sucesso. Se a gravação falhar, o handler retorna NotProcessedYet para que o Roblox possa tentar novamente. Qualquer novo Developer Product também precisa ser adicionado ao mapeamento do servidor; um ID não configurado não é concedido.

## Limites desta implementação
- Todos os Game Passes e Developer Products ficam inativos enquanto seus IDs forem zero.
- O preço não é codificado no HUD; a tela oficial de compra do Roblox apresenta o preço vigente antes de confirmar.
- A confirmação dos Game Passes usa eventos/consulta do MarketplaceService no servidor; o mascote VIP é salvo no inventário e 2x Starshards só aumenta recompensas de cristais e criaturas.
- Compras, recuperação de recibos e salvamento de dados ainda precisam ser testados em uma experiência publicada/configurada. Não é possível concluir essa etapa apenas editando arquivos no GitHub.
