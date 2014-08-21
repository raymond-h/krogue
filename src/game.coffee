async = require 'async'
{EventEmitter2} = require 'eventemitter2'
MersenneTwister = require 'mersennetwister'
winston = require 'winston'
Q = require 'q'
_ = require 'lodash'

saveData = require './save-data'
{arrayRemove} = require './util'

class Game extends EventEmitter2
	constructor: ->
		super
			wildcard: yes
			newListener: no

		@state = 'main-menu'

		@onAny (a...) ->
			winston.silly "Event: '#{@event}'; ", a

		(require './key-handling')(this)

		@logs = []

		@mapIdCounter = 0
		@maps = {}

	generateMapId: ->
		"map-#{@mapIdCounter++}"

	initialize: (@io) ->
		winston.info '*** Starting game...'

		@io.initialize @
		@io.initialized = yes
		@renderer = new @io.Renderer @

		(require './messages')(@)

		@on 'key.c', (ch, key) =>
			@quit() if key.ctrl

		.on 'log.add', (str) ->
			winston.info "<GAME> #{str}"

		.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		winston.silly "Init game"

		Player = require './player'
		{GenerationManager} = require './generation/manager'
		TimeManager = require './time-manager'
		Camera = require './camera'
		Random = require './random'

		@random = new Random(new MersenneTwister)
		@timeManager = new TimeManager
		@camera = new Camera { w: 80, h: 21 }, { x: 30, y: 9 }
		@generationManager = new GenerationManager

		creature = @createPlayerCreature()
		@player = new Player creature
		@timeManager.add creature
		@camera.target = creature

		# @transitionToMap (MapGenerator.generateBigRoom 80, 25), 'entrance'
		@goTo 'main-1', 'entrance'

		# @on 'key.z', =>
		# 	newMap = (MapGenerator.generateCellularAutomata 80, 21)
		# 	[startX, startY] = []

		# 	for row, y in newMap.data
		# 		for tile, x in row
		# 			if tile is '.'
		# 				[startX, startY] = [x, y]
		# 				break

		# 	@transitionToMap newMap, startX, startY

	createPlayerCreature: ->
		{Creature} = require './entities'
		{Human} = require './creature-species'

		creature = new Creature null, 0, 0, new Human

		gun = (require './generation/items').generateStartingGun()

		creature.equipment['right hand'] = gun

		creature

	quit: ->
		@io.deinitialize @ if @io.initialized

		Q.delay(100).then -> process.exit 0

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
		@camera.bounds map

		@timeManager.add map.entities...
		map.addEntity @player.creature

		if _.isString x
			{x, y} = map.positions[x]

		if x? and y?
			@player.creature.setPos x, y
			
		else
			@camera.update()

		@renderer.invalidate()

	save: (filename) ->
		saveData.save @, filename

	load: (filename) ->
		saveData.load @, filename

	goState: (state) ->
		@emit "state.exit.#{@state}", 'exit', @state
		@state = state
		@emit "state.enter.#{@state}", 'enter', @state

		@renderer.invalidate()

	message: (str) ->
		@logs.push str
		@logs.shift() while @logs.length > 20

		@emit 'log.add', str

	main: ->
		async.whilst (-> true),
			(next) =>
				switch @state
					when 'main-menu'
						@once 'key.s', =>
							@goState 'game'
							next()

					when 'game'
						@timeManager.tick next

			(err) =>
				winston.error err.stack if err?
				@quit()

	loadFromJSON: (json) ->
		@generationManager.connections =
			json.generationManager.connections

		@logs = json.logs
		@player.loadFromJSON json.player

		@camera.x = json.camera.x
		@camera.y = json.camera.y

		{Map} = require './map'
		for id, map of json.maps
			@maps[id] = Map.fromJSON map

		@transitionToMap @maps[json.currentMap]

		# puts player last in targets list
		@timeManager.targets.rotate()

	saveToJSON: ->
		{
			player: @player
			camera:
				x: @camera.x
				y: @camera.y
			@logs
			@generationManager
			currentMap: @currentMap.id
			@maps
		}

module.exports = new Game

module.exports.Game = Game