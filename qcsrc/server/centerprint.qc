void(entity e, string s) centerprint {
	entity spec;
	if (e.classname == "player")
		FOR_EACH_REALCLIENT(spec)
			if (spec.enemy == e)
			if (spec.classname == "spectator")
				centerprint(spec, s);

	builtin_centerprint(e, s);
}
