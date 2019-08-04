void(entity e, vector anim, float looping, float override, float restart) anim_set {
	if (anim_x == e.animstate_startframe)
	if (anim_y == e.animstate_numframes)
	if (anim_z == e.animstate_framerate) {
		if(restart) {
			if(restart > 0)
			if(anim_y == 1) // ZYM animation
				BITXOR_ASSIGN(e.effects, EF_TELEPORT_BIT);
		} else
			return;
	}
	e.animstate_startframe = anim_x;
	e.animstate_numframes = anim_y;
	e.animstate_framerate = anim_z;
	e.animstate_starttime = time - 0.01; // shift it a little bit into the past to prevent float inaccuracy hiccups
	e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
	e.animstate_looping = looping;
	e.animstate_override = override;
	e.frame = e.animstate_startframe;
}

void(entity e) anim_update {
	if (time >= e.animstate_endtime) {
		if (e.animstate_looping) {
			e.animstate_starttime = e.animstate_endtime;
			e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
		}
		e.animstate_override = FALSE;
	}
	e.frame = e.animstate_startframe + bound(0, (time - e.animstate_starttime) * e.animstate_framerate, e.animstate_numframes - 1);
	//print(ftos(time), " -> ", ftos(e.frame), "\n");
}

vector(float animfile) anim_parseline {
	string line;
	float c;
	vector anim;
	if (animfile < 0)
		return '0 1 2';

	line = fgets(animfile);
	c = tokenize_console(line);
	if (c < 3) {
		anim_parseerror = TRUE;
		return '0 1 2';
	}
	anim_x = stof(argv(0));
	anim_y = stof(argv(1));
	anim_z = stof(argv(2));
	// don't allow completely bogus values
	if (anim_x < 0 || anim_y < 1 || anim_z < 0.001)
		anim = '0 1 2';

	return anim;
}
