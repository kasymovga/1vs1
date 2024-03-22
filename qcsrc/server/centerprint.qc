void(entity e, string s) centerprint {
	entity spec;
	if (e.classname == "player")
		FOR_EACH_REALCLIENT(spec)
			if (spec.enemy == e)
			if (spec.classname == "spectator")
				centerprint(spec, s);

	builtin_centerprint(e, s);
}

void(entity e, string s, string arg1, string arg2, string arg3) centerprint_with_args {
	entity spec;
	if (e.classname == "player")
		FOR_EACH_REALCLIENT(spec)
			if (spec.enemy == e)
			if (spec.classname == "spectator")
				centerprint_with_args(spec, s, arg1, arg2, arg3);

	print_to(e, PRINT_CENTER, s, arg1, arg2, arg3);
}
