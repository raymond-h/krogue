{EventEmitter2: EventEmitter} = require 'eventemitter2'

TimeManager = require './time-manager'
{Map} = require './map'

{initialize, Renderer} = require './io/tty'

{Dummy, FastDummy, Player} = require './creatures'

class Game
	constructor: ->
		# console.error 'Starting game...'

		@timeManager = new TimeManager
		@events = new EventEmitter
			wildcard: yes
			# newListener: yes

		# @events.onAny (a...) ->
		# 	console.error "Event: '#{@event}'; ", a

		initialize @
		@renderer = new Renderer @

		@currentMap = new Map @, 50, 15

		@entities = [
			new Player @, @currentMap, 2, 2, 'KayArr'
			new Dummy @, @currentMap, 6, 6
			new FastDummy @, @currentMap, 12, 6
		]

		# @timeManager.targets.push new Dummy @, @currentMap, 1, 1
		@timeManager.targets.push @entities...
		# @timeManager.targets.push new Player @, @currentMap, 3, 1, 'Boat', 12

		@events.on 'key.q', -> process.exit 0

	main: ->
		do mainLoop = =>
			@timeManager.tick (err) =>
				return console.error err.stack if err?

				mainLoop()

game = new Game
game.main()