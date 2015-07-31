var Promise, Tty, argv, errorHandler, game, log, logLevel, ref, tty;

Promise = require('bluebird');

Promise.longStackTraces();

argv = (require('yargs')).argv;

log = require('./log');

errorHandler = function(err) {
  log.error('Uncaught exception:', err.stack);
  return setTimeout((function() {
    return process.exit(1);
  }), 1000);
};

process.on('uncaughtException', errorHandler);

process.on('unhandledRejection', errorHandler);

logLevel = (ref = argv.log) != null ? ref : 'info';

Tty = require('./io/tty');

game = require('./game');

tty = new Tty(game);

tty.initializeLog(logLevel);

log("Using log level " + logLevel);

game.initialize(tty);

game.main();
