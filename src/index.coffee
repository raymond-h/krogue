TimeManager = require './time-manager'

timeManager = new TimeManager

Q = require 'q'

class Dummy
	tickRate: 10

	tick: ->
		if Math.random() < 0.5
			Q.fcall -> console.log 'Rock on, you dick'
			.delay 2000
			.then -> console.log 'Depleted resources, must wait...'; 3000
		else
			Q.fcall -> console.log 'Eat this!'
			.delay 500
			.then -> console.log 'Not a lot, but still exhausted!'; 1000

timeManager.targets.push new Dummy

do mainLoop = ->
	timeManager.tick (err) ->
		return console.error err.stack if err?

		mainLoop()