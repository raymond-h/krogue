async = require 'async'
{EventEmitter2} = require 'eventemitter2'
MersenneTwister = require 'mersennetwister'
winston = require 'winston'

TimeManager = require './time-manager'
Camera = require './camera'
Random = require './random'
{Map} = require './map'
MapGenerator = require './map-generation'
{Dummy, FastDummy, Player} = require './creatures'
saveData = require './save-data'

module.exports = class Game
	constructor: (@io) ->
		winston.info '*** Starting game...'

		@state = 'main-menu'

		@events = new EventEmitter2
			wildcard: yes
			newListener: no

		@events.onAny (a...) ->
			winston.silly "Event: '#{@event}'; ", a

		@io.initialize @
		@renderer = new @io.Renderer @

		@events.on 'key.c', (ch, key) =>
			@quit() if key.ctrl

		@events.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		@random = new Random(new MersenneTwister)
		@timeManager = new TimeManager
		@camera = new Camera { w: 40, h: 15 }, { x: 10, y: 6 }

		@currentMap = MapGenerator.generateBigRoom @, 50, 25
		@camera.bounds @currentMap

		@currentMap.entities = [
			new Dummy @, @currentMap, 6, 6
			new FastDummy @, @currentMap, 12, 6
		]

		@timeManager.targets.push @currentMap.entities...

		# create player and add to the lists where it belongs
		@player = new Player @, @currentMap, 2, 2, 'KayArr'
		@camera.target = @player
		@currentMap.entities.unshift @player
		@timeManager.targets.unshift @player

		@camera.update()

	save: (filename) ->
		saveData.save @, filename

	load: (filename) ->
		saveData.load @, filename

	quit: ->
		@io.deinitialize @
		process.exit 0

	goState: (state) ->
		@events.emit "state.exit.#{@state}", 'exit', @state
		@state = state
		@events.emit "state.enter.#{@state}", 'enter', @state

		@renderer.invalidate()

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
		@currentMap = Map.fromJSON @, json.map
		
		@renderer.invalidate()

	saveToJSON: ->
		{
			map: @currentMap.toJSON()
		}