Q = require 'q'

{arrayRemove} = require '../util'

module.exports = class Effects
	constructor: (@io) ->
		@effects = []

	doEffect: (data) ->
		@[data.type]? data

	_performEffect: (data, cb) ->
		@effects.push data

		Q cb.call @, data

		.then =>
			arrayRemove @effects, data
			@invalidate()

	invalidate: -> @io.renderer.invalidate()