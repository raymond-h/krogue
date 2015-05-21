MapGen = require './maps'
CreatureGen = require './creatures'
ItemGen = require './items'

generateMap = (path, level, connections) ->
	map = MapGen.generateCellularAutomata path, level, connections, 100, 50

	generateEntities map, path, level

	map

generateEntities = (map, path, level) ->
	## Creatures
	for i in [1..20]
		{x, y} = MapGen.generatePos map
		map.addEntity CreatureGen.generateStrangeGoo x, y

	for i in [1..3]
		{x, y} = MapGen.generatePos map
		map.addEntity CreatureGen.generateViolentDonkey x, y

	# for i in [1..1]
	# 	{x, y} = MapGen.generatePos map
	# 	map.addEntity CreatureGen.generateTinyAlien x, y

	for i in [1..3]
		{x, y} = MapGen.generatePos map
		map.addEntity CreatureGen.generateSpaceAnemone x, y

	## Items
	for i in [1..3]
		{x, y} = MapGen.generatePos map

		map.addEntity ItemGen.generatePeculiarObject().asMapItem x, y

	{x, y} = MapGen.generatePos map
	map.addEntity ItemGen.generateGun().asMapItem x, y

module.exports = {generateMap, generateEntities}