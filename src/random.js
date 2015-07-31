import _ from 'lodash';
import MersenneTwister from 'mersennetwister';

export class Random {
	constructor(mersenneTwister = new MersenneTwister()) {
		this.mersenneTwister = mersenneTwister;
	}

	bool() {
		return (this.mersenneTwister.int31() % 2) === 0;
	}

	rnd() { return this.mersenneTwister.rnd(); }

	range(min, max) {
		return Math.floor(this.rangeFloat(min, max));
	}

	rangeFloat(min, max) {
		return this.rnd() * (max - min) + min;
	}

	chance(chance) {
		return this.rnd() < chance;
	}

	direction(n, diagonal = false) {
		let choices;

		switch(n) {
			case 4:
				choices =
					diagonal ? [
						'up-left', 'up-right',
						'down-left', 'down-right'
					]
					: [
						'up', 'down',
						'left', 'right'
					];
				break;

			case 8:
				choices = [
					'up-left', 'up-right',
					'down-left', 'down-right',
					'up', 'down', 'left', 'right'
				];
				break;
		}

		return this.sample(choices);
	}

	sample(a, n) {
		if(n == null)
			return a[this.range(0, a.length)];

		return _.take(this.shuffle(a.slice()));
	}

	shuffle(a) {
		for(let i = 0; i < a.length; i++) {
			const j = this.range(i, a.length);
			[a[i], a[j]] = [a[j], a[i]];
		}

		return a;
	}

	unitCirclePoint() {
		const t = 2 * Math.PI * this.rnd();
		const r = Math.sqrt(this.rnd());
		return [r * Math.cos(t), r * Math.sin(t)];
	}

	gaussian(mean = 0, stdev = 1) {
		const [x, y] = this.unitCirclePoint();
		const s = x * x + y * y;

		const c = Math.sqrt(-2 * Math.log(s) / s);
		return [x * c, y * c].map(v => stdev * v + mean);
	}
}

export default new Random();
