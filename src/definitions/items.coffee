_ = require 'lodash'

game = require '../game'
direction = require '../direction'
vectorMath = require '../vector-math'

{Item} = require '../items'

class exports.PeculiarObject extends Item
	typeName: 'peculiar-object'

	name: 'peculiar object'
	symbol: 'O'

class exports.Gun extends Item
	typeName: 'gun'

	name: 'gun'
	symbol: '/'

	fire: (a...) ->
		fn = @fireHandlers[@gunType ? '_dud']

		fn.apply @, a

	fireHandlers:
		'_dud': (creature, dir) ->
			game.message 'Nothing happens; this gun is a dud.'

		'handgun': (creature, dir) ->
			game.emit 'game.creature.fire', creature, @, dir

			offset = direction.parse dir
			endPos =
				vectorMath.add creature, (
					vectorMath.mult offset, @range
				)

			found = creature.raytraceUntilBlocked endPos

			switch found.type
				when 'none'
					game.emit 'game.creature.fire.hit.none', creature, @, dir

				when 'wall'
					game.emit 'game.creature.fire.hit.wall',
						creature, @, dir, found

				when 'creature'
					target = found.creature

					game.emit 'game.creature.fire.hit.creature', creature, @, dir, target
					target.damage 10, creature

		'shotgun': (creature, dir) ->
			game.emit 'game.creature.fire', creature, @, dir

			# shotguns shoot in a spread - need angle of dir first
			angle = direction.directionToRad dir
			compareAngles = (a0, a1) ->
				Math.PI - Math.abs(Math.abs(a0-a1) - Math.PI)

			spread = @spread ? (10 / 180 * Math.PI)

			targets = creature.map.listEntities (e) =>
				# we don't want to hit ourselves
				return no if e is creature

				diff = vectorMath.sub e, creature
				a = Math.atan2 -diff.y, diff.x

				(compareAngles angle, a) <= spread/2 and
					(creature.distanceSqTo e) <= (@range*@range) and
					creature.canSee e

			if targets.length > 0
				for target in targets
					game.emit 'game.creature.fire.hit.creature',
						creature, @, dir, target
					target.damage 10, creature

			else
				game.emit 'game.creature.fire.hit.none', creature, @, dir