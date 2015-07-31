var Promise, _;

_ = require('lodash');

Promise = require('bluebird');

exports.bresenhamLine = function(p0, p1, callback) {
  var dx, dy, e2, err, result, sx, sy, x0, x1, y0, y1;
  x0 = p0.x, y0 = p0.y;
  x1 = p1.x, y1 = p1.y;
  dx = Math.abs(x1 - x0);
  dy = Math.abs(y1 - y0);
  sx = x0 < x1 ? 1 : -1;
  sy = y0 < y1 ? 1 : -1;
  err = dx - dy;
  if (callback == null) {
    result = [];
    callback = function(x, y) {
      return result.push({
        x: x,
        y: y
      });
    };
  }
  while (true) {
    if ((callback(x0, y0)) === false) {
      break;
    }
    if (x0 === x1 && y0 === y1) {
      break;
    }
    e2 = 2 * err;
    if (e2 > -dx) {
      err -= dy;
      x0 += sx;
    }
    if (e2 < dy) {
      err += dx;
      y0 += sy;
    }
  }
  return result;
};

exports.makePromise = exports.p = function(val) {
  return Promise.resolve(val);
};

exports.whilst = function(test, fn) {
  var iteration;
  return (iteration = function() {
    return Promise.resolve(test()).then(function(doLoop) {
      if (doLoop) {
        return Promise.resolve(fn()).then(iteration);
      }
    });
  })();
};

exports.edge = function(r, edge) {
  switch (edge) {
    case 'left':
      return r.x;
    case 'right':
      return r.x + r.w;
    case 'top':
    case 'up':
      return r.y;
    case 'bottom':
    case 'down':
      return r.y + r.h;
  }
};

exports.snapToRange = function(min, curr, max) {
  return Math.max(min, Math.min(curr, max));
};

exports.repeat = function(n, item) {
  var i, j, ref, results;
  results = [];
  for (i = j = 1, ref = n; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
    results.push(item);
  }
  return results;
};

exports.distanceSq = function(o0, o1) {
  var dx, dy, ref;
  ref = [o1.x - o0.x, o1.y - o0.y], dx = ref[0], dy = ref[1];
  return dx * dx + dy * dy;
};

exports.distance = function(o0, o1) {
  return Math.sqrt(exports.distanceSq(o0, o1));
};
