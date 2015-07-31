var Promise, log, logLevel;

Promise = require('bluebird');

log = require('../log');

logLevel = 'info';

$(function() {
  var Web, game, web;
  Web = require('../io/web');
  game = require('../game');
  web = new Web(game);
  web.initializeLog(logLevel);
  log("Using log level " + logLevel);
  game.initialize(web);
  return game.main();
});
