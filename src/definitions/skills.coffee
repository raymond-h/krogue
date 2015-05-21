_ = require 'lodash'

game = require '../game'
log = require '../log'
prompts = game.prompts

direction = require '../direction'
vectorMath = require '../vector-math'
calc = require '../calc'

Skill = class exports.Skill
	name: 'skill'
	# symbol: 'skill' # allow symbols for skills (to show in list maybe)

class exports.TentacleWhip extends Skill
	name: 'tentacle whip'

	askParams: (creature) ->
		# only called for player, to populate params to pass to #use()

		params = {}

		prompts.position 'Whip towards where?', default: creature
		.then (pos) -> params.position = pos

		.then -> params

	use: (creature, params) ->
		console.log 'whip:', params
		12

class exports.SenseLasagna extends Skill
	name: 'sense lasagna'

	use: (creature) ->
		game.message "
			You feel no presence of any lasagna aura in your vicinity. Disappointing.
		"