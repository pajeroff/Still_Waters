class_name InteractablePoint
extends Area2D

signal activated(point: InteractablePoint, actor: Node2D)

@export var display_name := "Осмотреть"
@export_multiline var response := "Здесь пока тихо."

func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 0
	add_to_group("interactable")

func interact(actor: Node2D) -> void:
	activated.emit(self, actor)
