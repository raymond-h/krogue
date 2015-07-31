var Effects, WebRenderer, _, entityClasses, graphics, log, message, preRenderAscii, tileGraphics, vectorMath;

_ = require('lodash');

log = require('../../log');

vectorMath = require('../../vector-math');

message = require('../../message');

entityClasses = require('../../entities');

tileGraphics = require('../graphics-tiles');

graphics = require('../graphics-ascii');

Effects = require('./effects');

module.exports = WebRenderer = (function() {
  function WebRenderer(io, game) {
    var canvas, ref;
    this.io = io;
    this.game = game;
    this.invalidated = false;
    this.invalidate();
    this.camera = {
      x: 0,
      y: 0
    };
    this.promptMessage = null;
    this.tileSize = 32;
    this.cursor = null;
    this.logBox = document.getElementById('log');
    this.game.on('turn.player.start', (function(_this) {
      return function() {
        return _this.invalidate();
      };
    })(this)).on('log.add', (function(_this) {
      return function(str) {
        $(_this.logBox).append("<p>" + str + "</p>");
        return _this.logBox.scrollTop = _this.logBox.scrollHeight;
      };
    })(this));
    canvas = $('#viewport')[0];
    this.viewport = canvas.getContext('2d');
    window.onerror = (function(_this) {
      return function(errMsg, url, lineNumber) {
        _this.viewport.fillStyle = '#000000';
        _this.viewport.fillRect(0, 0, _this.viewport.canvas.width, _this.viewport.canvas.height);
        _this.viewport.font = '30pt monospace';
        _this.viewport.fillStyle = 'red';
        _this.viewport.fillText("Craaaash!", 5, 5 + 30);
        _this.viewport.font = '20pt monospace';
        _this.viewport.fillStyle = 'red';
        _this.viewport.fillText(errMsg, 5, 5 + 30 + 20 + 7);
        _this.viewport.font = '15pt monospace';
        _this.viewport.fillStyle = 'red';
        _this.viewport.fillText("...at " + url + ", line #" + lineNumber, 5, 5 + 30 + 20 + 7 + 15 + 7);
        return false;
      };
    })(this);
    window.onresize = _.debounce((function(_this) {
      return function() {
        _this.updateSize();
        return _this.invalidate();
      };
    })(this), 300);
    this.updateSize();
    this.asciiCanvas = $('<canvas>')[0];
    ref = [this.tileSize * 4, this.tileSize * 8], this.asciiCanvas.width = ref[0], this.asciiCanvas.height = ref[1];
    this.asciiCtx = this.asciiCanvas.getContext('2d');
    this.tilesImg = document.getElementById('tiles');
    this.graphics = preRenderAscii(this.asciiCtx, graphics, this.tileSize);
    this.useTiles = false;
    $('#menu').hide().html('');
  }

  WebRenderer.prototype.updateSize = function() {
    this.viewport.canvas.width = window.innerWidth;
    this.viewport.canvas.height = window.innerHeight;
    this.viewport.webkitImageSmoothingEnabled = false;
    this.viewport.mozImageSmoothingEnabled = false;
    this.viewport.oImageSmoothingEnabled = false;
    this.viewport.msImageSmoothingEnabled = false;
    return this.viewport.imageSmoothingEnabled = false;
  };

  WebRenderer.prototype.invalidate = function() {
    if (!this.invalidated) {
      this.invalidated = true;
      return process.nextTick((function(_this) {
        return function() {
          _this.invalidated = false;
          return _this.render();
        };
      })(this));
    }
  };

  WebRenderer.prototype.setPromptMessage = function(promptMessage) {
    this.promptMessage = promptMessage;
    if (this.promptMessage != null) {
      return this.message(this.promptMessage);
    }
  };

  WebRenderer.prototype.hasMoreLogs = function() {
    return false;
  };

  WebRenderer.prototype.showMoreLogs = function() {};

  WebRenderer.prototype.hideMenu = function() {
    $('#menu').off();
    return $('#menu').hide().html('');
  };

  WebRenderer.prototype.showSingleChoiceMenu = function(header, items, opts) {
    var i;
    $('#menu').show().html("<h1 class=\"menu-title\">" + header + "</h1> <ul class=\"single-choice items\"> " + (((function() {
      var j, len, results;
      results = [];
      for (j = 0, len = items.length; j < len; j++) {
        i = items[j];
        results.push("<li>" + i + "</li>");
      }
      return results;
    })()).join('')) + " </ul> <div class=\"actions\"> <a id=\"cancel\" class=\"action cancel\" href=\"#\">Cancel</a> </div>");
    $('#menu .items').on('click', 'li', function() {
      i = $(this).index();
      return opts != null ? opts.onChoice(i, items[i]) : void 0;
    });
    return $('#menu #cancel').click(function() {
      return opts != null ? typeof opts.onCancel === "function" ? opts.onCancel() : void 0 : void 0;
    });
  };

  WebRenderer.prototype.showMultiChoiceMenu = function(header, items, opts) {
    var done, i, updateChecked;
    $('#menu').show().html("<h1 class=\"menu-title\">" + header + "</h1> <ul class=\"multi-choice items\"> " + (((function() {
      var j, len, results;
      results = [];
      for (j = 0, len = items.length; j < len; j++) {
        i = items[j];
        results.push("<li>" + i + "</li>");
      }
      return results;
    })()).join('')) + " </ul> <div class=\"actions\"> <a id=\"cancel\" class=\"action cancel\" href=\"#\">Cancel</a> <a id=\"done\" class=\"action done\" href=\"#\">Done</a> </div>");
    updateChecked = function(i) {
      $('#menu .items > li').eq(i).toggleClass('checked');
      return opts != null ? typeof opts.onChecked === "function" ? opts.onChecked(i, items[i], $(this).hasClass('checked')) : void 0 : void 0;
    };
    done = function() {
      var indices;
      indices = [];
      $('#menu .items .checked').each(function() {
        return indices.push($(this).index());
      });
      return opts != null ? typeof opts.onDone === "function" ? opts.onDone(indices) : void 0 : void 0;
    };
    $('#menu .items').on('click', 'li', function() {
      console.log("Clicked " + ($(this).index()), this);
      return updateChecked($(this).index());
    });
    $('#menu #cancel').click(function() {
      return opts != null ? typeof opts.onCancel === "function" ? opts.onCancel() : void 0 : void 0;
    });
    $('#menu #done').click(function() {
      return done();
    });
    return [updateChecked, done];
  };

  WebRenderer.prototype.onClick = function(callback) {
    var canvas, handler;
    handler = (function(_this) {
      return function(e) {
        var eventData, worldPos;
        worldPos = {
          x: Math.floor((e.pageX + _this.camera.x) / _this.tileSize),
          y: Math.floor((e.pageY + _this.camera.y) / _this.tileSize)
        };
        eventData = {
          original: e,
          x: e.pageX + _this.camera.x,
          y: e.pageY + _this.camera.y,
          world: worldPos
        };
        return callback(eventData);
      };
    })(this);
    canvas = $(this.viewport.canvas);
    canvas.bind('click', handler);
    return (function() {
      return canvas.unbind('click', handler);
    });
  };

  WebRenderer.prototype.render = function() {
    this.viewport.fillStyle = '#000000';
    this.viewport.fillRect(0, 0, this.viewport.canvas.width, this.viewport.canvas.height);
    switch (this.game.state) {
      case 'game':
        this.renderMap(0, 0);
        if (this.cursor != null) {
          return this.renderCursor();
        }
        break;
      case 'death':
        return this.renderDeath();
      default:
        return null;
    }
  };

  WebRenderer.prototype.renderDeath = function() {
    this.viewport.font = '30pt monospace';
    this.viewport.textAlign = 'center';
    this.viewport.textBaseline = 'middle';
    this.viewport.fillStyle = 'red';
    return this.viewport.fillText("You have died, " + this.game.player.creature + "!", this.viewport.canvas.width / 2, this.viewport.canvas.height / 2);
  };

  WebRenderer.prototype.renderCursor = function() {
    var ref, x, y;
    ref = this.cursor, x = ref.x, y = ref.y;
    x = x * this.tileSize - this.camera.x;
    y = y * this.tileSize - this.camera.y;
    this.viewport.fillStyle = 'rgba(255,0,0, 0.2)';
    return this.viewport.fillRect(x, y, this.tileSize, this.tileSize);
  };

  WebRenderer.prototype.renderMap = function(x, y) {
    var base, base1, canvasSize, center, cx, cy, entities, entityLayer, graphic, graphicAt, j, k, map, playerScreenPos, ref, ref1;
    canvasSize = {
      x: this.viewport.canvas.width,
      y: this.viewport.canvas.height
    };
    playerScreenPos = vectorMath.mult(this.game.player.lookPos, this.tileSize);
    map = this.game.currentMap;
    center = vectorMath.add(playerScreenPos, {
      x: this.tileSize / 2,
      y: this.tileSize / 2
    });
    this.camera = vectorMath.sub(center, vectorMath.div(canvasSize, 2));
    this.camera.target = this.game.player.creature;
    (base = this.camera).x = Math.floor(base.x / 1);
    (base1 = this.camera).y = Math.floor(base1.y / 1);
    graphicAt = (function(_this) {
      return function(x, y) {
        if (_this.camera.target.canSee({
          x: x,
          y: y
        })) {
          return _this.getGraphicId(map.data[y][x]);
        }
      };
    })(this);
    for (cx = j = 0, ref = map.w; 0 <= ref ? j < ref : j > ref; cx = 0 <= ref ? ++j : --j) {
      for (cy = k = 0, ref1 = map.h; 0 <= ref1 ? k < ref1 : k > ref1; cy = 0 <= ref1 ? ++k : --k) {
        graphic = graphicAt(cx, cy);
        if (graphic != null) {
          this.renderGraphicAtSlot(cx, cy, graphic);
        }
      }
    }
    entityLayer = {
      'creature': 3,
      'item': 2,
      'stairs': 1
    };
    entities = map.entities.slice(0).sort(function(a, b) {
      return entityLayer[a.type] - entityLayer[b.type];
    });
    this.renderEntities(x, y, entities);
    return this.renderEffects(x, y);
  };

  WebRenderer.prototype.renderEntities = function(x, y, entities) {
    var e, j, len, results;
    results = [];
    for (j = 0, len = entities.length; j < len; j++) {
      e = entities[j];
      if (this.camera.target.canSee(e)) {
        results.push(this.renderGraphicAtSlot(e.x, e.y, this.getGraphicId(e)));
      }
    }
    return results;
  };

  WebRenderer.prototype.renderGraphicAtSlot = function(x, y, graphicId) {
    var c, ref, ref1, ref2, sourceX, sourceY;
    c = this.camera;
    if (this.useTiles) {
      ref = tileGraphics.get(graphicId), sourceX = ref.x, sourceY = ref.y;
      return this.viewport.drawImage(this.tilesImg, sourceX, sourceY, 16, 16, x * this.tileSize - c.x, y * this.tileSize - c.y, this.tileSize, this.tileSize);
    } else {
      ref2 = (ref1 = this.graphics[graphicId]) != null ? ref1 : this.graphics._default, sourceX = ref2.x, sourceY = ref2.y;
      return this.viewport.drawImage(this.asciiCanvas, sourceX * this.tileSize, sourceY * this.tileSize, this.tileSize, this.tileSize, x * this.tileSize - c.x, y * this.tileSize - c.y, this.tileSize, this.tileSize);
    }
  };

  WebRenderer.prototype.getGraphicId = function(input) {
    var ref;
    if (_.isString(input)) {
      return input;
    } else if (_.isObject(input)) {
      if (_.isPlainObject(input)) {
        return (ref = input.symbol) != null ? ref : input.type;
      } else if (input instanceof entityClasses.Creature) {
        return this.getGraphicId(input.species);
      } else if (input instanceof entityClasses.MapItem) {
        return this.getGraphicId(input.item);
      } else if (input instanceof entityClasses.Stairs) {
        if (input.down) {
          return 'stairsDown';
        } else {
          return 'stairsUp';
        }
      } else {
        return _.camelCase(input.constructor.name);
      }
    }
  };

  WebRenderer.prototype.renderEffects = function(ox, oy) {
    return this.io.effects.renderEffects(ox, oy);
  };

  return WebRenderer;

})();

preRenderAscii = function(ctx, graphics, tileSize, dim) {
  var g, i, name, renderSymbol, renderSymbolAtSlot, x, y;
  renderSymbolAtSlot = function(x, y, symbol, color) {
    return renderSymbol(x * tileSize, y * tileSize, symbol, color);
  };
  renderSymbol = function(x, y, symbol, color) {
    if (color == null) {
      color = 'white';
    }
    ctx.fillStyle = 'black';
    ctx.fillRect(x, y, tileSize, tileSize);
    ctx.font = tileSize + "px consolas";
    ctx.fillStyle = color;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    return ctx.fillText(symbol, x + tileSize / 2, y + tileSize);
  };
  if (dim == null) {
    dim = {
      x: 4,
      y: 8
    };
  }
  i = 0;
  return _.zipObject((function() {
    var ref, results;
    results = [];
    for (name in graphics.graphics) {
      g = graphics.get(name);
      ref = [i % dim.x, Math.floor(i / dim.x)], x = ref[0], y = ref[1];
      i++;
      renderSymbolAtSlot(x, y, g.symbol, g.color);
      results.push([
        name, {
          x: x,
          y: y,
          graphics: g
        }
      ]);
    }
    return results;
  })());
};
