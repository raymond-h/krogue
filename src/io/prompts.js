var Promise, Prompts, _, charRange, eventBus,
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Promise = require('bluebird');

_ = require('lodash');

eventBus = require('../event-bus');

charRange = function(start, end) {
  var j, ref, ref1, results;
  return (function() {
    results = [];
    for (var j = ref = start.charCodeAt(0), ref1 = end.charCodeAt(0); ref <= ref1 ? j <= ref1 : j >= ref1; ref <= ref1 ? j++ : j--){ results.push(j); }
    return results;
  }).apply(this).map(function(i) {
    return String.fromCharCode(i);
  });
};

module.exports = Prompts = (function() {
  Prompts.prototype.listOptions = slice.call(charRange('a', 'z')).concat(slice.call(charRange('A', 'Z')), slice.call(charRange('0', '9')));

  function Prompts(game) {
    this.game = game;
  }

  Prompts.prototype.generic = function(message, event, matcher, opts) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var e, handler, j, len;
        event = [].concat(event);
        handler = function() {
          var a, e, j, len;
          a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
          if (matcher.apply(null, [this.event].concat(slice.call(a)))) {
            for (j = 0, len = event.length; j < len; j++) {
              e = event[j];
              eventBus.off(e, handler);
            }
            return resolve([this.event].concat(slice.call(a)));
          }
        };
        for (j = 0, len = event.length; j < len; j++) {
          e = event[j];
          eventBus.on(e, handler);
        }
        return _this.game.renderer.setPromptMessage(message);
      };
    })(this));
  };

  Prompts.prototype.keys = function(message, keys, opts) {
    var ref, separator, showKeys, shownKeys;
    ref = _.defaults({}, opts, {
      showKeys: true,
      separator: ','
    }), showKeys = ref.showKeys, shownKeys = ref.shownKeys, separator = ref.separator;
    if ((message != null) && showKeys) {
      message = message + " [" + ((shownKeys != null ? shownKeys : keys).join(separator)) + "]";
    }
    return this.generic(message, 'key.*', function(event, ch, key) {
      var ref1;
      return ref1 = key.full, indexOf.call(keys, ref1) >= 0;
    }, opts).then(function(arg) {
      var ch, event, key;
      event = arg[0], ch = arg[1], key = arg[2];
      return key.full;
    });
  };

  Prompts.prototype.actions = function(message, actions, opts) {
    var cancelable, ref, separator, showActions, shownActions;
    ref = _.defaults({}, opts, {
      showActions: true,
      separator: ',',
      cancelable: false
    }), showActions = ref.showActions, shownActions = ref.shownActions, separator = ref.separator, cancelable = ref.cancelable;
    if ((message != null) && showActions) {
      message = message + " [" + ((shownActions != null ? shownActions : actions).join(separator)) + "]";
    }
    return this.generic(message, ['key.escape', 'action.**'], function() {
      var action, event, params;
      event = arguments[0], action = arguments[1], params = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      if (cancelable && event === 'key.escape') {
        return true;
      }
      return indexOf.call(actions, action) >= 0;
    }, opts).then(function(arg) {
      var a, event;
      event = arg[0], a = 2 <= arg.length ? slice.call(arg, 1) : [];
      if (event === 'key.escape') {
        return null;
      } else {
        return a;
      }
    });
  };

  Prompts.prototype.yesNo = function(message, opts) {
    var choices;
    if (opts == null) {
      opts = {};
    }
    if (opts.shownKeys == null) {
      opts.shownKeys = ['y', 'n'];
    }
    if (opts.separator == null) {
      opts.separator = '';
    }
    choices = ['y', 'n'];
    if (opts.cancelable) {
      choices.push('escape');
    }
    return this.keys(message, choices, opts).then(function(reply) {
      switch (reply) {
        case 'escape':
          return null;
        case 'y':
          return true;
        default:
          return false;
      }
    });
  };

  Prompts.prototype.direction = function(message, opts) {
    if (opts == null) {
      opts = {};
    }
    if (opts.cancelable) {
      if (opts.shownActions == null) {
        opts.shownActions = ['direction', 'escape'];
      }
    }
    return this.actions(message, ['direction'], opts).then(function(reply) {
      if (reply == null) {
        return null;
      }
      return reply[1];
    });
  };

  Prompts.prototype.pressedKey = function(key) {
    switch (false) {
      case !(('A' <= key && key <= 'Z')):
        return "S-" + (key.toLowerCase());
      default:
        return key;
    }
  };

  return Prompts;

})();
