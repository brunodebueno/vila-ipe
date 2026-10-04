# Vila Ipê — Arquitetura e contrato entre módulos

Godot 4.7, GDScript tipado, **indentação com TAB**. Sem comentários óbvios; `##` só para docs de API. Textos visíveis em pt-BR.

## Núcleo (já pronto — não reescrever, só estender com cuidado)
| Arquivo | Papel |
|---|---|
| `scripts/autoload/event_bus.gd` | Sinais globais. **Pode-se acrescentar sinais no fim**, nunca renomear/remover. |
| `scripts/autoload/item_db.gd` (`ItemDB`) | `get_def(id) -> ItemDef`, `display_name(id)`, `ids_in_category(cat)`. Dados em `data/items.json`. |
| `scripts/autoload/game_state.gd` (`GameState`) | `inventory`, `coins`, `give(id,n)`, `add_coins`, `spend_coins`, `selected_slot`, `selected_item()`, `flags`, `stats`, `add_stat`, `ui_blocking`. |
| `scripts/core/inventory.gd` (`Inventory`) | slots 32 (primeiros 8 = hotbar): `add/remove/has/count/can_add/move_slot/to_array/from_array`, sinal `changed`. |
| `scripts/core/terrain_data.gd` / `world_const.gd` | grade 64x64, níveis de altura (0,5 m cada), tiles GRASS/SAND/DIRT/PATH. Água em `WorldConst.WATER_LEVEL`. |
| `scripts/world/prop_manager.gd` (`PropManager`) | árvores e prédios por célula: `plant_tree`, `remove_tree`, `place_building`, `is_blocked(cell)`, `can_plant`. |
| `scripts/world/prop_library.gd` (`PropLibrary`) | `PropLibrary.create(id) -> Node3D`. Usa `.glb` em `assets/models/<cat>/<id>.glb` se existir, senão modelo procedural. |
| `scripts/player/tool_controller.gd` (`ToolController`) | Usa o item selecionado: `register_tool(&"nome", Callable(cell, hit, item_id))`; `enabled`; `hover_cell`, `hover_hit`. Raycast pega camadas 1 (terreno) e 4 (interagíveis). |
| `scripts/core/game_context.gd` (`GameContext.current`) | referências: `main, terrain, props, player, rig, tools, day_night`. |

## Como plugar um sistema (regra de ouro)
**Crie `scripts/features/<nome>.gd` estendendo `Feature`** (`class_name` opcional). `main.gd` carrega todos os arquivos dessa pasta, em ordem alfabética, e chama `install(ctx: GameContext)`. **Ninguém edita `main.gd`.** A UI do módulo é construída dentro do próprio `install()` (CanvasLayer próprio).

## Convenções
- Camadas de física: 1 = terreno, 2 = jogador, 4 = interagíveis (Area3D/StaticBody3D de objetos clicáveis/“F”).
- Pegar item: `GameState.give(id, n)` (já emite `EventBus.item_gained`). Avisos ao jogador: `EventBus.notify.emit("texto", item_id_ou_&"")`.
- Janelas modais: `GameState.ui_blocking += 1` ao abrir e `-= 1` ao fechar (para ferramentas/câmera ignorarem o mouse). Modais devem fechar com `pause` (Esc) ou a tecla que os abriu.
- Dados novos (itens) vão em `data/items.json` (mesmo formato; ids únicos). **Itens novos: cada agente cria o próprio `data/items/<modulo>.json`** (`{"items":[…]}`, mesmo formato); ItemDB carrega todos. Não edite `data/items.json`.
- Ações do input em `scripts/core/input_setup.gd` (`inventory`=Tab/I, `crafting`=R, `interact`=F, `build_mode`=B, `quest_log`=J, `pause`=Esc, `use_tool`=mouse esq., `orbit`=mouse dir., hotbar_1..8). Acrescentar nova ação só no fim do dicionário.
- Layout de HUD (zonas, para não sobrepor): título topo-esq · relógio/pincel topo-dir · **hotbar centro-baixo** · **moedas e notificações (toasts) direita** · **rastreador de missão esquerda-meio** · prompts “[F] …” centro-baixo acima da hotbar · modais centralizados.
- Verificação: `cd C:/Dev/Games/VilaIpe && C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --import --quit` (parse errors) e `timeout 90 C:/Godot/Godot_v4.7.2-stable_win64_console.exe --path . -- --shot` (roda 2 s, salva foto em `%APPDATA%/Godot/app_userdata/VilaIpe/`, e fecha). Sempre use `timeout` — sem ele o jogo não fecha.
- Outros agentes trabalham ao mesmo tempo: **só edite os arquivos que são seus**. Se o erro estiver em arquivo de outro módulo, ignore e relate.

## Módulos e donos
| Módulo | Arquivos | Dono |
|---|---|---|
| UI base (hotbar, inventário, toasts, moedas) | `scripts/features/ui_*.gd`, `scripts/ui/*` (exceto `hud.gd` do núcleo — pode editar só para remover coisas) | agente UI |
| Coleta e natureza (árvores colhíveis, itens no chão, frutas, pedras, pesca, insetos) | `scripts/features/harvest_*.gd`, `fishing.gd`, `bugs.gd`, `scripts/world/pickup*.gd`, `prop_manager.gd` | agente Coleta |
| Construção (modo construção, placeáveis) | `scripts/features/build_*.gd`, `scripts/building/*`, `prop_library.gd` | agente Construção |
| Economia e crafting (loja, venda, bancada, receitas) | `scripts/features/economy_*.gd`, `crafting.gd`, `shop_*.gd`, `data/recipes.json` | agente Economia |
| Vila viva (NPCs, diálogos, missões, progressão, tutorial) | `scripts/features/village_*.gd`, `npc*.gd`, `quest*.gd`, `scripts/npc/*`, `data/npcs.json`, `data/quests.json` | agente Vila |
| Atmosfera (áudio procedural, clima, fauna ambiente, câmera de trailer) | `scripts/features/atmos_*.gd`, `audio_*.gd`, `weather.gd`, `scripts/atmosphere/*`, `day_night.gd` | agente Atmosfera |
| Save/Load, menu principal e pausa | `scripts/features/system_*.gd`, `scripts/system/*`, `scenes/main_menu.tscn` | agente Sistema |

## Documentação
Cada agente escreve `docs/sistemas/<modulo>.md` (API pública, sinais, itens/ids usados, teclas, o que falta) — curto e atualizado.
