class_name BnBRain
extends BossAbility

# In this attack, piano tiles drop from the air and hit you.

@export var is_tgt : bool = false
@export var projectile_scene : PackedScene

@export_group("Biano Specific")
@export var wait_time : float # this is long it takes for Biano to "shoot" it into the skies and then the tiles show up.
@export var biano_num_per_attack : int

@export_subgroup("Motar Visuals")
@export var num_of_visuals : int
@export var visual_time_between : float
@export var visual_tile_speed : float
@export var tile_visual : Sprite2D

@export_category("Attack settings")
@export var height : float # How far you drop.
@export var num_per_attack : int
@export var offset_from_center : float

# Max distance a tile will spawn (starting from offset)
@export var rain_range : float
@export var frequency : float # How many attacks per second.

@export_subgroup("Attacking player")
@export var num_per_player : int
@export var range_from_player : float

@export_category("Projectile settings")
@export var speed : float
@export var dmg : float

var visual_count

func enter() -> void:
	super()
	if is_tgt:
		$BianoWaitTimer.start(wait_time)
		$GPUParticles2D.visible = true
		spawn_visual()
		visual_count = 1
		$SpawnVisualsTimer.start(visual_time_between)
	else:
		current_time = 1/frequency
	
func exit() -> void:
	super()
	$BianoWaitTimer.stop()
	$AfterProjectileTimer.stop()
	$SpawnVisualsTimer.stop()
	$GPUParticles2D.visible = false
	$GPUParticles2D.emitting = false

func update(_delta: float) -> void:
	super(_delta)
	if is_tgt:
		biano_update_loop(_delta)
	else:
		bnb_update_loop(_delta)


###
# 1. Spawn pattern, ring like (hades, turn around)
# 2. Choose like 5-6 random directions, and spawn them at the same time.

func spawn_pattern() -> void:
	if !multiplayer.is_server(): return
	
	var spawn_position : Vector2
	var rand_rotation : float
	var rand_position : int
	var rotation_vec : Vector2
	# decide location and spawn.
	for x in num_per_attack:
		# decide random direction vector.
		rand_rotation = randf_range(0,360)
		rotation_vec = Vector2.UP.rotated(rand_rotation)
		
		rand_position = randi_range(0, int(rain_range))
		
		spawn_position = global_position + ((offset_from_center + rand_position) * rotation_vec)
		spawn_position.y -= height
		spawn_projectile(spawn_position)

func spawn_near_players() -> void:
	if !multiplayer.is_server(): return
	
	var spawn_position : Vector2
	var rand_rotation : float
	var rand_position : Vector2
	var rotation_vec : Vector2
	
	for player in GameManager.Instance.players:
		if !player.is_alive(): continue
		for x in num_per_player:
			# Add a random position point within range.
			rand_position.x = randf_range(-range_from_player, range_from_player)
			rand_position.y = randf_range(-range_from_player, range_from_player)
			
			spawn_position = player.global_position + rand_position
			spawn_position.y -= height
			spawn_projectile(spawn_position)

func spawn_projectile(gpos : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.is_rain = true
	
	copy.height = height
	copy.dmg = dmg
	copy.spd = speed
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	
	# spawn in network node for sync
	GameManager.Instance.net.spawnable_path.add_child(copy, true)

func bnb_update_loop(_delta : float) -> void:
	current_time += _delta
	if current_time >= 1/frequency:
		spawn_pattern()
		spawn_near_players()
		current_time = 0


#region falling tiles attack (Biano normal attack)
func biano_update_loop(_delta :float) -> void:
	# We dont use this but we use timers for some bloody reason.
	pass

# For each player, we spawn a few around them.
func biano_spawn_pattern():
	if !multiplayer.is_server(): return
	
	var spawn_position : Vector2
	var rand_rotation : float
	var rand_position : Vector2
	var rotation_vec : Vector2
	
	for player in GameManager.Instance.players:
		if !player.is_alive(): continue
		for x in biano_num_per_attack:
			# Add a random position point within range.
			rand_position.x = randf_range(-range_from_player, range_from_player)
			rand_position.y = randf_range(-range_from_player, range_from_player)
			
			spawn_position = player.global_position + rand_position
			spawn_position.y -= height
			spawn_projectile(spawn_position)
	$AfterProjectileTimer.start(height/speed)
	#print("waiting to drop!")

func _on_biano_wait_timer_timeout() -> void:
	biano_spawn_pattern()

func _on_after_projectile_timer_timeout() -> void:
	if boss.falling_tiles_count >= 3:
		state_change.emit(self, "BianoIdle")
		return
	else:
		boss.falling_tiles_count += 1
		state_change.emit(self, "BnBRain")

#endregion

#region falling tiles motar animation


func spawn_visual() -> void:
	var copy : NonInteractiveProjectile = tile_visual.duplicate()
	copy.set_projectile_stats(0, visual_tile_speed, 20)
	add_child(copy, true)
	copy.visible = true
	$GPUParticles2D.emitting = true
	$GPUParticles2D.restart()

func _on_spawn_visuals_timer_timeout() -> void:
	spawn_visual()
	visual_count += 1
	if visual_count >= num_of_visuals:
		$SpawnVisualsTimer.stop()
#endregion
# When the projectile lands we go back.
