winston = require 'winston'

winston
	.remove winston.transports.Console
	.add winston.transports.File,
		level: 'info'
		filename: 'output.log'
		json: no

game = require './game'

game.initialize require './io/tty'
game.main()