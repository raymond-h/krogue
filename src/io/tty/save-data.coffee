fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

serialization = require '../../serialization'
{p} = require '../../util'

exports.save = (game, filename) ->
	filename = path.join 'saves', filename
	mkdirp.sync 'saves'

<<<<<<< HEAD
	p serialization.stringify game.saveToJSON()
=======
	Promise.resolve(serialization.stringify game.saveToJSON())
>>>>>>> Use Bluebird instead of Q for promises

	.then (json) ->
		fs.writeFileSync filename, json

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

<<<<<<< HEAD
	p serialization.parse (fs.readFileSync filename, encoding: 'utf-8')
=======
	Promise.resolve(serialization.parse (fs.readFileSync filename, encoding: 'utf-8'))
>>>>>>> Use Bluebird instead of Q for promises

	.then (obj) ->
		game.loadFromJSON obj