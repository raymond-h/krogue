Q = require 'q'

class exports.Dummy
	tickRate: 10

	tick: ->
		Q.fcall -> console.log 'Rock on, you dick'
		.delay 1000
		# .then -> console.log 'Depleted resources, must wait...'
		.thenResolve 30

class exports.Player
	constructor: (@name, @speed = 12) ->

	tickRate: -> @speed

	tick: ->
		console.log "#{@name}: I AM SO FAST"

		Q(30).delay 1000