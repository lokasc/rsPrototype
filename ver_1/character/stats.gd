class_name Stats

# All players, items, enemies use this. 
# unless they have a special effect.

@export var maxhp : int 	# Max Health
@export var aoe : float		# Area of Effect
@export var arm : int		# Armour
@export var atk : int		# Attack Damage
@export var spd : int		# Movement Speed
@export var cd : float		# Cooldown nb: atk speed
@export var pick : int		# Pick up radius
@export var mus : int		# Music multiplier (benefits from music sync)
@export var hsg : float		# Heal & Shield gain
@export var dur : float		# Duration of abilities
@export var atk_mul : float # Attack Multiplier
@export var shields : int	# Amount of shield health

func _init(_maxhp = 100, _aoe = 1, _arm = 1, _atk = 1, _spd = 1, _cd = 1, _pick = 1, _mus = 1, _hsg = 1, _dur = 1, _atk_mul = 1, _shields = 0):
	maxhp = _maxhp
	aoe = _aoe
	arm = _arm
	atk = _atk
	spd = _spd
	cd = _cd
	pick = _pick
	mus = _mus
	hsg = _hsg
	dur = _dur
	atk_mul = _atk_mul
	shields = _shields

# Get dmg with multiplier
func get_total_dmg() -> int:
	return int(atk_mul * atk)
