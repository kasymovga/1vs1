#define BGM_CONSTANT_SPEED_DECAY

float bgm_script_buf;
float bgm_script_bufsize;
float bgm_script_bufloaded;

.float bgmscriptline;
.float bgmscriptline0;
.float bgmscriptvolume;
.float bgmscripttime;
.float bgmscriptstate;
.float bgmscriptstatetime;

float(float a, float d, float s, float t) bgm_GetAttackDecaySustainAmplitude {
	// phase:
	//   attack: from 0 to 1, in time a for a full length
	//   decay: from 1 to s, in time d
	//   sustain: s
	if (t < 0)
		return 0;
	
	if (a)
	if(t <= a)
		return t / a;

	if (d)
	if (t <= a + d)
		return ((t - a) / d) * (s - 1) + 1;

	return s;
}

float(float d, float s, float r, float t) bgm_GetReleaseAmplitude {
	float decayval, releaseval;
	if not(r)
		return 0;
	
	if (t > r)
		return 0;
	
	releaseval = s * (1 - t / r);
	if (t < -d)
		return 1;

	if (t < 0 && t >= -d) {
		// pre-time decay
		// value is s at time  0
		//          1 at time -d
		decayval = ((t + d) / d) * (s - 1) + 1;
		return max(decayval, releaseval);
	}
	return releaseval;
}

float(float a, float amp) bgm_GetAttackTime {
	return amp * a;
}

float(float d, float s, float r, float amp) bgm_GetReleaseTime {
	float decaytime, releasetime;
	if not(s)
		return 0;
	
	// if amp > s, we may be in the attack or in the prolonged decay curve
	releasetime = (1 - amp / s) * r;
	if (amp > s) {
		if (s == 1) // gracefully handle division by zero here
			return 0;

		// pre-time decay
		// value is s at time  0
		//          1 at time -d
		decaytime = (amp - 1) / (s - 1) * d - d;
		return max(decaytime, releasetime);
	}
	return releasetime;
}

void(void) bgm_script_init {
	string s;
	float fh;
	bgm_script_buf = bgm_script_bufsize = 0;
	bgm_script_bufloaded = 1;
	s = strcat("maps/", map_shortname, ".bgs");
	fh = fopen(s, FILE_READ);
	if (fh < 0)
		return;

	bgm_script_buf = buf_create();
	while((s = fgets(fh))) {
		bufstr_set(bgm_script_buf, bgm_script_bufsize, s);
		++bgm_script_bufsize;
	}
	fclose(fh);
}

void(entity e) bgm_script_init_entity {
	float l;
	string m;
	if (e.bgmscript != "") {
		if not(bgm_script_bufloaded)
			bgm_script_init();

		float i;
		m = strcat(e.bgmscript, " ");
		l = strlen(m);
		e.bgmscriptline0 = -1;
		for (i = 0; i < bgm_script_bufsize; ++i) {
			if (substring(bufstr_get(bgm_script_buf, i), 0, l) == m)
				break;
		}
		e.bgmscriptline = e.bgmscriptline0 = i;
		if (i >= bgm_script_bufsize) {
			print("ERROR: bgmscript does not define ", e.bgmscript, "\n");
			e.bgmscript = "";
		}
	}
}

float(entity e, float trel) bgm_GetCurrentAmplitude {
	if (e.bgmscriptstate)
		return bgm_GetAttackDecaySustainAmplitude(e.bgmscriptattack, e.bgmscriptdecay, e.bgmscriptsustain, trel) * e.bgmscriptvolume;
	else {
#ifdef BGM_CONSTANT_SPEED_DECAY
		return bgm_GetReleaseAmplitude(e.bgmscriptdecay, e.bgmscriptsustain * e.bgmscriptvolume, e.bgmscriptrelease, trel);
#else
		return bgm_GetReleaseAmplitude(e.bgmscriptdecay, e.bgmscriptsustain, e.bgmscriptrelease, trel) * e.bgmscriptvolume;
#endif
	}
}

float(entity e, float amp) bgm_GetTimeForAmplitude {
	if (e.bgmscriptstate)
		return bgm_GetAttackTime(e.bgmscriptattack, amp / e.bgmscriptvolume);
	else {
#ifdef BGM_CONSTANT_SPEED_DECAY
		return bgm_GetReleaseTime(e.bgmscriptdecay, e.bgmscriptsustain * e.bgmscriptvolume, e.bgmscriptrelease, amp);
#else
		return bgm_GetReleaseTime(e.bgmscriptdecay, e.bgmscriptsustain, e.bgmscriptrelease, amp / e.bgmscriptvolume);
#endif
	}
}

float(entity e) bgm_script {
	float t;
	float amp, vel;
	if (CVAR(bgmvolume) <= 0)
		return -1;

	e.just_toggled = FALSE;
	t = gettime(GETTIME_CDTRACK);
	if (t < 0)
		return -1;

	if (t < e.bgmscripttime) {
		//print("reset ", e.bgmscript, "\n");
		amp = bgm_GetCurrentAmplitude(e, e.bgmscripttime - e.bgmscriptstatetime + view_drawframetime);
		e.bgmscriptline = e.bgmscriptline0;
		e.bgmscripttime = t;
		// treat this as a stop event for all notes, to prevent sticking keys
		e.bgmscriptstate = FALSE;
		e.bgmscriptvolume = 1;
		e.bgmscriptstatetime = t - bgm_GetTimeForAmplitude(e, amp);
	}
	// find the CURRENT line
	for (;;) {
		tokenize_console(bufstr_get(bgm_script_buf, e.bgmscriptline));
		if (stof(argv(1)) >= t || argv(0) != e.bgmscript) {
			e.bgmscripttime = t;
			return bgm_GetCurrentAmplitude(e, t - e.bgmscriptstatetime);
		} else if (t >= stof(argv(1))) {
			e.bgmscriptline += 1;
			e.bgmscripttime = stof(argv(1));
			amp = bgm_GetCurrentAmplitude(e, e.bgmscripttime - e.bgmscriptstatetime);
			// time code reached!
			vel = stof(argv(2));
			if (vel > 0) {
				e.just_toggled = e.bgmscriptstate = TRUE;
				e.bgmscriptvolume = vel;
			} else
				e.just_toggled = e.bgmscriptstate = FALSE;

			e.bgmscriptstatetime = e.bgmscripttime - bgm_GetTimeForAmplitude(e, amp);
		}
	}
}

