extends Area2D

const HitEffect = preload("res://Effects/HitEffect.tscn") 

export(bool) var showHit = true

func _on_Hurtbox_area_entered(area):
	if showHit:
		var hitEffect = HitEffect.instance()
		var main = get_tree().current_scene
		main.add_child(hitEffect)
		hitEffect.global_position = global_position - Vector2(0, 12)
