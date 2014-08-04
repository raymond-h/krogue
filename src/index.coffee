TimeManager = require './time-manager'
{Renderer} = require './render'
{Dummy, Player} = require './creatures'

class Game
	constructor: ->
		@timeManager = new TimeManager
		@renderer = new Renderer @

		@timeManager.targets.push new Dummy
		@timeManager.targets.push new Player 'KayArr'
		@timeManager.targets.push new Player 'Boat', 80

	main: ->
		do mainLoop = =>
			@timeManager.tick (err) =>
				return console.error err.stack if err?

				mainLoop()

game = new Game
game.main()