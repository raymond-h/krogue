var EventBus, EventEmitter2, Promise, exports, log,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

EventEmitter2 = require('eventemitter2').EventEmitter2;

Promise = require('bluebird');

EventBus = (function(superClass) {
  extend(EventBus, superClass);

  function EventBus() {
    EventBus.__super__.constructor.call(this, {
      wildcard: true,
      newListener: false
    });
  }

  EventBus.prototype.waitOn = function(event) {
    return (new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.once(event, function() {
          var params;
          params = 1 <= arguments.length ? slice.call(arguments, 0) : [];
          return resolve(params);
        });
      };
    })(this))).cancellable();
  };

  return EventBus;

})(EventEmitter2);

module.exports = exports = new EventBus;

exports.EventBus = EventBus;

log = require('./log');

exports.onAny(function() {
  var a;
  a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return log.silly("Event: '" + this.event + "'; ", a);
});
