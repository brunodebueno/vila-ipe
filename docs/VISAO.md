# Vila Ipê — Visão do jogo e direção de arte

> Este é o **alvo**. O jogo hoje ainda está longe dele (formas de caixa, sem animação, UI crua). Fonte completa: `docs/PROMPT_MESTRE.md`.

## Em uma frase
Um jogo **aconchegante e colorido** em que você refunda uma vila na **Ilha do Ipê**: molda o terreno, planta ipês, pesca, constrói casas coloridas e recebe moradores — tudo com cara, som e sabor do **Brasil**.

Inspiração de mecânica (não de conteúdo): Pokémon Pokopia (moldar o terreno), Dinkum (exploração e licenças), Go-Go Town (vila que trabalha sozinha).

## Pilares
1. **Aconchego brasileiro:** calor, cor, música, comida, gente simpática, humor leve.
2. **Liberdade de exploração:** biomas distintos, sempre algo novo.
3. **Construir junto:** a vila é do grupo (cooperativo no futuro).
4. **Natureza viva e respeitada:** replantar, proteger espécies, catalogar.
5. **Progressão constante:** em 20 min o jogador sente que avançou.

## Direção de arte
**Estilo:** 3D **estilizado suave e polido**, no nível de acabamento de **Dinkum, Go-Go Town e Pokémon Pokopia**. **NÃO é low-poly facetado**: superfícies lisas e arredondadas (normais suaves, bevels em tudo), volumes gordinhos e "de massinha/vinil", texturas pintadas limpas, cores **saturadas porém harmônicas**, iluminação macia (sombras suaves, oclusão ambiente, leve rim light, bloom discreto), subsurface sutil em folhas. Aparência "feito à mão e fofo", nunca realista, nunca cinza, nunca pontiagudo ou com quinas duras.

**Referências de acabamento (não copiar):** modelos de Dinkum e Go-Go Town (formas simples mas bem arredondadas, materiais pintados), terreno e vegetação do Pokopia (grama exuberante, árvores com copas volumosas e macias, água cristalina).

**Personagens:** modelos suaves e bem acabados, "chibi moderado" (cabeça ≈ 1/4 do corpo), mãos simples, **olhos grandes e expressivos**, silhueta única por personagem (chapéu de palha, avental, violão, bengala). Pele e cabelos diversos (crespo, cacheado, tranças…), sem caricatura. Animações exageradas e fofas (squash & stretch).

**Paleta-base:** verde-folha quente `#6dbf4f`, **amarelo-ipê** `#ffc928`, **roxo-ipê** `#b85fd9`, terracota de telha `#c4623a`, azul-azulejo `#7fb8e0`, turquesa de água `#4fd6c8`, areia `#f0d79c`, madeira `#a0693a`. Por bioma: Cerrado dourado/ocre, Amazônia verdes profundos, Caatinga terracota/prata, Pantanal azul/laranja de pôr do sol, etc.

**Arquitetura:** casario colonial colorido (Paraty/Ouro Preto), palafitas, taipa, galpão gaúcho, casa caiçara, moderno brasileiro com cobogós. Telhas de barro, janelas e portas de madeira, varandas, bandeirinhas de festa junina.

**Mundo:** terreno em blocos de bordas arredondadas e suavizadas (estilo Pokopia/Dinkum), grama com tufos balançando, água turquesa com espuma, céu de pôr do sol dourado, pétalas de ipê caindo, vagalumes à noite, luz quente saindo das janelas.

## Direção de UI
- **Material:** papel kraft, madeira pintada e **azulejo português** nas bordas; carimbos e selos de cordel; ícones desenhados à mão (xilogravura colorida), **não** quadradinhos de cor.
- **Formas:** cantos bem arredondados, botões "gordinhos" com sombra suave, animação de pulinho ao passar o mouse, tudo com leve inclinação orgânica.
- **Tipografia:** fonte amigável e grossa (licença OFL, acentos pt-BR) para títulos; legível para o texto.
- **HUD:** relógio estilizado + clima + estação, hotbar de madeira com ícones, moedas (Tostões T$), toasts com ícone do item, rastreador de missão em papel, prompt "[F] Falar".
- **Menu principal:** a própria ilha ao vivo ao pôr do sol, bandeirinhas no topo, título "Vila Ipê" grande, subtítulo "Refunde a vila. Plante o Brasil."
- **Diálogo:** balão com retrato do personagem (olhos expressivos), texto digitando, vozinha em balbucio.

## Som
Trilha original em estilos brasileiros: choro/MPB de dia, bossa à noite, forró, viola caipira, chamamé conforme o bioma. Ambiência: cigarras, sapos, ondas, chuva no telhado. Hoje tudo é **sintetizado por código** (placeholder); ver `docs/AUDIO.md` quando existir.

## Como chegamos lá (pipeline de arte)
1. **Conceito:** gerar imagem de referência no Mixar (`image_gen`, modelo GPT Image) com o prompt de estilo acima, fundo branco, vista 3/4.
2. **3D:** `model_3d` a partir da imagem (Tripo/Meshy/Hunyuan) em **qualidade média/alta** (malha suave, sem `face_limit` agressivo); suavizar normais e limpar se preciso. Orçamento: personagem 15–40 mil tris, árvore 5–15 mil, casa 10–30 mil, prop 500–5 mil, com LODs.
3. **Exportar:** `export_scene` em `.glb` → `assets/models/<categoria>/<id>.glb` (origem na base, 1 unidade = 1 m, frente −Z).
4. **No jogo:** `PropLibrary` troca o modelo de caixas pelo `.glb` automaticamente (mesmo id).
5. **Consistência:** todos os prompts partem do mesmo bloco de estilo e da mesma paleta; revisar em "folhas de contato" antes de exportar.

Bloco de estilo para prompts:
> *stylized 3D game asset, smooth rounded chunky shapes, soft bevels, clean hand-painted textures, soft saturated warm colors, polished cozy-game look like Dinkum and Pokemon Pokopia, Brazilian theme, cute, not low-poly, no sharp edges, centered, plain white background, 3/4 view*

## O que NÃO é o jogo (por enquanto)
Multiplayer, Steam, 9 biomas e 3.000 assets são **metas de longo prazo**. O próximo marco real é: **uma ilha pequena, bonita e divertida de jogar por 20 minutos** (ver `docs/ROADMAP.md`, Fases 1–3).
