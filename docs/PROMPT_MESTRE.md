> **Documento-fonte (visão completa do jogo).** Onde aparece "Blender" / "Blender MCP", leia **Mixar** (decisão do dono do projeto: modelos 3D saem do Mixar). **Correção de estilo:** onde o texto diz "low-poly", entenda 3D estilizado suave e polido (acabamento de Dinkum, Go-Go Town e Pokopia), com orçamentos de polígonos maiores; ver `docs/VISAO.md`. Esta é a meta de longo prazo; o escopo atual está em `docs/ROADMAP.md` e o resumo da visão em `docs/VISAO.md`.

# PROMPT MESTRE — "VILA IPÊ": jogo completo de vida, construção, exploração e aventura com temática e folclore brasileiros (execução one-shot)

> Cole este documento inteiro como instrução principal para o agente (ex.: Claude Code com Blender MCP e acesso ao projeto Godot). Ele é ao mesmo tempo **briefing criativo**, **especificação técnica** e **plano de execução**. O agente deve segui-lo até o fim, sem deixar o jogo pela metade.

---

## 0. PAPEL, MISSÃO E REGRAS DE TRABALHO

Você é um **estúdio de desenvolvimento completo em uma pessoa só**: diretor de jogo, game designer, programador sênior Godot (GDScript tipado), artista técnico 3D (Blender via MCP), designer de UI/UX, sound designer e engenheiro de build/release.

**Missão:** criar do zero, e entregar **finalizado, jogável do início ao fim, polido e divertido**, o jogo **Vila Ipê** — um jogo de simulação de vida, coleta, criação e construção de cidade em 3D estilizado, inspirado na liberdade de exploração e progressão por licenças de **Dinkum** e na gestão de vila com moradores trabalhando de forma autônoma de **Go-Go Town!**, porém com identidade 100% brasileira: biomas, fauna, flora, culinária, música, festas, folclore e arquitetura do Brasil.

**Ferramentas obrigatórias:**
- **Blender (4.x) controlado via Blender MCP** para modelar, texturizar, rigar e animar todos os assets 3D.
- **Godot 4.x (versão estável mais recente)** para todo o jogo.
- **GodotSteam (versão GDExtension compatível com a versão do Godot)** para integração com a Steam (`steam_api64.dll` / `libsteam_api.so`).
- **Multiplayer cooperativo online** via Steam (lobbies + P2P) com fallback LAN/IP direto via ENet.

**Regras inegociáveis de trabalho:**
1. **Nada de placeholders no produto final.** Cubos cinza, `TODO`, `pass`, funções vazias e textos "lorem ipsum" só podem existir temporariamente e devem ser eliminados antes de cada marco ser considerado concluído.
2. **Tudo orientado a dados.** Itens, receitas, animais, plantas, NPCs, construções, missões e diálogos são `Resource` (`.tres`) ou JSON, nunca valores fixos espalhados no código.
3. **GDScript com tipagem estática** em 100% do código (`var x: int`, `func f() -> void`), `class_name` em classes reutilizáveis, sinais tipados.
4. **Multiplayer pensado desde o primeiro script.** Toda ação que altera o mundo passa pelo host (servidor autoritativo). Nunca escreva uma mecânica "single-player primeiro, rede depois".
5. **Teste contínuo.** Após cada sistema, rode o projeto, verifique erros no console, escreva testes (GUT ou gdUnit4) para lógica pura (inventário, economia, crafting, save/load, calendário).
6. **Commits pequenos e descritivos** em Git, um por sistema/asset relevante. Use Git LFS para `.blend`, `.glb`, `.png`, `.wav`, `.ogg`.
7. **Documente decisões** em `docs/DECISOES.md` e mantenha `docs/PROGRESSO.md` com checklist de marcos.
8. **Conteúdo original.** Nenhum asset, música, nome ou arte copiados de Dinkum, Go-Go Town ou qualquer outra obra. Inspiração de mecânica, não de conteúdo. Toda música é composição original em estilos brasileiros.
9. **Respeito cultural.** Representação positiva e cuidadosa de povos originários, quilombolas, ribeirinhos, caiçaras, sertanejos e gaúchos; sem caricaturas. Folclore tratado como mitologia rica, não como piada.
10. Ao terminar cada marco, **abra o jogo, jogue o fluxo completo daquele marco** e corrija o que estiver quebrado ou sem graça antes de avançar.

### 0.1 MODO ONE-SHOT (EXECUÇÃO AUTÔNOMA DE PONTA A PONTA)
Este prompt deve ser executado **de uma vez só, do projeto vazio até o jogo exportado**, sem pedir aprovação intermediária.
1. **Não faça perguntas.** Quando faltar informação, decida pelo que melhor serve aos pilares de design e registre em `docs/DECISOES.md`.
2. **Não pare entre marcos.** Ao concluir um marco, marque-o em `docs/PROGRESSO.md`, faça commit e siga imediatamente para o próximo.
3. **Retomada à prova de interrupção.** `docs/PROGRESSO.md` é a fonte da verdade. Se a sessão ou o contexto for interrompido, a próxima execução lê `PROGRESSO.md`, `DECISOES.md` e o último commit e continua exatamente de onde parou, sem refazer nada.
4. **Gestão de contexto.** Trabalhe sistema por sistema. Mantenha um resumo curto de cada sistema em `docs/sistemas/<nome>.md` (API pública, sinais, dependências, IDs usados) e consulte esses resumos em vez de reabrir arquivos enormes.
5. **Paralelismo.** Se o ambiente permitir subagentes, divida o trabalho em trilhas independentes (ex.: uma trilha modela fauna no Blender enquanto outra implementa a IA dos animais). Antes de dividir, defina os contratos entre as trilhas: nomes de arquivos, nomes de animações, IDs de itens e sinais.
6. **Conteúdo em massa por dados e automação.** Use scripts para gerar conteúdo: Python no Blender (inclusive Geometry Nodes), `EditorScript` no Godot, e geração de `.tres` a partir de planilhas CSV em `data/`. Ícones de inventário são renderizados automaticamente de cada modelo (256×256, fundo transparente).
7. **Loop de autoverificação após cada sistema:**
   - rodar o projeto headless e ler erros e avisos;
   - rodar os testes automatizados;
   - capturar screenshots in-game e avaliar visualmente;
   - corrigir e repetir até chegar a zero erros.
8. **Nunca declare o jogo pronto** sem cumprir a checklist da seção 28 inteira.
9. **Se uma ferramenta falhar** (MCP desconectado, addon incompatível), use a alternativa documentada, como rodar o Blender em linha de comando com `blender -b -P script.py`. Nunca abandone a tarefa por causa disso.

---

## 1. VISÃO GERAL DO JOGO

**Título:** Vila Ipê
**Gênero:** simulação de vida + construção de vila + sandbox de terreno + exploração/aventura com combate leve não letal e chefes, cooperativo.
**Câmera:** terceira pessoa com câmera orbital livre (estilo Dinkum), zoom ajustável, e um **modo planejamento** com câmera isométrica de cima para construir e posicionar lotes (estilo Go-Go Town).
**Jogadores:** 1 a 6 em cooperativo online (Steam) ou LAN.
**Plataforma:** PC Windows (principal) e Linux/Steam Deck (compatível, controles de gamepad completos).
**Classificação alvo:** Livre / 10+. Sem sangue, sem morte gráfica; animais "desmaiam" e fogem.

**Premissa narrativa:**
O jogador recebe uma carta da **Dona Cida**, uma senhora aposentada da prefeitura, que ganhou na loteria da "Fundação Terra Brasilis" o direito de refundar uma vila abandonada no meio de uma ilha continental fictícia, a **Ilha do Ipê**, onde todos os biomas brasileiros se encontram em miniatura. O jogador chega de barco com uma mochila, uma barraca e um facão de roçar. Seu papel: ser o **Prefeito(a)-Fundador(a)**, atrair moradores, abrir comércios, restaurar a natureza, catalogar a fauna e a flora e transformar a vila abandonada em uma cidade turística de 5 estrelas — sem destruir o ambiente.

**Pilares de design (toda decisão deve servir a pelo menos um):**
1. **Aconchego brasileiro** — calor, cor, música, comida, gente simpática, humor leve.
2. **Liberdade de exploração** — mundo grande, biomas distintos, sempre algo novo para descobrir.
3. **Construir junto** — a vila é do grupo; cooperar é mais eficiente e mais divertido que jogar sozinho.
4. **Natureza viva e respeitada** — coletar e usar recursos com equilíbrio; replantar, proteger espécies, catalogar.
5. **Progressão constante** — em qualquer sessão de 20 minutos o jogador sente que avançou.

**Loop central (minuto a minuto):** explorar → coletar (madeira, pedra, frutas, peixes, insetos) → vender/craftar → cumprir pedidos de moradores → ganhar dinheiro e pontos de licença → desbloquear ferramentas/construções → expandir a vila → abrir novas áreas.

**Loop de meta (dia a dia):** acordar → ler o quadro de avisos → dar ordens aos moradores trabalhadores → explorar um bioma → voltar ao entardecer → vender na feira → cozinhar → dormir (salva o jogo).

**Loop longo (semanas/estações):** subir a nota da vila (1★ a 5★), completar o **Catálogo da Biodiversidade**, organizar festas sazonais, liberar pontes para novos biomas, atrair turistas, terminar a história principal.

**Duração alvo:** 40–60 horas para "zerar" a história (vila 5★ + catálogo principal completo); 150+ horas para 100% de conquistas.

---

## 2. STACK TÉCNICA E CONFIGURAÇÃO DO PROJETO

