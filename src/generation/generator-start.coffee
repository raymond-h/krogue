MapGen = require './maps'

generateMap = (path, level, connections) ->
	map = MapGen.generateBigRoom path, level, connections, 80, 21

	generateEntities map, path, level

	map

generateEntities = (map, path, level) ->

module.exports = {generateMap, generateEntities}