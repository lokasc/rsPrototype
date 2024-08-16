extends Node
class_name BaseState

signal state_change
var hero_owner : BaseHero

func initialise_states(hero : BaseHero):
	hero_owner = hero

func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass
