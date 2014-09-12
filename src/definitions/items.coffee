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
		Object.defineProperties @,
			name:
				get: =>
					name = @creature.name ? @creature.species.name
					"corpse of #{name}"

			weight:
				get: => @creature.calc 'weight'

class exports.PokeBall extends Item
	name: 'poké ball'
	symbol: '*'

	rates:
		'normal': 1
		'great': 1.5
		'ultra': 2
		'master': 255

	names:
		'normal': 'poké ball'
		'great': 'great ball'
		'ultra': 'ultra ball'
		'master': 'master ball'

	constructor: (@type = null, @creature = null) ->
		Object.defineProperty @, 'name',
			get: =>
				if @creature?
					name = @creature.name ? @creature.species.name
					"#{@names[@type ? 'normal']} w/ #{name}"

				else @names[@type ? 'normal']

	calcRate: (target) ->
		190 * @rates[@type ? 'normal']

	catchRate: (target) ->
		{max: maxHp, current: currHp} = target.health

		(3*maxHp - 2*currHp) / (3*maxHp) * @calcRate target

	catchProb: (target) ->
		return 1 if @type is 'master'

		a = @catchRate target
		return 1 if a >= 255

		b = 1048560 / Math.sqrt Math.sqrt 16711680 / a
		Math.pow ((b + 1) / (1<<16)), 4

	onHit: (map, pos, target) ->
		if not @creature?
			catchProb = @catchProb target

			if game.random.chance catchProb
				map.removeEntity target
				game.timeManager.remove target
				@creature = target

				name = target.name ? 'The ' + target.species.name

				game.message "Gotcha! #{name} was caught!"

			else
				lines = [
					'Oh, no! The creature broke free!'
					'Aww! It appeared to be caught!'
					'Aargh! Almost had it!'
					'Shoot! It was so close, too!'
				]
				game.message game.random.sample lines

			no

	onLand: (map, pos, hit) ->
		if @creature? and not hit
			map.addEntity @creature
			@creature.setPos pos
			game.timeManager.add @creature

			lines = [
				'Go'
				'This is your chance! Go'
				'The opponent is weak, finish them! Go'
			]

			game.message "
				#{game.random.sample lines} #{@creature.name ? @creature.species.name}!
			"

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
			endPos = found if found.type in ['wall', 'creature']

			game.renderer.effectLine creature, endPos,
				delay: 20
				symbol: '*'

			.then ->
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