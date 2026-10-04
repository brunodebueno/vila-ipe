# Roadmap

Avaliação honesta: o jogo hoje é um protótipo técnico. Mundo e ferramentas funcionam, mas **o visual é feio** (bonecos e casas de caixas, sem animação), há pouco conteúdo e nada foi balanceado. A prioridade é **aparência e "sensação boa"** antes de mais sistemas.

## Fase 1 — Fazer rodar bem (curto prazo)
- [ ] Jogar cada módulo de ponta a ponta e corrigir bugs (loja, crafting, construção, pesca, diálogo, diário).
- [ ] Testar save/load de ida e volta; ligar menu principal como cena inicial.
- [ ] Hotbar e HUD: legibilidade e layout sem sobreposição; escala em 1080p.
- [ ] Testes automatizados da lógica pura (Inventory, receitas, economia, save).
- [ ] CI simples: `godot --headless --import` falha o build em erro de parse.

## Fase 2 — Visual (maior alavanca)
- [ ] Modelos reais via Mixar (imagem → 3D → glb): ipê amarelo/roxo, palmeira, jabuticabeira, 4 casas coloniais, capivara, personagem e NPCs, barraca, móveis.
- [ ] Personagem rigado com animações (idle, andar, correr, cortar, pescar, sentar).
- [ ] Paleta de cores e estilo único (toon suave, contorno), terreno com bordas arredondadas e texturas.
- [ ] Água, grama e céu revisados; partículas de pétalas, vagalumes, luzes de janela à noite.
- [ ] Ícones de item desenhados (hoje são quadrados coloridos); UI com identidade (papel kraft, azulejo).

## Fase 3 — Jogabilidade (o que torna divertido)
- [ ] Loop claro: plantar → ver a ilha mudar → atrair moradores → desbloquear.
- [ ] Terraformação mais satisfatória (animações, som, desfazer, pré-visualização de altura).
- [ ] Moradores com rotina real, casas atribuídas, pedidos e amizade.
- [ ] Mais conteúdo: peixes, insetos, receitas, decorações, estações e clima com efeito no jogo.
- [ ] Tutorial guiado e diário de bordo.

## Fase 4 — Polimento e lançamento de demo
- [ ] Música e SFX de verdade (hoje procedural); mixagem.
- [ ] Otimização (MultiMesh p/ árvores e grama, LOD, culling); 60 FPS em GPU média.
- [ ] Câmera de trailer afinada e trailer de 60 s.
- [ ] Exportação Windows, ícone, splash, página de apresentação.

## Futuro
Biomas extras (Cerrado, Pantanal, Caatinga…), multiplayer cooperativo, Steam, localização en/es.
