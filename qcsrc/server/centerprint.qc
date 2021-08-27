.float centerprint_priority;
.float centerprint_expires;
void(entity e, float prio, string s) centerprint_atprio {
	if (map_intermission_running)
		if (prio < CENTERPRINT_PRIO_MAPVOTE)
			return;

	entity spec;
	if (e.classname == "player")
		FOR_EACH_REALCLIENT(spec)
			if (spec.enemy == e)
			if (spec.classname == "spectator")
				centerprint_atprio(spec, prio, s);

	if (time > e.centerprint_expires)
		e.centerprint_priority = 0;

	if (prio >= e.centerprint_priority) {
		e.centerprint_priority = prio;
		e.centerprint_expires = time + (e.cvar_scr_centertime * max(slowmo, 0.0001));
		builtin_centerprint(e, s);
	}
}

void(entity e, float prio) centerprint_expire {
	if (prio == e.centerprint_priority) {
		e.centerprint_priority = 0;
		builtin_centerprint(e, "");
	}
}

void centerprint(entity e, string s) {
	centerprint_atprio(e, CENTERPRINT_PRIO_NORMAL, s);
}
