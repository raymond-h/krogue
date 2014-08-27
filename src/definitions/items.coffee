_ = require 'lodash'

game = require '../game'
direction = require '../direction'
vectorMath = require '../vector-math'

{Item} = require '../items'

class exports.PeculiarObject extends Item
	name: 'peculiar object'
	symbol: 'O'

class exports.Gun extends Item
	name: 'gun'
	symbol: '/'

	fire: (a...) ->
		fn = @fireHandlers[@fireType()]

		fn.apply @, a

	fireType: ->
		switch @gunType
			when 'handgun' then 'line'

			when 'shotgun' then 'spread'

			else '_dud'

	fireHandlers:
		'_dud': (creature, offset) ->
			game.message 'Nothing happens; this gun is a dud.'

		'line': (creature, offset) ->
			game.emit 'game.creature.fire', creature, @, offset

			if _.isString offset
				offset = direction.parse offset

			{x, y} = offset
			angle = Math.atan2 -y, x
			offset =
				x: Math.round Math.cos(angle) * @range
				y: -Math.round Math.sin(angle) * @range

			endPos = vectorMath.add creature, offset

			found = creature.raytraceUntilBlocked endPos

			switch found.type
				when 'none'
					game.emit 'game.creature.fire.hit.none', creature, @, offset

				when 'wall'
					game.emit 'game.creature.fire.hit.wall',
						creature, @, offset, found

				when 'creature'
					target = found.creature

					game.emit 'game.creature.fire.hit.creature', creature, @, offset, target
					target.damage 10, creature

		'spread': (creature, offset) ->
			game.emit 'game.creature.fire', creature, @, offset

			if _.isString offset
				offset = direction.parse offset

			# shotguns shoot in a spread - need angle of offset first
			angle = Math.atan2 -offset.y, offset.x

			compareAngles = (a0, a1) ->
				Math.PI - Math.abs(Math.abs(a0-a1) - Math.PI)

			spread = @spread ? (10 / 180 * Math.PI)

			targets = creature.map.listEntities (e) =>
				# we don't want to hit ourselves
				return no if e is creature
				return if e.type isnt 'creature'

				diff = vectorMath.sub e, creature
				a = Math.atan2 -diff.y, diff.x

				(compareAngles angle, a) <= spread/2 and
					(creature.distanceSqTo e) <= (@range*@range) and
					creature.canSee e

			if targets.length > 0
				for target in targets
					game.emit 'game.creature.fire.hit.creature',
						creature, @, offset, target
					target.damage 10, creature

			else
				game.emit 'game.creature.fire.hit.none', creature, @, offset