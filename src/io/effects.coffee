{arrayRemove} = require '../util'
{p} = require '../util'

module.exports = class Effects
	constructor: (@io) ->
		@effects = []

	doEffect: (data) ->
		@[data.type]? data

	_performEffect: (data, cb) ->
		@effects.push data

		p cb.call @, data

		.then =>
			arrayRemove @effects, data
			@invalidate()

	invalidate: -> @io.renderer.invalidate()