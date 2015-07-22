async = require 'async'
_ = require 'lodash'
Promise = require 'bluebird'
TimeManager = require 'rl-time-manager'

log = require './log'
eventBus = require './event-bus'
message = require './message'
random = require './random'

(require './messages')(eventBus)

aliasFns = (Clazz, obj, fns) ->
	for fn in fns then do (fn) ->
		Clazz::[fn] = (params...) ->
			obj[fn] params...

class Game
	constructor: ->
		@state = 'main-menu'

		(require './key-handling')(this)

		@logs = []

		@mapIdCounter = 0
		@maps = {}

	aliasFns @, eventBus, ['waitOn', 'on', 'off', 'emit']
	message: message

	generateMapId: ->
		"map-#{@mapIdCounter++}"

	initialize: (@io) ->
		log '*** Starting game...'

		@io.initialize()
		@io.initialized = yes

		@renderer = @io.renderer
		@effects = @io.effects
		@prompts = @io.prompts

		eventBus
		.on 'key.c', (ch, key) =>
			@quit() if key.ctrl

		.on 'log.add', (str) =>
			log "<GAME> #{str}"

			@logs.push str
			@logs.shift() while @logs.length > 20

		.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		log "Init game"

		Player = require './player'
		{GenerationManager} = require './generation/manager'
		@timeManager = new TimeManager(Promise.resolve.bind Promise)
		@generationManager = new GenerationManager

		creature = @createPlayerCreature()
		@player = new Player creature
		@timeManager.add creature

		@goTo 'main-1', 'entrance'

		eventBus.on 'game.creature.dead', (creature, cause) =>
			if creature.isPlayer()
				@goState 'death'

	createPlayerCreature: ->
		{Creature} = require './entities'
		{human} = require './definitions/creature-species'

		creature = new Creature {x: 0, y: 0, species: human}

		gun = (require './generation/items').generateStartingGun()

		creature.equip gun, yes

		items = require './definitions/items'
		creature.inventory = for i in [1..5]
			new items.PokeBall @random.sample ['normal', 'great', 'ultra', 'master']

		creature.inventory.push new items.BulletPack (new items.Bullet 'medium'), 20
		creature.inventory.push new items.BulletPack (new items.Bullet 'medium'), 5
		(creature.inventory.push(new items.Bullet 'medium')) for i in [1..3]

		creature

	quit: ->
		@io.deinitialize @ if @io.initialized

		setTimeout (-> process.exit 0), 100

	goTo: (mapId, position) ->
		map = @maps[mapId] ?
			@generationManager.generateMap mapId

		@transitionToMap map, position

	transitionToMap: (map, x, y) ->
		if @currentMap?
			@currentMap.removeEntity @player.creature
			@timeManager.remove @currentMap.entities...

		map.id ?= @generateMapId()
		@maps[map.id] = map

		@currentMap = map

		@timeManager.add map.entities...
		map.addEntity @player.creature

		if _.isString x
			{x, y} = map.positions[x]

		if x? and y?
			@player.creature.setPos x, y

	save: (filename) ->
		@io.saveData.save @, filename

	load: (filename) ->
		@io.saveData.load @, filename

	goState: (state) ->
		eventBus.emit "state.exit.#{@state}", 'exit', @state
		@state = state
		eventBus.emit "state.enter.#{@state}", 'enter', @state

	main: ->
		async.whilst (-> true),
			(next) =>
				switch @state
					when 'main-menu'
						eventBus.once 'key.s', =>
							@goState 'game'
							next()

					when 'game'
						@timeManager.tick next

			(err) =>
				log.error err.stack if err?
				@quit()

	loadFromJSON: (json) ->
		@generationManager[k] = v for k,v of json.generationManager

		@logs = json.logs

		@timeManager.remove @player.creature

		@player.creature = json.player.creature

		@timeManager.add @player.creature

		@maps = json.maps

		@transitionToMap @maps[json.currentMap]

	saveToJSON: ->
		{
			player:
				creature: @player.creature
			@logs
			@generationManager
			currentMap: @currentMap.id
			@maps
		}

module.exports = new Game

module.exports.Game = Game
