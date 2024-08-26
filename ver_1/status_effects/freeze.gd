class_name Freeze
extends BaseStatus

var unfreeze_dmg : int # additional damage dealt when unfreezing by dealing damage
var duration : float # duration of the freeze status
var duration_time : float # the amount of time currently being frozen

var initial_health : int # health of the character at the start of freeze
var dmg_taken : int
var dmg_threshold : int # damage required to unfreeze

# Constructor, affects new() function for creating new copies of Freeze.
func _init(_unfreeze_dmg : int, _duration : float, _dmg_threshold : int) -> void:
	unfreeze_dmg = _unfreeze_dmg
	duration = _duration
	dmg_threshold = _dmg_threshold
	pass

func on_added() -> void:
	dmg_taken = 0
	if character.frozen == false:
		duration_time = 0
		initial_health = character.current_health
		freeze()

func update(delta:float) -> void:
	duration_time += delta
	dmg_taken = initial_health - character.current_health
	
	## remove me
	if duration_time >= duration or dmg_taken >= dmg_threshold:
		if character.frozen == true:
			holder.remove_status(self)

func on_removed() -> void:
	unfreeze()

func freeze():
	if "can_move" in character:
		character.frozen = true
		character.can_move = false
		character.modulate = Color.SKY_BLUE

func unfreeze():
	if "can_move" in character:
		character.frozen = false
		character.can_move = true
		character.modulate = Color.WHITE
		
		if dmg_taken >= dmg_threshold:
			character.take_damage(unfreeze_dmg)
