winston = require 'winston'

winston
	.remove winston.transports.Console
	.add winston.transports.File,
		level: 'silly'
		filename: 'output.log'
		json: no

Game = require './game'

game = new Game(require './io/tty')
game.main()