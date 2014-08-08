Q = require 'q'
_ = require 'lodash'

{createMapData, mapGen: {border, randomTiles}, cellularAutomataGeneration} = require './src/map-generation'
{repeat} = require './src/util'

printMap = (map) ->
	for row in map
		console.log row.join ''

# return '#' if not (0 < x < w-1 and 0 < y < h-1)

# large encompassing caves with tunnels
# initProb = 0.40
# rules = _.flatten [
# 	repeat 4, (neighbours) -> neighbours >= 6 or neighbours < 1
# 	repeat 3, (neighbours) -> neighbours >= 5
# ]

# large encompassing caves with tunnels 2
# initProb = 0.35
# rules = _.flatten [
# 	repeat 2, (neighbours) -> neighbours >= 5 or neighbours < 1
# 	repeat 3, (neighbours) -> neighbours >= 5
# ]

# huge open cave
# initProb = 0.40
# rules = _.flatten [
# 	repeat 2, (neighbours) -> neighbours % 4 is 0
# 	repeat 3, (neighbours) -> neighbours >= 4
# ]

# also huge cave
# initProb = 0.20
# rules = _.flatten [
# 	repeat 1, (neighbours) -> neighbours >= 3
# 	repeat 4, (neighbours) -> neighbours >= 5
# ]

# initProb = 0.45
# rules = _.flatten [
# 	repeat 6, (neighbours) -> neighbours >= 5
# 	repeat 4, (neighbours) -> neighbours >= 4
# ]

initProb = 0.40
rules = _.flatten [
	repeat 3, (neighbours) -> neighbours >= 5 or neighbours < 1
	repeat 2, (neighbours) -> neighbours >= 4
	repeat 2, (neighbours) -> neighbours >= 7
]

w = 150
h = 100

_randomTiles = randomTiles(Math.random, initProb)

map = createMapData w, h, (a...) -> (border a...) ? (_randomTiles a...)

for rule in rules
	printMap map
	console.log '-----'
	map = cellularAutomataGeneration map, w, h, rule

printMap map