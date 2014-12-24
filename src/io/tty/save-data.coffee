fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

Q = require 'q'

serialization = require '../../serialization'

exports.save = (game, filename) ->
	filename = path.join 'saves', filename
	mkdirp.sync 'saves'

	Q serialization.stringify game.saveToJSON()

	.then (json) ->
		fs.writeFileSync filename, json

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

	Q serialization.parse (fs.readFileSync filename, encoding: 'utf-8')

	.then (obj) ->
		game.loadFromJSON obj