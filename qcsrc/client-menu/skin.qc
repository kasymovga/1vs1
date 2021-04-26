void(void) skin_init {
	float fh, n;
	string s;
	fh = -1;
	str_unzone_ifneeded(draw_skin);
	if (cvar_string("menu_skin") != "") {
		draw_skin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(draw_skin, "/skinvalues.txt"), FILE_READ);
	}
#ifndef CSQC
	if (fh < 0)
	if (cvar_defstring("menu_skin") != "") {
		draw_skin = strcat("gfx/menu/", cvar_defstring("menu_skin"));
		fh = fopen(strcat(draw_skin, "/skinvalues.txt"), FILE_READ);
	}
#endif
	if (fh < 0) {
		draw_skin = "gfx/menu/default";
		fh = fopen(strcat(draw_skin, "/skinvalues.txt"), FILE_READ);
	}
	draw_skin = strzone(draw_skin);
	while ((s = fgets(fh))) {
		// these two are handled by skinlist.qc
		if(substring(s, 0, 6) == "title ")
			continue;

		if(substring(s, 0, 7) == "author ")
			continue;

		n = tokenize_console(s);
		if(n >= 2)
			skin_setting_apply(argv(0), substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
	}
	fclose(fh);
}
