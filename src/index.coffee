TimeManager = require 'time-manager'

timeManager = new TimeManager

do mainLoop = ->
	timeManager.tick (err) ->
		return console.error err.stack if err?

		process.nextTick mainLoop