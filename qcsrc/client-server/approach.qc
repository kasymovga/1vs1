float(float v, float t, float d) approach {
	if(v < t) {
		v += d;
		if(v > t)
			return t;
	} else if(v > t) {
		v -= d;
		if(v < t)
			return t;
	}
	return v;
}

float(float v, float t, float d) approach_angle {
	while (v - t < -180)
		v += 360;

	while (v - t > 180)
		v -= 360;

	return approach(v, t, d);
}
