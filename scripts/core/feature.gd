class_name Feature
extends Node
## Base de um módulo de gameplay. Arquivos em res://scripts/features/*.gd (que estendem Feature)
## são instanciados automaticamente por main.gd, em ordem alfabética, e recebem install(ctx).
## Assim cada sistema se pluga no jogo sem editar main.gd.

func install(_ctx: GameContext) -> void:
	pass
