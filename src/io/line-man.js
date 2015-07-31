var EventEmitter, LineMan, wordwrap,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

EventEmitter = require('events').EventEmitter;

wordwrap = require('wordwrap');

module.exports = LineMan = (function(superClass) {
  extend(LineMan, superClass);

  function LineMan(width, maxLines) {
    this.width = width;
    this.maxLines = maxLines != null ? maxLines : Infinity;
    this.wrap = wordwrap.hard(this.width);
    this.lines = [];
  }

  LineMan.prototype.add = function(line) {
    var ref, results;
    if (this.lines.length > 0) {
      line = this.lines.pop() + ' ' + line;
    }
    (ref = this.lines).push.apply(ref, (this.wrap(line)).split('\n'));
    this.emit('update', this.lines);
    results = [];
    while (this.lines.length > this.maxLines) {
      results.push(this.lines.shift());
    }
    return results;
  };

  return LineMan;

})(EventEmitter);
