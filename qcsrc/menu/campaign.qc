void(void) campaign_init {
	float file = fopen("campaign.cfg", FILE_READ);
	if (file < 0) return;
	print("Loading campaign.cfg\n");
	string l;
	float n;
	string arg1;
	while ((l = fgets(file))) {
		n = tokenize_console(l);
		if (n != 3)
			continue;

		if (argv(0) != "set")
			continue;

		arg1 = argv(1);
		if (substring(arg1, 0, 10) != "g_campaign") {
			print("Unknown variable in campaign.cfg: ", arg1, "\n");
			continue;
		}
		if (substring(arg1, -6, 6) != "_index" && substring(arg1, -4, 4) != "_won") continue;
		registercvar(arg1, "", 0);
		cvar_set(arg1, argv(2));
	}
	fclose(file);
}
