async = require 'async'
{EventEmitter2: EventEmitter} = require 'eventemitter2'

TimeManager = require './time-manager'
{Map} = require './map'

{initialize, deinitialize, Renderer} = require './io/tty'

{Dummy, FastDummy, Player} = require './creatures'

class Game
	constructor: ->
		# console.error 'Starting game...'
		@state = 'main menu'

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

		@timeManager.targets.push @entities...

		@events.on 'key.c', (ch, key) =>
			@quit() if key.ctrl

	quit: ->
		deinitialize @
		process.exit 0

	goState: (state) ->
		@state = state
		@renderer.invalidate()

	main: ->
		async.whilst (-> true),
			(next) =>
				switch @state
					when 'main menu'
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