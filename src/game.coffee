async = require 'async'
{EventEmitter2} = require 'eventemitter2'
MersenneTwister = require 'mersennetwister'
winston = require 'winston'
Q = require 'q'

TimeManager = require './time-manager'
Camera = require './camera'
Random = require './random'
Player = require './player'
saveData = require './save-data'
{arrayRemove} = require './util'

{Map} = require './map'
MapGenerator = require './generation/maps'

{Creature} = require './entities'
{Human} = require './creature-species'
require './personality'

class Game
	constructor: ->
		@state = 'main-menu'

		@events = new EventEmitter2
			wildcard: yes
			newListener: no

		@events.onAny (a...) ->
			winston.silly "Event: '#{@event}'; ", a

		(require './key-handling')(this)

		@logs = []

	initialize: (@io) ->
		winston.info '*** Starting game...'

		@io.initialize @
		@io.initialized = yes
		@renderer = new @io.Renderer @

		@events
		.on 'key.c', (ch, key) =>
			@quit() if key.ctrl

		.on 'log.add', (str) ->
			winston.info "<GAME> #{str}"

		.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		winston.silly "Init game"
		@random = new Random(new MersenneTwister)
		@timeManager = new TimeManager
		@camera = new Camera { w: 80, h: 21 }, { x: 30, y: 9 }

		creature = @createPlayerCreature()
		@player = new Player creature
		@timeManager.targets.push creature

		@transitionToMap (MapGenerator.generateBigRoom 80, 25), 2, 2

		@events.on 'key.k', =>
			newMap = (MapGenerator.generateCellularAutomata 80, 21)
			[startX, startY] = []

			for row, y in newMap.data
				for tile, x in row
					if tile is '.'
						[startX, startY] = [x, y]
						break

			@transitionToMap newMap, startX, startY

	createPlayerCreature: ->
		creature = new Creature null, 0, 0, new Human

		gun = new (require './items').Gun
		gun.name = 'trusty handgun'
		gun.gunType = 'handgun'

		creature.equipment['right hand'] = gun

		creature

	quit: ->
		@io.deinitialize @ if @io.initialized

		Q.delay(100).then -> process.exit 0

	transitionToMap: (map, x, y) ->
		if @currentMap?
			for e in @currentMap.entities when e isnt @player.creature
				@timeManager.targets.remove e

			arrayRemove @currentMap.entities, @player.creature

		@currentMap = map
		@camera.bounds map

		@timeManager.targets.push map.entities...

		map.entities.unshift @player.creature
		@player.creature.map = map

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
		@events.emit "state.exit.#{@state}", 'exit', @state
		@state = state
		@events.emit "state.enter.#{@state}", 'enter', @state

		@renderer.invalidate()

	message: (str) ->
		@logs.push str
		@logs.shift() while @logs.length > 20

		@events.emit 'log.add', str

	main: ->
		async.whilst (-> true),
			(next) =>
				switch @state
					when 'main-menu'
						@events.once 'key.s', =>
							@goState 'game'
							next()

					when 'game'
						@timeManager.tick next

			(err) =>
				winston.error err.stack if err?
				@quit()

	loadFromJSON: (json) ->
		@logs = json.logs
		@player.loadFromJSON json.player

		@camera.x = json.camera.x
		@camera.y = json.camera.y
		@transitionToMap Map.fromJSON json.map

		# puts player last in targets list
		@timeManager.targets.rotate()

	saveToJSON: ->
		{
			player: @player
			camera:
				x: @camera.x
				y: @camera.y
			@logs
			map: @currentMap
		}

module.exports = new Game

module.exports.Game = Game