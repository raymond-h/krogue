_ = require 'lodash'

game = require '../game'
log = require '../log'

direction = require '../direction'
vectorMath = require '../vector-math'
calc = require '../calc'

Skill = class exports.Skill
	name: 'skill'
	# symbol: 'skill' # allow symbols for skills (to show in list maybe)

class exports.TentacleWhip extends Skill
	name: 'tentacle whip'

class exports.SenseLasagna extends Skill
	name: 'sense lasagna'

	use: (creature) ->
		game.message "
			You feel no presence of any lasagna aura in your vicinity. Disappointing.
		"