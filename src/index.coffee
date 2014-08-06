async = require 'async'
{EventEmitter2: EventEmitter} = require 'eventemitter2'
MersenneTwister = require 'mersennetwister'

TimeManager = require './time-manager'
Random = require './random'
{Map} = require './map'

{Dummy, FastDummy, Player} = require './creatures'

{initialize, deinitialize, Renderer} = require './io/tty'

class Game
	constructor: ->
		# console.error 'Starting game...'
		@state = 'main-menu'

		@events = new EventEmitter
			wildcard: yes
			# newListener: yes

		# @events.onAny (a...) ->
		# 	console.error "Event: '#{@event}'; ", a

		initialize @
		@renderer = new Renderer @

		@events.on 'key.c', (ch, key) =>
			@quit() if key.ctrl

		@events.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		@random = new Random(new MersenneTwister)
		@timeManager = new TimeManager
		@currentMap = new Map @, 50, 15

		@entities = [
			new Player @, @currentMap, 2, 2, 'KayArr'
			new Dummy @, @currentMap, 6, 6
			new FastDummy @, @currentMap, 12, 6
		]

		@timeManager.targets.push @entities...

	quit: ->
		deinitialize @
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
				console.error err.stack if err?
				@quit()

game = new Game
game.main()