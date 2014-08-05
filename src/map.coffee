_ = require 'lodash'

class exports.Map
	constructor: (@game, @w, @h) ->
		tile = (x,y) => if (0 < x < @w-1 and 0 < y < @h-1) then '.' else '#'

		@data = ((tile x,y for x in [0...@w]) for y in [0...@h])

	collidable: (x, y) ->
		return true unless 0 <= x < @w and 0 <= y < @h

		@data[y][x] is '#'