# Vila Ipê

Jogo 3D de vida, construção e terraformação ambientado no Brasil: refunde uma vila na Ilha do Ipê, molde o terreno, plante ipês, pesque, construa e receba moradores. Inspirado em Pokémon Pokopia, Dinkum e Go-Go Town (mecânica, não conteúdo).

> **Estado: protótipo inicial (pré-alfa).** Funciona e roda, mas o visual ainda é provisório (formas geradas por código). Veja `docs/ROADMAP.md`.

## Rodar
Requer **Godot 4.7.x** (https://godotengine.org). Abra a pasta no editor e aperte F5, ou:

```
godot --path .
```

Foto automática (QA): `godot --path . -- --shot` (salva em `user://` e fecha).

## Controles
| Ação | Tecla |
|---|---|
| Andar / correr / pular | WASD / Shift / Espaço |
| Câmera | botão direito (girar), roda (zoom) |
| Usar ferramenta do slot | botão esquerdo |
| Hotbar | 1–8 |
| Tamanho do pincel | Q / E |
| Inventário / bancada / construção / missões | Tab / R / B / J |
| Interagir / presentear | F / G |
| Pausa | Esc |
| Esconder HUD / foto / câmera de trailer | F1 / F2 / F4 |

## Estrutura
Veja `docs/ARQUITETURA.md`. Cada sistema é um `Feature` em `scripts/features/` carregado automaticamente.
