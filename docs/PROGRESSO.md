# Progresso — o que foi feito

Legenda: ✅ funciona e foi visto rodando · 🟡 código escrito, **não testado em jogo** · ❌ não feito

## Núcleo ✅
- Terreno em blocos (grade 64x64, degraus de 0,5 m), chunks 16x16 com rebuild só do chunk alterado.
- Gerador de ilha por semente: platô da vila, rio, praia, mata de ipês e palmeiras.
- Itens orientados a dados (`data/items.json`, `data/items/*.json`), `Inventory` (32 slots, hotbar de 8), `GameState` (moedas, flags, stats).
- `ToolController` (item selecionado = ferramenta), terraformação (subir, cavar, nivelar, caminho, grama, plantar).
- Plug-in de módulos: `scripts/features/*.gd` carregados por `main.gd`.
- Jogador, câmera orbital, dia/noite, capivaras, água.

## Módulos feitos por agentes em paralelo (interrompidos antes do fim) 🟡
Carregam sem erro de parse e o jogo abre, mas **nenhum foi jogado de ponta a ponta**.
| Módulo | Arquivos | Obs. |
|---|---|---|
| UI (hotbar, inventário, toasts, moedas, prompt) | `ui_*.gd` | moedas e missões aparecem; hotbar visível só parcialmente na captura |
| Coleta (árvores, pedras, pesca, insetos, pickups) | `harvest_*.gd`, `fishing.gd`, `bugs.gd`, `pickups.gd` | sem doc própria |
| Construção | `build_mode.gd`, `scripts/building/` | sem doc própria |
| Economia e crafting | `economy_*.gd`, `crafting.gd`, `data/recipes.json` | sem doc própria |
| Vila (NPCs, missões, progressão) | `village_*.gd`, `quests.gd` | NPCs e barraca aparecem no mundo; diário (J) incompleto |
| Atmosfera (áudio procedural, clima, polimento) | `audio_manager.gd`, `weather.gd`, `ambient_life.gd`, `visual_polish.gd`, `grass_decor.gd`, `trailer_camera.gd` | áudio não verificado (sem som no headless) |
| Sistema (menu, pausa, save/load) | `system_*.gd`, `scenes/main_menu.tscn` | save/load **não** foi testado de ida e volta |

## Correções de integração desta sessão
- Shaders com comentário `##` (inválido) → `//`.
- Post-process lia textura vazia e deixava a tela branca → usa `hint_screen_texture`.
- Erros de tipagem em `audio_manager.gd` e `village_npcs.gd`.

## Pipeline de arte (Mixar) 🟡
- MCPs registrados em `~/AppData/Local/hermes/config.yaml` (Mixar e Godot); Mixar testado por stdio (62 ferramentas, créditos ok).
- Geração testada: imagem de referência do ipê (`gpt-image-2.5-flare`) ✅; modelo 3D (`tripo-low`) enfileirado, **resultado não confirmado nem exportado**. Nenhum `.glb` está no projeto ainda: todos os modelos são procedurais provisórios.
- Créditos Mixar gastos até aqui: ~91 de 1000.
- Receita: imagem de referência → `model_3d` (image_name da moodboard) → `export_scene` glb → `assets/models/<cat>/<id>.glb`. `PropLibrary` já troca o procedural pelo `.glb` automaticamente.
