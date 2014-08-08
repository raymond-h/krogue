{Map} = require './map'

{Dummy, FastDummy} = require './creatures'

exports.generateBigRoom = (game, w, h) ->
	map = new Map game, w, h

	# generate map itself ('.' everywhere, '#' surrounding entire room)
	tile = (x,y) => if (0 < x < w-1 and 0 < y < h-1) then '.' else '#'
	
	map.data = ((tile x,y for x in [0...w]) for y in [0...h])

	# 'generate' entities to inhabit the map
	map.entities = [
		new Dummy game, map, 6, 6
		new FastDummy game, map, 12, 6
	]

	map