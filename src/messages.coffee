_ = require 'lodash'

The = (cause) ->
	if _.isString cause then cause

	else if cause.isPlayer() then 'You'

	else "The #{cause.species.name}"

the = (cause) ->
	if _.isString cause then cause

	else if cause.isPlayer() then 'you'

	else "the #{cause.species.name}"

module.exports = (game) ->
	msg = (m) -> game.message m

	game.events

	.on 'game.creature.hurt', (target, dmg, cause) ->
		It_was =
			if target.isPlayer() then 'You were'
			else "The #{target.species.name} was"

		msg "#{It_was} hurt for #{dmg} damage!"

	.on 'game.creature.dead', (target, cause) ->
		It_has =
			if target.isPlayer() then 'You have'
			else "The #{target.species.name} has"

		msg "#{It_has} been killed by #{the cause}!"

	.on 'game.creature.kick.none', (kicker, dir) ->
		It_does =
			if kicker.isPlayer() then 'You do'
			else "The #{kicker.species.name} does"

		msg "#{It_does} a cool kick without hitting anything!"

	.on 'game.creature.kick.wall', (kicker, dir) ->
		It_kicks =
			if kicker.isPlayer() then 'You kick'
			else "The #{kicker.species.name} kicks"

		msg "#{It_kicks} a wall!"

	.on 'game.creature.kick.creature', (kicker, dir, target) ->
		It_kicks =
			if kicker.isPlayer() then 'You kick'
			else "The #{kicker.species.name} kicks"

		msg "#{It_kicks} at #{the target}!"

	.on 'game.creature.fire', (firer, item, dir) ->
		msg 'BANG!'

	.on 'game.creature.fire.hit.none', (firer, item, dir) ->
		msg 'The bullet doesn\'t hit anything...'

	.on 'game.creature.fire.hit.wall', (firer, item, dir, pos) ->
		msg 'The bullet strikes a wall...'

	.on 'game.creature.fire.hit.creature', (firer, item, dir, target) ->
		msg "The bullet hits #{the target}!"