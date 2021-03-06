_ = require 'lodash'
Promise = require 'bluebird'

game = require '../game'
log = require '../log'
message = require '../message'
prompts = game.prompts

direction = require 'rl-directions'
vectorMath = require '../vector-math'
calc = require '../calc'

Skill = class exports.Skill
	name: 'skill'

class exports.TentacleWhip extends Skill
	name: 'tentacle whip'

	askParams: (creature) ->
		# only called for player, to populate params to pass to #use()

		Promise.all [
			prompts.position 'Whip towards where?', default: creature
		]

		.then ([position]) -> {position}

	use: (creature, params) ->
		console.log 'whip:', params
		12

class exports.SenseLasagna extends Skill
	name: 'sense lasagna'

	use: (creature) ->
		message "
			You feel no presence of any lasagna aura in your vicinity. Disappointing.
		"

class exports.Blink extends Skill
	name: 'blink'

	askParams: (creature) ->
		Promise.try ->
			prompts.position 'Teleport where?', default: creature

		.then (position) ->
			if not creature.canSee position
				prompts.yesNo 'This is a terrible idea. Do it anyway?'
				.then (doIt) -> [position, doIt]

			else Promise.resolve [position, yes]

		.then ([position, doIt]) -> {position, doIt}

	use: (creature, {position, doIt}) ->
		if not doIt
			message "
				Cancelled blinking.
			"

		else
			message "
				*BZOOM*
			"

			creature.setPos position
			2
