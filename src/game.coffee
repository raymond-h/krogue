async = require 'async'
_ = require 'lodash'
Promise = require 'bluebird'
TimeManager = require 'rl-time-manager'

log = require './log'
eventBus = require './event-bus'
message = require './message'
random = require './random'

require './messages'
require './key-handling'

class Game
	constructor: ->
		@state = 'main-menu'

		@logs = []

		@mapIdCounter = 0
		@maps = {}

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
			@logs.push str
			@logs.shift() while @logs.length > 20

		.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		log "Init game"

		Player = require './player'

		{GenerationManager} = require './generation/manager'
		@generationManager = new GenerationManager

		{generateStartingPlayer} = require './generation/creatures'
		creature = generateStartingPlayer()
		@player = new Player creature

		@goTo 'main-1', 'entrance'

		eventBus.on 'game.creature.dead', (creature, cause) =>
			if creature.isPlayer()
				@goState 'death'

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

		map.id ?= @generateMapId()
		@maps[map.id] = map

		@currentMap = map

		map.addEntity @player.creature

		if _.isString x
			{x, y} = map.positions[x]

		if x? and y?
			@player.creature.setPos x, y

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
						@currentMap.timeManager.tick next

			(err) =>
				log.error err.stack if err?
				@quit()

module.exports = new Game

module.exports.Game = Game
