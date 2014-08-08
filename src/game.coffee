async = require 'async'
{EventEmitter2} = require 'eventemitter2'
MersenneTwister = require 'mersennetwister'
winston = require 'winston'

TimeManager = require './time-manager'
Camera = require './camera'
Random = require './random'
{Map} = require './map'
MapGenerator = require './map-generation'
{Player} = require './creatures'
saveData = require './save-data'
{arrayRemove} = require './util'

require './entity-registry'

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
		@camera = new Camera { w: 80, h: 21 }, { x: 10, y: 6 }

		@player = new Player @, null, 0, 0, 'KayArr'
		@camera.target = @player
		@timeManager.targets.push @player

		@transitionToMap (MapGenerator.generateBigRoom @, 80, 25), 2, 2

	transitionToMap: (map, x, y) ->
		if @currentMap?
			for e in @currentMap.entities when e isnt @player
				@timeManager.targets.remove e

			arrayRemove @currentMap.entities, @player

		@currentMap = map
		@camera.bounds map

		@timeManager.targets.push map.entities...

		map.entities.unshift @player
		@player.map = map

		if x? and y?
			@player.setPos x, y
			
		else
			@camera.update()

		@renderer.invalidate()

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
		@player.loadFromJSON json.player
		@transitionToMap Map.fromJSON @, json.map

		# puts player last in targets list
		@timeManager.targets.rotate()

	saveToJSON: ->
		{
			player: @player
			map: @currentMap
		}