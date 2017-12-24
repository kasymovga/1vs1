void SkinInit() {
	float fh, glob, n, i;
	string s;
	fh = -1;
	if(cvar_string("menu_skin") != "")
	{
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
#ifndef CSQC
	if(fh < 0)
	if(cvar_defstring("menu_skin") != "")
	{
		draw_currentSkin = strcat("gfx/menu/", cvar_defstring("menu_skin"));
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
#endif
	if(fh < 0)
	{
		draw_currentSkin = "gfx/menu/default";
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
	draw_currentSkin = strzone(draw_currentSkin);
	while((s = fgets(fh)))
	{
		// these two are handled by skinlist.qc
		if(substring(s, 0, 6) == "title ")
			continue;
		if(substring(s, 0, 7) == "author ")
			continue;
		n = tokenize_console(s);
		if(n >= 2)
			Skin_ApplySetting(argv(0), substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
	}
	fclose(fh);

	glob = search_begin(strcat(draw_currentSkin, "/*.tga"), TRUE, TRUE);
	if(glob >= 0)
	{
		n = search_getsize(glob);
		for(i = 0; i < n; ++i)
			precache_pic(search_getfilename(glob, i));
		search_end(glob);
	}

}