- **Godot 4.x estável** (Forward+ renderer; oferecer opção "Compatibilidade/Mobile" nas configurações gráficas para PCs fracos).
- **Física:** Jolt Physics (integrado ao Godot 4.4+) se disponível; senão Godot Physics.
- **GodotSteam GDExtension** instalado em `addons/godotsteam/`.
- **Testes:** gdUnit4 ou GUT em `addons/`.
- **Diálogos:** sistema próprio simples baseado em Resources (ou Dialogue Manager addon, se preferir), com suporte a variáveis (`{player_name}`, `{npc_name}`) e condições.
- **Localização:** arquivos CSV/PO do Godot com `tr()` em todo texto visível. Idiomas: **pt-BR (principal)**, inglês, espanhol.
- **Controle de versão:** Git + Git LFS.
- **Resolução base:** 1920×1080, UI escalável (stretch mode `canvas_items`, aspect `expand`), suporte a 16:10 (Steam Deck) e ultrawide.
- **Taxa de quadros alvo:** 60 FPS em GPU equivalente a GTX 1060 no preset "Médio"; 40+ FPS estáveis no Steam Deck no preset "Deck".

### 2.1 Estrutura de pastas

```
res://
├── addons/                    # godotsteam, gdunit4, etc.
├── assets/
│   ├── models/                # .glb exportados do Blender, por categoria
│   │   ├── characters/ animals/ plants/ trees/ crops/ buildings/
│   │   ├── furniture/ tools/ props/ vehicles/ terrain/ fish/ insects/
│   ├── blend/                 # arquivos-fonte .blend (Git LFS)
│   ├── textures/              # atlas de paleta, gradientes, noise
│   ├── materials/             # .tres de materiais e shaders
│   ├── shaders/               # água, vento em folhagem, toon, céu
│   ├── audio/ music/ sfx/ ambience/ voices/
│   ├── fonts/
│   └── ui/                    # ícones, molduras, cursores
├── data/
│   ├── items/ recipes/ crops/ animals/ fish/ insects/ trees/
│   ├── npcs/ dialogues/ quests/ buildings/ shops/ festivals/
│   ├── biomes/ weather/ achievements/ licenses/
├── scenes/
│   ├── main/ (Boot, MainMenu, Game, Loading)
│   ├── world/ (World, Chunk, Biomes/*)
│   ├── player/ npc/ animals/ buildings/ interactables/ vehicles/ ui/
├── scripts/
│   ├── autoload/ core/ systems/ network/ steam/ ui/ util/
├── tests/
├── docs/
└── export_presets.cfg
```

### 2.2 Autoloads (singletons)

| Autoload | Responsabilidade |
|---|---|
| `EventBus` | Sinais globais desacoplados (item_collected, day_started, building_completed…) |
| `GameState` | Estado da partida atual: dinheiro da vila, nota, dia, desbloqueios |
| `TimeManager` | Relógio do jogo, dia/noite, calendário, estações |
| `WeatherManager` | Clima por bioma, chuva, trovoada, seca, neblina, vento |
| `ItemDB` | Carrega e indexa todos os Resources de itens/receitas |
| `SaveManager` | Salvar/carregar, versionamento, migração, Steam Cloud |
| `NetworkManager` | Host/cliente, peers, spawn de jogadores, RPCs centrais |
| `SteamManager` | Inicialização da Steam, lobbies, conquistas, stats, rich presence |
| `AudioManager` | Música adaptativa por bioma/hora, SFX com pool, buses |
| `SettingsManager` | Gráficos, áudio, controles, acessibilidade (salvo em `user://settings.cfg`) |
| `UIManager` | Pilha de telas, HUD, notificações, tooltips |
| `QuestManager` | Missões principais, pedidos diários, marcos |

---

## 3. PIPELINE DE ARTE COM BLENDER MCP

