exports.SizeAltered = (function() {
  SizeAltered.prototype.name = function() {
    if (this.factor < 1) {
      return 'shrunken x' + (1 / this.factor);
    } else {
      return 'enlarged x' + this.factor;
    }
  };

  function SizeAltered(arg) {
    this.factor = arg.factor;
  }

  SizeAltered.prototype.modifyStat = function(creature, stat, name) {
    if (name === 'strength' || name === 'agility' || name === 'endurance' || name === 'weight') {
      return Math.max(1, Math.floor(stat * this.factor / 1));
    }
  };

  return SizeAltered;

})();
