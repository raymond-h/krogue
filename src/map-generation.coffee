{Map} = require './map'

exports.generateBigRoom = (game, w, h) ->
	map = new Map game, w, h

	tile = (x,y) => if (0 < x < w-1 and 0 < y < h-1) then '.' else '#'

	map.data = ((tile x,y for x in [0...w]) for y in [0...h])

	map