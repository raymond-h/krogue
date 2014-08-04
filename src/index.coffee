TimeManager = require './time-manager'

timeManager = new TimeManager

Q = require 'q'

class Dummy
	tickRate: 10

	tick: ->
		Q.fcall -> console.log 'Rock on, you dick'
		.delay 1000
		# .then -> console.log 'Depleted resources, must wait...'
		.thenResolve 30

class Player
	constructor: (@name) ->
		@speed = 12

	tickRate: -> @speed

	tick: ->
		console.log "#{@name}: I AM SO FAST"

		Q(30).delay 1000

timeManager.targets.push new Dummy
timeManager.targets.push new Player 'KayArr'

do mainLoop = ->
	timeManager.tick (err) ->
		return console.error err.stack if err?

		mainLoop()