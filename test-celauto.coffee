Q = require 'q'
_ = require 'lodash'

{createMapData, neighbourCount, randomTiles, cellularAutomataGeneration} = require './src/map-generation'
{repeat} = require './src/util'

printMap = (map) ->
	for row in map
		console.log row.join ''

# large encompassing caves with tunnels
# rules = _.flatten [
# 	repeat 4, (neighbours) -> neighbours >= 6 or neighbours < 1
# 	repeat 3, (neighbours) -> neighbours >= 5
# ]

# huge open cave
# rules = _.flatten [
# 	repeat 2, (neighbours) -> neighbours % 4 is 0
# 	repeat 3, (neighbours) -> neighbours >= 4
# ]

rules = _.flatten [
	repeat 2, (neighbours) -> neighbours % 4 is 0
	repeat 3, (neighbours) -> neighbours >= 4
]

w = 80
h = 30

map = createMapData w, h, randomTiles(Math.random, 0.40)

for rule in rules
	printMap map
	console.log '-----'
	map = cellularAutomataGeneration map, w, h, rule

printMap map