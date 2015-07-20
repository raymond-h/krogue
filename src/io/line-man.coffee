{EventEmitter} = require 'events'
wordwrap = require 'wordwrap'

module.exports = class LineMan extends EventEmitter
	constructor: (@width, @maxLines = Infinity) ->
		@wrap = wordwrap.hard @width
		@lines = []

	add: (line) ->
		if @lines.length > 0
			line = @lines.pop() + ' ' + line

		@lines.push (@wrap line).split('\n')...

		@emit 'update', @lines

		@lines.shift() while @lines.length > @maxLines