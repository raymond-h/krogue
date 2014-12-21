Q = require 'q'

vectorMath = require '../../vector-math'
{bresenhamLine, whilst, arrayRemove} = require '../../util'

module.exports = class WebEffects
	constructor: (@io) ->
		@effects = []

	throw: ({start, end, symbol}) ->
		@line {start, end, symbol, delay: 50}

	shootLine: ({start, end, symbol}) ->
		@line {start, end, symbol, delay: 50}

	line: (data) ->
		points = bresenhamLine start, end
		
		if time? and not delay?
			delay = time / points.length

		@_performEffect {type: 'line', symbol}, (data) ->
			
			whilst (-> points.length > 0),
				=>
					Q.fcall =>
						data.current = points.shift()
						@invalidate()

					.delay delay

	doEffect: (data) ->
		@[data.type]? data

	_performEffect: (data, cb) ->
		@effects.push data

		Q cb.call @, data

		.then =>
			arrayRemove @effects, data
			@invalidate()

	renderEffects: (ox, oy) ->
		for e in @effects then switch e.type
			when 'line'
				{x, y} = e.current
				@io.renderer.renderGraphicAtSlot x+ox, y+oy, e.symbol

	invalidate: -> @io.renderer.invalidate()