void(void) fog_force {
	// TODO somehow thwart prvm_globalset client ...
	if(fog_settings != "")
		localcmd(strcat("\nfog ", fog_settings, "\nr_fog_exp2 0\nr_drawfog 1\n"));
}
