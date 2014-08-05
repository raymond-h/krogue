TimeManager = require './time-manager'
{Map} = require './map'

{initialize, Renderer} = require './io/tty'

{Dummy, Player} = require './creatures'

class Game
	constructor: ->
		@timeManager = new TimeManager

		initialize @
		@renderer = new Renderer @

		@currentMap = new Map @, 50, 15

		@entities = [
			new Player @, @currentMap, 2, 2, 'KayArr'
		]

		# @timeManager.targets.push new Dummy @, @currentMap, 1, 1
		@timeManager.targets.push @entities...
		# @timeManager.targets.push new Player @, @currentMap, 3, 1, 'Boat', 12

	main: ->
		do mainLoop = =>
			@timeManager.tick (err) =>
				return console.error err.stack if err?

				mainLoop()

game = new Game
game.main()