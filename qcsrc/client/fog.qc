void(void) fog_force {
	// TODO somehow thwart prvm_globalset client ...
	if(forcefog != "")
		localcmd(strcat("\nfog ", forcefog, "\nr_fog_exp2 0\nr_drawfog 1\n"));
}