### 3.1 Direção de arte
- **Estilo:** low-poly estilizado e arredondado, "brinquedo de madeira pintado", com leve toon shading, bordas suaves, cores saturadas mas harmoniosas. Referências de clima (não copiar): cerâmica do Vale do Jequitinhonha, azulejos portugueses, casarios coloniais de Paraty e Ouro Preto, palafitas amazônicas, bandeirinhas de festa junina, fitas do Bonfim, xilogravura de cordel (para UI e ilustrações de menu).
- **Paleta global:** um **atlas de paleta 256×256** (gradientes) compartilhado por quase todos os modelos; UVs dos modelos apontam para células de cor. Isso mantém coesão visual, reduz draw calls e memória.
- **Paletas por bioma:** Amazônia (verdes profundos, marrom-rio, rosa-boto), Cerrado (dourado, ocre, verde-oliva, roxo-ipê), Caatinga (terracota, cinza-prateado, verde-cacto, flores amarelas), Pantanal (azul-lâmina d'água, verde-limão, laranja do pôr do sol), Mata Atlântica (verde-esmeralda, bromélias vermelhas, névoa), Pampa (verde-campo, céu imenso, cinza de nuvens), Mata de Araucárias (verde-escuro, marrom-pinhão, geada azulada), Litoral (turquesa, areia, branco das dunas).
- **Personagens:** proporção "chibi-moderada" (cabeça ~1/4 do corpo), mãos simples de 4 dedos, olhos grandes expressivos com texturas trocáveis para emoções.

### 3.2 Orçamentos de polígonos (triângulos)
| Tipo | LOD0 | LOD1 | LOD2 |
|---|---|---|---|
| Personagem jogável/NPC | 4.000–6.000 | 2.000 | 800 |
| Animal grande (onça, anta) | 2.500–4.000 | 1.200 | 400 |
| Animal pequeno/inseto/peixe | 300–1.200 | 300 | — |
| Árvore grande | 1.500–3.000 | 800 | impostor/billboard |
| Construção | 1.500–6.000 | 50% | 20% |
| Item/prop | 50–600 | — | — |

### 3.3 Convenções no Blender (o agente deve seguir ao usar o MCP)
- Unidade: metros, escala 1.0, Z-up no Blender (o exportador glTF converte para Y-up), **origem na base do objeto** (pés no chão).
- Nomenclatura: `categoria_nome_variante` em inglês-snake-case para arquivos (`animal_capybara_adult`), com nome exibido traduzido via localização.
- Sufixos de importação do Godot nos objetos: `-col` (colisão convexa), `-colonly`, `-navmesh`, `-noimp` para helpers.
- LODs: gerar via importador do Godot (auto-LOD) quando possível; criar LOD manual apenas para árvores e personagens.
- Aplicar modificadores e transformações antes de exportar. Normais: shade auto smooth com ângulo 40°.
- **Rig:** armature humanoide padrão compartilhada por todos os humanos (jogador e NPCs) para reaproveitar animações. Quadrúpedes: 3 rigs base (quadrúpede pequeno, médio, grande) + rigs especiais (ave, peixe, serpente, inseto).
- **Animações por ação (NLA/Actions)** com nomes padronizados: `idle`, `walk`, `run`, `jump`, `swim`, `climb`, `sit`, `sleep`, `chop`, `mine`, `dig`, `water`, `fish_cast`, `fish_reel`, `net_swing`, `carry`, `eat`, `wave`, `dance_forro`, `dance_samba`, `dance_frevo`, `celebrate`, `sad`, `think`, `hurt`, `faint`, `ride_bike`, `ride_horse`, `drive`, `paddle`.
- Exportar **.glb** para `res://assets/models/<categoria>/`, mantendo o `.blend` fonte em `res://assets/blend/`.
- Automatize: crie um **script Python do Blender** (executado via MCP) que exporta em lote todos os objetos de uma coleção com as convenções acima. Reutilize-o sempre.
- Após cada lote exportado, abra no Godot, confira escala (um humano ≈ 1,6 m), orientação (frente em -Z no Godot), colisões e materiais.

### 3.4 Shaders no Godot
- **Toon/cel suave** com rim light sutil, recebendo sombras.
- **Vento em folhagem** (deslocamento de vértices por noise + máscara por cor de vértice), com intensidade controlada pelo `WeatherManager`.
- **Água:** rio (fluxo direcional, espuma nas margens por profundidade), mar (ondas Gerstner leves, espuma), lago do Pantanal (espelho com reflexo SSR ou planar barato), igarapé (água escura tipo chá), mangue (água turva).
- **Céu procedural** com ciclo dia/noite, nuvens, estrelas e Cruzeiro do Sul visível à noite.
- **Grama instanciada** via MultiMesh por chunk, com interação (se abaixa quando o jogador passa).
- **Chuva/poeira/folhas** via GPUParticles3D; poças que se formam no chão com decal/shader.
- **Outline** opcional (pós-processamento) configurável.

---

### 3.5 Manifesto de modelos 3D (mínimo obrigatório)
Crie `data/asset_manifest.csv` com as colunas id, categoria, bioma, tris alvo, animações, variações e status, e produza **todos** os itens abaixo via Blender MCP. Use modularidade e variações (cor, escala, partes intercambiáveis) para multiplicar o conteúdo sem multiplicar o trabalho.

| Categoria | Quantidade mínima | Exemplos / observações |
|---|---|---|
| Personagem jogável | 1 corpo base, 60 cabelos, 40 rostos (texturas), 300+ peças de roupa e acessórios | chapéus de palha, de vaqueiro e boina gaúcha; bombacha; chita; abadá; fantasias de folclore |
| NPCs nomeados | 30 | cada um com silhueta própria (chapéu, bengala, avental, violão…) |
| NPCs genéricos e turistas | 1 base + 40 variações modulares | mochileiro, família, surfista, fotógrafo, excursão escolar |
| Encantados (folclore) | 20 | ver seção 12.1 |
| Chefes | 12 + arenas próprias | ver seção 12.4 |
| Inimigos comuns | 20 | Fuliguinhos, drones, golens de lixo… |
| Fauna selvagem | 80 espécies | 30 mamíferos, 30 aves, 12 répteis e anfíbios, 8 outros |
| Peixes | 70 | água doce, salgada e salobra; 6 lendários |
| Insetos e invertebrados | 60 | incluindo caranguejos, aranhas e sapos |
| Animais de criação | 12 + filhotes | galinha, pato, codorna, cabra, ovelha, vaca, porco, cavalo, jegue, burro, boi, búfalo |
| Montarias | 17 + 40 acessórios | selas, mantas, alforjes (seção 16A) |
| Pets | vira-lata caramelo + 6 pelagens de cão, 6 de gato, papagaio, jabuti | |
| Árvores | 45 espécies × 5 estágios de crescimento | variações sazonais: floradas, frutos, folhas secas |
| Arbustos, plantas e flores | 120 | bromélias, orquídeas, helicônias, vitória-régia, capim-dourado |
| Lavouras | 45 culturas × 4–5 estágios | |
| Rochas e peças de terreno | 60 | rochas, falésias, cascatas, estalactites, cristais, lajedos |
| Minérios e gemas | 25 | em estado bruto e lapidado |
| Construções da vila | 70 prédios com interiores | nos 7 estilos arquitetônicos |
| Kit modular de construção | 250 peças | seção 8A |
| Móveis e decoração | 500+ | em conjuntos temáticos |
| Ferramentas | 18 tipos × 4–5 tiers | |
| Armas de purificação | 12 tipos × 4 tiers | seção 12.3 |
| Veículos | 35 + peças de customização | seção 16A |
| Comidas | 150 | pratos e ingredientes |
| Recursos e itens de crafting | 200 | |
| Props de cenário e pontos de interesse | 250 | ruínas, naufrágios, placas, postes, barracas de feira, bandeirinhas, carros alegóricos, fogueiras |
| Colecionáveis | 30 relíquias, 20 fósseis (em 3 partes), 20 estatuetas de barro | figurinhas são ilustrações 2D |
| Efeitos visuais | 80 sistemas de partículas | |

**Total estimado:** cerca de 3.000 assets únicos, ou mais de 6.000 contando as variações.

**Estratégia de produção em escala:**
1. Crie primeiro os kits base e os rigs.
2. Use geração procedural no Blender (Geometry Nodes) para árvores, rochas, plantas e cercas.
3. Escreva scripts Python que geram variações parametrizadas.
4. Revise por folhas de contato: renders com 20 modelos por imagem, para checar coerência de estilo e escala.
5. Exporte em lote.

**Padrão de qualidade:**
- Todo modelo precisa ser reconhecível pela silhueta na distância normal de jogo.
- Todo animal tem no mínimo `idle`, `walk`, `run`, `eat`, `sleep` e `flee`.
- Todo chefe tem animações de telegrafia (aviso antes de cada golpe) exageradas e legíveis.

## 4. MUNDO, MAPA E BIOMAS

### 4.1 Estrutura do mundo
- Mapa único de aproximadamente **2 km × 2 km**, dividido em **chunks de 64 m** com carregamento por streaming ao redor de cada jogador (host carrega a união das áreas de todos os jogadores).
- **Mundo semi-procedural:** layout macro dos biomas é fixo e desenhado à mão (para garantir boa jornada), mas a distribuição de árvores, pedras, arbustos, flores, ninhos, tocas e minérios é procedural com **semente** escolhida ao criar o mundo; recursos renascem ao longo dos dias.
- Terreno: heightmap + editável pelo jogador (enxada/pá para nivelar, cavar lagoas, fazer caminhos) — com limites para evitar abuso e sincronizado em rede como deltas de altura por chunk.
- **Vila Ipê** fica no centro, no encontro da Mata Atlântica, do Cerrado e do rio.
- Áreas bloqueadas por progressão: pontes quebradas, balsas, estradas de terra alagadas, portões de parques. Cada bioma novo é liberado ao construir/consertar uma ligação.

### 4.2 Biomas (cada um com identidade visual, sonora e de recursos própria)

**1. Mata Atlântica (bioma inicial)**
- Relevo: morros suaves, cachoeiras, trilhas, névoa matinal.
- Flora: palmeira-juçara, jequitibá, pau-brasil (protegido — não pode ser cortado, apenas plantado e cuidado), quaresmeira, bromélias, orquídeas, samambaiaçu, embaúba, jabuticabeira, pitangueira.
- Fauna: mico-leão-dourado, quati, sagui, tucano-de-bico-verde, sabiá-laranjeira, tiê-sangue, preguiça, tatu, cutia, jararaca (perigo leve), borboleta-azul, vaga-lume.
- Recursos: madeira comum, argila, pedra, frutas nativas, cogumelos.

**2. Cerrado**
- Relevo: planalto, árvores retorcidas, veredas com buritizais, chapadas ao fundo.
- Flora: ipê-amarelo e ipê-roxo (florada sazonal espetacular), pequizeiro, baru, buriti, lobeira, capim-dourado, canela-de-ema, cagaita, mangaba.
- Fauna: lobo-guará (tímido, raro), tamanduá-bandeira, ema, seriema, arara-canindé, veado-campeiro, cupinzeiros gigantes (recurso de argila fina), tatu-canastra (raríssimo).
- Recursos: capim-dourado (artesanato valioso), pequi, baru, cristais de quartzo nas chapadas.
- Evento: queimadas controladas na seca (missão de brigada de incêndio para proteger o bioma).

**3. Amazônia**
- Relevo: floresta densa, igarapés, rio largo de água escura e barrenta, várzea que alaga na estação chuvosa.
- Flora: castanheira, seringueira, samaúma gigante (landmark), açaizeiro, cupuaçuzeiro, guaraná, vitória-régia, cacaueiro nativo.
- Fauna: onça-pintada (perigosa, só ataca se provocada, derruba o jogador que acorda na clínica), boto-cor-de-rosa, macaco-prego, arara-vermelha, harpia, bicho-preguiça, sucuri (perigo), poraquê, tartaruga-da-amazônia, morpho azul.
- Peixes: pirarucu, tambaqui, tucunaré, pacu, piranha, aruanã, jaraqui.
- Recursos: madeiras nobres (só via plano de manejo licenciado), látex, castanhas, açaí, sementes para biojoias.
- Transporte: barco (voadeira/canoa) essencial.

**4. Pantanal**
- Relevo: planície alagável, cordilheiras de terra seca, baías, corixos, pôr do sol laranja.
- Flora: carandá, piúva (ipê-roxo pantaneiro), aguapé, camalote, vitória-régia.
- Fauna: tuiuiú (símbolo), capivara (bando grande e muito dócil), jacaré-do-pantanal, ariranha, cervo-do-pantanal, anta, arara-azul-grande, colhereiro, onça-pintada nadando.
- Peixes: dourado, pintado, pacu, piraputanga, jaú (raro, gigante).
- Mecânica: **cheia e seca** mudam o mapa (áreas alagadas só acessíveis de barco na cheia; trilhas a pé na seca).
- Cultura: comitiva pantaneira, berrante, cavalos pantaneiros.

**5. Caatinga / Sertão**
- Relevo: solo pedregoso, lajedos, serras, açudes, vegetação cinza que **fica verde de repente após a chuva** (efeito visual marcante).
- Flora: mandacaru, xique-xique, juazeiro, umbuzeiro, aroeira, barriguda, macambira, palma forrageira.
- Fauna: tatu-bola, preá, asa-branca, carcará, cabra/bode (criação), mocó, gato-do-mato, cascavel (perigo), ararinha-azul (espécie reintroduzida em missão especial de conservação).
- Recursos: couro sintético? não — **fibras de caroá e sisal**, argila vermelha, pedras semipreciosas, mel de abelha nativa (jandaíra).
- Cultura: cordel, xilogravura, forró pé-de-serra, feira nordestina, repentistas.

**6. Pampa**
- Relevo: coxilhas (colinas suaves de campo aberto), vento forte, céu enorme, sangas.
- Flora: capim-caninha, butiazeiro, corticeira, macela, marcela (colhida na Sexta-feira Santa como tradição).
- Fauna: quero-quero (barulhento, "guarda" o campo), ema, graxaim, joão-de-barro (seu ninho vira inspiração para o forno de barro), zorrilho, perdiz.
- Recursos: lã (criação de ovelhas), erva-mate processada (vem da mata de araucárias vizinha), couro? substituir por **lã e feltro**.
- Cultura: galpão crioulo, chimarrão, fogo de chão, cavalo crioulo.

**7. Mata de Araucárias (serra fria)**
- Relevo: serra alta, cânions, campos de altitude, geada e às vezes neve rara (evento especial).
- Flora: araucária (pinhão como coleta sazonal de outono/inverno), erva-mate, xaxim, imbuia, podocarpo.
- Fauna: gralha-azul (planta araucárias — mecânica: gralhas espalham pinhões e criam novas árvores), papagaio-charão, bugio, ouriço-cacheiro, veado-mão-curta.
- Recursos: pinhão, erva-mate, madeira de reflorestamento, mel.

**8. Litoral: praia, restinga, dunas e manguezal**
- Flora: coqueiro, cajueiro, pitangueira de restinga, salsa-de-praia, mangue-vermelho, mangue-branco.
- Fauna: caranguejo-uçá, guaiamum, siri, garça, tartaruga-marinha (desova — missão de proteção, jamais capturável), golfinho, baleia-jubarte (avistável no inverno), fragata, maria-farinha.
- Peixes: robalo, tainha, sardinha, garoupa, cavala, badejo; pesca de rede de arrasto com moradores (minijogo cooperativo).
- Recursos: sal, conchas, coco, areia (para vidro), algas.
- Área especial: **ilha de corais** ao largo (mergulho com snorkel no fim do jogo).

**9. Grutas e subterrâneo**
- Cavernas calcárias inspiradas em grutas brasileiras (estalactites, lagos azuis subterrâneos).
- Mineração: pedra, calcário, ferro, cobre, ouro (garimpo responsável com bateia no rio), turmalina, ametista, esmeralda, topázio-imperial, água-marinha.
- Fauna: morcegos (polinizadores, não inimigos), bagres cegos, aranhas grandes (inofensivas).
- Níveis de profundidade liberados por licença de mineração.

### 4.3 Tempo, calendário e clima
- **1 dia no jogo = 20 minutos reais** (configurável pelo host: 15/20/30 min). Das 6h às 2h; às 2h o jogador desmaia de cansaço se não tiver dormido.
- **Ano com 4 estações de 28 dias**, com nomes brasileiros e efeitos reais: **Primavera** (floradas, ipês), **Verão** (chuvas de fim de tarde, calor, praia lotada), **Outono** (pinhão, colheita de café e milho), **Inverno** (seca no Cerrado e Pantanal, geada na serra, festas juninas).
- **Clima dinâmico por bioma:** sol, nublado, garoa, pancada de chuva de verão, tempestade com raios, neblina serrana, vento minuano no Pampa, seca extrema no Sertão, geada, chuva de caju (evento no Nordeste no fim do ano).
- Clima afeta: crescimento das plantas, aparecimento de animais/peixes/insetos, humor dos NPCs, turistas, energia do jogador.
- **Previsão do tempo** na TV/rádio da casa e no painel da prefeitura.

---

## 5. PERSONAGEM DO JOGADOR

- **Criador de personagem completo:** tom de pele (ampla gama realista representando a diversidade brasileira), formato de rosto, olhos, sobrancelhas, nariz, boca, cabelos (crespo, cacheado, ondulado, liso, black power, tranças nagô, dreads, raspado, coque, etc.), cor de cabelo, barba, sardas, óculos, altura (3 opções), tipo de corpo (3 opções), voz (6 "vozinhas" estilo balbucio), pronomes livres.
- **Atributos:** Vida (❤) e Energia (⚡). Energia gasta com ferramentas, recuperada com comida, descanso, rede de dormir, banho de cachoeira. Comidas dão **buffs** (velocidade, sorte na pesca, força na mineração, resistência ao calor/frio).
- **Movimentação:** andar, correr, pular, nadar, mergulhar (após licença), escalar paredes baixas, deitar na rede, sentar, remar, andar de bicicleta, cavalgar, pilotar.
- **Mochila:** 10 slots iniciais → até 40 com upgrades de bolsa (bornal de couro → mochila de lona → mochila de trilha). Barra rápida de 10 slots.
- **Roupas e cosméticos:** mais de 300 peças — chapéu de palha, chapéu de couro de vaqueiro nordestino (versão sintética/tecido), boina gaúcha, lenço de pescoço, bombacha, camisa de chita, vestido de festa junina, abadá de carnaval, camisa de time fictício, havaianas genéricas (chinelos de dedo), botas de borracha, capa de chuva, fantasias de folclore, óculos de mergulho, etc.

---

## 6. SISTEMA DE PROGRESSÃO: LICENÇAS ("CARTEIRINHAS")

Inspirado nas licenças do Dinkum, mas com a temática de **Carteirinhas da Prefeitura**. Compradas com **Pontos de Cidadania (PC)**, ganhos em praticamente toda ação produtiva.

| Carteirinha | Níveis | Desbloqueia |
|---|---|---|
| Lenhador(a) Consciente | 1–3 | machados melhores, cortar árvores maiores, madeira nobre com plano de manejo |
| Garimpo e Mineração | 1–4 | picaretas, grutas mais profundas, bateia, gemas |
| Agricultura Familiar | 1–4 | enxadas, regadores maiores, irrigação, estufa, adubo orgânico, culturas exóticas |
| Pesca Artesanal | 1–4 | varas, rede de arremesso, covo, pesca embarcada, pesca oceânica |
| Pecuária e Quintal | 1–3 | galinheiro, curral, apriscos, estábulo, cavalos |
| Naturalista | 1–4 | puçá para insetos, binóculo, câmera, armadilha fotográfica, fichas de espécies raras |
| Mergulho | 1–2 | nadar sob a água, coletar no fundo, recifes |
| Navegação | 1–3 | canoa, voadeira, barco de pesca |
| Pilotagem | 1–3 | bicicleta cargueira, moto, caminhonete, **ultraleve** (fim de jogo) |
| Construção Civil | 1–5 | tamanho de casas, pontes, cercas, estradas, construções públicas |
| Paisagismo | 1–3 | editar terreno, caminhos, lagos, jardins |
| Culinária | 1–4 | fogão a lenha, forno de barro, receitas regionais, restaurante |
| Artesanato | 1–4 | bancadas, cerâmica, cestaria, biojoias, capim-dourado, renda de bilro |
| Brigada Ambiental | 1–3 | combater queimadas, resgatar animais, soltar filhotes, missões de conservação |
| Comércio | 1–3 | sua própria barraca de feira, preços melhores, exportação |

---

## 7. FERRAMENTAS E EQUIPAMENTOS

Cada ferramenta tem 4 tiers de material: **Madeira → Ferro → Bronze-cobre → "Ouro de Aluvião"/Titânio decorativo** + versões especiais de fim de jogo (ex.: "Facão do Curupira" que não gasta energia na mata).

- Facão de roçar (capim, cipó, arbustos)
- Machado (árvores)
- Picareta (pedras, minérios)
- Enxada (arar, nivelar)
- Pá (cavar, desenterrar fósseis e artefatos arqueológicos)
- Regador → regador grande → aspersor
- Vara de pesca (bambu → carbono) + iscas (minhoca, milho, massa, camarão, artificial)
- Tarrafa (rede de arremesso) e covos (armadilhas de peixe)
- Puçá (insetos)
- Estilingue de semente (espantar animais — não machuca)
- Laço (animais de criação)
- Bateia (garimpo em rio)
- Binóculo e câmera fotográfica (catálogo por foto de espécies raras e protegidas)
- Lanterna / lamparina
- Guarda-chuva (reduz perda de energia na chuva)
- Martelo de construção (modo construção)
- Pincel de pintura (pintar construções e móveis com paleta)
- Kit de primeiros socorros veterinários (resgatar animais feridos após queimadas)

Ferramentas têm **durabilidade** reparável na Ferraria do Seu Zé.

---

## 8. CONSTRUÇÃO DA VILA (NÚCLEO GO-GO TOWN)

### 8.1 Modo Planejamento
- Câmera de cima com grade de 1 m. Jogador demarca **lotes**, estradas, calçadas, praças, cercas, postes, jardins.
- Construções são posicionadas como **"canteiro de obra"**: aparece um andaime; recursos precisam ser entregues no canteiro (por jogadores ou por moradores trabalhadores); ao completar, a construção sobe com animação e festa.
- Rotação 90°/livre, pintura de paredes e telhados, escolha de estilo arquitetônico por construção: **Colonial (Paraty/Ouro Preto)**, **Palafita Ribeirinha**, **Casa de Taipa Sertaneja**, **Chalé Serrano de Madeira**, **Galpão Gaúcho**, **Casa de Praia Caiçara**, **Moderno Brasileiro (cobogós, concreto, brises)**.
- Estradas: terra batida → cascalho → paralelepípedo → pedra portuguesa (calçadão com desenho de ondas como padrão original).

### 8.2 Construções (todas com interior visitável)

**Serviços públicos:** Prefeitura (centro de progressão), Posto de Saúde (onde o jogador acorda se desmaiar), Escola (NPCs crianças, eventos), Correios (mercado de encomendas e cartas), Delegacia/Guarda Ambiental, Corpo de Bombeiros/Brigada, Rodoviária (chegada de turistas), Porto/Trapiche, Estação de Trem turístico (fim de jogo), Biblioteca, Coreto na praça, Igreja/Capela colonial e Terreiro cultural (espaços culturais com eventos festivos, apresentados com respeito), **Museu de História Natural** (doar espécimes e fósseis), **Centro de Conservação** (reabilitação de fauna), Viveiro de Mudas, Observatório (céu do hemisfério sul).

**Comércios (cada um com dono NPC e estoque rotativo):** Mercadinho, Padaria (pão francês, pão de queijo), Feira livre (barracas dos próprios jogadores e NPCs), Açaiteria, Pastelaria com caldo de cana, Sorveteria de frutas regionais, Casa do Norte (produtos nordestinos), Loja de Material de Construção, Ferraria, Loja de Pesca, Loja de Roupas/Costureira, Loja de Móveis, Floricultura, Barbearia/Salão, Restaurante (gerido pelo jogador), Pousada (hospeda turistas), Loja de Artesanato, Banca de Revista (catálogos, jornal diário com dicas), Oficina de bicicletas e motos, Estúdio de Música (desbloqueia rádio da vila).

**Produção:** Casa de Farinha (mandioca → farinha, polvilho, tapioca), Engenho (cana → rapadura, melado, açúcar mascavo), Torrefação de café, Fábrica de chocolate artesanal (cacau), Queijaria (queijo minas, coalho), Olaria (tijolos, telhas, cerâmica), Serraria, Tecelagem (algodão, lã), Casa do Mel (abelhas nativas sem ferrão), Fábrica de doces (goiabada, doce de leite, cocada), Salga de peixe, Beneficiamento de castanha e açaí.

### 8.3 Moradores trabalhadores (automação estilo Go-Go Town)
- Moradores chegam pela rodoviária ao atingir requisitos (casas disponíveis + nota da vila + construções que atraem aquele perfil).
- Cada morador tem **profissão preferida, habilidades (1–5 estrelas)** em: Coleta, Construção, Agricultura, Pesca, Cozinha, Comércio, Transporte, Artesanato.
- O jogador **atribui empregos** no quadro da Prefeitura. Moradores seguem rotinas: acordam, trabalham, almoçam, voltam para casa, socializam na praça, vão a festas.
- **Tarefas automatizadas:** colher lavouras, regar, alimentar animais, levar recursos aos canteiros de obra, atender balcões de lojas, cozinhar no restaurante, pescar para a peixaria, reabastecer prateleiras, varrer ruas, transportar cargas com carrinho de mão e carroça.
- **Pathfinding** com NavigationServer3D (regiões por chunk, atualização quando construções mudam), com evitação de multidões (RVO).
- **Felicidade do morador:** moradia (tamanho e decoração), acesso a comida favorita, lazer (praça, praia, bar de sucos), emprego compatível, amizade com o jogador. Moradores felizes trabalham mais rápido; infelizes podem pedir mudança (com aviso e chance de resolver).
- **Limite:** até 40 moradores nomeados + turistas genéricos (instanciados leves, com LOD agressivo).

### 8.4 Turismo e nota da vila
- **Nota de 1★ a 5★**, calculada por: número de moradores e felicidade média, variedade de comércios, beleza (decoração, flores, limpeza, árvores), biodiversidade catalogada, eventos realizados, infraestrutura (estradas, iluminação, transporte).
- Turistas chegam de ônibus e barco, gastam em lojas, se hospedam na pousada, tiram fotos de pontos turísticos (mirantes, cachoeiras, cristo-mirante fictício no morro, estátuas, murais), deixam avaliações engraçadas no "App de Avaliações" dentro do celular do jogador.
- Cada estrela desbloqueia construções, NPCs e capítulos da história.

---

## 9. AGRICULTURA, CRIAÇÃO E COZINHA

### 9.1 Plantio
- Solo: arar → plantar → regar → adubar (esterco, compostagem, adubo de húmus de minhoca) → colher. Qualidade da colheita (normal/prata/ouro/"de feira premiada").
- Culturas por estação e bioma preferido (bônus quando plantado no bioma certo):
  - **Primavera:** milho, feijão, alface, couve, cheiro-verde, maracujá, melancia.
  - **Verão:** mandioca (longa), abacaxi, açaí (árvore), caju (árvore), quiabo, maxixe, jiló, pimenta-de-cheiro, pimenta-malagueta.
  - **Outono:** café, cana-de-açúcar, abóbora, batata-doce, inhame, amendoim.
  - **Inverno:** mexerica, laranja (árvores), morango (serra), couve-flor, erva-mate, trigo (Pampa).
  - **Perenes/árvores frutíferas:** banana, manga, goiaba, jabuticaba, acerola, pitanga, cacau, cupuaçu, graviola, coco, caju, pequi, umbu, bacuri, cajá, siriguela, jaca, guaraná, açaí.
- **Algodão, sisal e urucum** para tecelagem e tintas.
- Espantalho (estilo "judas de pano" fofinho), cercas, irrigação por gotejamento, cisterna para a seca no Sertão, estufa.
- **Pragas naturais** (lagartas, formigas-saúva) combatidas com controle biológico (joaninhas, galinhas soltas).

### 9.2 Criação de animais (bem-estar em primeiro lugar)
- Galinha caipira (ovos), pato, codorna, cabra (leite, queijo), ovelha (lã), vaca (leite), porco-do-quintal (trufas? não — **encontra raízes e cogumelos**), cavalo crioulo e mangalarga (montaria), jegue/jumento nordestino (montaria resistente no Sertão, carrega carga), abelhas nativas (jataí, uruçu, mandaçaia, jandaíra).
- Nenhum abate de animais no jogo. Produtos são ovos, leite, lã, mel, adubo.
- Animais têm afeição, nomes, podem ganhar fitas em exposições agropecuárias.

### 9.3 Culinária (mais de 120 receitas)
Fogão a lenha, forno de barro, fogareiro de acampamento, panela de pressão (desbloqueio), churrasqueira.
Exemplos obrigatórios: feijoada, arroz com feijão e farofa, pão de queijo, coxinha, pastel de feira, caldo de cana, tapioca, cuscuz nordestino, baião de dois, carne de sol (versão com ingredientes da criação? usar **queijo coalho na brasa**), moqueca capixaba e baiana, bobó de camarão, acarajé, vatapá, caruru, tacacá, pato no tucupi (versão com pato? evitar abate: usar **"tucupi com jambu e peixe"**), açaí na tigela, pirarucu de casaca, peixe na folha de bananeira, arroz carreteiro, chimarrão, pinhão cozido, sagu de vinho (versão de uva), brigadeiro, beijinho, pé de moleque, paçoca, pamonha, curau, canjica, quentão (versão sem álcool: "quentão de frutas"), bolo de fubá, bolo de rolo, cocada, goiabada com queijo (Romeu e Julieta), doce de leite, quindim, pudim, suco de caju, cajuína, guaraná caseiro, café coado no coador de pano, empadão goiano, pequi com arroz, galinhada (com frango comprado no mercado, não criado), tutu de feijão, polenta frita, farofa de banana, sanduíche de mortadela, pastel de Belém? não — **pastel de nata** substituir por **"cueca virada"** e **"sonho de padaria"**.

Cada prato dá energia + buff específico e tem valor de venda. **Minijogo de cozinha** opcional (ritmo simples de mexer/virar), desligável nas opções.

---

## 10. PESCA, INSETOS, CATÁLOGO E MUSEU

- **Pesca:** minijogo de tensão de linha com barra (peixe puxa, jogador solta/recolhe), sombra do peixe na água indicando tamanho. Mais de **70 peixes** de água doce, salgada e salobra, cada um com bioma, horário, estação, clima, isca preferida e raridade (comum, incomum, raro, lendário).
- **Peixes lendários** (um por bioma, com missão): Pirarucu Ancião, Dourado Real do Pantanal, Tucunaré-Açu Dourado, Mero Gigante (proteção: só pode ser fotografado e solto), Jaú do Rio Grande, Surubim Pintado Gigante.
- **Insetos e pequenos animais:** mais de **60 espécies** (borboletas morpho, borboleta-oitenta-e-oito, besouro-hércules, louva-a-deus, esperança, cigarra, vaga-lume, joaninha, formiga-saúva, abelha jataí, bicho-pau, libélulas, caranguejos, sapos como o sapo-cururu e a perereca-de-vidro, lagartos como o calango e o teiú, jabuti).
- **Catálogo da Biodiversidade:** fichas ilustradas em estilo aquarela de naturalista, com nome popular, nome científico, bioma, curiosidade educativa verdadeira e status de conservação (inspirado em dados reais simplificados).
- **Espécies protegidas** (onça, arara-azul, mico-leão-dourado, tartaruga-marinha, ararinha-azul, lobo-guará, tamanduá-bandeira, peixe-boi, boto): **só podem ser fotografadas**, nunca capturadas; foto rara vale muito para o Museu e a Brigada.
- **Museu de História Natural:** alas de Peixes, Insetos, Fósseis (dinossauros brasileiros fictícios inspirados em achados reais do Brasil, preguiça-gigante, tigre-dentes-de-sabre sul-americano), Arqueologia (cerâmica marajoara estilizada original, pinturas rupestres — representadas com respeito e contextualização), Minerais e Gemas, Fotografia de Fauna. Visitação com placas legendadas e turistas.

---

## 11. FAUNA SELVAGEM: IA E COMPORTAMENTO

- Máquina de estados (ou Behavior Tree simples) por animal: `Idle`, `Wander`, `Graze/Forage`, `Flee`, `Curious`, `Sleep`, `Drink`, `Swim`, `Flock` (bandos: capivaras, emas, araras, quero-queros), `Territorial` (quero-quero dá rasante; tuiuiú intimida), `Stalk` (onça, só em defesa do território ou se provocada).
- **Ciclo diário:** noturnos (tatu, lobo-guará, vaga-lume, corujas, morcegos), diurnos, crepusculares.
- **Interações amigáveis:** alimentar capivaras (ganha amizade e elas seguem o jogador), fazer carinho em animais resgatados, guiar filhotes de tartaruga ao mar (minijogo noturno), soltar animais reabilitados.
- **Perigos:** onça, sucuri, jacaré (se muito perto), cascavel e jararaca, piranhas em cardume (dano leve na água), enxame de marimbondos. Dano derruba o jogador, que acorda no Posto de Saúde perdendo uma pequena taxa em dinheiro (nunca itens). Sem morte explícita.
- **Ecossistema leve:** populações regeneram por bioma; caça não existe; excesso de corte de árvores reduz animais e diminui a nota da vila — incentivo ao replantio.
- Todos os animais sincronizados pelo host; clientes interpolam posições.

---

## 12. FOLCLORE E EVENTOS ESPECIAIS

Criaturas do folclore aparecem como **personagens mágicos benevolentes/travessos** em eventos, sempre apresentados com respeito e como mitologia:
- **Saci-Pererê:** redemoinhos de vento que roubam um item da mochila por brincadeira; missão para recuperá-lo com um "gorro vermelho" e ganhar um amigo que dá dicas.
- **Curupira:** guardião da mata; aparece se o jogador for bom com a floresta (muito replantio) e dá o "Facão do Curupira". Se houver desmatamento excessivo, faz o jogador se perder na mata (pegadas ao contrário).
- **Boto:** aparece como moço de chapéu branco nas festas juninas ribeirinhas; conversa enigmática e presentes.
- **Iara:** canto no rio ao anoitecer; minijogo musical que dá isca lendária.
- **Mula sem cabeça:** "cavalo de fogo" inofensivo visto galopando ao longe em noites de sexta; conquista por fotografá-lo.
- **Cuca e Boitatá:** Boitatá como cobra de luz que protege campos contra queimadas (aliado no evento de brigada); Cuca como NPC bruxa-jacaré engraçada que vende poções de buff no mercado noturno lunar.
- **Lobisomem? (substituir por Corpo-Seco? evitar temas pesados)** → usar **Negrinho do Pastoreio?** Tema sensível: **não usar**. Usar **Caipora** (variante protetora dos animais) e **Vitória-régia (lenda de Naiá)** como evento de florada noturna.

**Festivais do calendário (com decoração automática da vila, roupas temáticas, minijogos, NPCs participando):**
- **Carnaval** (verão): blocos de rua, escolha de fantasia, minijogo rítmico de samba/frevo/axé, desfile na avenida da vila, concurso de marchinha (letras originais geradas pelo jogo).
- **Festa Junina / Arraiá** (inverno): quadrilha com passos em minijogo de ritmo, fogueira, bandeirinhas, pescaria de brinquedo, correio elegante, barracas de comida típica, casamento caipira encenado pelos NPCs.
- **Festival de Parintins inspirado** → evento original "**Festival do Boi-Bumbá da Vila**" com dois grupos rivais de cores azul e vermelho criados pelo jogo.
- **Festa do Divino / Folia de Reis** (versão cultural festiva, cortejo com música).
- **Semana do Meio Ambiente:** plantio coletivo, soltura de animais.
- **Dia do Folclore (22 de agosto):** noite de lendas, todos os seres folclóricos aparecem.
- **Círio fluvial fictício "Procissão das Águas"** com barcos enfeitados (evento cultural de barcos, sem cunho religioso explícito).
- **Festa do Peão/Rodeio? (evitar)** → **Exposição Agropecuária**: concurso de animais bem cuidados, frutas gigantes, queijos.
- **Natal Tropical e Réveillon na praia:** roupas brancas, pular 7 ondas, fogos, lentilhas, desejos no mar.
- **Festival da Primavera do Ipê:** florada, piquenique, concurso de fotografia.
- **Torneio de Pesca** por estação, **Corrida de jangadas**, **Campeonato de futebol de várzea** (minijogo de futebol 3×3 com NPCs e jogadores — MUITO importante e divertido em multiplayer).

---

## 13. NPCs PRINCIPAIS (MÍNIMO 25 NOMEADOS NO LANÇAMENTO)

Cada NPC tem: nome, origem regional, profissão, personalidade (tipo: animado, rabugento-fofo, sonhador, atleta, intelectual, mãezona, festeiro, tímido), comidas favoritas/odiadas, presentes preferidos, rotina, aniversário, 10 níveis de amizade com eventos (cutscenes curtas), 150+ falas contextuais (clima, estação, festas, conquistas do jogador, fofocas sobre outros NPCs).

Exemplos iniciais:
1. **Dona Cida** (paulista do interior) — prefeita interina e guia do tutorial, fala "meu bem".
2. **Seu Zé Ferreiro** (mineiro) — ferreiro, calado, adora pão de queijo e café.
3. **Tia Nena** (baiana) — dona do quiosque de acarajé e moqueca, conselheira da vila.
4. **Raimundo "Mundinho"** (cearense) — repentista, vende cordéis, piadista.
5. **Iara Tikuna** (amazonense, indígena) — bióloga do Centro de Conservação, expert em fauna, apresentada como cientista e líder comunitária.
6. **Gaúcho Tonho** (gaúcho) — dono da estância de ovelhas, chimarrão, tchê.
7. **Juma** (paraense) — barqueira, piloto de voadeira, ama açaí com peixe.
8. **Lelê** (carioca) — surfista e salva-vidas, organiza o Carnaval.
9. **Dona Benedita** (quilombola goiana) — agricultora, sementes crioulas, doce de pequi.
10. **Kenji Nakamura** (paulistano descendente de japoneses) — dono do mercadinho e da horta hidropônica.
11. **Fátima Haddad** (descendente de libaneses de São Paulo) — dona da loja de tecidos, faz esfirra.
12. **Pedrinho** (criança curiosa) — coleciona insetos e desafia o jogador.
13. **Vó Zefa** (pernambucana) — rendeira de bilro, contadora de lendas.
14. **Carlão Pantaneiro** (sul-mato-grossense) — peão de comitiva, berrante, guia do Pantanal.
15. **Bia Arquiteta** (brasiliense) — projeta construções modernas, cobogós.
16. **Dr. Otávio** — médico do Posto de Saúde, hipocondríaco engraçado.
17. **Sargento Rita** — chefe da Brigada Ambiental.
18. **Mestre Bira** — capoeirista e músico, dá aula na praça (minijogo rítmico de capoeira-dança).
19. **Luana** (catarinense) — guia de ecoturismo da serra, pinhão.
20. **Seu Genésio** — dono do boteco de sucos e caldo de cana, fofoqueiro oficial.
21. **Professora Marta** — escola e biblioteca.
22. **Nando DJ** — rádio da vila.
23. **Dona Irene** — padeira.
24. **Tião do Engenho** — engenho e rapadura.
25. **Jaci** — artista de murais (grafite) que pinta pontos turísticos.

Além disso: **pets adotáveis** (vira-lata caramelo — obrigatório e icônico, gato frajola, papagaio que aprende frases que o jogador digita com filtro de palavrões).

---

## 14. ECONOMIA

- **Moeda:** "**Tostões (T$)**".
- Duas carteiras: **dinheiro pessoal** (cada jogador) e **Cofre da Vila** (compartilhado; alimentado por impostos leves das lojas, turismo e doações). Construções públicas usam o Cofre da Vila + recursos.
- **Preços dinâmicos** leves: vender muito do mesmo item baixa o preço temporariamente (recupera em dias); pedidos especiais pagam bônus.
- **Pedidos diários** no quadro de avisos e no Correio (entregar X itens), com recompensas em T$ e Pontos de Cidadania.
- **Feira livre:** jogadores montam barraca, definem preços, NPCs e turistas compram com IA baseada em preço justo e desejo.
- **Exportação** semanal pelo porto (vender em grandes quantidades).
- Balanceamento documentado em planilha `docs/economia.csv` com curvas de preço, tempo de crescimento e lucro/hora por atividade; nenhuma atividade deve ser mais de 2× mais lucrativa por hora que outra no mesmo estágio de jogo.

---

## 15. CRAFTING E DECORAÇÃO

- **Bancadas:** Bancada de Carpintaria, Mesa de Artesanato, Torno de Cerâmica, Tear, Forja, Fogão, Moinho, Destilaria de óleos essenciais (andiroba, copaíba — cosméticos), Mesa de Biojoias.
- **500+ itens de decoração/mobília** em conjuntos temáticos: Colonial Mineiro, Rede e Varanda Nordestina, Casa de Vó (toalhinha de crochê, filtro de barro, rádio antigo, estante com enfeites), Praia Caiçara, Galpão Gaúcho, Moderno Brasileiro (poltrona de design original inspirada no modernismo), Festa Junina, Carnaval, Amazônia Ribeirinha, Jardim Tropical.
- **Sistema de decoração livre** em grade + posicionamento livre (segurar Shift), empilhar itens em mesas/prateleiras, pendurar em paredes, pintar móveis.
- **Casa do jogador** expansível: barraca → barraco de pau a pique → casa de tijolo → sobrado → casarão, com cômodos adicionáveis, porão e varanda.
- **Paisagismo:** plantar flores, trilhas, fontes, bancos, postes, lagos com peixes ornamentais, jardins de bromélias e orquídeas, labirinto de cerca viva.

---

## 16. TRANSPORTE

- A pé, bicicleta (cestinha de carga), bicicleta cargueira, carroça com jegue/cavalo, cavalo (montaria com galope e pulo), moto de trilha, caminhonete (transporta 4 jogadores + carga, perfeita para multiplayer), canoa, voadeira, barco de pesca, balsa, **ultraleve** (voo livre sobre o mapa no fim do jogo), **teleférico turístico** entre morros (construção de vila), **trem turístico** (Maria-Fumaça) ligando biomas.
- Veículos sincronizados em rede com o motorista como autoridade de input e o host como autoridade física (ou o motorista com autoridade física + validação do host para reduzir latência; documentar a escolha em `DECISOES.md`).

---

## 17. HISTÓRIA E MISSÕES

**Capítulos principais (liberados pela nota da vila):**
1. **"Chegada"** (0★→1★): montar a barraca, conhecer Dona Cida, construir a Prefeitura provisória, receber os 3 primeiros moradores, consertar a ponte para o Cerrado.
2. **"Raízes"** (1★→2★): abrir feira, padaria, ferraria; restaurar o viveiro de mudas; primeira festa junina; conhecer Iara e o Centro de Conservação.
3. **"Rio Acima"** (2★→3★): restaurar o porto, ganhar a voadeira, abrir a Amazônia e o Pantanal; missão de resgate de animais numa enchente.
4. **"Sertão e Serra"** (3★→4★): trazer água ao Sertão com cisternas e açude (a Caatinga reverdece); abrir a estrada da serra; reintroduzir a ararinha-azul; Carnaval completo.
5. **"Cidade Maravilha"** (4★→5★): trem turístico, observatório, museu completo, grande festival final com todos os NPCs; cena final com mural gigante pintado por Jaci com fotos tiradas pelos jogadores durante a campanha (usar capturas reais do álbum do jogador).
6. **Pós-jogo:** Ilha de Corais, peixes e insetos lendários, conquistas raras, ranking de beleza da vila, desafios semanais gerados (pesca, coleta, construção).

**Missões secundárias:** 100+ (amizades, pedidos, caças ao tesouro com mapa rasgado, fotografias específicas, restauração de ruínas coloniais, mistério do sumiço do queijo do Seu Zé (é o Saci), etc.).

---

## 18. MULTIPLAYER (DETALHADO)

### 18.1 Modelo
- **Cooperativo de 1 a 6 jogadores**, **host autoritativo** (o host é também jogador — "listen server").
- Transportes: **SteamMultiplayerPeer** (P2P via Steam Networking Sockets, com relay da Steam, sem necessidade de abrir portas) como padrão; **ENetMultiplayerPeer** para LAN/IP direto (porta configurável, padrão 24565).
- Abstração `NetworkManager` que expõe a mesma API independente do transporte.

### 18.2 Lobbies Steam
- Criar lobby (público, somente amigos, privado/convite), nome do mundo, senha opcional, número máximo de jogadores, metadata (versão do jogo, nome da vila, nota ★, dia do jogo, modo de tempo).
- Navegador de lobbies com filtro por versão compatível e amigos em primeiro lugar.
- **Convites pelo overlay da Steam** (`join_requested`, `GameLobbyJoinRequested`) e "Entrar no jogo" pelo perfil do amigo (rich presence `connect`).
- Tratamento de erros com mensagens claras em pt-BR: versão diferente, lobby cheio, host saiu, conexão perdida, Steam não inicializada.

### 18.3 Sincronização
- **Jogadores:** `MultiplayerSynchronizer` com posição, rotação, animação atual, item na mão, montaria; interpolação no cliente com buffer de 100 ms; previsão local do próprio movimento com reconciliação suave.
- **Mundo:** o host guarda o estado canônico dos chunks (árvores, pedras, plantações, construções, itens no chão, altura do terreno). Clientes recebem **snapshot do chunk ao entrar na área** + **deltas via RPC confiável** (árvore cortada, planta regada, construção posicionada).
- **Ações:** o cliente envia *intenção* (`request_chop_tree(tree_id)`), o host valida (distância, ferramenta, energia, licença) e transmite o resultado a todos. Nunca confie no cliente para dinheiro, itens ou inventário.
- **Inventário:** autoritativo no host, espelhado para o dono; baús compartilhados com trava de uso (um jogador por vez) ou modo "vários veem, um modifica por vez com reservas".
- **Animais/NPCs:** simulados no host; transmissão de estado compacto a 10 Hz com prioridade por distância; fora do raio de interesse de um cliente, não são enviados (interest management por chunk).
- **Tempo e clima:** controlados pelo host; sono exige que **todos os jogadores durmam** (ou maioria configurável) para pular a noite, com indicador na tela.
- **Otimização:** empacotar deltas por frame, compressão, IDs inteiros compactos para entidades, limites de banda testados para 6 jogadores com ≤ 150 kbps por cliente.
- **Entrada no meio da partida:** o novo jogador recebe estado global + chunks ao redor da vila; aparece na rodoviária/porto com animação de chegada.
- **Saída do host:** salvamento automático imediato; clientes voltam ao menu com mensagem "O anfitrião encerrou a sessão; o progresso da vila foi salvo no mundo dele".
- **Dados dos convidados:** personagem, inventário, dinheiro pessoal e licenças de cada convidado são salvos **no mundo do host indexados pelo SteamID** e também uma cópia do personagem no save local do convidado (para levar o visual e cosméticos entre mundos, sem levar itens para evitar trapaça — configurável pelo host).
- **Permissões do host por jogador:** pode construir, pode demolir, pode usar o Cofre da Vila, pode editar terreno, pode abrir baús da casa do host.

### 18.4 Social em jogo
- Chat de texto com filtro de palavrões opcional, balões de fala sobre a cabeça, **roda de emotes** (acenar, dançar forró, samba, frevo, rir, bater palma, "joinha", deitar na rede), ping no mapa, marcadores de mapa compartilhados, fotos em grupo com timer de câmera.
- Chat de voz via Steam: não obrigatório; se implementado, usar a API de voz da Steam com proximidade (opcional nas configurações).
- **Atividades pensadas para grupo:** puxar rede de arrasto na praia (precisa de 2+), carregar tronco gigante de samaúma (2+), futebol de várzea, quadrilha junina (pares), corridas de bicicleta/cavalo, torneio de pesca com placar.

---

## 19. INTEGRAÇÃO COM A STEAM (GodotSteam)

- **Instalação:** addon GodotSteam GDExtension em `addons/godotsteam/`; em desenvolvimento usar **AppID 480** (Spacewar) com `steam_appid.txt` na raiz do projeto e ao lado do executável exportado; trocar para o AppID real antes do lançamento via constante única em `SteamManager`.
- **Exportação:** garantir que `steam_api64.dll` (Windows) e `libsteam_api.so` (Linux) sejam copiados ao lado do executável; configurar os presets de exportação com os arquivos da GDExtension incluídos; documentar em `docs/BUILD.md`.
- **Inicialização:** `Steam.steamInitEx()` no boot; se falhar, jogo roda em **modo offline** (single-player + LAN) com aviso, sem travar. Chamar `Steam.run_callbacks()` todo frame (ou usar o modo de callbacks embutido).
- **Conquistas (mínimo 50)**, exemplos:
  - "Pé na Estrada" — chegar à ilha.
  - "Primeiro Tijolo" — concluir a primeira construção.
  - "Vila de Respeito" / "Cidade Maravilha" — 3★ e 5★.
  - "Capivara Amiga" — fazer amizade com 10 capivaras.
  - "Olho de Naturalista" — fotografar todas as espécies protegidas.
  - "Arraiá Arretado" — vencer a quadrilha com nota máxima.
  - "Folia Completa" — participar de todos os festivais em um ano.
  - "Pirarucu Ancião", "Dourado Real" — peixes lendários.
  - "Amigo do Curupira" — plantar 1.000 árvores.
  - "Sertão Virou Mar" — reverdecer a Caatinga.
  - "Ararinha em Casa" — reintroduzir a ararinha-azul.
  - "Gol de Placa" — marcar 50 gols no futebol de várzea (multiplayer).
  - "Mutirão" — concluir uma construção com 4+ jogadores contribuindo.
  - "Caramelo Leal" — adotar o vira-lata caramelo.
  - "Saci Travesso" — recuperar o item roubado pelo Saci.
- **Estatísticas Steam** para conquistas progressivas (árvores plantadas, peixes pescados, T$ ganhos, dias jogados).
- **Rich Presence** em pt-BR/en: "Pescando no Pantanal — Vila ★★★ — Dia 45", com `steam_display` e tokens localizados.
- **Steam Cloud** para os saves (`user://saves/`), com resolução de conflito por data e aviso ao jogador.
- **Overlay:** pausar/mostrar indicador ao abrir overlay em single-player.
- **Steam Input:** suporte completo a controle com glifos dinâmicos (Xbox, PlayStation, Steam Deck).
- (Opcional pós-lançamento) **Steam Workshop** para projetos de casas e mapas de vila compartilhados.

---

## 20. SAVE/LOAD

- Formato: arquivo binário compactado com `FileAccess.open_compressed` + cabeçalho JSON legível (versão, nome da vila, dia, nota, miniatura PNG da última cena).
- **Versionamento de save** com funções de migração (`migrate_v1_to_v2`), testadas.
- Salvamento: automático ao dormir, a cada 10 min (configurável), ao sair; **3 slots de backup rotativos** por mundo para evitar corrupção.
- Mundos múltiplos (lista com miniatura), personagens separados de mundos.
- Salvar somente estado mutável (deltas) sobre a geração procedural com semente — manter saves pequenos (< 20 MB mesmo no fim do jogo).

---

## 21. INTERFACE (UI/UX)

- **Estilo visual da UI:** papel kraft, bordas de azulejo português estilizado, carimbos e selos de cordel, tipografia amigável e legível (fonte livre com licença OFL, suporte total a acentos pt-BR), ícones desenhados à mão estilo xilogravura colorida.
- **Telas:** Menu principal (com cena viva da vila ao fundo e música), Criar mundo, Carregar mundo, Multiplayer (hospedar/entrar/navegador/lobby com personagens dançando), Criador de personagem, Configurações, Créditos.
- **HUD:** relógio analógico estilizado + data + clima + estação, barras de vida e energia, barra rápida, minimapa circular (opcional), indicador de dinheiro, notificações empilháveis (item obtido, conquista, carta recebida), bússola de missão.
- **Menus em jogo (abas):** Mochila, Mapa (com marcadores, biomas desbloqueados, jogadores), Catálogo da Biodiversidade, Receitas, Missões/Pedidos, Carteirinhas, Relacionamentos (NPCs com corações), Celular do jogador (câmera, álbum de fotos, app de avaliações de turistas, previsão do tempo, rádio), Configurações.
- **Modo planejamento** com barra de ferramentas de construção, pré-visualização verde/vermelha, custos visíveis e recursos faltantes destacados.
- **Diálogos:** caixa com retrato animado do NPC, texto com efeito de digitação, vozinhas em balbucio com entonação diferente por NPC, escolhas de resposta que afetam amizade.
- **Controles:** teclado/mouse remapeáveis e gamepad completo; navegação de UI 100% por gamepad (foco visível).
- **Acessibilidade:** tamanho de texto, legendas para sons importantes, modos para daltonismo (protanopia, deuteranopia, tritanopia), desligar tremor de tela, desligar efeitos piscantes, pular minijogos de ritmo/cozinha (sucesso automático com recompensa padrão), velocidade do tempo ajustável (single-player), modo "sem perigos" (animais nunca atacam), segurar vs. alternar para ações repetitivas.

---

## 22. ÁUDIO E MÚSICA

- **Trilha original adaptativa** (camadas que entram/saem conforme hora, bioma, clima e atividade):
  - Vila de dia: **choro e MPB instrumental** (violão 7 cordas, cavaquinho, flauta, pandeiro).
  - Vila à noite: **bossa nova suave**.
  - Mata Atlântica: violão e flauta com sons de mata.
  - Cerrado: **viola caipira** e moda instrumental.
  - Amazônia: flautas, percussões de madeira, carimbó instrumental nas festas.
  - Pantanal: viola pantaneira, chamamé instrumental, berrante.
  - Caatinga: **forró pé-de-serra/baião** (sanfona, zabumba, triângulo), xote nas tardes.
  - Pampa: **milonga** e chamamé com acordeom.
  - Serra: música de câmara suave com violão e cordas.
  - Praia: **samba-reggae e ijexá** suaves.
  - Festas: samba-enredo original, frevo, marchinhas originais, quadrilha junina, boi-bumbá.
  - Grutas: ambient com gotas e ecos.
- **Ambiência por bioma e hora:** cigarras, sapos à noite, sabiá ao amanhecer, bugios na serra, ondas, chuva no telhado de zinco/telha, vento no Pampa, quero-queros, araras.
- **SFX** para todas as ações (cortar, minerar, regar, pescar, construir, UI).
- **Buses de áudio:** Master, Música, Efeitos, Ambiente, Vozes, UI; mixagem com sidechain leve (música abaixa em diálogos).
- **Rádio da vila:** estação com a trilha do jogo e "locutor" de texto engraçado com notícias do que os jogadores fizeram ("Atenção, vila! Fulano pescou um pirarucu de 2 metros!").
- Se o agente não puder compor áudio real, gerar trilhas via ferramentas/sintetizadores disponíveis e **documentar em `docs/AUDIO.md` exatamente quais faixas precisam ser produzidas por um compositor**, com BPM, instrumentação, clima e duração — e ainda assim deixar uma versão funcional (sintetizada/procedural) no jogo, nunca silêncio.

---

## 23. DESEMPENHO

- Streaming de chunks em thread (`WorkerThreadPool`), instanciação espalhada entre frames.
- MultiMesh para grama, flores, pedrinhas, cercas e árvores distantes; impostores para árvores longe.
- Occlusion culling (OccluderInstance3D) na vila e grutas; visibility ranges (HLOD) configurados.
- Sombras: cascatas ajustadas por preset; luzes da vila à noite com orçamento e desligamento por distância.
- Pooling de partículas, projéteis, itens no chão, sons.
- NPCs distantes rodam em "modo econômico" (lógica simplificada, sem animação completa).
- Presets gráficos: Baixo, Médio, Alto, Ultra, Deck; limite de FPS; V-Sync; escala de renderização (FSR 2 se disponível).
- Perfilar com o profiler e monitor do Godot em cada marco; registrar resultados em `docs/PERFORMANCE.md`.

---

## 24. TUTORIAL E ONBOARDING

- Primeiros 30 minutos guiados por Dona Cida com objetivos claros e curtos (nunca paredes de texto): montar barraca → roçar capim → cortar árvore → fazer fogueira → cozinhar milho → dormir → vender na feira → construir a Prefeitura provisória.
- Dicas contextuais únicas na primeira vez de cada ação (desativáveis).
- **"Diário de Bordo"** com resumo de tudo que foi ensinado.
- Em multiplayer, convidados novos veem o tutorial compacto em paralelo.

---

## 25. POLIMENTO E "GAME FEEL" (OBRIGATÓRIO)

- Animações de squash & stretch ao coletar, itens "pulando" para a mochila, partículas de folhas ao cortar, faíscas ao minerar, respingos d'água.
- Pequeno hitstop e tremor sutil (desligável) ao derrubar árvores e quebrar pedras.
- Árvores caem com física e rolam levemente; troncos viram itens.
- NPCs reagem ao jogador (acenam, comentam roupa nova, pulam de alegria com presente favorito).
- Pets seguem o jogador e cavam tesouros.
- Pôr do sol com bandos de araras ou garças cruzando o céu.
- Easter eggs leves e originais (um tatu-bola que rola como bola de futebol; uma capivara "zen" meditando numa pedra).
- Transições suaves entre telas; nenhuma tela de loading maior que 5 s em SSD.

---

## 26. QA, TESTES E BUILD

- **Testes automatizados** (gdUnit4/GUT): inventário (empilhamento, limites), crafting (consome e produz corretamente), economia (preço dinâmico), calendário (virada de estação/ano), crescimento de plantas, save/load round-trip (salvar e carregar resulta no mesmo estado), migração de save, validação de RPCs (rejeitar ações inválidas).
- **Testes de rede:** rodar 2–4 instâncias locais (Debug → "Run Multiple Instances") com ENet; testar entrada/saída no meio, latência simulada, perda de pacotes; testar Steam P2P com duas contas quando possível.
- **Checklist manual** em `docs/QA_CHECKLIST.md` por sistema.
- **Build:** presets de exportação Windows x64 e Linux x64; ícone do jogo, nome, versão (`1.0.0`), splash screen com logo original "Vila Ipê" (ipê florido + casinha colonial). Script `build.sh`/`build.ps1` que exporta ambos e copia DLL/SO + `steam_appid.txt` (somente em builds de teste).
- **Preparação Steam:** estrutura de depots documentada (`docs/STEAM_RELEASE.md`), descrição da loja em pt-BR e inglês, lista de tags (Farming Sim, Life Sim, City Builder, Co-op, Open World, Cute, Relaxing, Crafting), requisitos mínimos e recomendados, sugestões de capturas de tela a gerar in-game.

---

## 27. PLANO DE EXECUÇÃO POR MARCOS

Execute nesta ordem. Não avance sem cumprir o "pronto quando" do marco anterior.

**M0 — Fundação (pronto quando: projeto abre, Steam inicializa ou cai em modo offline sem erro, dois jogadores se conectam via ENet e se veem andando)**
Projeto Godot, pastas, Git/LFS, autoloads vazios porém funcionais, GodotSteam instalado, NetworkManager com ENet e Steam, jogador cápsula sincronizado, câmera orbital, input map completo.

**M1 — Pipeline de arte (pronto quando: personagem rigado e animado do Blender anda no Godot em rede)**
Paleta global, script de exportação em lote no Blender via MCP, personagem base com rig e 15 animações essenciais, criador de personagem mínimo, shaders toon/vento/água básicos.

**M2 — Mundo e coleta (pronto quando: dá para explorar a Mata Atlântica e o Cerrado, coletar, e isso aparece igual para todos os jogadores)**
Terreno por chunks com streaming, geração procedural com semente, árvores/pedras/arbustos, ferramentas tier 1, inventário e barra rápida, itens no chão, sincronização de mundo por deltas, dia/noite e clima básico.

**M3 — Vida básica (pronto quando: loop de um dia completo funciona — coletar, cozinhar, vender, dormir e salvar/carregar)**
Energia/vida, culinária inicial, feira/loja, dinheiro, casa-barraca, dormir para pular a noite (todos os jogadores), save/load completo com migração.

**M4 — Vila (pronto quando: jogadores constroem prédios em conjunto, moradores chegam e trabalham sozinhos)**
Modo planejamento, canteiros de obra, 10 construções iniciais, 6 NPCs com rotina, diálogo e amizade, empregos automatizados, nota da vila 0★→2★, Prefeitura e Carteirinhas.

**M5 — Natureza viva (pronto quando: pesca, insetos, fauna com IA e catálogo/museu funcionam)**
Pesca com minijogo, puçá, 30 peixes, 25 insetos, 15 animais com IA, Museu, Catálogo, fotografia, espécies protegidas.

**M6 — Agricultura e criação (pronto quando: fazenda completa com estações)**
Plantio completo, estações, 30 culturas, árvores frutíferas, criação de 6 animais, produção (casa de farinha, engenho, queijaria).

**M7 — Expansão de biomas (pronto quando: todos os 9 biomas estão acessíveis por progressão)**
Amazônia, Pantanal, Caatinga, Pampa, Serra, Litoral, Grutas com fauna, flora, peixes, recursos e músicas próprios; barcos, montarias, veículos.

**M8 — Conteúdo completo (pronto quando: história principal jogável de ponta a ponta até 5★)**
Todos os 25+ NPCs, 5 capítulos, festivais e folclore, 120 receitas, 500 itens de decoração, 70 peixes, 60 insetos, turismo, todos os comércios e produções.

**M9 — Steam e polimento (pronto quando: conquistas, rich presence, cloud, convites e overlay funcionam; jogo sem bugs conhecidos de gravidade alta)**
50+ conquistas, stats, lobbies com convites, Steam Input, UI final, acessibilidade, localização en/es, trilha e SFX completos, game feel, otimização nos presets.

**M10 — Lançamento (pronto quando: builds Windows/Linux exportadas, testadas em máquina limpa, documentação completa)**
QA completo, balanceamento final com `economia.csv`, build scripts, `STEAM_RELEASE.md`, créditos, página de loja em rascunho.

---

## 28. DEFINIÇÃO DE "JOGO FINALIZADO"

O jogo só é considerado pronto quando **todos** os itens abaixo forem verdadeiros:
- [ ] É possível começar um mundo novo e chegar a **Vila 5★ e à cena final** sem bugs bloqueadores, sozinho e em grupo de 4.
- [ ] Todos os 9 biomas, 25+ NPCs, festivais, peixes, insetos, fauna, culturas, receitas e construções listados existem com arte final (sem placeholder).
- [ ] Multiplayer via Steam (convite de amigo) e LAN funcionando com 6 jogadores, incluindo entrada/saída no meio da partida e persistência dos convidados.
- [ ] Conquistas, estatísticas, rich presence e Steam Cloud funcionando; jogo roda offline se a Steam não estiver aberta.
- [ ] Save/load confiável, com backups e migração testados.
- [ ] 60 FPS no preset Médio em hardware alvo; sem travadas perceptíveis ao trocar de chunk.
- [ ] Controle e teclado/mouse completos; UI navegável por gamepad; opções de acessibilidade funcionando.
- [ ] Textos 100% localizados em pt-BR, en, es; nenhum texto fixo sem `tr()`.
- [ ] Música e ambiência em todos os biomas e festas; nenhum momento em silêncio acidental.
- [ ] Todos os testes automatizados passam; `QA_CHECKLIST.md` completo.
- [ ] Builds exportadas com DLL/SO da Steam corretas e documentação de build e publicação escrita.
- [ ] **É divertido:** cada sessão de 20 minutos entrega pelo menos uma descoberta, uma melhoria visível na vila e um momento de interação com NPC ou com outro jogador.

---

## 29. COMO VOCÊ (AGENTE) DEVE SE COMPORTAR DURANTE A EXECUÇÃO

- Comece lendo este documento inteiro e criando `docs/PROGRESSO.md` com todos os marcos e subtarefas como checklist.
- Antes de cada marco, escreva um mini-plano técnico (arquivos a criar, cenas, recursos, riscos) em `docs/PLANOS/Mx.md`.
- Use o Blender MCP de forma iterativa: modele, **renderize uma prévia**, avalie visualmente se está coerente com a direção de arte, ajuste, só então exporte.
- Reutilize ao máximo: rigs, animações, materiais, cenas base (`BaseInteractable`, `BaseAnimal`, `BaseNPC`, `BaseBuilding`, `BaseTool`) com herança e composição.
- Quando uma decisão não estiver coberta aqui, escolha o que melhor serve aos **cinco pilares de design** e registre em `DECISOES.md`.
- Se algo for tecnicamente impossível no ambiente (ex.: produzir áudio gravado de verdade), implemente a melhor alternativa funcional e documente o que falta para um humano completar.
- Ao final, gere `docs/RESUMO_FINAL.md` com: o que foi feito, como compilar, como testar multiplayer, como trocar o AppID, pendências conhecidas e sugestões de atualização pós-lançamento (novos biomas como Fernando de Noronha fictício, casamento com NPCs, Workshop, modo criativo).

**Agora comece pelo Marco M0.**