fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

serialization = require '../../serialization'
{p} = require '../../util'

exports.save = (game, filename) ->
	filename = path.join 'saves', filename
	mkdirp.sync 'saves'

	p serialization.stringify game.saveToJSON()

	.then (json) ->
		fs.writeFileSync filename, json

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

	p serialization.parse (fs.readFileSync filename, encoding: 'utf-8')

	.then (obj) ->
		game.loadFromJSON obj