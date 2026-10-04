extends Node
## Autoload: registra as entradas antes de qualquer cena.

func _init() -> void:
	InputSetup.register()
