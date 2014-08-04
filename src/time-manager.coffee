async = require 'async'

module.exports = class TimeManager
	constructor: ->
		@targets = []

		@targets.remove = (item) ->
			i = @indexOf item
			@[i..i] = []
			i

		@targets.rotate = ->
			@push @shift()

	tick: (callback) ->
		callback()