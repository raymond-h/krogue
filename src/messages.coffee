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

	game

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

	.on 'game.creature.attack.none', (attacker, dir) ->
		It_does =
			if attacker.isPlayer() then 'You do'
			else "The #{attacker.species.name} does"

		msg "#{It_does} a cool attack without hitting anything!"

	.on 'game.creature.attack.wall', (attacker, dir) ->
		It_attacks =
			if attacker.isPlayer() then 'You attack'
			else "The #{attacker.species.name} attacks"

		msg "#{It_attacks} a wall!"

	.on 'game.creature.attack.creature', (attacker, dir, target) ->
		It_attacks =
			if attacker.isPlayer() then 'You attack'
			else "The #{attacker.species.name} attacks"

		msg "#{It_attacks} at #{the target}!"

	.on 'game.creature.fire', (firer, item, dir) ->
		msg 'BANG!'

	.on 'game.creature.fire.empty', (firer, item, dir) ->
		msg 'Click! No ammo...'

	.on 'game.creature.fire.hit.none', (firer, item, dir) ->
		msg 'The bullet doesn\'t hit anything...'

	.on 'game.creature.fire.hit.wall', (firer, item, dir, pos) ->
		msg 'The bullet strikes a wall...'

	.on 'game.creature.fire.hit.creature', (firer, item, dir, target) ->
		msg "The bullet hits #{the target}!"

	.on 'game.creature.pickup', (creature, item) ->
		It_picks =
			if creature.isPlayer() then 'You pick'
			else "The #{creature.species.name} picks"

		msg "#{It_picks} up the #{item.name}."

	.on 'game.creature.drop', (creature, item) ->
		It_drops =
			if creature.isPlayer() then 'You drop'
			else "The #{creature.species.name} drops"

		msg "#{It_drops} the #{item.name}."

	.on 'game.creature.equip', (equipper, item) ->
		It_equips =
			if equipper.isPlayer() then 'You equip'
			else "The #{equipper.species.name} equips"

		msg "#{It_equips} the #{item.name}."

	.on 'game.creature.unequip', (equipper, item) ->
		It_puts =
			if equipper.isPlayer() then 'You put'
			else "The #{equipper.species.name} puts"

		msg "#{It_puts} away the #{item.name}."