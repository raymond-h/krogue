fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

serialization = require '../serialization'

exports.save = (game, filename) ->
	filename = path.join 'saves', filename
	mkdirp.sync 'saves'

	json = serialization.stringify game.saveToJSON()

	fs.writeFileSync filename, json

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

	obj = serialization.parse (fs.readFileSync filename, encoding: 'utf-8')

	game.loadFromJSON obj