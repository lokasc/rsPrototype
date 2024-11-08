# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
class_name BassheartFreeze
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg : float
@export var initial_cd : int
## time it takes to charge
@export var charge_duration : float
## time it takes to shoot out the wave
@export var active_duration : float
@export var zero_cd : bool = false

@export_category("Empowered game stats")
@export var is_empowered : bool
@export var area_multiplier : float
@export var freeze_duration_multiplier : float
@export var damage_multiplier : float

@export_category("Freeze stats")
@export var freeze_duration : float
@export var unfreeze_dmg : float
@export var dmg_threshold : float

@export_category("Beat sync stats")
## The incremental times for each note, meaning the float will be the note length added to the previous notes. It won't be greater than the charge duration. Here are the notes translated to time in 120 bpm: 1/16 = 0.125s, 1/8 = 0.25s, 1/4 = 0.5s, 3/8 = 0.75s, 1/2 = 1.0s, 3/4 = 1.5s, 1/1 = 2.0s. For more information visit https://toolstud.io/music/bpm.php 
@export var recast_timestamps : Array[float]
@export var sync_area_multiplier : float
@export var sync_dmg_multiplier : float
@export var recast_grace_time : float

var is_charging : bool
var is_enlarged : bool

var note_count : int = 0
var synced_amount : int = 0
var current_charge_time : float

@onready var bc : BeatController = GameManager.Instance.bc
@onready var beat_visual : BeatVisualizer = GameManager.Instance.ui.player_ui_layer.get_node("BeatVisualizerLines")
@onready var beat_visual2 : BeatVisualizer = GameManager.Instance.ui.player_ui_layer.get_node("BeatVisualizerLines2")
@onready var wave_timer : Timer = $WaveTimer
@onready var charge_timer : Timer = $ChargeTimer
@onready var hitbox : Area2D = $HitBox
@onready var hitbox_shape : CollisionPolygon2D = $HitBox/CollisionShape2D

@onready var beat_sync_effects : GPUParticles2D = $"../Sprites/BeatSyncEffect"
@onready var freeze_effect_sprite : AnimatedSprite2D = $"../Sprites/RotatingWeapon/FreezeEffectSprite2D"
@onready var indicator : Area2D = $IndicatorBox

# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init() -> void:
	super()
	pass

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	action_icon_path = "res://assets/icons/bassheart_freeze_icon.png"
	desc = "Freezes enemies towards mouse direction.\nDealing enough damage to frozen enemies will do additionall damage.\nBeat Sync: Increases the range.\nEmpowered: Increases range and freeze duration"

func _ready() -> void:
	super()
	hitbox.area_entered.connect(on_hit)
	hitbox.visible = false
	hitbox.monitoring = false
	indicator.visible = false
	indicator.monitoring = false
	if zero_cd:
		a_stats.cd = 0
	# Sets the note to max duration if it exceeds the duration
	for note in recast_timestamps:
		if note > charge_duration:
			note = charge_duration

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter() -> void:
	super()
	set_ability_to_hero_stats()
	is_charging = true
	is_empowered = hero.is_empowered
	charge_timer.start(charge_duration + recast_grace_time)
	indicator.visible = true
	indicator.monitoring = true
	if is_empowered:
		hitbox_shape.scale *= area_multiplier
		freeze_effect_sprite.scale *= area_multiplier
		is_enlarged = true
	if is_synced:
		beat_sync_effects.restart()
		if hero.is_multiplayer_authority():
			beat_visual.show()
			beat_visual2.show()
		
		for timestamp in recast_timestamps:
			beat_visual.spawn_note(timestamp, Vector2(-timestamp*400,0))
			beat_visual2.spawn_note(timestamp, Vector2(timestamp*400,0))

func _on_charge_timer_timeout() -> void:
	hitbox.monitoring = true
	hitbox.visible = true
	indicator.visible = false
	indicator.monitoring = false
	is_charging = false
	
	hitbox_shape.scale *= (1+ synced_amount * sync_area_multiplier * hero.char_stats.mus)
	
	current_charge_time = 0
	wave_timer.start(active_duration)
	freeze_effect_sprite.scale *= (1+ synced_amount * sync_area_multiplier * hero.char_stats.mus)
	hero.animator.play("freeze")

func _on_wave_timer_timeout() -> void:
	hero.input.canMove = true
	hitbox.monitoring = false
	hitbox.visible = false
	state_change.emit(self, "BassheartAttack")

func exit() -> void:
	super() # starts cd here.
	if is_empowered:
		hitbox_shape.scale /= area_multiplier
		freeze_effect_sprite.scale /= area_multiplier
		hero.reset_meter()
	hitbox_shape.scale /= (1+ synced_amount * sync_area_multiplier * hero.char_stats.mus)
	freeze_effect_sprite.scale /= (1+ synced_amount * sync_area_multiplier * hero.char_stats.mus)
	synced_amount = 0
	note_count = 0
	
	# Call this on the local player
	if hero.is_multiplayer_authority():
		beat_visual.hide()
		beat_visual2.hide()

func update(_delta: float) -> void:
	super(_delta)
	if is_synced and is_charging:
		current_charge_time = charge_duration - charge_timer.time_left
		beat_sync_logic()
		if current_charge_time > recast_timestamps[note_count]:
			note_count += 1
	hero.input.ability_1 = false

func beat_sync_logic():
	if recast_timestamps.is_empty() == false and hero.input.ability_1:
		if note_count <= recast_timestamps.size() - 1:
			beat_visual.check_accuracy(current_charge_time, recast_timestamps[note_count], 0.01, 0.03, recast_grace_time)
			beat_visual2.check_accuracy(current_charge_time, recast_timestamps[note_count], 0.01, 0.03, recast_grace_time)
			if is_within_timestamp(recast_timestamps[note_count]):
				beat_sync_effects.restart()
				synced_amount += 1
			else:
				if synced_amount > 0: #Punishes if you don't sync
					synced_amount -= 1

func physics_update(_delta: float) -> void:
	super(_delta)
	if is_charging:
		hero.input.canMove = false
		look_at(hero.input.get_mouse_position())

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	enemy.hit.connect(lifesteal)
	if is_empowered:
		enemy.take_damage(get_multiplied_atk() * (damage_multiplier + synced_amount * sync_dmg_multiplier * hero.char_stats.mus))
		if enemy.frozen == false:
			enemy.add_status("Freeze", [unfreeze_dmg, a_stats.dur * freeze_duration_multiplier,dmg_threshold])
	#This comparison has to be added to prevent applying status twice, also bugs out freeze code
	elif not is_empowered:
		enemy.take_damage(get_multiplied_atk() * (1 + synced_amount * sync_dmg_multiplier * hero.char_stats.mus))
		if enemy.frozen == false:
			enemy.add_status("Freeze", [unfreeze_dmg, a_stats.dur, dmg_threshold])
	enemy.hit.disconnect(lifesteal)

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

func set_ability_to_hero_stats() -> void:
	a_stats.aoe = hero.char_stats.aoe ; scale = a_stats.aoe * Vector2.ONE
	a_stats.atk = initial_dmg * hero.get_total_dmg()/hero.initial_damage
	a_stats.cd = initial_cd * hero.char_stats.cd
	a_stats.dur = freeze_duration * hero.char_stats.dur

# Only checks with charge timer, change if required to check with another timer
func is_within_timestamp(timestamp : float) -> bool:
	if current_charge_time <= timestamp + recast_grace_time and current_charge_time >= timestamp - recast_grace_time:
		return true
	else: return false
