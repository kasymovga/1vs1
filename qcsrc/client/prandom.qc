// prandom - PREDICTABLE random number generator (not seeded yet)
float prandom_seed;
float() prandom {
	float c;
	c = crc16(FALSE, strcat(ftos(prandom_seed), ftos(prandom_seed + 3.1415926535)));
	prandom_seed = c;
	return c / 65536; // in [0..1[
}

vector(void) prandomvec {
	vector v;
	v_x = prandom();
	v_y = prandom();
	v_z = prandom();
	if (vlen(v) > 1)
		v = v * 0.57735;

	return v;
}

void(float seed) prandom_seed_set {
	prandom_seed = seed;
}

void(float ignore) prandom_seed_read {
	prandom_seed_set(net_read_short());
}

