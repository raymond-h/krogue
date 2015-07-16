_ = require 'lodash'

game = require '../game'
direction = require '../direction'
vectorMath = require '../vector-math'
calc = require '../calc'
log = require '../log'
{MapItem} = require '../entities'

Item = class exports.Item
	symbol: 'geneticItem'

	getEquipSlotUse: (slot, creature) ->
		if slot is 'hand' then calc.itemSlotUse creature, @
		else 0

	equipSlotUse: ->
		(require './creature-species')._equipSlots
		.map (slot) => @getEquipSlotUse slot

	copy: ->
		c = new @constructor
		_.assign c, @
		c

	equipSlotUseString: (creature) ->
		(require './creature-species')._equipSlots

		.filter (slot) => (@getEquipSlotUse slot, creature) > 0
		.map (slot) =>
			log.info "Slot #{slot} is go!"
			count = @getEquipSlotUse slot, creature

			if count is 1 then slot else "#{count} #{slot}"

		.join ', '

	asMapItem: (x, y) ->
		new MapItem null, x, y, @

class exports.PeculiarObject extends Item
	name: 'peculiar object'
	symbol: 'peculiarObject'

class exports.Corpse extends Item
	name: 'unknown corpse'
	symbol: 'corpse'

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
	symbol: 'pokeBall'

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

class exports.Bullet extends Item
	name: 'bullet'
	symbol: 'bullet'
	leaveWhenShot: no

	constructor: (@type = 'medium') ->
		Object.defineProperty @, 'name',
			get: => "#{@type} bullet"

	onHit: (map, pos, target, dealDamage) ->
		# When this, fired as ammo, hits something...

	onLand: (map, pos, target, dealDamage) ->
		# When this, fired as ammo, lands on the ground...

class exports.BulletPack extends Item
	name: 'pack of ammo'
	symbol: 'gunAmmoPack'

	constructor: (@ammo = new exports.Bullet, @amount = 1) ->
		Object.defineProperty @, 'name',
			get: => "pack of #{@amount}x ammo (#{@ammo.name})"

	reload: (ammoItem) ->
		if ammoItem instanceof exports.BulletPack and _.isEqual ammoItem.ammo, @ammo
			@amount += ammoItem.amount
			yes

		else if _.isEqual ammoItem, @ammo
			@amount += 1
			yes

		else no

class exports.Gun extends Item
	name: 'gun'
	symbol: 'gun'

	constructor: (@ammo = []) ->

	fire: (a...) ->
		fn = @fireHandlers[@fireType()]

		fn.apply @, a

	reload: (ammoItem) ->
		if ammoItem instanceof exports.BulletPack
			(@ammo.push ammoItem.ammo.copy()) for i in [1..ammoItem.amount]

		else @ammo.push ammoItem

		util = require 'util'
		log.info "Current ammo after reload: #{util.inspect @ammo} (#{@ammo.length})"
		yes

	fireType: ->
		switch @gunType
			when 'handgun', 'sniper' then 'line'

			when 'shotgun' then 'spread'

			else '_dud'

	pullCurrentAmmo: ->
		currentAmmo = @ammo.shift()
		# return null if not currentAmmo?

		log.info "Current ammo: #{(require 'util').inspect @ammo} (#{@ammo.length})"

		currentAmmo

	fireHandlers:
		'_dud': (creature, offset) ->
			game.message 'Nothing happens; this gun is a dud.'

		'line': (creature, offset) ->
			currentAmmo = @pullCurrentAmmo()
			if not currentAmmo?
				game.emit 'game.creature.fire.empty', creature, @, offset
				return

			game.emit 'game.creature.fire', creature, @, offset

			if _.isString offset
				offset = vectorMath.mult (direction.parse offset), @range

			endPos = vectorMath.add creature, offset

			found = creature.raytraceUntilBlocked endPos, {@range}

			if found.type in ['creature', 'none']
				endPos = found

			else if found.type is 'wall'
				endPos = found.checked[1]

			game.effects.shootLine
				start: creature, end: found
				symbol: currentAmmo.symbol

			.then =>
				map = creature.map
				hit = no

				switch found.type
					when 'none'
						game.emit 'game.creature.fire.hit.none', creature, @, offset

					when 'wall'
						game.emit 'game.creature.fire.hit.wall',
							creature, @, offset, found

					when 'creature'
						target = found.creature
						dmg = calc.gunDamage creature, @, target

						dealDamage = ->
							target.damage dmg, creature

						game.emit 'game.creature.fire.hit.creature', creature, @, offset, target

						r = currentAmmo.onHit? map, found, target, dealDamage
						if r isnt no then dealDamage()

						hit = yes

				if (currentAmmo.leaveWhenShot ? yes)
					mapItem = currentAmmo.asMapItem endPos.x, endPos.y
					map.addEntity mapItem
					game.timeManager.add mapItem

				currentAmmo.onLand? map, endPos, hit

				return

		'spread': (creature, offset) ->
			currentAmmo = @pullCurrentAmmo()
			if not currentAmmo?
				game.emit 'game.creature.fire.empty', creature, @, offset
				return

			game.emit 'game.creature.fire', creature, @, offset

			if _.isString offset
				offset = direction.parse offset

			# shotguns shoot in a spread - need angle of offset first
			angle = Math.atan2 -offset.y, offset.x

			compareAngles = (a0, a1) ->
				Math.PI - Math.abs(Math.abs(a0-a1) - Math.PI)

			spread = @spread ? (10 / 180 * Math.PI)

			game.effects.shootSpread {
				start: creature, symbol: currentAmmo.symbol
				angle, spread, @range
			}

			.then =>
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
						dmg = calc.gunDamage creature, @, target

						game.emit 'game.creature.fire.hit.creature',
							creature, @, offset, target

						target.damage dmg, creature

				else
					game.emit 'game.creature.fire.hit.none', creature, @, offset