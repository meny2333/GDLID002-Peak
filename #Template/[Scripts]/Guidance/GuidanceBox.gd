extends Area3D
class_name GuidanceBox

@export var trigger_distance: float = 1.0
@export var appear_distance: float = 600.0
@export var can_be_triggered: bool = true
@export var have_line: bool = true

var _player: Player
var _root: Node3D
var _sprite: Sprite3D
var _trigger_effect: PackedScene
var _index: int = 0
var _initialized: bool = false

var triggered: bool = false
var _displayed: bool = false

func _ready() -> void:
	_try_initialize()

func _try_initialize() -> bool:
	if _initialized:
		return true

	var player: Player = Player.instance
	if not is_instance_valid(player):
		return false

	_player = player
	_root = $".."
	_sprite = $"../Sprite3D"
	_trigger_effect = load("res://#Template/[Resources]/Triggered.tscn")
	_initialized = true
	_check_initial_distance()
	return true

func _check_initial_distance() -> void:
	var dist_sq: float = global_position.distance_squared_to(_player.global_position)
	if dist_sq > appear_distance:
		_disappear(false)

func _process(_delta: float) -> void:
	if not _try_initialize():
		return

	if triggered:
		return

	if not is_instance_valid(_player):
		_initialized = false
		return

	var dist_sq: float = global_position.distance_squared_to(_player.global_position)

	if not _displayed and dist_sq <= appear_distance:
		_appear()

	if LevelManager.Clicked and can_be_triggered and dist_sq <= trigger_distance * trigger_distance:
		if LevelManager.GameState == LevelManager.GameStatus.Playing and not _player.disallowInput:
			_trigger()

func _trigger() -> void:
	triggered = true
	set_process(false)
	_disappear(true)
	var effect: Node3D = _trigger_effect.instantiate() as Node3D
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position
	await get_tree().create_timer(1.0).timeout
	effect.queue_free()

func set_color(color: Color) -> void:
	if not _sprite:
		_sprite = $"../Sprite3D"
		if not _sprite:
			push_warning("GuidanceBox: Sprite3D not found at ../Sprite3D")
			return
	_sprite.modulate = color

func _appear() -> void:
	if not _displayed:
		_displayed = true
		_index = LevelManager.checkpoint_count
		_root.visible = true
		_sprite.visible = true
		LevelManager.add_revive_listener(_reset_data)

func _disappear(only_box: bool) -> void:
	if only_box:
		_sprite.visible = false
	else:
		_root.visible = false
		_sprite.visible = false

func _reset_data() -> void:
	LevelManager.remove_revive_listener(_reset_data)
	_displayed = false
	triggered = false
	set_process(true)
	_disappear(false)

func _on_taper_entered(body: Node3D) -> void:
	pass

func _on_taper_exited(body: Node3D) -> void:
	pass

func _exit_tree() -> void:
	LevelManager.remove_revive_listener(_reset_data)
