> Documento histórico (primeira demo de terreno). Estado atual: `docs/PROGRESSO.md`; plano: `docs/ROADMAP.md`.

# Vila Ipê — MVP de demo (trailer)

Escopo: **uma ilha jogável de ~5 min** para gravar trailer. Nada de multiplayer/Steam/save neste marco (ver PROMPT MESTRE para o jogo completo).

## O que existe
- Terreno em blocos (grade 1 m, degraus de 0,5 m) com chunks 16x16 e rebuild só do chunk sujo.
- Terraformação: subir, cavar, nivelar, caminho, grama, plantar ipê; pincel 1/3/5.
- Ilha gerada por semente: vila no platô central, rio a leste, praia, mata de ipês e palmeiras.
- Ciclo dia/noite com céu procedural; capivaras vagando; água com espuma de margem.
- Câmera orbital, modo cinema (C), esconder HUD (F1), foto (F2), `-- --shot` para screenshot automático.

## Estrutura
- `scripts/core` dados puros (TerrainData, WorldConst, InputSetup)
- `scripts/world` terreno, chunks, props, gerador, dia/noite, fauna
- `scripts/player` jogador, câmera, ferramenta de terraformação
- `scripts/ui` HUD · `scripts/autoload` EventBus, Boot
- `assets/models/<categoria>/<id>.glb` — **qualquer .glb com o id certo substitui o modelo provisório** (PropLibrary)

## Pipeline Mixar → Godot
Gerar no Mixar e exportar `.glb` (origem na base, 1 unidade = 1 m, frente -Z) com estes ids:
`player`, `capybara`, `tree_ipe_yellow`, `tree_ipe_purple`, `tree_palm`, `tree_generic`,
`house_colonial_blue|pink|yellow|green` (footprint 3x3 células).
Pastas: characters/, animals/, trees/, buildings/.

## Pendente para o trailer
Modelos finais do Mixar, animações (andar/cortar), música, ponte/barco/bandeirinhas, câmera de trailer com trilho.
