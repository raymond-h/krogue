_ = require 'lodash'

game = require '../game'
direction = require '../direction'
vectorMath = require '../vector-math'

Item = class exports.Item
	symbol: 'I'

class exports.PeculiarObject extends Item
	name: 'peculiar object'
	symbol: 'O'

class exports.Corpse extends Item
	name: 'unknown corpse'
	symbol: '%'

	constructor: (@creature) ->
		Object.defineProperty @, 'name',
			get: =>
				name = @creature.name ? @creature.species.name
				"corpse of #{name}"

class exports.PokeBall extends Item
	name: 'poké ball'
	symbol: '*'

	constructor: (@creature = null) ->
		Object.defineProperty @, 'name',
			get: =>
				if @creature?
					name = @creature.name ? @creature.species.name
					"#{PokeBall::name} w/ #{name}"

				else PokeBall::name

	onHit: (map, pos, target) ->
		if not @creature?
			map.removeEntity target
			game.timeManager.remove target
			@creature = target

			game.message "Gotcha! #{target.name ? 'The ' + target.species.name} was caught!"

	onLand: (map, pos) ->
		if @creature?
			map.addEntity @creature
			@creature.setPos pos
			game.timeManager.add @creature

			lines = ['Go', 'This is your chance! Go', 'The opponent is weak, finish them! Go']
			game.message "#{game.random.sample lines} #{@creature.name ? @creature.species.name}!"

			@creature = null

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
				offset = vectorMath.mult (direction.parse offset), @range

			endPos = vectorMath.add creature, offset

			found = creature.raytraceUntilBlocked endPos, {@range}

			switch found.type
				when 'none'
					game.emit 'game.creature.fire.hit.none', creature, @, offset

				when 'wall'
					game.emit 'game.creature.fire.hit.wall',
						creature, @, offset, found
					endPos = found

				when 'creature'
					target = found.creature

					game.emit 'game.creature.fire.hit.creature', creature, @, offset, target
					target.damage 10, creature
					endPos = found

			game.renderer.effectLine creature, endPos,
				delay: 20
				symbol: '*'

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