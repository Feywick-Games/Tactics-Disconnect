class_name Global
extends Object

enum PhysicsLayers {
	ENVIRONMENT = 1,
	INTERACTION = 2,
	ALLY = 3
}

enum SkillErrorCode
{
	OK,
	NO_TARGET,
	MOVE_BLOCKED,
	UNREACHABLE
}

const PLAYER_SPEED: float = 70
const TILE_SIZE := Vector2i(30, 30)

const BATTLE_MAP_ATLAS_COORDS := Vector2.ZERO
const RETICLE_MOVE_ALTAS_COORDS := Vector2i(0,1)
const RETICLE_ATTACK_ATLAS_COORDS := Vector2i(0,2)
const RETICLE_OVERLAP_BASIC_ATLAS_COORDS := Vector2i(0,3)
const RETICLE_OVERLAP_SPECIAL_ATLAS_COORDS := Vector2i(0,4)
const RETICLE_SPECIAL_ALTAS_COORDS := Vector2i(0,5)

const RETICLE_FACING_RIGHT := Vector2i(0,6)
const RETICLE_FACING_DOWN := Vector2i(0,7)
const RETICLE_FACING_LEFT := Vector2i(0,8)
const RETICLE_FACING_UP := Vector2i(0,9)
 
const GAME_SIZE := Vector2i(640,360)

const TIMER_MAX_VALUE := 30
const QUICK_MULTIPLIER : float = 1.25
const BACK_MULTIPLIER : float = .5
const SLOW_MULTIPLIER : float = .75
const QUICK_TIME_PERCENT : float = .25
const SLOW_TIME_PERCENT : float = .75
