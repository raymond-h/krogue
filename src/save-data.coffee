fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

exports.save = (game, filename) ->
	filename = path.join 'saves', filename

	mkdirp.sync 'saves'
	fs.writeFileSync filename, JSON.stringify game.saveToJSON()

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

	json = JSON.parse fs.readFileSync filename, encoding: 'utf-8'

	game.loadFromJSON json