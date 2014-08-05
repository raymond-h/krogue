class exports.Entity
	constructor: (@game, @map, @x, @y) ->
		@symbol = '?'

	setPos: (x, y) ->
		@x = x
		@y = y
		@game.renderer.invalidate()

	move: (x, y) ->
		@setPos @x+x, @y+y

	tickRate: 0

	tick: ->