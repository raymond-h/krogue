_ = require 'lodash'

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
			_.pull @effects, data
			@invalidate()

	invalidate: -> @io.renderer.invalidate()
