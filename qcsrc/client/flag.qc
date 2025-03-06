#define FLAG_ANIM_LINEAR(frames,rate,offs) math_mod(floor((time) * (rate) + (offs)), frames)
#define FLAG_ANIM_SINE(frames,rate,offs) (frames - 1) * (sin(time * rate + offs) * 0.5 + 0.5)

float(string cn) flag_animate {
	if (cn == "17")
		return FLAG_ANIM_LINEAR(35, 18, 0);

	return -1;
}

string(string cn) flag_icon {
	string i;
	string path = "gfx/flagicons";
	if (sv_ip2country_subpath != "")
		path = strcat(path, "/", sv_ip2country_subpath);

	if (cn == "")
		return strcat(path, "/xx");

	i = strcat(path, "/", cn);
	float aframe = flag_animate(cn);
	if (aframe >= 0)
		i = strcat(i, "-", ftos(fabs(rint(aframe))));

	if (drawgetimagesize(i) == '0 0 0')
		return strcat(path, "/xx");

	return i;
}
