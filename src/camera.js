var Camera, _, edge, log, ref, snapToRange;

_ = require('lodash');

log = require('./log');

ref = require('./util'), edge = ref.edge, snapToRange = ref.snapToRange;

module.exports = Camera = (function() {
  function Camera(viewport, minBoundDist1) {
    this.viewport = viewport;
    this.minBoundDist = minBoundDist1;
    this.worldBounds = null;
    this.x = this.y = 0;
  }

  Camera.prototype.bounds = function(rect) {
    return this.worldBounds = _.defaults(_.pick(rect, 'x', 'y', 'w', 'h'), {
      x: 0,
      y: 0,
      w: this.viewport.w,
      h: this.viewport.h
    });
  };

  Camera.prototype.calculateOffset = function(relPos, camSize, minBoundDist) {
    if (minBoundDist > relPos) {
      return relPos - minBoundDist;
    } else if ((camSize - minBoundDist) <= relPos) {
      return (relPos - (camSize - minBoundDist)) + 1;
    } else {
      return 0;
    }
  };

  Camera.prototype.update = function() {
    var wb;
    wb = this.worldBounds;
    if (this.target != null) {
      this.x += this.calculateOffset(this.target.x - this.x, this.viewport.w, this.minBoundDist.x);
      this.y += this.calculateOffset(this.target.y - this.y, this.viewport.h, this.minBoundDist.y);
    }
    this.x = snapToRange(edge(wb, 'left'), this.x, (edge(wb, 'right')) - this.viewport.w);
    this.y = snapToRange(edge(wb, 'up'), this.y, (edge(wb, 'down')) - this.viewport.h);
    return log("Updating camera pos to " + this.x + "," + this.y);
  };

  return Camera;

})();
